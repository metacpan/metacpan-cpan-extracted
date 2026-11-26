use v5.44;
use Test::More;

plan skip_all => 'set TEST_ONLINE to a PostgreSQL connection string to run this test'
    unless $ENV{TEST_ONLINE};

use Future::AsyncAwait future_class => "Mojo::Promise";
use Mojo::IOLoop;
use Mojo::Pg;
use Mojo::Promise;
use Mojolicious::Lite -signatures;
use Test::Mojo;
use BoardStreams;

my $schema = 'bs_hub_test';
my $admin  = Mojo::Pg->new($ENV{TEST_ONLINE});
$admin->db->query("drop schema if exists $schema cascade");
$admin->db->query("create schema $schema");

my $joins = 0;

sub build_app (%conf) {
    my $in  = delete $conf{schema} // $schema;
    my $app = Mojolicious->new;
    $app->log->level('fatal');
    my $hub = $app->plugin(BoardStreams => { pg => Mojo::Pg->new($ENV{TEST_ONLINE})->search_path([$in]),
        identify => sub ($c) { $c->param('user') },
        %conf,
    });
    $hub->channel('counter:*',
        initial_state => { n => 0, log => [] },
        join          => sub ($ctx) {
            $joins++;
            $ctx->reject('banned', { until => 'tomorrow' }) if $ctx->channel eq 'counter:banned';
            return $ctx->channel ne 'counter:closed';
        },
        actions => {
            poke => sub ($ctx, $payload) { $ctx->emit(poked => $payload) },
            whoami    => sub ($ctx, $payload) { $ctx->emit(iam => $ctx->user) },
            kick_me   => sub ($ctx, $payload) { $ctx->kick('asked_for_it', $payload) },
            hangup_me => sub ($ctx, $payload) { $ctx->disconnect('asked_for_it', $payload) },
        },
        requests => {
            add => async sub ($ctx, $payload) {
                await Mojo::Promise->timer(0.01);
                $ctx->reject('too_big', { max => 10 }) if $payload->{by} > 10;
                await $ctx->update(sub ($u) {
                    $u->state->{n} += $payload->{by};
                    push $u->state->{log}->@*, $payload->{by};
                    $u->emit(added => { by => $payload->{by} });
                });
                return { thanks => Mojo::JSON->true };
            },
            peek => sub ($ctx, $payload) { 'nothing changed' },
            boom => sub ($ctx, $payload) { die "kaboom\n" },
        },
    );
    return $app;
}

my $t  = Test::Mojo->new(build_app());
my $t2 = Test::Mojo->new(build_app());    # stands in for a second worker process

# Every connection starts with a heartbeat announcing the interval and the
# protocol version, which is a number of its own and not the library's.
my $protocol = BoardStreams::PROTOCOL_VERSION;
like $protocol, qr/\A[1-9]\d*\z/, "protocol version on the wire is $protocol";

sub ws ($tm = $t, $user = undef) {
    $tm->websocket_ok('/boardstreams' . (defined $user ? "?user=$user" : ''))->message_ok
        ->json_message_is(q{} => { type => 'heartbeat', interval => 25, protocol => $protocol }, 'first heartbeat');
}
sub msg ($tm, $expected, $desc) { $tm->message_ok->json_message_is(q{} => $expected, $desc) }

sub tables_in ($name) {
    return $admin->db->query('select table_name from information_schema.tables where table_schema = ? order by 1', $name)
        ->arrays->flatten->to_array;
}

