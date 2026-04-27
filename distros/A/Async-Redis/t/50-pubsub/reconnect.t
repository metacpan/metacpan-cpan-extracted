# t/50-pubsub/reconnect.t
#
# Test pub/sub auto-resubscription on reconnect
#
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis qw(run skip_without_redis await_f);
use Future::AsyncAwait;
use Test2::V0;
use Async::Redis;
use Future;

# --- Unit tests (no Redis needed) ---

subtest 'get_replay_commands returns correct commands' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    $sub->_add_channel('chan:a');
    $sub->_add_channel('chan:b');
    $sub->_add_pattern('events.*');

    my @commands = $sub->get_replay_commands;

    is(scalar @commands, 2, 'two replay commands (SUBSCRIBE + PSUBSCRIBE)');

    my ($sub_cmd) = grep { $_->[0] eq 'SUBSCRIBE' } @commands;
    ok($sub_cmd, 'has SUBSCRIBE command');
    is(scalar @$sub_cmd, 3, 'SUBSCRIBE has 2 channels');
    ok(
        (grep { $_ eq 'chan:a' } @$sub_cmd) && (grep { $_ eq 'chan:b' } @$sub_cmd),
        'SUBSCRIBE includes both channels'
    );

    my ($psub_cmd) = grep { $_->[0] eq 'PSUBSCRIBE' } @commands;
    ok($psub_cmd, 'has PSUBSCRIBE command');
    is($psub_cmd->[1], 'events.*', 'PSUBSCRIBE has correct pattern');
};

subtest '_reset_connection clears in_pubsub flag' => sub {
    my $redis = Async::Redis->new(host => 'localhost');

    $redis->{in_pubsub} = 1;
    $redis->{connected} = 1;
    $redis->{socket} = undef;

    $redis->_reset_connection('test');

    is($redis->{in_pubsub}, 0, 'in_pubsub cleared after reset');
};

subtest 'on_reconnect accessor' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    is($sub->on_reconnect, undef, 'no callback by default');

    my $cb = sub { 1 };
    $sub->on_reconnect($cb);
    is($sub->on_reconnect, $cb, 'callback stored');
};

subtest '_read_frame_with_reconnect is defined and returns a Future' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    my $sub = Async::Redis::Subscription->new(redis => $redis);
    can_ok($sub, '_read_frame_with_reconnect');

    # Without a real connection it will fail, but it must return a Future.
    my $f = $sub->_read_frame_with_reconnect;
    ok(ref($f) && $f->isa('Future'), 'returns a Future');
    # Consume the failure so no uncaught Future warning fires.
    $f->on_fail(sub { });
};

subtest '_reconnect_attempt resets to 0 after successful reconnect' => sub {
    my $redis = Async::Redis->new(host => 'localhost');
    # Simulate prior failed attempts having bumped the counter.
    $redis->{_reconnect_attempt} = 5;

    # Stub connect to succeed immediately (set connected and return).
    no warnings 'redefine';
    local *Async::Redis::connect = async sub { $_[0]->{connected} = 1; return $_[0] };

    $redis->_reconnect->get;

    is($redis->{_reconnect_attempt}, 0,
        '_reconnect_attempt reset to 0 after loop exit');
};

subtest '_reconnect honors reconnect_max_attempts cap' => sub {
    my $redis = Async::Redis->new(
        host                   => 'localhost',
        reconnect_max_attempts => 3,
        reconnect_delay        => 0.001,   # tiny so the test is fast
        reconnect_delay_max    => 0.001,
        reconnect_jitter       => 0,
    );

    # Stub connect to always fail.
    my $calls = 0;
    no warnings 'redefine';
    local *Async::Redis::connect = async sub {
        $calls++;
        die Async::Redis::Error::Disconnected->new(message => 'simulated');
    };

    my $err = dies { $redis->_reconnect->get };
    ok($err, '_reconnect dies after max attempts exhausted');
    like("$err", qr/gave up after 3 attempts/,
        'error message names the attempt cap');
    is($calls, 3, 'connect called exactly 3 times');
    is($redis->{_reconnect_attempt}, 0,
        'attempt counter reset to 0 after the cap is exhausted');
};

