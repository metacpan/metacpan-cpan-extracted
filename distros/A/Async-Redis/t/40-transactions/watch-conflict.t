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
    run { $redis->del('conflict:key', 'conflict:counter', 'conflict:watched', 'conflict:poisoned') };

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

    # Regression test for a subtle state leak in watch_multi().
    #
    # watch_multi() does:
    #   1. WATCH key(s)
    #   2. read current values
    #   3. invoke the user callback
    #   4. then start MULTI/EXEC
    #
    # If the callback dies in step 3, the client must still UNWATCH and
    # clear its local state. Otherwise the connection is "poisoned": a later,
    # unrelated MULTI/EXEC on the same socket can abort after another client
    # touches the previously watched key.
    #
    # The important assertion here is not just !$redis->watching. We also
    # mutate the old watched key from a second connection and then prove a
    # fresh transaction on the original connection still succeeds. That shows
    # the server-side WATCH was actually unwound, not just the local flag.
    subtest 'watch_multi callback failure unwatches connection' => sub {
        run { $redis->set('conflict:watched', '0') };
        run { $redis->del('conflict:poisoned') };

        my $error;
        eval {
            await_f($redis->watch_multi(['conflict:watched'], async sub {
                my ($tx, $watched) = @_;
                is($watched->{'conflict:watched'}, '0', 'got watched value before callback dies');
                die "callback boom";
            }));
            1;
        } or $error = $@;

        like("$error", qr/callback boom/, 'callback failure propagated');
        ok(!$redis->watching, 'local watch state cleared after callback failure');

        # Touch the old watched key from another client. A leaked WATCH on the
        # original connection would make the EXEC below return undef.
        run { $redis2->set('conflict:watched', '1') };

        run { $redis->multi_start() };
        run { $redis->command('SET', 'conflict:poisoned', 'ok') };
        my $results = run { $redis->exec() };

        ok(defined $results, 'later transaction succeeds after callback failure');
        is($results, ['OK'], 'later EXEC applies queued write');

        my $value = run { $redis->get('conflict:poisoned') };
        is($value, 'ok', 'later transaction persisted value');
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
    run { $redis->del('conflict:key', 'conflict:counter', 'conflict:watched', 'conflict:poisoned') };
}

done_testing;
