# t/70-blocking/brpop.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Time::HiRes qw(time);

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('brpop:queue') };

    subtest 'BRPOP returns from right side' => sub {
        run { $redis->rpush('brpop:queue', 'first', 'second', 'third') };

        my $result = run { $redis->brpop('brpop:queue', 5) };
        is($result, ['brpop:queue', 'third'], 'got rightmost item');

        $result = run { $redis->brpop('brpop:queue', 5) };
        is($result, ['brpop:queue', 'second'], 'got next rightmost');

        # Cleanup
        run { $redis->del('brpop:queue') };
    };

    subtest 'BRPOP waits for data' => sub {
        run { $redis->del('brpop:queue') };

        # Schedule push after 0.3s
        my $pusher = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $pusher->connect };

        my $push_f = get_loop()->delay_future(after => 0.3)->then(sub {
            $pusher->lpush('brpop:queue', 'delayed');
        });

        my $start = time();
        my $result = run { $redis->brpop('brpop:queue', 5) };
        my $elapsed = time() - $start;

        is($result, ['brpop:queue', 'delayed'], 'got delayed item');
        ok($elapsed >= 0.2 && $elapsed < 1.0, "waited for item (${elapsed}s)");
    };

    subtest 'BRPOP returns undef on timeout' => sub {
        run { $redis->del('brpop:empty') };

        my $start = time();
        my $result = run { $redis->brpop('brpop:empty', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'non-blocking verification' => sub {
        run { $redis->del('brpop:nonblock') };

        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        my $result = run { $redis->brpop('brpop:nonblock', 1) };

        $timer->stop;
        get_loop()->remove($timer);

        is($result, undef, 'BRPOP timed out');
        ok(@ticks >= 50, "Event loop ticked " . scalar(@ticks) . " times");
    };

    # Cleanup
    run { $redis->del('brpop:queue') };
}

done_testing;
