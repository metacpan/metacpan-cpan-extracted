# BoardStreams::Client against a scripted server: the test plays the
# server's part message by message. Mirrors test/client.test.ts of the
# JavaScript client. Needs no database.
use v5.44;
use Test::More;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojolicious;
use Time::HiRes qw(time);

use BoardStreams::Client;

my $PROTOCOL = BoardStreams::PROTOCOL_VERSION;

# The scripted server keeps every connection it was given, in order.
my @connections;
my $accepting = 1;
my $app = Mojolicious->new;
$app->log->level('fatal');
$app->routes->websocket('/boardstreams' => sub ($c) {
    return $c->finish(1013) unless $accepting;
    $c->inactivity_timeout(300);
    my $connection = { c => $c, got => [], closed => 0, ready => 0 };
    push @connections, $connection;
    # The test may only speak once the handshake is over. (The real server
    # greets from inside this action, which is fine at any time.)
    Mojo::IOLoop->timer(0.02 => sub { $connection->{ready} = 1 });
    $c->on(json   => sub ($c, $message) { push $connection->{got}->@*, $message });
    $c->on(finish => sub { $connection->{closed} = 1 });
});
my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1)->start;
my $url    = 'ws://127.0.0.1:' . $daemon->ports->[0] . '/boardstreams';

sub client (%options) { BoardStreams::Client->new(url => $url, min_delay => 0.1, max_delay => 0.4, %options) }

# Runs the event loop until the condition holds.
sub wait_for ($condition, $what, $seconds = 5) {
    my $deadline = time + $seconds;
    my $tick     = Mojo::IOLoop->recurring(0.005 => sub { });
    Mojo::IOLoop->one_tick until $condition->() or time > $deadline;
    Mojo::IOLoop->remove($tick);
    my $ok = $condition->();
    ok $ok, $what;
    return $ok;
}
sub idle ($seconds) { my $until = time + $seconds; wait_for(sub { time >= $until }, "waited ${seconds}s", $seconds + 1) }

sub connection_number ($n) {
    wait_for(sub { @connections >= $n and $connections[$n - 1]{ready} }, "connection number $n was made");
    return $connections[$n - 1];
}
sub server_says ($connection, $message) { $connection->{c}->send({ json => $message }) }
sub greet ($connection, %with) { server_says($connection, { type => 'heartbeat', interval => 1000, protocol => $PROTOCOL, %with }) }
sub take ($connection, $count, $what) {
    wait_for(sub { $connection->{got}->@* >= $count }, $what);
    return splice $connection->{got}->@*, 0, $count;
}
sub collect ($observable) {
    my @seen;
    $observable->subscribe({ next => sub ($value) { push @seen, $value }, complete => sub { push @seen, '(complete)' } });
    return \@seen;
}
sub outcome ($promise) {
    my @result;
    $promise->then(sub (@values) { @result = (resolved => @values) }, sub ($error) { @result = (rejected => $error) });
    wait_for(sub { scalar @result }, 'the promise settled');
    return @result;
}
sub error_like ($promise, $reason, $data, $what) {
    my ($how, $error) = outcome($promise);
    is $how, 'rejected', "$what: rejected";
    isa_ok $error, 'BoardStreams::Client::Error';
    is $error->reason, $reason, "$what: reason";
    is_deeply $error->data, $data, "$what: data";
    is "$error", "BoardStreams: $reason", "$what: reads as a message";
}

subtest 'joins once the server has announced the same protocol version, and exposes the state' => sub {
    @connections = ();
    my $bs       = client();
    my $statuses = collect($bs->status_o);
    my $channel  = $bs->join('counter');
    is $bs->join('counter'), $channel, 'joining twice gives the same channel';
    my $server = connection_number(1);

    idle(0.1);
    is_deeply $server->{got}, [], 'nothing is sent before the server greets';
    is_deeply $statuses, ['connecting'], '...and the connection does not count as made';
    is $channel->state, undef, 'no state yet';

    greet($server, interval => 25);
    is_deeply [take($server, 1, 'the join arrived')], [{ type => 'join', channel => 'counter' }], 'the join is sent after the greeting';
    is_deeply $statuses, ['connecting', 'connected'], 'connected';

    server_says($server, { type => 'joined', channel => 'counter', seq => 7, state => { n => 1 } });
    is_deeply [outcome($channel->joined)], ['resolved'], 'joined() resolves';
    is_deeply collect($channel->state_o), [{ n => 1 }], 'state_o replays the state to a late subscriber';
    is_deeply $channel->state, { n => 1 }, 'state';
    is_deeply collect($channel->status_o), ['joined'], 'status_o replays the status';

    server_says($server, { type => 'heartbeat', interval => 25 });
    idle(0.1);
    ok !$server->{closed}, 'a later heartbeat without a protocol version changes nothing';
    $bs->close;
};

