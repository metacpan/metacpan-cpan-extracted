# t/10-connection/timeout.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Time::HiRes qw(time);

# Helper: await a Future and return its result (throws on failure)

subtest 'constructor accepts timeout parameters' => sub {
    my $redis = Async::Redis->new(
        host                    => 'localhost',
        connect_timeout         => 5,
        read_timeout            => 10,
        write_timeout           => 10,
        request_timeout         => 3,
        blocking_timeout_buffer => 2,
    );

    is($redis->{connect_timeout}, 5, 'connect_timeout');
    is($redis->{read_timeout}, 10, 'read_timeout');
    is($redis->{write_timeout}, 10, 'write_timeout');
    is($redis->{request_timeout}, 3, 'request_timeout');
    is($redis->{blocking_timeout_buffer}, 2, 'blocking_timeout_buffer');
};

subtest 'default timeout values' => sub {
    my $redis = Async::Redis->new(host => 'localhost');

    is($redis->{connect_timeout}, 10, 'default connect_timeout');
    is($redis->{read_timeout}, 30, 'default read_timeout');
    is($redis->{request_timeout}, 5, 'default request_timeout');
    is($redis->{blocking_timeout_buffer}, 2, 'default blocking_timeout_buffer');
};

subtest 'connect timeout fires on unreachable host' => sub {
    my $start = time();

    my $redis = Async::Redis->new(
        host            => '10.255.255.1',  # non-routable IP
        connect_timeout => 0.5,
    );

    my $error;
    my $f = $redis->connect;
    get_loop()->await($f);
    eval { $f->get };  # ->get throws on failure
    $error = $@;

    my $elapsed = time() - $start;

    ok($error, 'connect failed');
    ok($elapsed >= 0.4, "waited at least 0.4s (got ${elapsed}s)");
    ok($elapsed < 1.5, "didn't wait too long (got ${elapsed}s)");
};

subtest 'event loop not blocked during connect timeout' => sub {
    my @ticks;
    my $timer = IO::Async::Timer::Periodic->new(
        interval => 0.05,
        on_tick  => sub { push @ticks, time() },
    );
    get_loop()->add($timer);
    $timer->start;

    my $redis = Async::Redis->new(
        host            => '10.255.255.1',
        connect_timeout => 0.3,
    );

    my $start = time();
    my $f = $redis->connect;
    get_loop()->await($f);
    eval { $f->get };  # convert failure to exception (ignored)
    my $elapsed = time() - $start;

    $timer->stop;
    get_loop()->remove($timer);

    # Should have ticked multiple times during the 0.3s wait
    ok(@ticks >= 3, "timer ticked " . scalar(@ticks) . " times during ${elapsed}s timeout");
};

# Tests requiring actual Redis connection
SKIP: {
    my $test_redis = eval {
        my $r = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 4 unless $test_redis;
    $test_redis->disconnect;

    subtest 'request timeout fires on slow command' => sub {
        my $redis = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            request_timeout => 0.3,
        );
        run { $redis->connect };

        # Check if DEBUG command is available (not allowed in Docker Redis by default)
        my $debug_available = eval { run { $redis->command('DEBUG', 'SLEEP', '0') }; 1 };
        unless ($debug_available) {
            $redis->disconnect;
            plan skip_all => 'DEBUG command not available (requires enable-debug-command config)';
            return;
        }

        my $start = time();
        my $error;
        eval {
            # DEBUG SLEEP causes Redis to block for N seconds
            run { $redis->command('DEBUG', 'SLEEP', '2') };
        };
        $error = $@;
        my $elapsed = time() - $start;

        ok($error, 'command failed');
        like("$error", qr/timed?\s*out/i, 'error mentions timeout');
        ok($elapsed >= 0.2, "waited at least 0.2s (got ${elapsed}s)");
        ok($elapsed < 1.0, "timed out before command finished (got ${elapsed}s)");

        $redis->disconnect;
    };

    subtest 'event loop not blocked during request timeout' => sub {
        my $redis = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            request_timeout => 0.3,
        );
        run { $redis->connect };

        # Check if DEBUG command is available (not allowed in Docker Redis by default)
        my $debug_available = eval { run { $redis->command('DEBUG', 'SLEEP', '0') }; 1 };
        unless ($debug_available) {
            $redis->disconnect;
            plan skip_all => 'DEBUG command not available (requires enable-debug-command config)';
            return;
        }

        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.05,
            on_tick  => sub { push @ticks, time() },
        );
        get_loop()->add($timer);
        $timer->start;

        eval { run { $redis->command('DEBUG', 'SLEEP', '2') } };

        $timer->stop;
        get_loop()->remove($timer);

        ok(@ticks >= 3, "timer ticked " . scalar(@ticks) . " times during timeout");

        $redis->disconnect;
    };

    subtest 'blocking command uses extended timeout' => sub {
        my $redis = Async::Redis->new(
            host                    => $ENV{REDIS_HOST} // 'localhost',
            request_timeout         => 1,
            blocking_timeout_buffer => 1,
        );
        run { $redis->connect };

        # Clean up any existing list
        run { $redis->del('timeout:test:list') };

        my $start = time();
        # BLPOP with 0.5s server timeout
        # Client deadline should be 0.5 + 1 (buffer) = 1.5s
        my $result = run { $redis->command('BLPOP', 'timeout:test:list', '0.5') };
        my $elapsed = time() - $start;

        # BLPOP returns undef on timeout
        is($result, undef, 'BLPOP returned undef (server timeout)');
        ok($elapsed >= 0.4, "waited for server timeout (${elapsed}s)");
        ok($elapsed < 1.0, "didn't hit client timeout (${elapsed}s)");

        $redis->disconnect;
    };

    subtest 'normal commands work within timeout' => sub {
        my $redis = Async::Redis->new(
            host            => $ENV{REDIS_HOST} // 'localhost',
            request_timeout => 5,
        );
        run { $redis->connect };

        # Normal commands should complete well within timeout
        my $result = run { $redis->command('PING') };
        is($result, 'PONG', 'PING works');

        run { $redis->command('SET', 'timeout:test:key', 'value') };
        my $value = run { $redis->command('GET', 'timeout:test:key') };
        is($value, 'value', 'GET/SET work');

        # Cleanup
        run { $redis->del('timeout:test:key') };
        $redis->disconnect;
    };
}

done_testing;
