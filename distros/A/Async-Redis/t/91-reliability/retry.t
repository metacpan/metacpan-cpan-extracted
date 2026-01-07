# t/91-reliability/retry.t
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'reconnect after disconnect' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.1,
        );
        run { $r->connect };

        # Set a value
        run { $r->set('retry:key1', 'value1') };
        is(run { $r->get('retry:key1') }, 'value1', 'initial set works');

        # Force disconnect
        $r->disconnect;

        # Next command should trigger reconnect
        run { $r->set('retry:key2', 'value2') };
        is(run { $r->get('retry:key2') }, 'value2', 'command after reconnect works');

        run { cleanup_keys($r, 'retry:*') };
        $r->disconnect;
    };

    subtest 'reconnect respects delay settings' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 1,
            reconnect_delay => 0.05,
            reconnect_delay_max => 1,
        );
        run { $r->connect };

        # Verify backoff calculation
        my $delay1 = $r->_calculate_backoff(1);
        my $delay2 = $r->_calculate_backoff(2);
        my $delay3 = $r->_calculate_backoff(3);

        ok($delay1 <= 0.1, "first delay reasonable: $delay1");
        ok($delay2 > $delay1 * 0.5, "second delay increases: $delay2");
        ok($delay3 <= 1, "third delay within max: $delay3");

        $r->disconnect;
    };

    subtest 'no reconnect when disabled' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            reconnect => 0,
        );
        run { $r->connect };

        # Disconnect
        $r->disconnect;

        # Should fail without reconnect
        my $error;
        eval { run { $r->ping } };
        $error = $@;

        ok($error, 'error thrown when reconnect disabled');
        like("$error", qr/Not connected|Disconnected/i, 'correct error type');
    };

    $redis->disconnect;
}

done_testing;