subtest 'applies updates in order: state first, then events' => sub {
    @connections = ();
    my $bs      = client();
    my $channel = $bs->join('counter');
    my $server  = connection_number(1);
    greet($server);
    server_says($server, { type => 'joined', channel => 'counter', seq => 0, state => { n => 0, list => [1] } });
    wait_for(sub { $channel->state }, 'joined');

    my @seen;
    $channel->events_o->subscribe(sub ($event) { push @seen, [$event, $channel->state->{n}] });
    my $added  = collect($channel->on('added'));
    my $before = $channel->state;

    server_says($server, {
        type => 'update', channel => 'counter', seq => 1,
        diff   => { o => { n => { v => 5 } } },
        events => [{ name => 'added', payload => 5 }, { name => 'other', payload => undef }],
    });
    server_says($server, { type => 'update', channel => 'counter', seq => 1, diff => { o => { n => { v => 99 } } }, events => [] });
    wait_for(sub { @seen == 2 }, 'both events arrived');
    idle(0.05);

    is_deeply \@seen, [
        [{ name => 'added', payload => 5,     seq => 1 }, 5],
        [{ name => 'other', payload => undef, seq => 1 }, 5],
    ], 'events carry the sequence number and see the new state';
    is_deeply $added, [5], 'on() gives the payloads of one kind of event';
    is_deeply $channel->state, { n => 5, list => [1] }, 'an update that was already applied is ignored';
    is_deeply $before, { n => 0, list => [1] }, 'the previous state value is left untouched';
    is $channel->state->{list}, $before->{list}, '...and the parts that did not change are shared';
    $bs->close;
};

subtest 'a response is held until the update it caused has been applied' => sub {
    @connections = ();
    my $bs      = client();
    my $channel = $bs->join('counter');
    my $server  = connection_number(1);
    greet($server);
    server_says($server, { type => 'joined', channel => 'counter', seq => 3, state => { n => 0 } });
    take($server, 1, 'join');

    my @result;
    $channel->request('add', { by => 2 })->then(sub ($payload) { @result = ($payload, $channel->state->{n}) });
    my ($sent) = take($server, 1, 'the request arrived');
    is_deeply { %$sent, id => 'x' }, { type => 'request', channel => 'counter', id => 'x', name => 'add', payload => { by => 2 } },
        'the request as sent';
    like $sent->{id}, qr/\A[A-Za-z0-9]{32}\z/, '...with a unique id';

    server_says($server, { type => 'response', id => $sent->{id}, ok => Mojo::JSON->true, payload => 'done', seq => 4 });
    idle(0.1);
    is_deeply \@result, [], 'the response alone does not settle the request';

    server_says($server, { type => 'update', channel => 'counter', seq => 4, diff => { o => { n => { v => 2 } } }, events => [] });
    wait_for(sub { scalar @result }, 'the request settled');
    is_deeply \@result, ['done', 2], '...once the state reflects it';

    my $failing = $channel->request('add', { by => 99 });
    ($sent) = take($server, 1, 'second request');
    server_says($server, { type => 'response', id => $sent->{id}, ok => Mojo::JSON->false, error => { reason => 'too_big', data => { max => 10 } }, seq => 0 });
    error_like($failing, 'too_big', { max => 10 }, 'a failed request');
    $bs->close;
};

