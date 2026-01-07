# t/40-transactions/nested.t
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

    subtest 'nested MULTI returns error' => sub {
        run { $redis->multi_start() };

        # Trying to start another MULTI should return error
        my $error;
        eval {
            run { $redis->multi_start() };
        };
        $error = $@;

        # Clean up
        run { $redis->discard() };

        ok($error, 'nested MULTI threw error');
        like("$error", qr/MULTI calls can not be nested/i, 'correct error message');
    };

    subtest 'multi() callback prevents nesting' => sub {
        my $error;
        eval {
            await_f($redis->multi(async sub {
                my ($tx) = @_;

                # Try to start nested transaction
                await_f($redis->multi(async sub {
                    my ($tx2) = @_;
                    $tx2->set('nested:key', 'value');
                }));
            }));
        };
        $error = $@;

        ok($error, 'nested multi() threw error');
        like("$error", qr/already in a transaction/i, 'correct error message for nested multi()');
    };

    subtest 'connection usable after nested error' => sub {
        # Connection should still work
        my $result = run { $redis->ping };
        is($result, 'PONG', 'connection still usable');
    };
}

done_testing;
