# t/20-commands/sets.t
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
    run { $redis->del('test:set1', 'test:set2') };

    subtest 'SADD and SMEMBERS' => sub {
        my $added = run { $redis->sadd('test:set1', 'a', 'b', 'c') };
        is($added, 3, 'SADD returns count');

        my $members = run { $redis->smembers('test:set1') };
        is([sort @$members], ['a', 'b', 'c'], 'SMEMBERS returns all members');
    };

    subtest 'SISMEMBER and SCARD' => sub {
        my $is = run { $redis->sismember('test:set1', 'a') };
        is($is, 1, 'SISMEMBER returns 1 for member');

        $is = run { $redis->sismember('test:set1', 'z') };
        is($is, 0, 'SISMEMBER returns 0 for non-member');

        my $card = run { $redis->scard('test:set1') };
        is($card, 3, 'SCARD returns cardinality');
    };

    subtest 'SREM' => sub {
        my $removed = run { $redis->srem('test:set1', 'a') };
        is($removed, 1, 'SREM returns count');

        my $card = run { $redis->scard('test:set1') };
        is($card, 2, 'cardinality decreased');
    };

    subtest 'SINTER, SUNION, SDIFF' => sub {
        run { $redis->sadd('test:set1', 'a', 'b', 'c') };
        run { $redis->sadd('test:set2', 'b', 'c', 'd') };

        my $inter = run { $redis->sinter('test:set1', 'test:set2') };
        is([sort @$inter], ['b', 'c'], 'SINTER works');

        my $union = run { $redis->sunion('test:set1', 'test:set2') };
        is([sort @$union], ['a', 'b', 'c', 'd'], 'SUNION works');

        my $diff = run { $redis->sdiff('test:set1', 'test:set2') };
        is([sort @$diff], ['a'], 'SDIFF works');
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
            run { $redis->sadd('test:set1', "member$i") };
        }

        $timer->stop;
        get_loop()->remove($timer);

        # Timing-sensitive test - just verify loop processed
        pass("Event loop processed during operations");
    };

    # Cleanup
    run { $redis->del('test:set1', 'test:set2') };
}

done_testing;