subtest 'reconnects with growing delays, rejoins from where it was and resends what was not confirmed' => sub {
    @connections = ();
    my $bs       = client();
    my $channel  = $bs->join('counter');
    my $statuses = collect($channel->status_o);
    my $first    = connection_number(1);
    greet($first);
    server_says($first, { type => 'joined', channel => 'counter', seq => 3, state => { n => 3 } });
    take($first, 1, 'join');

    $channel->action('poke');
    my ($acked) = take($first, 1, 'first action');
    server_says($first, { type => 'ack', id => $acked->{id} });
    idle(0.05);
    $channel->action('poke', 'again');
    my $request = $channel->request('add', { by => 1 });
    my ($action, $sent) = take($first, 2, 'an action and a request');

    # Refuse the next attempts, to watch the delays grow: at most 0.1,
    # 0.2, 0.4 and 0.4 seconds, and at least half of each.
    $accepting = 0;
    my $dropped = time;
    $first->{c}->finish;
    wait_for(sub { $first->{closed} }, 'the connection dropped');
    $channel->action('late');
    is_deeply $statuses, ['joining', 'joined', 'joining'], 'the channel is joining again while disconnected';
    idle(0.9);
    $accepting = 1;
    my $second = connection_number(2);
    my $took   = time - $dropped;
    cmp_ok $took, '>', 0.5, "the delays grew (reconnected after ${\ sprintf '%.2f', $took}s)";
    cmp_ok $took, '<', 2.5, '...up to the limit';

    greet($second);
    is_deeply [take($second, 1, 'rejoin')], [{ type => 'join', channel => 'counter', since => 3 }], 'it rejoins saying where it was';
    server_says($second, {
        type => 'joined', channel => 'counter', seq => 5,
        updates => [
            { seq => 4, diff => { o => { n => { v => 4 } } }, events => [] },
            { seq => 5, events => [{ name => 'poked', payload => undef }] },
        ],
    });
    my @resent = take($second, 3, 'what was unconfirmed is sent again');
    is_deeply [@resent[0, 1]], [$action, $sent], 'the same messages, same ids, in the same order';
    is_deeply [@{ $resent[2] }{qw(type name)}], ['action', 'late'], '...then what was queued while disconnected';
    ok !(grep { $_->{id} eq $acked->{id} } @resent), 'the acknowledged action is not sent again';
    is_deeply $channel->state, { n => 4 }, 'the missed updates were applied';
    is_deeply $statuses, ['joining', 'joined', 'joining', 'joined'], 'joined again';

    server_says($second, { type => 'response', id => $sent->{id}, ok => Mojo::JSON->true, payload => 'ok', seq => 4 });
    is_deeply [outcome($request)], [resolved => 'ok'], 'the request made before the drop is answered after it';

    my $again = time;
    $second->{c}->finish;
    connection_number(3);
    cmp_ok time - $again, '<', 0.3, 'after a working connection the delay starts small again';
    $bs->close;
};

subtest 'a snapshot after too long an absence replaces the state and reports a gap' => sub {
    @connections = ();
    my $bs      = client();
    my $channel = $bs->join('counter');
    my $gaps    = collect($channel->gaps_o);
    my $states  = collect($channel->state_o);
    my $first   = connection_number(1);
    greet($first);
    server_says($first, { type => 'joined', channel => 'counter', seq => 3, state => { n => 3 } });
    wait_for(sub { $channel->state }, 'joined');
    is scalar @$gaps, 0, 'no gap on a first join';

    $first->{c}->finish;
    my $second = connection_number(2);
    greet($second);
    server_says($second, { type => 'joined', channel => 'counter', seq => 900, gap => Mojo::JSON->true, state => { n => 900 } });
    wait_for(sub { @$gaps == 1 }, 'the gap is reported');
    is_deeply $states, [{ n => 3 }, { n => 900 }], 'the state was replaced';
    $bs->close;
};

subtest 'a skipped update makes the client reconnect instead of applying it' => sub {
    @connections = ();
    my $bs      = client();
    my $channel = $bs->join('counter');
    my $first   = connection_number(1);
    greet($first);
    server_says($first, { type => 'joined', channel => 'counter', seq => 1, state => { n => 1 } });
    server_says($first, { type => 'update', channel => 'counter', seq => 3, diff => { o => { n => { v => 3 } } }, events => [] });
    wait_for(sub { $first->{closed} }, 'the client dropped the connection');
    is_deeply $channel->state, { n => 1 }, 'the update was not applied';
    my $second = connection_number(2);
    greet($second);
    is_deeply [take($second, 1, 'rejoin')], [{ type => 'join', channel => 'counter', since => 1 }], 'it asks for what it missed';
    $bs->close;
};

