# BoardStreams::Client against the real server: two hubs standing in for
# two server processes, and Perl clients connected to them over real
# WebSockets. Mirrors test/e2e.test.ts of the JavaScript client.
use v5.44;
use Test::More;

plan skip_all => 'set TEST_ONLINE to a PostgreSQL connection string to run this test'
    unless $ENV{TEST_ONLINE};

use Future::AsyncAwait future_class => 'Mojo::Promise';
use Mojo::IOLoop;
use Mojo::Pg;
use Mojo::Promise;
use Mojo::Server::Daemon;
use Mojolicious;
use Time::HiRes qw(time);

use BoardStreams::Client;

my $schema = 'bs_client_test';
my $admin  = Mojo::Pg->new($ENV{TEST_ONLINE});
$admin->db->query("drop schema if exists $schema cascade");
$admin->db->query("create schema $schema");

sub server {
    my $app = Mojolicious->new;
    $app->log->level('fatal');
    my $hub = $app->plugin(BoardStreams => {
        pg                      => Mojo::Pg->new($ENV{TEST_ONLINE})->search_path([$schema]),
        identify                => sub ($c) { $c->param('user') },
        retry_delay             => 0.3,
        listener_check_interval => 0.2,
    });
    $hub->channel('counter:*',
        initial_state => { n => 0, log => [] },
        join          => sub ($ctx) {
            $ctx->reject('members_only', { hint => 'ask an admin' }) if $ctx->channel eq 'counter:private';
            return 1;
        },
        actions  => { wave => sub ($ctx, $payload) { $ctx->emit(waved => $payload) } },
        requests => {
            add => async sub ($ctx, $payload) {
                $ctx->reject('too_big', { max => 10 }) if abs $payload->{by} > 10;
                my $n;
                await $ctx->update(sub ($u) {
                    $n = $u->state->{n} += $payload->{by};
                    push $u->state->{log}->@*, $payload->{by};
                    $u->emit(added => { by => $payload->{by} });
                });
                return { n => $n };
            },
            slow => sub ($ctx, $payload) { Mojo::Promise->timer(30) },
        },
    );
    my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1)->start;
    return { hub => $hub, daemon => $daemon, url => 'ws://127.0.0.1:' . $daemon->ports->[0] . '/boardstreams' };
}
my @servers = (server(), server());

my @clients;
sub connect_to ($server, $user = undef) {
    my $bs = BoardStreams::Client->new(
        url => $servers[$server]{url} . (defined $user ? "?user=$user" : ''), min_delay => 0.05, max_delay => 0.5);
    push @clients, $bs;
    return $bs;
}
sub wait_for ($condition, $what, $seconds = 10) {
    my $deadline = time + $seconds;
    my $tick     = Mojo::IOLoop->recurring(0.005 => sub { });
    Mojo::IOLoop->one_tick until $condition->() or time > $deadline;
    Mojo::IOLoop->remove($tick);
    return ok $condition->(), $what;
}
sub settle ($promise) {
    my @result;
    $promise->then(sub (@values) { @result = (resolved => @values) }, sub ($error) { @result = (rejected => $error) });
    wait_for(sub { scalar @result }, 'the promise settled');
    return @result;
}
sub value ($promise) { my ($how, $value) = settle($promise); is $how, 'resolved', 'it resolved' or diag "$value"; return $value }
sub failure ($promise, $reason, $data, $what) {
    my ($how, $error) = settle($promise);
    is $how, 'rejected', "$what: rejected";
    return fail "$what: not an error object" unless ref $error and $error->isa('BoardStreams::Client::Error');
    is $error->reason, $reason, "$what: reason";
    is_deeply $error->data, $data, "$what: data";
}
sub collect ($observable) {
    my @seen;
    $observable->subscribe(sub ($value) { push @seen, $value });
    return \@seen;
}
sub joined (@channels) { value($_->joined) for @channels }

subtest 'two clients on two server processes share a channel' => sub {
    my $alice = connect_to(0)->join('counter:shared');
    my $bob   = connect_to(1)->join('counter:shared');
    joined($alice, $bob);
    is_deeply $alice->state, { n => 0, log => [] }, 'the initial state';

    my @bob_saw;
    $bob->events_o->subscribe(sub ($event) { push @bob_saw, [$event->{name}, $event->{payload}, $bob->state->{n}] });

    is_deeply value($alice->request('add', { by => 3 })), { n => 3 }, 'the response payload';
    is_deeply $alice->state, { n => 3, log => [3] }, 'the state already reflects the request when its promise resolves';

    $alice->action('wave', 'hello');
    wait_for(sub { @bob_saw == 2 }, 'the other client saw both events');
    is_deeply \@bob_saw, [['added', { by => 3 }, 3], ['waved', 'hello', 3]], '...in order, each with the state up to date';

    failure($alice->request('add', { by => 50 }), 'too_big', { max => 10 }, 'a request the handler rejects');
    failure(connect_to(0)->join('counter:private')->joined, 'members_only', { hint => 'ask an admin' }, 'a join the handler refuses');
    failure(connect_to(0)->join('nowhere')->joined, 'unknown_channel', undef, 'a channel nobody registered');
};

