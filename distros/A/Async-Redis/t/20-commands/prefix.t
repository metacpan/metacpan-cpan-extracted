# t/20-commands/prefix.t
use strict;
use warnings;
use Test::Lib;
use Test::Async::Redis ':redis';
use Test2::V0;
use Async::Redis;

SKIP: {
    my $redis = eval {
        my $r = Async::Redis->new(
            host   => $ENV{REDIS_HOST} // 'localhost',
            prefix => 'test:prefix:',
            connect_timeout => 2,
        );
        run { $r->connect };
        $r;
    };
    skip "Redis not available: $@", 1 unless $redis;

    subtest 'prefix applied to SET/GET' => sub {
        run { $redis->set('key1', 'value1') };

        # Value should be stored under prefixed key
        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        my $value = run { $raw_redis->get('test:prefix:key1') };
        is($value, 'value1', 'key stored with prefix');

        # Our prefixed client should find it
        $value = run { $redis->get('key1') };
        is($value, 'value1', 'prefixed GET works');

        # Cleanup via raw connection
        run { $raw_redis->del('test:prefix:key1') };
    };

    subtest 'prefix applied to MGET' => sub {
        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        # Set up keys with prefix
        run { $raw_redis->set('test:prefix:a', '1') };
        run { $raw_redis->set('test:prefix:b', '2') };
        run { $raw_redis->set('test:prefix:c', '3') };

        # MGET with prefixed client
        my $values = run { $redis->mget('a', 'b', 'c') };
        is($values, ['1', '2', '3'], 'MGET with prefix works');

        # Cleanup
        run { $raw_redis->del('test:prefix:a', 'test:prefix:b', 'test:prefix:c') };
    };

    subtest 'prefix NOT applied to values' => sub {
        run { $redis->set('key2', 'my:value:with:colons') };

        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        my $value = run { $raw_redis->get('test:prefix:key2') };
        is($value, 'my:value:with:colons', 'value not prefixed');

        # Cleanup
        run { $raw_redis->del('test:prefix:key2') };
    };

    subtest 'prefix in MSET - keys only, not values' => sub {
        run { $redis->mset('x', 'val:x', 'y', 'val:y') };

        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        my $x = run { $raw_redis->get('test:prefix:x') };
        my $y = run { $raw_redis->get('test:prefix:y') };
        is($x, 'val:x', 'x value unchanged');
        is($y, 'val:y', 'y value unchanged');

        # Cleanup
        run { $raw_redis->del('test:prefix:x', 'test:prefix:y') };
    };

    subtest 'prefix in hash commands' => sub {
        run { $redis->hset('myhash', 'field1', 'value1') };

        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        # Check it's stored with prefix
        my $value = run { $raw_redis->hget('test:prefix:myhash', 'field1') };
        is($value, 'value1', 'hash stored with prefixed key');

        # Field name should NOT be prefixed
        my $exists = run { $raw_redis->hexists('test:prefix:myhash', 'field1') };
        is($exists, 1, 'field name not prefixed');

        # Cleanup
        run { $raw_redis->del('test:prefix:myhash') };
    };

    subtest 'DEL with multiple keys' => sub {
        my $raw_redis = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $raw_redis->connect };

        run { $raw_redis->set('test:prefix:d1', '1') };
        run { $raw_redis->set('test:prefix:d2', '2') };
        run { $raw_redis->set('test:prefix:d3', '3') };

        # Delete via prefixed client
        my $deleted = run { $redis->del('d1', 'd2', 'd3') };
        is($deleted, 3, 'DEL with prefix deleted 3 keys');

        # Verify deleted
        my $exists = run { $raw_redis->exists('test:prefix:d1') };
        is($exists, 0, 'key deleted');
    };

    subtest 'no prefix when disabled' => sub {
        my $no_prefix = Async::Redis->new(host => $ENV{REDIS_HOST} // 'localhost');
        run { $no_prefix->connect };

        run { $no_prefix->set('raw:key', 'value') };
        my $value = run { $no_prefix->get('raw:key') };
        is($value, 'value', 'no prefix client works');

        # Cleanup
        run { $no_prefix->del('raw:key') };
    };
}

done_testing;