subtest 'creating the tables' => sub {
    is_deeply tables_in($schema), [qw(bs_channel bs_event bs_floor bs_request mojo_migrations)],
        'by default the tables exist as soon as the plugin is loaded';

    for my $first_use (qw(join emit snapshot)) {
        my $lazy_schema = "${schema}_lazy_$first_use";
        $admin->db->query("drop schema if exists $lazy_schema cascade");
        $admin->db->query("create schema $lazy_schema");
        my $lazy = Test::Mojo->new(build_app(schema => $lazy_schema, lazy_migrate => 1));
        my $hub  = $lazy->app->boardstreams;

        is_deeply tables_in($lazy_schema), [], "lazy_migrate: no tables after loading the plugin ($first_use)";
        ws($lazy);
        $hub->purge->wait;
        is_deeply tables_in($lazy_schema), [], '...nor after a browser connects, nor after a purge';

        if ($first_use eq 'join') {
            $lazy->send_ok({ json => { type => 'join', channel => 'counter:a' } });
            msg $lazy, { type => 'joined', channel => 'counter:a', seq => 0, state => { n => 0, log => [] } }, 'joined';
        }
        elsif ($first_use eq 'emit') { $hub->emit('counter:a', 'hello')->wait }
        else {
            my $snapshot;
            $hub->snapshot('counter:a')->then(sub { $snapshot = shift })->wait;
            is_deeply $snapshot, { seq => 0, state => { n => 0, log => [] } }, 'snapshot';
        }
        is_deeply tables_in($lazy_schema), [qw(bs_channel bs_event bs_floor bs_request mojo_migrations)],
            "...but they exist after the first $first_use";
        $lazy->finish_ok;
        $admin->db->query("drop schema $lazy_schema cascade");
    }
};

subtest 'joining' => sub {
    ws->send_ok({ json => { type => 'join', channel => 'nowhere' } });
    msg $t, { type => 'rejected', channel => 'nowhere', reason => 'unknown_channel', data => undef }, 'unknown channel';

    $t->send_ok({ json => { type => 'join', channel => 'counter:closed' } });
    msg $t, { type => 'rejected', channel => 'counter:closed', reason => 'forbidden', data => undef }, 'handler said no';

    $t->send_ok({ json => { type => 'join', channel => 'counter:banned' } });
    msg $t, { type => 'rejected', channel => 'counter:banned', reason => 'banned', data => { until => 'tomorrow' } },
        'handler rejected with a reason';

    $t->send_ok({ json => { type => 'request', channel => 'counter:banned', id => 'x1', name => 'add', payload => { by => 1 } } });
    msg $t, { type => 'response', id => 'x1', seq => 0, ok => Mojo::JSON->false, error => { reason => 'not_joined', data => undef } },
        'cannot use a channel that was not joined';

    $t->send_ok({ json => { type => 'join', channel => 'counter:a' } });
    msg $t, { type => 'joined', channel => 'counter:a', seq => 0, state => { n => 0, log => [] } }, 'joined with initial state';
    $t->finish_ok;
};

subtest 'requests, events and state' => sub {
    ws->send_ok({ json => { type => 'join', channel => 'counter:a' } })->message_ok;
    ws($t2)->send_ok({ json => { type => 'join', channel => 'counter:a' } })->message_ok;

    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r1', name => 'add', payload => { by => 2 } } });
    my $update = {
        type => 'update', channel => 'counter:a', seq => 1,
        diff   => { o => { n => { v => 2 }, log => { v => [2] } } },
        events => [{ name => 'added', payload => { by => 2 } }],
    };
    my %got;
    for (1 .. 2) {
        $t->message_ok;
        my $m = Mojo::JSON::decode_json($t->message->[1]);
        $got{ $m->{type} } = $m;
    }
    is_deeply $got{update}, $update, 'the sender gets the update';
    is_deeply $got{response}, { type => 'response', id => 'r1', seq => 1, ok => Mojo::JSON->true, payload => { thanks => Mojo::JSON->true } },
        'the response names the sequence number it caused';
    msg $t2, $update, 'a browser on another worker gets the same update';

    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r1', name => 'add', payload => { by => 2 } } });
    msg $t, { type => 'response', id => 'r1', seq => 1, ok => Mojo::JSON->true, payload => { thanks => Mojo::JSON->true } },
        'a resent request gets the recorded response';
    my $snap;
    $t->app->boardstreams->snapshot('counter:a')->then(sub { $snap = shift })->wait;
    is_deeply $snap, { seq => 1, state => { n => 2, log => [2] } }, '...and is not applied twice';

    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r2', name => 'add', payload => { by => 11 } } });
    msg $t, { type => 'response', id => 'r2', seq => 0, ok => Mojo::JSON->false, error => { reason => 'too_big', data => { max => 10 } } },
        'rejected request';
    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r3', name => 'boom' } });
    msg $t, { type => 'response', id => 'r3', seq => 0, ok => Mojo::JSON->false, error => { reason => 'internal_error', data => undef } },
        'a dying handler does not leak its message';
    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r4', name => 'peek' } });
    msg $t, { type => 'response', id => 'r4', seq => 0, ok => Mojo::JSON->true, payload => 'nothing changed' }, 'request without update';
    $t->send_ok({ json => { type => 'request', channel => 'counter:a', id => 'r5', name => 'nope' } });
    msg $t, { type => 'response', id => 'r5', seq => 0, ok => Mojo::JSON->false, error => { reason => 'unknown_request', data => undef } },
        'unknown request';

    for (1 .. 2) {
        $t->send_ok({ json => { type => 'action', channel => 'counter:a', id => 'a1', name => 'poke', payload => 'hi' } });
    }
    my @types;
    for (1 .. 3) { $t->message_ok; push @types, Mojo::JSON::decode_json($t->message->[1])->{type} }
    is_deeply [sort @types], [qw(ack ack update)], 'a resent action is acknowledged twice but runs once';
    msg $t2, { type => 'update', channel => 'counter:a', seq => 2, events => [{ name => 'poked', payload => 'hi' }] },
        'event without a state change';

    $t2->app->boardstreams->update('counter:a', sub ($u) { $u->state->{n} = 100 })->wait;
    msg $t, { type => 'update', channel => 'counter:a', seq => 3, diff => { o => { n => { v => 100 } } }, events => [] },
        'update made outside any handler, on the other worker';
    $t2->message_ok;

    $t2->send_ok({ json => { type => 'leave', channel => 'counter:a' } });
    $t->app->boardstreams->emit('counter:a', 'bye')->wait;
    msg $t, { type => 'update', channel => 'counter:a', seq => 4, events => [{ name => 'bye', payload => undef }] }, 'event';
    $t2->send_ok({ json => { type => 'join', channel => 'counter:b' } });
    msg $t2, { type => 'joined', channel => 'counter:b', seq => 0, state => { n => 0, log => [] } },
        'after leaving, the next message is not an update of the old channel';
    $t->finish_ok;
    $t2->finish_ok;
};