subtest 'kick, kick_all, disconnect and delete_channel' => sub {
    my $hub   = $servers[0]{hub};
    my @hal   = (connect_to(0, 'hal'), connect_to(1, 'hal'));
    my @room  = map { $_->join('counter:mod') } @hal;
    my $other = $hal[0]->join('counter:elsewhere');
    my $ivy   = connect_to(1, 'ivy')->join('counter:mod');
    joined(@room, $other, $ivy);

    my @room_statuses = map { collect($_->status_o) } @room;
    my $unanswered    = $room[1]->request('slow');
    Mojo::Promise->timer(0.1)->wait;
    value($hub->kick('hal', 'counter:mod', 'spam', { strikes => 3 }));
    failure($unanswered, 'spam', { strikes => 3 }, 'an unanswered request of a kicked client');
    wait_for(sub { !grep { $_->[-1] ne 'rejected' } @room_statuses },
        'both of the user\'s clients were removed, on both servers');
    failure($room[0]->request('add', { by => 1 }), 'rejected', undef, 'a request on a channel one was kicked from');
    is_deeply value($ivy->request('add', { by => 1 })),   { n => 1 }, 'another user is still in the channel';
    is_deeply value($other->request('add', { by => 2 })), { n => 2 }, 'the kicked user keeps their other channel';

    my $back = $hal[0]->join('counter:mod');
    joined($back);
    my @statuses = map { collect($_->status_o) } $back, $ivy;
    value($servers[1]{hub}->kick_all('counter:mod', 'closing_time'));
    wait_for(sub { !grep { $_->[-1] ne 'rejected' } @statuses }, 'kick_all removes everyone, whoever they are');

    my $doomed = $hal[1]->join('counter:doomed');
    joined($doomed);
    value($doomed->request('add', { by => 4 }));
    my $doomed_status = collect($doomed->status_o);
    is value($hub->delete_channel('counter:doomed', 'archived')), 1, 'the channel is deleted';
    wait_for(sub { $doomed_status->[-1] eq 'rejected' }, 'its member is removed and told');
    my $fresh = $hal[1]->join('counter:doomed');
    joined($fresh);
    is_deeply $fresh->state, { n => 0, log => [] }, 'joined again, the channel starts afresh';

    my @connections = map { collect($_->status_o) } @hal;
    value($hub->disconnect('hal', 'banned', { days => 7 }));
    wait_for(sub { !grep { $_->[-1] ne 'closed' } @connections }, 'disconnect closes all of the user\'s connections');
    failure($hal[0]->join('counter:mod')->joined, 'banned', { days => 7 }, 'a channel joined after being disconnected');
    Mojo::Promise->timer(0.7)->wait;
    is_deeply [map { $_->[-1] } @connections], ['closed', 'closed'], 'the clients do not reconnect';
};

subtest 'a client catches up after its server stops hearing PostgreSQL' => sub {
    my ($near, $far) = (connect_to(0), connect_to(1));
    my $carol = $near->join('counter:deaf');
    my $dave  = $far->join('counter:deaf');
    joined($carol, $dave);
    value($carol->request('add', { by => 1 }));
    my $connection = collect($near->status_o);
    my $channel    = collect($carol->status_o);
    my $events     = collect($carol->events_o);
    my $gaps       = collect($carol->gaps_o);

    # The first server's listening connection goes deaf, so it lets go of
    # its clients; meanwhile the channel moves on through the other one.
    $servers[0]{hub}->pg->pubsub->db->query('unlisten boardstreams_control');
    wait_for(sub { grep { $_ eq 'disconnected' } @$connection }, 'the client was disconnected');
    my $pending = $carol->request('add', { by => 5 });
    value($dave->request('add', { by => 2 }));
    value($dave->request('add', { by => 2 }));

    is_deeply value($pending), { n => 10 }, 'a request made while disconnected is delivered once the client is back';
    is_deeply $carol->state, { n => 10, log => [1, 2, 2, 5] }, 'the client has caught up';
    is_deeply [map { $_->{payload}{by} } @$events], [2, 2, 5], 'the events it missed were replayed, in order';
    is scalar @$gaps, 0, 'no gap was reported, since nothing was lost';
    is_deeply [@$channel[0, 1, -1]], ['joined', 'joining', 'joined'], 'the channel went through joining and back';
    wait_for(sub { $dave->state->{n} == 10 }, 'the other client saw the late request');
};

$_->close for @clients;
Mojo::Promise->timer(0.1)->wait;
$admin->db->query("drop schema $schema cascade");
done_testing;
