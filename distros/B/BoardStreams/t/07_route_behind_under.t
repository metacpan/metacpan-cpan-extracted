# The WebSocket route behind an "under" (the plugin's routes option), both
# one that answers at once and one that answers later, as a check that
# looks something up would. The second kind used to get its connection
# closed with code 1006 right after the first heartbeat.
use v5.44;
use Test::More;

plan skip_all => 'set TEST_ONLINE to a PostgreSQL connection string to run this test'
    unless $ENV{TEST_ONLINE};

use Mojo::IOLoop;
use Mojo::Pg;
use Mojo::Promise;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojolicious;
use Time::HiRes qw(time);

use BoardStreams;
use BoardStreams::Client;

my $schema = 'bs_under_test';
my $admin  = Mojo::Pg->new($ENV{TEST_ONLINE});
$admin->db->query("drop schema if exists $schema cascade");
$admin->db->query("create schema $schema");

sub server ($late) {
    my $app = Mojolicious->new;
    $app->log->level('fatal');
    my $gate = $app->routes->under(sub ($c) {
        my $decide = sub {
            return $c->render(text => 'no entry', status => 403) && undef if $c->param('refuse');
            # What a server that signs its answer would do.
            $c->res->headers->header('X-Signed-By' => 'the gate');
            $c->res->headers->header('X-Signed-Nonce' => 'signed:' . ($c->req->headers->header('X-Nonce') // ''));
            return 1;
        };
        return $decide->() unless $late;
        Mojo::IOLoop->timer(0.05 => sub { $c->continue if $decide->() });
        return undef;
    });
    my $hub = $app->plugin(BoardStreams => {
        pg                      => Mojo::Pg->new($ENV{TEST_ONLINE})->search_path([$schema]),
        routes                  => $gate,
        retry_delay             => 0.3,
        listener_check_interval => 0.2,
        heartbeat_interval      => 0.2,
    });
    $hub->channel('room:*', initial_state => { n => 0 }, join => sub ($ctx) { 1 });
    my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1)->start;
    return { hub => $hub, daemon => $daemon, url => 'ws://127.0.0.1:' . $daemon->ports->[0] . '/boardstreams' };
}

sub wait_for ($condition, $what, $seconds = 10) {
    my $deadline = time + $seconds;
    my $tick     = Mojo::IOLoop->recurring(0.005 => sub { });
    Mojo::IOLoop->one_tick until $condition->() or time > $deadline;
    Mojo::IOLoop->remove($tick);
    return ok $condition->(), $what;
}
sub idle ($seconds) { my $until = time + $seconds; wait_for(sub { time >= $until }, "waited ${seconds}s", $seconds + 1) }

my $ua = Mojo::UserAgent->new->inactivity_timeout(0);

# Opens a connection by hand and records what the server does with it.
sub open_raw ($url) {
    my $seen = { messages => [] };
    $ua->websocket($url => sub ($ua, $tx) {
        $seen->{status}  = $tx->res->code;
        $seen->{headers} = $tx->res->headers;
        return $seen->{closed} = 'refused' unless $tx->is_websocket;
        $seen->{tx} = $tx;
        $tx->on(json   => sub ($tx, $message) { push $seen->{messages}->@*, $message });
        $tx->on(finish => sub ($tx, $code, @) { $seen->{closed} = $code });
    });
    return $seen;
}

for my $case (['an "under" that answers at once', 0], ['an "under" that answers later', 1]) {
    my ($what, $late) = @$case;
    subtest "behind $what" => sub {
        my $server = server($late);
        my $hub    = $server->{hub};

        my $raw = open_raw($server->{url});
        wait_for(sub { $raw->{messages}->@* >= 1 }, 'the server spoke');
        is $raw->{status}, 101, 'the handshake was accepted';
        is $raw->{headers}->header('X-Signed-By'), 'the gate', 'a header that the "under" set is in the answer to the handshake';
        is_deeply $raw->{messages}[0],
            { type => 'heartbeat', interval => 0.2, protocol => BoardStreams::PROTOCOL_VERSION },
            'the first message is the heartbeat that carries the protocol version';
        $raw->{tx}->send({ json => { type => 'join', channel => "room:raw$late" } });
        wait_for(sub { grep { $_->{type} eq 'joined' } $raw->{messages}->@* }, 'joined');
        $hub->emit("room:raw$late", hello => 'there')->wait;
        wait_for(sub { grep { $_->{type} eq 'update' } $raw->{messages}->@* }, 'an event arrived');
        is_deeply [grep { $_->{type} ne 'heartbeat' } $raw->{messages}->@*], [
            { type => 'joined', channel => "room:raw$late", seq => 0, state => { n => 0 } },
            { type => 'update', channel => "room:raw$late", seq => 1, events => [{ name => 'hello', payload => 'there' }] },
        ], 'the messages and their order are the usual ones';
        idle(0.7);
        ok !$raw->{closed}, 'the connection is still open after several heartbeats';
        cmp_ok scalar(grep { $_->{type} eq 'heartbeat' } $raw->{messages}->@*), '>=', 3, '...which did arrive';

        my $refused = open_raw("$server->{url}?refuse=1");
        wait_for(sub { $refused->{closed} }, 'a handshake that the "under" refuses ends');
        is $refused->{status}, 403, '...with its status';

        # The client of this distribution.
        my $bs       = BoardStreams::Client->new(url => $server->{url}, min_delay => 0.05, max_delay => 0.3);
        my $statuses = [];
        $bs->status_o->subscribe(sub ($status) { push @$statuses, $status });
        my $room   = $bs->join("room:client$late");
        my $events = [];
        $room->events_o->subscribe(sub ($event) { push @$events, $event->{name} });
        wait_for(sub { $room->state }, 'the client joined and has the state');
        is_deeply $room->state, { n => 0 }, 'the state';
        $hub->update("room:client$late", sub ($u) { $u->state->{n} = 5; $u->emit('changed') })->wait;
        wait_for(sub { @$events }, 'the client received an event');
        is_deeply $room->state, { n => 5 }, '...and the change of state';
        idle(0.7);
        is_deeply $statuses, ['connecting', 'connected'], 'the client stayed connected throughout';
        $bs->close;

        # The two sides checking each other at the handshake, with the
        # client's headers and on_handshake options.
        my ($nonce, @answers) = (0);
        my %signing = (
            headers      => sub { { 'X-Nonce' => 'n' . ++$nonce } },
            on_handshake => sub ($handshake) {
                push @answers, [$handshake->code, $handshake->header('X-Signed-Nonce')];
                return BoardStreams::Client::Error->new(reason => 'refused', data => $handshake->body) unless $handshake->accepted;
                return $handshake->header('X-Signed-Nonce') eq 'signed:' . $handshake->sent->{'X-Nonce'};
            },
        );
        my $signed = BoardStreams::Client->new(url => $server->{url}, min_delay => 0.05, %signing);
        my $signed_room = $signed->join("room:client$late");
        wait_for(sub { $signed_room->state }, 'a client that checks the signature of the answer joins');
        is_deeply \@answers, [[101, 'signed:n1']], '...having seen the signature of its own nonce';
        $signed->close;
        my $unwelcome = BoardStreams::Client->new(url => "$server->{url}?refuse=1", min_delay => 0.05, %signing);
        my ($outcome, $error);
        $unwelcome->join('room:any')->joined->then(sub { $outcome = 'joined' }, sub { ($outcome, $error) = ('refused', shift) });
        wait_for(sub { $outcome }, 'a client that the gate turns away gives up');
        is_deeply [$outcome, $error->reason, $error->data], ['refused', 'refused', 'no entry'], '...with the reason its callback chose';

        # A process that cannot hear PostgreSQL refuses connections.
        $hub->pg->pubsub->db->query('unlisten boardstreams_control');
        wait_for(sub { ($raw->{closed} // 0) == 1013 }, 'a process that stops hearing PostgreSQL lets go of the connection with 1013');
        my $deaf = open_raw($server->{url});
        wait_for(sub { $deaf->{closed} }, 'a connection made meanwhile ends');
        is $deaf->{closed}, 1013, '...refused with 1013';
        is $deaf->{status}, 101, '...after an accepted handshake, as before';
        my $back;
        wait_for(sub {
            $back = open_raw($server->{url}) if !$back or $back->{closed};
            scalar $back->{messages}->@*;
        }, 'connections are served again once the process hears PostgreSQL');

        # A process that is stopping gracefully refuses them too.
        Mojo::IOLoop->singleton->emit('finish');
        wait_for(sub { ($back->{closed} // 0) == 1001 }, 'a graceful stop lets go of the connection with 1001');
        my $stopping = open_raw($server->{url});
        wait_for(sub { $stopping->{closed} }, 'a connection made during the stop ends');
        is $stopping->{closed}, 1001, '...refused with 1001';
        Mojo::IOLoop->singleton->unsubscribe('finish');
    };
}

$admin->db->query("drop schema $schema cascade");
done_testing;