subtest 'rejoining' => sub {
    my $before = $joins;
    ws->send_ok({ json => { type => 'join', channel => 'counter:a', since => 4 } });
    msg $t, { type => 'joined', channel => 'counter:a', seq => 4, updates => [] }, 'nothing missed';
    is $joins, $before + 1, 'the join handler runs again on a rejoin';

    $t->send_ok({ json => { type => 'join', channel => 'counter:a', since => 2 } });
    msg $t, {
        type => 'joined', channel => 'counter:a', seq => 4,
        updates => [
            { seq => 3, diff => { o => { n => { v => 100 } } }, events => [] },
            { seq => 4, events => [{ name => 'bye', payload => undef }] },
        ],
    }, 'missed updates are replayed';

    $t->app->boardstreams->pg->db->query('delete from bs_event where channel = ? and seq = 3', 'counter:a');
    $t->send_ok({ json => { type => 'join', channel => 'counter:a', since => 2 } });
    msg $t, { type => 'joined', channel => 'counter:a', seq => 4, gap => Mojo::JSON->true, state => { n => 100, log => [2] } },
        'when history is gone the whole state is sent, flagged as a gap';

    $t->send_ok({ json => { type => 'join', channel => 'counter:a', since => 99 } });
    msg $t, { type => 'joined', channel => 'counter:a', seq => 4, gap => Mojo::JSON->true, state => { n => 100, log => [2] } },
        'a browser that is ahead of the server is reset too';
    $t->finish_ok;
};

subtest 'purging' => sub {
    my $db = $t->app->boardstreams->pg->db;
    $db->query("update bs_event set created_at = now() - interval '2 hours' where seq < 4");
    $db->query("update bs_request set created_at = now() - interval '2 hours' where id <> 'r4'");
    $t->app->boardstreams->purge->wait;
    is_deeply $db->query('select seq from bs_event order by seq')->arrays->flatten->to_array, [4], 'old events are deleted';
    is_deeply $db->query('select id from bs_request')->arrays->flatten->to_array, ['r4'], 'old request ids are deleted';
};

subtest 'heartbeats' => sub {
    my $fast = Test::Mojo->new(build_app(heartbeat_interval => 0.1));
    $fast->websocket_ok('/boardstreams');
    msg $fast, { type => 'heartbeat', interval => 0.1, protocol => $protocol }, 'the first heartbeat announces the protocol version';
    msg $fast, { type => 'heartbeat', interval => 0.1 }, "heartbeat $_" for 2 .. 3;
    $fast->finish_ok;
};

