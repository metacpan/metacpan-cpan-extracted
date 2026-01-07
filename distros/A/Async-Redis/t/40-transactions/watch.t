# t/40-transactions/watch.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Future::AsyncAwait;
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
    run { $redis->del('watch:key', 'watch:balance', 'watch:a', 'watch:b') };

    subtest 'watch_multi with unchanged key' => sub {
        run { $redis->set('watch:balance', '100') };

        my $results = await_f($redis->watch_multi(['watch:balance'], async sub {
            my ($tx, $watched) = @_;

            is($watched->{'watch:balance'}, '100', 'watched value provided');

            $tx->decrby('watch:balance', 10);
            $tx->get('watch:balance');
        }));

        ok(defined $results, 'transaction succeeded');
        is($results->[0], 90, 'DECRBY result');
        is($results->[1], '90', 'GET result');
    };

    subtest 'watch with multiple keys' => sub {
        run { $redis->set('watch:a', '1') };
        run { $redis->set('watch:b', '2') };

        my $results = await_f($redis->watch_multi(['watch:a', 'watch:b'], async sub {
            my ($tx, $watched) = @_;

            is($watched->{'watch:a'}, '1', 'first watched value');
            is($watched->{'watch:b'}, '2', 'second watched value');

            $tx->incr('watch:a');
            $tx->incr('watch:b');
        }));

        is($results, [2, 3], 'both incremented');

        # Cleanup
        run { $redis->del('watch:a', 'watch:b') };
    };

    subtest 'manual WATCH/MULTI/EXEC' => sub {
        run { $redis->set('watch:key', 'original') };

        run { $redis->watch('watch:key') };
        run { $redis->multi_start() };
        run { $redis->command('SET', 'watch:key', 'modified') };
        my $results = run { $redis->exec() };

        ok(defined $results, 'manual transaction succeeded');
        is($results->[0], 'OK', 'SET succeeded');

        my $value = run { $redis->get('watch:key') };
        is($value, 'modified', 'value updated');
    };

    subtest 'UNWATCH clears watches' => sub {
        run { $redis->set('watch:key', 'value') };

        run { $redis->watch('watch:key') };
        run { $redis->unwatch() };

        # Now modify key from another connection
        my $redis2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $redis2->connect };
        run { $redis2->set('watch:key', 'changed') };

        # Transaction should still succeed because we unwatched
        run { $redis->multi_start() };
        run { $redis->command('GET', 'watch:key') };
        my $results = run { $redis->exec() };

        ok(defined $results, 'transaction succeeded after UNWATCH');
    };

    # Cleanup
    run { $redis->del('watch:key', 'watch:balance') };
}

done_testing;