subtest 'a refused join rejects joined() and pending requests' => sub {
    @connections = ();
    my $bs      = client();
    my $channel = $bs->join('secret');
    my $request = $channel->request('anything');
    my $server  = connection_number(1);
    greet($server);
    is_deeply [map { $_->{type} } take($server, 1, 'join')], ['join'], 'a request made before the join is held back';
    server_says($server, { type => 'rejected', channel => 'secret', reason => 'forbidden', data => { why => 'private' } });

    error_like($channel->joined, 'forbidden', { why => 'private' }, 'joined()');
    error_like($request,         'forbidden', { why => 'private' }, 'the held request');
    error_like($channel->request('more'), 'rejected', undef, 'a request on a refused channel');
    is_deeply collect($channel->status_o), ['(complete)'], 'the channel\'s observables have completed';
    isnt $bs->join('secret'), $channel, 'joining again makes a fresh attempt';
    $bs->close;
};

subtest 'leave and close' => sub {
    @connections = ();
    my $bs       = client();
    my $statuses = collect($bs->status_o);
    my $channel  = $bs->join('counter');
    my $other    = $bs->join('other');
    my $server   = connection_number(1);
    greet($server);
    take($server, 2, 'two joins');
    server_says($server, { type => 'joined', channel => 'counter', seq => 0, state => {} });
    wait_for(sub { $channel->state }, 'joined');

    my $request = $channel->request('slow');
    take($server, 1, 'request');
    $channel->leave;
    is_deeply [take($server, 1, 'leave')], [{ type => 'leave', channel => 'counter' }], 'leaving tells the server';
    error_like($request, 'left', undef, 'an unanswered request of a left channel');

    $bs->close;
    wait_for(sub { $server->{closed} }, 'the connection is closed');
    error_like($other->joined, 'left', undef, 'a channel that was still joining');
    is_deeply $statuses, ['connecting', 'connected', 'closed', '(complete)'], 'closed for good';
    idle(0.6);
    is scalar @connections, 1, 'it does not reconnect';
};

subtest 'a connection that goes silent is abandoned and replaced' => sub {
    @connections = ();
    my $bs       = client();
    my $statuses = collect($bs->status_o);
    my $channel  = $bs->join('counter');
    my $first    = connection_number(1);
    greet($first, interval => 0.2);
    server_says($first, { type => 'joined', channel => 'counter', seq => 1, state => { n => 1 } });

    # Any message counts as a sign of life, not only heartbeats.
    for my $seq (2 .. 4) {
        idle(0.3);
        server_says($first, { type => 'update', channel => 'counter', seq => $seq, events => [] });
    }
    idle(0.1);
    is scalar @connections, 1, 'the connection is kept while anything arrives';

    my $silent = time;
    my $second = connection_number(2);
    cmp_ok time - $silent, '>', 0.3, 'silence for two and a half intervals...';
    cmp_ok time - $silent, '<', 1.2, '...makes the client give up on the connection';
    is_deeply [@$statuses[-2, -1]], ['disconnected', 'connecting'], 'it reports the disconnection';

    greet($second);
    is_deeply [take($second, 1, 'rejoin')], [{ type => 'join', channel => 'counter', since => 4 }], 'and rejoins on a new connection';
    idle(0.8);
    is scalar @connections, 2, 'the new connection is judged by its own heartbeat interval';
    $bs->close;
};