subtest 'history purged under a connected member' => sub {
    ws->send_ok({ json => { type => 'join', channel => 'counter:g' } })->message_ok;
    $t->app->boardstreams->emit('counter:g', 'one')->wait;
    $t->message_ok;

    # Pretend that updates 2 and 3 were committed but 2 was purged before
    # this process could deliver it.
    my $db = $t->app->boardstreams->pg->db;
    $db->query(q{update bs_channel set seq = 3, state = '{"n": 7, "log": []}' where name = 'counter:g'});
    $db->query(q{insert into bs_event (channel, seq, events) values ('counter:g', 3, '[]')});
    $db->query(q{select pg_notify('boardstreams', '3 counter:g')});
    msg $t, { type => 'joined', channel => 'counter:g', seq => 3, gap => Mojo::JSON->true, state => { n => 7, log => [] } },
        'the member is given the whole state, flagged as a gap';

    $t->app->boardstreams->emit('counter:g', 'four')->wait;
    msg $t, { type => 'update', channel => 'counter:g', seq => 4, events => [{ name => 'four', payload => undef }] },
        '...and keeps receiving updates afterwards';
    $t->finish_ok;
};

subtest 'kicking and disconnecting' => sub {
    # Each Test::Mojo holds one connection: alice has two browsers, on
    # different workers; bob and an anonymous visitor have one each.
    my $alice1 = Test::Mojo->new($t->app);
    my $alice2 = Test::Mojo->new($t2->app);
    my $bob    = Test::Mojo->new($t->app);
    my $anon   = Test::Mojo->new($t2->app);
    my $hub    = $t->app->boardstreams;
    my $update = sub ($channel, $seq, $name, $payload = undef) {
        return { type => 'update', channel => $channel, seq => $seq, events => [{ name => $name, payload => $payload }] };
    };

    ws($alice1, 'alice'); ws($alice2, 'alice'); ws($bob, 'bob'); ws($anon);
    for my $tm ($alice1, $alice2, $bob, $anon) {
        $tm->send_ok({ json => { type => 'join', channel => 'counter:k' } })->message_ok;
    }
    $alice1->send_ok({ json => { type => 'join', channel => 'counter:k2' } })->message_ok;

    $alice1->send_ok({ json => { type => 'action', channel => 'counter:k2', id => 'w1', name => 'whoami' } });
    my %got;
    for (1 .. 2) { $alice1->message_ok; my $m = Mojo::JSON::decode_json($alice1->message->[1]); $got{ $m->{type} } = $m }
    is_deeply $got{update}, $update->('counter:k2', 1, iam => 'alice'), 'handlers see who the connection belongs to';

    $t2->app->boardstreams->kick('alice', 'counter:k', 'spam', { strikes => 3 })->wait;
    my $kicked = { type => 'rejected', channel => 'counter:k', reason => 'spam', data => { strikes => 3 } };
    msg $alice1, $kicked, 'a kick reaches the user on this worker';
    msg $alice2, $kicked, '...and on another worker';

    $hub->emit('counter:k', 'after_kick')->wait;
    msg $bob,  $update->('counter:k', 1, 'after_kick'), 'another user stays in the channel';
    msg $anon, $update->('counter:k', 1, 'after_kick'), '...and so does an anonymous one';
    $hub->emit('counter:k2', 'elsewhere')->wait;
    msg $alice1, $update->('counter:k2', 2, 'elsewhere'),
        'the kicked user gets nothing more from that channel, but keeps the other';

    $alice1->send_ok({ json => { type => 'request', channel => 'counter:k', id => 'k1', name => 'peek' } });
    msg $alice1, { type => 'response', id => 'k1', seq => 0, ok => Mojo::JSON->false, error => { reason => 'not_joined', data => undef } },
        '...and can no longer use it';
    $alice1->send_ok({ json => { type => 'join', channel => 'counter:k' } });
    msg $alice1, { type => 'joined', channel => 'counter:k', seq => 1, state => { n => 0, log => [] } },
        '...unless the join handler lets it back in';

    $hub->kick('bob', 'counter:k')->wait;
    msg $bob, { type => 'rejected', channel => 'counter:k', reason => 'kicked', data => undef }, 'the default reason is "kicked"';
    $hub->kick('nobody', 'counter:k')->wait;
    $hub->kick('bob', 'counter:never_joined')->wait;

    $anon->send_ok({ json => { type => 'action', channel => 'counter:k', id => 'km', name => 'kick_me', payload => 'please' } });
    msg $anon, { type => 'rejected', channel => 'counter:k', reason => 'asked_for_it', data => 'please' },
        'a handler can kick its own connection';
    msg $anon, { type => 'ack', id => 'km' }, '...and the action is still acknowledged';

    $t2->app->boardstreams->disconnect('alice', 'banned', { days => 7 })->wait;
    for my $tm ($alice1, $alice2) {
        msg $tm, { type => 'disconnect', reason => 'banned', data => { days => 7 } }, 'the user is told why';
        $tm->finished_ok(4000);
    }
    $hub->emit('counter:k2', 'nobody_home')->wait;

    $bob->send_ok({ json => { type => 'join', channel => 'counter:k' } })->message_ok;
    $bob->send_ok({ json => { type => 'action', channel => 'counter:k', id => 'hm', name => 'hangup_me' } });
    msg $bob, { type => 'disconnect', reason => 'asked_for_it', data => undef }, 'a handler can disconnect its own connection';
    $bob->finished_ok(4000);

    $hub->disconnect('nobody')->wait;
    $anon->send_ok({ json => { type => 'join', channel => 'counter:k' } });
    msg $anon, { type => 'joined', channel => 'counter:k', seq => 1, state => { n => 0, log => [] } },
        'connections of other users are untouched';
    $anon->finish_ok;

    my $too_big;
    $hub->kick('alice', 'counter:k', 'x' x 8000)->catch(sub ($err) { $too_big = $err })->wait;
    like $too_big, qr/must be small/, 'an oversized reason is refused instead of being lost';
};

