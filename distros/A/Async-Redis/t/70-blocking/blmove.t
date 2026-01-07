# t/70-blocking/blmove.t
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

    # Check Redis version supports BLMOVE (6.2+)
    my $info_raw = run { $redis->command('INFO', 'server') };
    my ($version) = $info_raw =~ /redis_version:(\d+\.\d+)/;
    $version //= '0';
    my ($major, $minor) = split /\./, $version;
    skip "BLMOVE requires Redis 6.2+, got $version", 1
        unless ($major > 6 || ($major == 6 && $minor >= 2));

    # Cleanup
    run { $redis->del('blmove:src', 'blmove:dst') };

    subtest 'BLMOVE moves element' => sub {
        run { $redis->rpush('blmove:src', 'a', 'b', 'c') };

        my $result = run { $redis->blmove('blmove:src', 'blmove:dst', 'RIGHT', 'LEFT', 5) };
        is($result, 'c', 'moved rightmost element');

        my $src = run { $redis->lrange('blmove:src', 0, -1) };
        is($src, ['a', 'b'], 'source has remaining elements');

        my $dst = run { $redis->lrange('blmove:dst', 0, -1) };
        is($dst, ['c'], 'destination has moved element');
    };

    subtest 'BLMOVE LEFT RIGHT' => sub {
        run { $redis->del('blmove:src', 'blmove:dst') };
        run { $redis->rpush('blmove:src', 'x', 'y', 'z') };

        my $result = run { $redis->blmove('blmove:src', 'blmove:dst', 'LEFT', 'RIGHT', 5) };
        is($result, 'x', 'moved leftmost element');

        my $dst = run { $redis->lrange('blmove:dst', 0, -1) };
        is($dst, ['x'], 'pushed to right of destination');
    };

    subtest 'BLMOVE waits for source data' => sub {
        run { $redis->del('blmove:src', 'blmove:dst') };

        # Schedule push after 0.3s
        my $pusher = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $pusher->connect };

        my $push_f = get_loop()->delay_future(after => 0.3)->then(sub {
            $pusher->rpush('blmove:src', 'delayed');
        });

        my $start = time();
        my $result = run { $redis->blmove('blmove:src', 'blmove:dst', 'LEFT', 'LEFT', 5) };
        my $elapsed = time() - $start;

        is($result, 'delayed', 'got delayed item');
        ok($elapsed >= 0.2 && $elapsed < 1.0, "waited for item (${elapsed}s)");
    };

    subtest 'BLMOVE returns undef on timeout' => sub {
        run { $redis->del('blmove:src', 'blmove:dst') };

        my $start = time();
        my $result = run { $redis->blmove('blmove:src', 'blmove:dst', 'LEFT', 'LEFT', 1) };
        my $elapsed = time() - $start;

        is($result, undef, 'returned undef on timeout');
        ok($elapsed >= 0.9 && $elapsed < 2.0, "waited ~1s (${elapsed}s)");
    };

    subtest 'non-blocking verification' => sub {
        run { $redis->del('blmove:src', 'blmove:dst') };

        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        my $result = run { $redis->blmove('blmove:src', 'blmove:dst', 'LEFT', 'LEFT', 1) };

        $timer->stop;
        get_loop()->remove($timer);

        is($result, undef, 'BLMOVE timed out');
        ok(@ticks >= 50, "Event loop ticked " . scalar(@ticks) . " times");
    };

    # Cleanup
    run { $redis->del('blmove:src', 'blmove:dst') };
}

done_testing;