subtest '_reconnect cap is per reconnect cycle, not permanent client poison' => sub {
    my $redis = Async::Redis->new(
        host                   => 'localhost',
        reconnect_max_attempts => 2,
        reconnect_delay        => 0,
        reconnect_delay_max    => 0,
        reconnect_jitter       => 0,
    );

    my $phase = 'fail';
    my $calls = 0;

    # First cycle: Redis stays unreachable, so _reconnect should try
    # exactly reconnect_max_attempts times and then give up.
    # Second cycle: Redis is back, so the same client should be able to
    # make a fresh reconnect attempt instead of immediately failing
    # because the previous cycle left _reconnect_attempt above the cap.
    no warnings 'redefine';
    local *Async::Redis::connect = async sub {
        $calls++;

        if ($phase eq 'fail') {
            die Async::Redis::Error::Disconnected->new(message => 'still down');
        }

        $_[0]->{connected} = 1;
        return $_[0];
    };

    my $first_err = dies { $redis->_reconnect->get };
    like("$first_err", qr/gave up after 2 attempts/,
        'first reconnect cycle gives up after the configured cap');
    is($calls, 2, 'first cycle made exactly 2 connect attempts');

    $phase = 'success';

    my $second_err = dies { $redis->_reconnect->get };
    is($second_err, undef,
        'second reconnect cycle can try again and succeed after Redis returns');
    is($calls, 3, 'second cycle called connect again');
    is($redis->{_reconnect_attempt}, 0,
        'attempt counter reset after successful later reconnect');
};

subtest 'pubsub reports reconnect exhaustion, not the original read error' => sub {
    my $redis = Async::Redis->new(
        host                   => 'localhost',
        reconnect              => 1,
        reconnect_max_attempts => 1,
        reconnect_delay        => 0,
        reconnect_delay_max    => 0,
        reconnect_jitter       => 0,
    );
    my $sub = Async::Redis::Subscription->new(redis => $redis);

    $redis->{_subscription} = $sub;
    $sub->_add_channel('chan');

    # The read fails first, which is the trigger for pub/sub recovery.
    # Recovery then exhausts reconnect_max_attempts.  The consumer-facing
    # error should be the reconnect exhaustion error, because that tells
    # users recovery was attempted and failed; the original read error is
    # only the cause that started the recovery path.
    no warnings 'redefine';
    local *Async::Redis::_read_pubsub_frame = async sub {
        die Async::Redis::Error::Disconnected->new(message => 'read failed');
    };
    local *Async::Redis::connect = async sub {
        die Async::Redis::Error::Disconnected->new(message => 'connect failed');
    };

    my $err = dies { $sub->_read_frame_with_reconnect->get };

    like("$err", qr/Reconnect gave up after 1 attempts/,
        'subscription sees reconnect exhaustion error');
    unlike("$err", qr/read failed/,
        'original read error does not mask reconnect exhaustion');
};

# --- Integration tests (require Redis) ---