subtest 'removing everyone from a channel' => sub {
    # Two members on one worker and two on the other; one is anonymous.
    my @members = (Test::Mojo->new($t->app), Test::Mojo->new($t->app), Test::Mojo->new($t2->app), Test::Mojo->new($t2->app));
    my $outsider = Test::Mojo->new($t->app);
    my $hub      = $t->app->boardstreams;
    ws($members[0], 'carol'); ws($members[1]); ws($members[2], 'carol'); ws($members[3], 'dave'); ws($outsider, 'erin');
    $_->send_ok({ json => { type => 'join', channel => 'counter:all' } })->message_ok for @members;
    $_->send_ok({ json => { type => 'join', channel => 'counter:other' } })->message_ok for $members[0], $outsider;

    $t2->app->boardstreams->kick_all('counter:all', 'closing_time', { reopens => 'tomorrow' })->wait;
    msg $_, { type => 'rejected', channel => 'counter:all', reason => 'closing_time', data => { reopens => 'tomorrow' } },
        'every member is told, on both workers' for @members;

    $hub->emit('counter:all', 'to_nobody')->wait;
    $hub->emit('counter:other', 'elsewhere')->wait;
    my $elsewhere = { type => 'update', channel => 'counter:other', seq => 1, events => [{ name => 'elsewhere', payload => undef }] };
    msg $members[0], $elsewhere, 'a removed member gets nothing more from that channel, but keeps its other one';
    msg $outsider,   $elsewhere, 'members of other channels are untouched';

    $members[1]->send_ok({ json => { type => 'request', channel => 'counter:all', id => 'ka1', name => 'peek' } });
    msg $members[1], { type => 'response', id => 'ka1', seq => 0, ok => Mojo::JSON->false, error => { reason => 'not_joined', data => undef } },
        '...and can no longer use it';

    $members[1]->send_ok({ json => { type => 'join', channel => 'counter:all' } });
    msg $members[1], { type => 'joined', channel => 'counter:all', seq => 1, state => { n => 0, log => [] } },
        'the channel keeps its state and history, and can be joined again';
    $hub->kick_all('counter:all')->wait;
    msg $members[1], { type => 'rejected', channel => 'counter:all', reason => 'kicked', data => undef }, 'the default reason is "kicked"';
    $hub->kick_all('counter:nobody_there')->wait;
    $_->finish_ok for @members, $outsider;
};

