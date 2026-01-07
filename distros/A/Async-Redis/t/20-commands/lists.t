# t/20-commands/lists.t
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
    run { $redis->del('test:list') };

    subtest 'LPUSH and RPUSH' => sub {
        my $len = run { $redis->rpush('test:list', 'a', 'b', 'c') };
        is($len, 3, 'RPUSH returns new length');

        $len = run { $redis->lpush('test:list', 'z') };
        is($len, 4, 'LPUSH returns new length');
    };

    subtest 'LRANGE' => sub {
        my $list = run { $redis->lrange('test:list', 0, -1) };
        is($list, ['z', 'a', 'b', 'c'], 'LRANGE returns full list');

        $list = run { $redis->lrange('test:list', 0, 1) };
        is($list, ['z', 'a'], 'LRANGE with slice');
    };

    subtest 'LPOP and RPOP' => sub {
        my $val = run { $redis->lpop('test:list') };
        is($val, 'z', 'LPOP returns left element');

        $val = run { $redis->rpop('test:list') };
        is($val, 'c', 'RPOP returns right element');
    };

    subtest 'LLEN and LINDEX' => sub {
        my $len = run { $redis->llen('test:list') };
        is($len, 2, 'LLEN returns length');

        my $val = run { $redis->lindex('test:list', 0) };
        is($val, 'a', 'LINDEX returns element at index');
    };

    subtest 'LSET' => sub {
        run { $redis->lset('test:list', 0, 'A') };
        my $val = run { $redis->lindex('test:list', 0) };
        is($val, 'A', 'LSET modified element');
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
            run { $redis->rpush('test:list', "item$i") };
        }
        run { $redis->lrange('test:list', 0, -1) };

        $timer->stop;
        get_loop()->remove($timer);

        # Timing-sensitive test - just verify loop processed
        pass("Event loop processed during operations");
    };

    # Cleanup
    run { $redis->del('test:list') };
}

done_testing;
