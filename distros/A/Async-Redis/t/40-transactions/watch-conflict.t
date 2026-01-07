# t/40-transactions/watch-conflict.t
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

    # Second connection to modify watched keys
    my $redis2 = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
    run { $redis2->connect };

    # Cleanup
    run { $redis->del('conflict:key', 'conflict:counter') };

    subtest 'WATCH conflict returns undef' => sub {
        run { $redis->set('conflict:key', 'original') };

        # Start watching
        run { $redis->watch('conflict:key') };

        # Another client modifies the key
        run { $redis2->set('conflict:key', 'modified') };

        # Try to execute transaction
        run { $redis->multi_start() };
        run { $redis->command('SET', 'conflict:key', 'from_transaction') };
        my $results = run { $redis->exec() };

        is($results, undef, 'EXEC returns undef on WATCH conflict');

        # Verify the other client's value persisted
        my $value = run { $redis->get('conflict:key') };
        is($value, 'modified', 'other client value persisted');
    };

    subtest 'watch_multi returns undef on conflict' => sub {
        run { $redis->set('conflict:key', 'original') };

        my $results = await_f($redis->watch_multi(['conflict:key'], async sub {
            my ($tx, $watched) = @_;

            is($watched->{'conflict:key'}, 'original', 'got original value');

            # Simulate race: other client modifies between WATCH and EXEC
            run { $redis2->set('conflict:key', 'raced') };

            $tx->set('conflict:key', 'from_tx');
        }));

        is($results, undef, 'watch_multi returns undef on conflict');

        # Verify race winner
        my $value = run { $redis->get('conflict:key') };
        is($value, 'raced', 'race condition winner persisted');
    };

    subtest 'retry pattern on conflict' => sub {
        run { $redis->set('conflict:counter', '0') };

        my $attempts = 0;
        my $success = 0;

        # Retry loop pattern
        while ($attempts < 5 && !$success) {
            $attempts++;

            my $results = await_f($redis->watch_multi(['conflict:counter'], async sub {
                my ($tx, $watched) = @_;

                my $current = $watched->{'conflict:counter'} // 0;

                # On first attempt, simulate a race
                if ($attempts == 1) {
                    run { $redis2->incr('conflict:counter') };
                }

                $tx->set('conflict:counter', $current + 10);
            }));

            $success = defined $results;
        }

        ok($success, 'eventually succeeded after retry');
        ok($attempts > 1, "needed $attempts attempts");

        my $final = run { $redis->get('conflict:counter') };
        # Should be 11: redis2 set to 1, then we added 10 to that
        is($final, '11', 'final value includes both modifications');
    };

    # Cleanup
    run { $redis->del('conflict:key', 'conflict:counter') };
}

done_testing;