# Connects and reports "accepted" if the server greets, or else the code it
# closed the connection with.
sub probe ($tm) {
    my $outcome = Mojo::Promise->new;
    # The handlers must be in place before the first frame is read, which
    # the callback form guarantees and the promise form does not.
    $tm->ua->websocket('/boardstreams' => sub ($ua, $tx) {
        return $outcome->resolve('error: ' . ($tx->error // {})->{message}) unless $tx->is_websocket;
        $tx->on(message => sub ($tx, @) { $outcome->resolve('accepted'); $tx->finish });
        $tx->on(finish  => sub ($tx, $code, @) { $outcome->resolve($code) });
    });
    my $result;
    $outcome->then(sub { $result = shift })->wait;
    return $result;
}

sub accepted_within ($tm, $seconds) {
    for (1 .. $seconds * 10) {
        return 1 if probe($tm) eq 'accepted';
        Mojo::Promise->timer(0.1)->wait;
    }
    return 0;
}

subtest 'a process that stops hearing PostgreSQL serves nobody' => sub {
    my $app  = build_app(retry_delay => 0.3, listener_check_interval => 0.2);
    my $one  = Test::Mojo->new($app);
    my $two  = Test::Mojo->new($app);
    my $hub  = $app->boardstreams;
    ws($_)->send_ok({ json => { type => 'join', channel => 'counter:deaf' } })->message_ok for $one, $two;

    Mojo::Promise->timer(0.7)->wait;
    $hub->emit('counter:deaf', 'still_here')->wait;
    msg $_, { type => 'update', channel => 'counter:deaf', seq => 1, events => [{ name => 'still_here', payload => undef }] },
        'connections survive the periodic check while notifications arrive' for $one, $two;

    # Make the listening connection deaf without closing it, as a silently
    # broken network path would.
    $hub->pg->pubsub->db->query('unlisten boardstreams_control');
    $_->finished_ok(1013) for $one, $two;
    is probe($one), 1013, 'new connections are refused meanwhile';
    ok accepted_within($one, 5), '...and accepted again once the process hears PostgreSQL';

    ws($one)->send_ok({ json => { type => 'join', channel => 'counter:deaf', since => 1 } });
    msg $one, { type => 'joined', channel => 'counter:deaf', seq => 1, updates => [] }, 'a browser that comes back rejoins as usual';
    $hub->emit('counter:deaf', 'again')->wait;
    msg $one, { type => 'update', channel => 'counter:deaf', seq => 2, events => [{ name => 'again', payload => undef }] },
        '...and gets updates again';
    $one->finish_ok;
};

subtest 'PostgreSQL restart' => sub {
    plan skip_all => 'set TEST_PG_RESTART to a command that restarts the test PostgreSQL' unless $ENV{TEST_PG_RESTART};
    ws->send_ok({ json => { type => 'join', channel => 'counter:r' } })->message_ok;
    system($ENV{TEST_PG_RESTART}) == 0 or die 'restart command failed';
    $t->finished_ok(1013);

    ok accepted_within($t, 10),  'the worker accepts browsers again after the restart';
    ok accepted_within($t2, 10), '...and so does the other one';
    my $seq;
    for my $attempt (1 .. 50) {
        last if eval { $t2->app->boardstreams->emit('counter:r', 'back')->then(sub { $seq = shift })->wait; 1 };
        Mojo::Promise->timer(0.2)->wait;
    }
    is $seq, 1, 'updates work again after the restart';
    ws->send_ok({ json => { type => 'join', channel => 'counter:r', since => 0 } });
    msg $t, {
        type => 'joined', channel => 'counter:r', seq => 1,
        updates => [{ seq => 1, events => [{ name => 'back', payload => undef }] }],
    }, 'a browser that was connected before the restart catches up when it rejoins';
    $t->finish_ok;
};

subtest 'a process whose code is older than the schema retires' => sub {
    # Its own schema, as a separate application sharing the database would have.
    my $apart = "${schema}_apart";
    $admin->db->query("drop schema if exists $apart cascade");
    $admin->db->query("create schema $apart");

    # Listen in on what processes tell each other.
    my @heard;
    my $ear = Mojo::Pg->new($ENV{TEST_ONLINE});
    $ear->pubsub->json('boardstreams_control')->listen(boardstreams_control => sub ($pubsub, $message) { push @heard, $message });

    my $app = build_app(schema => $apart, retry_delay => 0.3, listener_check_interval => 0.2);
    my $hub = $app->boardstreams;
    my ($one, $two) = (Test::Mojo->new($app), Test::Mojo->new($app));
    Mojo::Promise->timer(0.1)->wait;
    is_deeply [grep { $_->{op} eq 'schema' } @heard], [{ op => 'schema', schema => 2, scope => $apart }],
        'a process announces the schema version once it has migrated';

    ws($_)->send_ok({ json => { type => 'join', channel => 'counter:a' } })->message_ok for $one, $two;
    ws($t)->send_ok({ json => { type => 'join', channel => 'counter:a' } })->message_ok;
    @heard = ();
    Mojo::Promise->timer(0.5)->wait;
    my ($echo) = grep { $_->{op} eq 'echo' and $_->{scope} eq $apart } @heard;
    is $echo->{schema}, 2, '...and keeps saying so with its periodic echo';

    subtest 'applications in other schemas of the database do not hear each other' => sub {
        $hub->kick_all('counter:a', 'not_you')->wait;
        msg $_, { type => 'rejected', channel => 'counter:a', reason => 'not_you', data => undef }, 'its own members are removed' for $one, $two;
        $t->app->boardstreams->emit('counter:a', 'still_in')->wait;
        $t->message_ok;
        is Mojo::JSON::decode_json($t->message->[1])->{type}, 'update',
            'members of the same channel name in another schema are not';
        $_->send_ok({ json => { type => 'join', channel => 'counter:a' } })->message_ok for $one, $two;
    };

    # What a process running newer code would send, first to another schema...
    my $announce = sub ($scope, $version) {
        $admin->db->query('select pg_notify(?, ?)', 'boardstreams_control',
            Mojo::JSON::to_json({ op => 'schema', schema => $version, scope => $scope }));
        Mojo::Promise->timer(0.2)->wait;
    };
    $announce->('some_other_schema', 99);
    $announce->($apart, 2);
    is probe($one), 'accepted', 'an announcement for another schema, or of the same version, changes nothing';

    # ...then to this one.
    $announce->($apart, 3);
    $_->finished_ok(1013) for $one, $two;
    Mojo::Promise->timer(1)->wait;
    is probe($one), 1013, 'after hearing of a newer schema version, the process serves nobody, and stays that way';
    my $error;
    $hub->emit('counter:a', 'nope')->catch(sub ($err) { $error = $err })->wait;
    like $error, qr/schema version 3, which this code is too old for/, '...and refuses to touch the tables';
    is probe($t), 'accepted', 'the application in the other schema carries on';
    $t->finish_ok;

    $ear->pubsub->reset;
    $admin->db->query("drop schema $apart cascade");
};

# Runs last: deleting channels raises the number that new channels start
# from, which the subtests above take to be zero.
subtest 'deleting a channel' => sub {
    my ($near, $far, $other) = (Test::Mojo->new($t->app), Test::Mojo->new($t2->app), Test::Mojo->new($t->app));
    my $hub = $t->app->boardstreams;
    my $db  = $admin->db;
    my $rows = sub ($channel) {
        return [map { $db->query("select count(*) from $schema.$_ where " . ($_ eq 'bs_channel' ? 'name' : 'channel') . ' = ?', $channel)->array->[0] }
            qw(bs_channel bs_event bs_request)];
    };
    my $json = sub ($tm) { Mojo::JSON::decode_json($tm->message->[1]) };
    my $add = sub ($tm, $channel, $id, $by) {
        $tm->send_ok({ json => { type => 'request', channel => $channel, id => $id, name => 'add', payload => { by => $by } } });
        my %got;
        for (1 .. 2) { $tm->message_ok; my $m = $json->($tm); $got{ $m->{type} } = $m }
        return $got{update}{seq};
    };

    ws($_) for $near, $far, $other;
    $_->send_ok({ json => { type => 'join', channel => 'counter:del' } })->message_ok for $near, $far;
    $other->send_ok({ json => { type => 'join', channel => 'counter:keep' } })->message_ok;
    my $last = $add->($near, 'counter:del', 'd1', 2);
    $far->message_ok;
    $add->($other, 'counter:keep', 'd2', 1);
    is_deeply $rows->('counter:del'), [1, 1, 1], 'the channel has a row, an event and a recorded request';

    my $deleted;
    $t2->app->boardstreams->delete_channel('counter:del', 'archived', { by => 'admin' })->then(sub { $deleted = shift })->wait;
    ok $deleted, 'the promise reports that there was something to delete';
    msg $_, { type => 'rejected', channel => 'counter:del', reason => 'archived', data => { by => 'admin' } },
        'every member is removed and told, on both workers' for $near, $far;
    is_deeply $rows->('counter:del'),  [0, 0, 0], 'the events and recorded requests went with the row';
    is_deeply $rows->('counter:keep'), [1, 1, 1], 'other channels are untouched';

    $hub->delete_channel('counter:del')->then(sub { $deleted = shift })->wait;
    ok !$deleted, 'deleting a channel that does not exist reports so';

    $near->send_ok({ json => { type => 'join', channel => 'counter:del', since => $last } })->message_ok;
    my $again = $json->($near);
    is_deeply [@$again{qw(type state gap)}], ['joined', { n => 0, log => [] }, Mojo::JSON->true],
        'a browser returning with its old position gets the fresh state, flagged as a gap';
    cmp_ok $again->{seq}, '>', $last, 'the new channel does not reuse the old one\'s sequence numbers';
    is $add->($near, 'counter:del', 'd3', 1), $again->{seq} + 1, 'the new channel works';
    $hub->delete_channel('counter:del')->wait;
    msg $near, { type => 'rejected', channel => 'counter:del', reason => 'deleted', data => undef }, 'the default reason is "deleted"';

    subtest 'a row deleted behind the hub\'s back' => sub {
        $far->send_ok({ json => { type => 'join', channel => 'counter:manual' } })->message_ok;
        my $before = $add->($far, 'counter:manual', 'm1', 3);
        $db->query("delete from $schema.bs_channel where name = 'counter:manual'");
        is_deeply $rows->('counter:manual'), [0, 0, 0], 'the foreign keys clean up after a plain SQL delete too';

        $hub->emit('counter:manual', 'after')->wait;
        $far->message_ok;
        my $healed = $json->($far);
        is_deeply [@$healed{qw(type state gap)}], ['joined', { n => 0, log => [] }, Mojo::JSON->true],
            'a member left behind is given the fresh state at the next update, flagged as a gap';
        cmp_ok $healed->{seq}, '>', $before + 1, '...with a sequence number beyond the old channel\'s';
    };

    subtest 'a join that is reading the channel while it is deleted' => sub {
        $near->send_ok({ json => { type => 'join', channel => 'counter:race' } })->message_ok;
        my $old = $add->($near, 'counter:race', 'r1', 5);

        # Make the next join of this channel read the row, and only get to
        # use what it read after the channel has been deleted.
        my $original = \&BoardStreams::Hub::snapshot;
        my $armed    = 1;
        no warnings 'redefine';
        local *BoardStreams::Hub::snapshot = sub ($self, $channel) {
            return $original->($self, $channel) unless $armed and $channel eq 'counter:race';
            $armed = 0;
            return $original->($self, $channel)->then(sub ($snapshot) {
                is $snapshot->{state}{n}, 5, 'the join read the channel before the deletion';
                return $self->delete_channel($channel)->then(sub { Mojo::Promise->timer(0.3) })->then(sub { $snapshot });
            });
        };

        $other->send_ok({ json => { type => 'join', channel => 'counter:race' } })->message_ok;
        my $joined = $json->($other);
        is_deeply [@$joined{qw(type state)}], ['joined', { n => 0, log => [] }],
            'it is joined to the fresh channel, not left with the deleted one\'s state';
        ok !exists $joined->{gap}, '...and a first-time joiner is told of no gap';
        is $joined->{seq}, $old + 1, '...at the fresh channel\'s number';
        msg $near, { type => 'rejected', channel => 'counter:race', reason => 'deleted', data => undef },
            'the member who was already in is removed as usual';

        $hub->emit('counter:race', 'live')->wait;
        msg $other, { type => 'update', channel => 'counter:race', seq => $old + 2, events => [{ name => 'live', payload => undef }] },
            '...and the new member receives updates';
    };
    $_->finish_ok for $near, $far, $other;
};

$admin->db->query("drop schema $schema cascade");
done_testing;