for my $case (['another protocol version', $PROTOCOL + 1], ['a server too old to announce one', undef]) {
    my ($what, $announced) = @$case;
    subtest "refuses to work with $what" => sub {
        @connections = ();
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $bs       = client();
        my $statuses = collect($bs->status_o);
        my $channel  = $bs->join('counter');
        my $request  = $channel->request('add');
        my $server   = connection_number(1);
        server_says($server, { type => 'heartbeat', interval => 25, (defined $announced ? (protocol => $announced) : ()) });

        my $data = { client => $PROTOCOL, server => $announced };
        error_like($channel->joined, 'protocol_mismatch', $data, 'joined()');
        error_like($request,         'protocol_mismatch', $data, 'a pending request');
        wait_for(sub { $server->{closed} }, 'the connection is closed');
        is_deeply $server->{got}, [], 'nothing was ever sent to the server';
        is_deeply $statuses, ['connecting', 'closed', '(complete)'], 'closed without ever being connected';
        is scalar @warnings, 1, 'one warning';
        like $warnings[0], qr/client speaks protocol version $PROTOCOL but the server speaks/, '...naming the versions';

        idle(0.6);
        is scalar @connections, 1, 'it does not retry';
        error_like($bs->join('other')->joined, 'protocol_mismatch', $data, 'a channel joined afterwards');
    };
}

subtest 'being kicked from a channel ends that channel only' => sub {
    @connections = ();
    my $bs     = client();
    my $kicked = $bs->join('counter');
    my $other  = $bs->join('other');
    my $server = connection_number(1);
    greet($server);
    server_says($server, { type => 'joined', channel => $_, seq => 1, state => { n => 1 } }) for 'counter', 'other';
    take($server, 2, 'joins');
    wait_for(sub { $other->state }, 'both joined');
    my $statuses = collect($kicked->status_o);
    my $request  = $kicked->request('slow');
    take($server, 1, 'request');

    server_says($server, { type => 'rejected', channel => 'counter', reason => 'kicked', data => { by => 'admin' } });
    error_like($request, 'kicked', { by => 'admin' }, 'an unanswered request');
    is_deeply $statuses, ['joined', 'rejected', '(complete)'], 'the channel ends as rejected';

    server_says($server, { type => 'update', channel => 'counter', seq => 2, diff => { o => { n => { v => 2 } } }, events => [] });
    server_says($server, { type => 'update', channel => 'other',   seq => 2, diff => { o => { n => { v => 2 } } }, events => [] });
    wait_for(sub { $other->state->{n} == 2 }, 'the other channel carries on');
    is_deeply $kicked->state, { n => 1 }, 'nothing more is taken from the kicked channel';
    ok !$server->{closed}, 'the connection stays';

    isnt $bs->join('counter'), $kicked, 'joining again is a fresh attempt';
    is_deeply [take($server, 1, 'new join')], [{ type => 'join', channel => 'counter' }], '...which asks the server again';
    $bs->close;
};

subtest 'a disconnect by the server is final' => sub {
    @connections = ();
    my $bs       = client();
    my $statuses = collect($bs->status_o);
    my $channel  = $bs->join('counter');
    my $server   = connection_number(1);
    greet($server);
    server_says($server, { type => 'joined', channel => 'counter', seq => 1, state => {} });
    wait_for(sub { $channel->state }, 'joined');
    my $request = $channel->request('slow');

    server_says($server, { type => 'disconnect', reason => 'banned', data => { until => 'tomorrow' } });
    error_like($request, 'banned', { until => 'tomorrow' }, 'an unanswered request');
    wait_for(sub { $server->{closed} }, 'the connection is closed');
    is_deeply $statuses, ['connecting', 'connected', 'closed', '(complete)'], 'closed for good';
    idle(0.6);
    is scalar @connections, 1, 'it does not reconnect';
    error_like($bs->join('other')->joined, 'banned', { until => 'tomorrow' }, 'a channel joined afterwards');
};

subtest 'a server that cannot be reached is retried' => sub {
    @connections = ();
    my $unused   = Mojo::IOLoop::Server->generate_port;
    my $bs       = BoardStreams::Client->new(url => "ws://127.0.0.1:$unused/boardstreams", min_delay => 0.05, max_delay => 0.1);
    my $statuses = collect($bs->status_o);
    wait_for(sub { (grep { $_ eq 'disconnected' } @$statuses) >= 3 }, 'it keeps trying');
    is_deeply [@$statuses[0 .. 3]], [qw(connecting disconnected connecting disconnected)], 'connecting and failing in turn';
    $bs->close;
    is $statuses->[-2], 'closed', 'until it is closed';
};

done_testing;
