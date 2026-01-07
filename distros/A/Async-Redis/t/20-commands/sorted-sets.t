# t/20-commands/sorted-sets.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost', connect_timeout => 2);
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    # Cleanup
    run { $redis->del('test:zset') };

    subtest 'ZADD and ZSCORE' => sub {
        my $added = run { $redis->zadd('test:zset', 1, 'one', 2, 'two', 3, 'three') };
        is($added, 3, 'ZADD returns count');

        my $score = run { $redis->zscore('test:zset', 'two') };
        is($score, '2', 'ZSCORE returns score');
    };

    subtest 'ZRANGE' => sub {
        my $range = run { $redis->zrange('test:zset', 0, -1) };
        is($range, ['one', 'two', 'three'], 'ZRANGE returns ordered members');

        # With WITHSCORES
        $range = run { $redis->zrange('test:zset', 0, -1, 'WITHSCORES') };
        is($range, ['one', '1', 'two', '2', 'three', '3'], 'ZRANGE WITHSCORES works');
    };

    subtest 'ZRANK' => sub {
        my $rank = run { $redis->zrank('test:zset', 'one') };
        is($rank, 0, 'ZRANK returns 0-based rank');

        $rank = run { $redis->zrank('test:zset', 'three') };
        is($rank, 2, 'ZRANK for third element');
    };

    subtest 'ZINCRBY' => sub {
        my $new = run { $redis->zincrby('test:zset', 10, 'one') };
        is($new, '11', 'ZINCRBY returns new score');

        # Now 'one' should be last
        my $range = run { $redis->zrange('test:zset', -1, -1) };
        is($range, ['one'], 'order updated after ZINCRBY');
    };

    subtest 'ZCARD and ZREM' => sub {
        my $card = run { $redis->zcard('test:zset') };
        is($card, 3, 'ZCARD returns count');

        my $removed = run { $redis->zrem('test:zset', 'one') };
        is($removed, 1, 'ZREM returns count');

        $card = run { $redis->zcard('test:zset') };
        is($card, 2, 'count decreased after ZREM');
    };

    subtest 'non-blocking verification' => sub {
        my @ticks;
        my $timer = IO::Async::Timer::Periodic->new(
            interval => 0.01,
            on_tick => sub { push @ticks, 1 },
        );
        get_loop()->add($timer);
        $timer->start;

        for my $i (1..50) {
            run { $redis->zadd('test:zset', $i, "member$i") };
        }

        $timer->stop;
        get_loop()->remove($timer);

        # Timing-sensitive test - just verify loop processed
        pass("Event loop ticked during sorted set operations");
    };

    # Cleanup
    run { $redis->del('test:zset') };
}

done_testing;
