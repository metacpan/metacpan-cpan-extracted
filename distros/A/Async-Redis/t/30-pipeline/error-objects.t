# t/30-pipeline/error-objects.t
#
# Test that pipeline and auto-pipeline use typed error objects,
# not string matching, for error detection.
#
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;
use Scalar::Util qw(blessed);
use Future;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'pipeline errors are Error::Redis objects' => sub {
        run { $redis->set('errobj:string', 'hello') };

        my $results = await_f(
            $redis->pipeline
                ->set('errobj:a', 1)
                ->lpush('errobj:string', 'item')  # WRONGTYPE error
                ->set('errobj:b', 2)
                ->execute
        );

        is($results->[0], 'OK', 'first SET succeeded');

        # Error should be a proper object, not a plain string
        my $err = $results->[1];
        ok(blessed($err), 'error is a blessed object')
            or diag "got: " . (defined $err ? $err : '<undef>');
        ok($err->isa('Async::Redis::Error::Redis'), 'error isa Error::Redis')
            if blessed($err);

        is($results->[2], 'OK', 'third SET succeeded');

        run { $redis->del('errobj:string', 'errobj:a', 'errobj:b') };
    };

    subtest 'values starting with "Redis error:" are not false positives' => sub {
        my $tricky_value = 'Redis error: this is just a normal string value';
        run { $redis->set('errobj:tricky', $tricky_value) };

        my $results = await_f(
            $redis->pipeline
                ->get('errobj:tricky')
                ->execute
        );

        is($results->[0], $tricky_value, 'value preserved exactly');
        ok(!blessed($results->[0]), 'value is not an error object');

        run { $redis->del('errobj:tricky') };
    };

    subtest 'auto-pipeline: values starting with "Redis error:" work correctly' => sub {
        my $redis_ap = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 1,
        );
        run { $redis_ap->connect };

        my $tricky_value = 'Redis error: this is legitimate data';
        run { $redis_ap->set('errobj:ap:tricky', $tricky_value) };

        # This value should be returned as-is, not treated as an error
        my $result = run { $redis_ap->get('errobj:ap:tricky') };
        is($result, $tricky_value, 'tricky value returned correctly via auto-pipeline');

        run { $redis_ap->del('errobj:ap:tricky') };
        $redis_ap->disconnect;
    };

    subtest 'auto-pipeline: real errors are still caught' => sub {
        my $redis_ap = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
            auto_pipeline => 1,
        );
        run { $redis_ap->connect };

        run { $redis_ap->set('errobj:ap:str', 'hello') };

        # This should fail with WRONGTYPE
        my $error;
        eval {
            run { $redis_ap->lpush('errobj:ap:str', 'item') };
        };
        $error = $@;

        ok($error, 'error propagated');
        like("$error", qr/WRONGTYPE/i, 'correct error type');

        run { $redis_ap->del('errobj:ap:str') };
        $redis_ap->disconnect;
    };

    subtest 'regular command errors are Error::Redis objects' => sub {
        run { $redis->set('errobj:regular', 'hello') };

        my $error;
        eval {
            run { $redis->lpush('errobj:regular', 'item') };
        };
        $error = $@;

        ok($error, 'error thrown');
        ok(blessed($error), 'error is a blessed object')
            or diag "got: $error";
        ok($error->isa('Async::Redis::Error::Redis'), 'error isa Error::Redis')
            if blessed($error);

        run { $redis->del('errobj:regular') };
    };
}

done_testing;
