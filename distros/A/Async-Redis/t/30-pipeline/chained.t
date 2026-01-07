# t/30-pipeline/chained.t
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

    subtest 'chained pipeline style' => sub {
        my $results = await_f(
            $redis->pipeline
                ->set('chain:a', 1)
                ->set('chain:b', 2)
                ->get('chain:a')
                ->get('chain:b')
                ->execute
        );

        is($results, ['OK', 'OK', '1', '2'], 'chained pipeline works');

        # Cleanup
        run { $redis->del('chain:a', 'chain:b') };
    };

    subtest 'chained with mixed commands' => sub {
        run { $redis->del('chain:list', 'chain:hash') };

        my $results = await_f(
            $redis->pipeline
                ->rpush('chain:list', 'a', 'b', 'c')
                ->lrange('chain:list', 0, -1)
                ->hset('chain:hash', 'field', 'value')
                ->hget('chain:hash', 'field')
                ->execute
        );

        is($results->[0], 3, 'RPUSH returned 3');
        is($results->[1], ['a', 'b', 'c'], 'LRANGE returned list');
        is($results->[2], 1, 'HSET returned 1');
        is($results->[3], 'value', 'HGET returned value');

        # Cleanup
        run { $redis->del('chain:list', 'chain:hash') };
    };

    subtest 'chained returns pipeline for method chaining' => sub {
        my $pipe = $redis->pipeline;

        my $ret = $pipe->set('chain:x', 1);
        is($ret, $pipe, 'set returns pipeline');

        $ret = $pipe->get('chain:x');
        is($ret, $pipe, 'get returns pipeline');

        run { $pipe->execute };
        run { $redis->del('chain:x') };
    };
}

done_testing;