SKIP: {
    my $test_redis = eval {
        my $r = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 6 unless $test_redis;
    $test_redis->disconnect;

    my $TEST_TIMEOUT = 5;

    # Helper: simulate a dropped connection by having the publisher
    # CLIENT KILL the subscriber. Server-side close → kernel delivers
    # EOF on our still-valid fd → reader sees 0 bytes → _reader_fatal
    # fires cleanly. Matches how a real peer-initiated disconnect works,
    # whereas `close $sub_redis->{socket}` leaves a stale poller in
    # Future::IO's select loop with undef fileno, which gets coerced to
    # fd 0 (STDIN) and deadlocks select in a TTY context.
    #
    # CLIENT commands are forbidden once a connection enters pub/sub
    # mode, so the caller MUST capture the subscriber's client ID
    # BEFORE subscribing and issue the KILL from a separate connection.

    subtest 'subscriber reconnects and receives messages after drop' => sub {
        my $pub = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $pub->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $sub_redis->connect };

        # Capture subscriber's client ID before pubsub mode locks us out.
        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->subscribe('reconnect:test') };
        ok($subscription, 'subscribed');

        # Verify pre-disconnect message works
        my $pre_future = (async sub {
            await Future::IO->sleep(0.1);
            await $pub->publish('reconnect:test', 'before');
        })->();

        my $msg1 = run { $subscription->next };
        is($msg1->{data}, 'before', 'received message before disconnect');
        run { $pre_future };

        # Server-initiated disconnect via KILL from pub connection.
        eval { run { $pub->client('KILL', 'ID', $sub_client_id) } };

        # Publish after reconnect window
        my $post_future = (async sub {
            await Future::IO->sleep(0.3);
            await $pub->publish('reconnect:test', 'after');
        })->();

        # next() should reconnect transparently and return real message
        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out waiting for message after reconnect");
        });
        my $msg2 = eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };

        if ($@) {
            fail("received message after reconnect: $@");
        } else {
            is($msg2->{type}, 'message', 'got real message type after reconnect');
            is($msg2->{data}, 'after', 'correct data after reconnect');
        }

        eval { run { $post_future } };

        is([$subscription->channels], ['reconnect:test'], 'still tracking channel');
        ok(!$subscription->is_closed, 'subscription not closed');

        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    };

    subtest 'on_reconnect callback fires on reconnect' => sub {
        my $pub = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $pub->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $sub_redis->connect };

        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->subscribe('callback:test') };

        # Register callback
        my @events;
        $subscription->on_reconnect(sub {
            my ($sub) = @_;
            push @events, {
                channels => [$sub->channels],
                patterns => [$sub->patterns],
            };
        });

        # Server-initiated disconnect.
        eval { run { $pub->client('KILL', 'ID', $sub_client_id) } };

        my $publish_future = (async sub {
            await Future::IO->sleep(0.3);
            await $pub->publish('callback:test', 'hello');
        })->();

        # next() reconnects, fires callback, returns real message
        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out");
        });
        my $msg = eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };

        if ($@) {
            fail("got message after reconnect: $@");
        } else {
            is($msg->{type}, 'message', 'next() returns real message');
            is($msg->{data}, 'hello', 'correct data');
        }

        # Verify callback fired
        is(scalar @events, 1, 'on_reconnect callback fired once');
        is($events[0]{channels}, ['callback:test'], 'callback received correct channels');

        eval { run { $publish_future } };
        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    };

    subtest 'psubscribe reconnects with patterns' => sub {
        my $pub = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $pub->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $sub_redis->connect };

        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->psubscribe('precon:*') };

        my @events;
        $subscription->on_reconnect(sub { push @events, 'reconnected' });

        # Server-initiated disconnect.
        eval { run { $pub->client('KILL', 'ID', $sub_client_id) } };

        my $publish_future = (async sub {
            await Future::IO->sleep(0.3);
            await $pub->publish('precon:chan1', 'pattern_msg');
        })->();

        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out");
        });
        my $msg = eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };

        if ($@) {
            fail("got pmessage after reconnect: $@");
        } else {
            is($msg->{type}, 'pmessage', 'got pmessage after reconnect');
            is($msg->{data}, 'pattern_msg', 'correct data');
            is($msg->{pattern}, 'precon:*', 'correct pattern');
        }

        is(scalar @events, 1, 'on_reconnect fired for pattern sub');

        eval { run { $publish_future } };
        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    };

    subtest 'multi-channel resubscribe after reconnect' => sub {
        my $pub = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $pub->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $sub_redis->connect };

        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->subscribe('multi:a', 'multi:b', 'multi:c') };
        is(scalar $subscription->channel_count, 3, 'subscribed to 3 channels');

        # Server-initiated disconnect.
        eval { run { $pub->client('KILL', 'ID', $sub_client_id) } };

        my $publish_future = (async sub {
            await Future::IO->sleep(0.3);
            await $pub->publish('multi:a', 'msg_a');
            await $pub->publish('multi:b', 'msg_b');
            await $pub->publish('multi:c', 'msg_c');
        })->();

        # Read 3 messages — all should be real messages
        my %received;
        my $error;
        for my $i (1..3) {
            my $next_fi = $subscription->next;
            my $timeout_fi = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
                Future->fail("Timed out waiting for message $i");
            });
            my $msg = eval { await_f(Future->wait_any($next_fi, $timeout_fi)); $next_fi->get };
            if ($@) { $error = $@; last }
            $received{$msg->{channel}} = $msg->{data};
        }

        if ($error) {
            fail("received all messages: $error");
        } else {
            is($received{'multi:a'}, 'msg_a', 'received from channel a');
            is($received{'multi:b'}, 'msg_b', 'received from channel b');
            is($received{'multi:c'}, 'msg_c', 'received from channel c');
        }

        eval { run { $publish_future } };
        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    };

    subtest 'no reconnect callback without registration' => sub {
        my $pub = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $pub->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $sub_redis->connect };

        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->subscribe('nocb:test') };
        # No on_reconnect callback registered

        # Server-initiated disconnect.
        eval { run { $pub->client('KILL', 'ID', $sub_client_id) } };

        my $publish_future = (async sub {
            await Future::IO->sleep(0.3);
            await $pub->publish('nocb:test', 'silent');
        })->();

        # Should still work — just no callback
        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out");
        });
        my $msg = eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };

        if ($@) {
            fail("reconnect without callback: $@");
        } else {
            is($msg->{type}, 'message', 'reconnect works without callback');
            is($msg->{data}, 'silent', 'correct data');
        }

        eval { run { $publish_future } };
        eval { $pub->disconnect };
        eval { $sub_redis->disconnect };
    };

    subtest 'no reconnect when reconnect disabled' => sub {
        my $killer = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $killer->connect };

        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 0,
        );
        run { $sub_redis->connect };

        my $sub_client_id = run { $sub_redis->client('ID') };

        my $subscription = run { $sub_redis->subscribe('norecon:test') };

        # Server-initiated disconnect.
        eval { run { $killer->client('KILL', 'ID', $sub_client_id) } };

        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out — next() should have thrown immediately");
        });
        my $error;
        eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };
        $error = $@;

        ok($error, 'error thrown when reconnect disabled');
        like("$error", qr/connect|disconnect|closed|peer/i, 'error is connection-related');

        eval { $killer->disconnect };
        eval { $sub_redis->disconnect };
    };
}

done_testing;
