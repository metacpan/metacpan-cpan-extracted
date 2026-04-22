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

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

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

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

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

        my $subscription = run { $sub_redis->psubscribe('precon:*') };

        my @events;
        $subscription->on_reconnect(sub { push @events, 'reconnected' });

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

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

        my $subscription = run { $sub_redis->subscribe('multi:a', 'multi:b', 'multi:c') };
        is(scalar $subscription->channel_count, 3, 'subscribed to 3 channels');

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

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

        my $subscription = run { $sub_redis->subscribe('nocb:test') };
        # No on_reconnect callback registered

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

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
        my $sub_redis = Async::Redis->new(
            host      => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 0,
        );
        run { $sub_redis->connect };

        my $subscription = run { $sub_redis->subscribe('norecon:test') };

        # Force disconnect
        close $sub_redis->{socket};
        $sub_redis->{connected} = 0;

        my $next_f = $subscription->next;
        my $timeout_f = Future::IO->sleep($TEST_TIMEOUT)->then(sub {
            Future->fail("Timed out — next() should have thrown immediately");
        });
        my $error;
        eval { await_f(Future->wait_any($next_f, $timeout_f)); $next_f->get };
        $error = $@;

        ok($error, 'error thrown when reconnect disabled');
        like("$error", qr/connect|disconnect|fileno|closed/i, 'error is connection-related');
    };
}

done_testing;
