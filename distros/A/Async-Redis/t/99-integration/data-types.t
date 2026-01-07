#!/usr/bin/env perl
# Test: All Redis data types integration
use strict;
use warnings;
use Test2::V0;
use Test::Lib;
use Test::Async::Redis qw(init_loop skip_without_redis await_f cleanup_keys run);

my $loop = init_loop();

SKIP: {
    my $redis = skip_without_redis();

    subtest 'strings' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # SET/GET
        run { $r->set('str:key', 'value') };
        is(run { $r->get('str:key') }, 'value', 'GET works');

        # SETNX
        run { $r->setnx('str:nx', 'first') };
        run { $r->setnx('str:nx', 'second') };
        is(run { $r->get('str:nx') }, 'first', 'SETNX only sets if not exists');

        # GETSET
        my $old = run { $r->getset('str:key', 'newvalue') };
        is($old, 'value', 'GETSET returns old value');
        is(run { $r->get('str:key') }, 'newvalue', 'GETSET sets new value');

        # APPEND
        run { $r->set('str:app', 'hello') };
        run { $r->append('str:app', ' world') };
        is(run { $r->get('str:app') }, 'hello world', 'APPEND works');

        # STRLEN
        my $len = run { $r->strlen('str:app') };
        is($len, 11, 'STRLEN correct');

        # MSET/MGET
        run { $r->mset('str:m1', 'v1', 'str:m2', 'v2', 'str:m3', 'v3') };
        my $vals = run { $r->mget('str:m1', 'str:m2', 'str:m3') };
        is($vals, ['v1', 'v2', 'v3'], 'MSET/MGET work');

        # INCR/DECR
        run { $r->set('str:num', '10') };
        is(run { $r->incr('str:num') }, 11, 'INCR works');
        is(run { $r->decr('str:num') }, 10, 'DECR works');
        is(run { $r->incrby('str:num', 5) }, 15, 'INCRBY works');
        is(run { $r->decrby('str:num', 3) }, 12, 'DECRBY works');

        run { cleanup_keys($r, 'str:*') };
        $r->disconnect;
    };

    subtest 'lists' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # LPUSH/RPUSH
        run { $r->rpush('list:key', 'a', 'b', 'c') };
        run { $r->lpush('list:key', 'z') };

        # LRANGE
        my $items = run { $r->lrange('list:key', 0, -1) };
        is($items, ['z', 'a', 'b', 'c'], 'LPUSH/RPUSH/LRANGE work');

        # LLEN
        is(run { $r->llen('list:key') }, 4, 'LLEN correct');

        # LINDEX
        is(run { $r->lindex('list:key', 1) }, 'a', 'LINDEX works');

        # LSET
        run { $r->lset('list:key', 1, 'A') };
        is(run { $r->lindex('list:key', 1) }, 'A', 'LSET works');

        # LPOP/RPOP
        is(run { $r->lpop('list:key') }, 'z', 'LPOP works');
        is(run { $r->rpop('list:key') }, 'c', 'RPOP works');

        # LREM
        run { $r->rpush('list:rem', 'a', 'b', 'a', 'c', 'a') };
        run { $r->lrem('list:rem', 2, 'a') };
        my $rem_items = run { $r->lrange('list:rem', 0, -1) };
        is($rem_items, ['b', 'c', 'a'], 'LREM works');

        run { cleanup_keys($r, 'list:*') };
        $r->disconnect;
    };

    subtest 'sets' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # SADD
        run { $r->sadd('set:key', 'a', 'b', 'c') };

        # SCARD
        is(run { $r->scard('set:key') }, 3, 'SCARD correct');

        # SISMEMBER
        ok(run { $r->sismember('set:key', 'a') }, 'SISMEMBER finds member');
        ok(!run { $r->sismember('set:key', 'x') }, 'SISMEMBER returns false for non-member');

        # SMEMBERS
        my $members = run { $r->smembers('set:key') };
        is([sort @$members], ['a', 'b', 'c'], 'SMEMBERS returns all');

        # SREM
        run { $r->srem('set:key', 'b') };
        ok(!run { $r->sismember('set:key', 'b') }, 'SREM removes member');

        # Set operations
        run { $r->sadd('set:a', '1', '2', '3') };
        run { $r->sadd('set:b', '2', '3', '4') };

        my $union = run { $r->sunion('set:a', 'set:b') };
        is([sort @$union], ['1', '2', '3', '4'], 'SUNION works');

        my $inter = run { $r->sinter('set:a', 'set:b') };
        is([sort @$inter], ['2', '3'], 'SINTER works');

        my $diff = run { $r->sdiff('set:a', 'set:b') };
        is($diff, ['1'], 'SDIFF works');

        run { cleanup_keys($r, 'set:*') };
        $r->disconnect;
    };

    subtest 'hashes' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # HSET/HGET
        run { $r->hset('hash:key', 'field1', 'value1') };
        is(run { $r->hget('hash:key', 'field1') }, 'value1', 'HSET/HGET work');

        # HMSET/HMGET
        run { $r->hmset('hash:key', 'f2', 'v2', 'f3', 'v3') };
        my $vals = run { $r->hmget('hash:key', 'field1', 'f2', 'f3') };
        is($vals, ['value1', 'v2', 'v3'], 'HMSET/HMGET work');

        # HGETALL
        my $all = run { $r->hgetall('hash:key') };
        is(ref($all), 'HASH', 'HGETALL returns hash');
        is($all->{field1}, 'value1', 'HGETALL field1 correct');
        is($all->{f2}, 'v2', 'HGETALL f2 correct');

        # HKEYS/HVALS
        my $keys = run { $r->hkeys('hash:key') };
        is([sort @$keys], ['f2', 'f3', 'field1'], 'HKEYS works');

        my $values = run { $r->hvals('hash:key') };
        is([sort @$values], ['v2', 'v3', 'value1'], 'HVALS works');

        # HLEN
        is(run { $r->hlen('hash:key') }, 3, 'HLEN correct');

        # HEXISTS
        ok(run { $r->hexists('hash:key', 'field1') }, 'HEXISTS finds field');
        ok(!run { $r->hexists('hash:key', 'nofield') }, 'HEXISTS false for missing');

        # HDEL
        run { $r->hdel('hash:key', 'f3') };
        ok(!run { $r->hexists('hash:key', 'f3') }, 'HDEL removes field');

        # HINCRBY
        run { $r->hset('hash:num', 'count', '10') };
        is(run { $r->hincrby('hash:num', 'count', 5) }, 15, 'HINCRBY works');

        run { cleanup_keys($r, 'hash:*') };
        $r->disconnect;
    };

    subtest 'sorted sets' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # ZADD
        run { $r->zadd('zset:key', 1, 'one', 2, 'two', 3, 'three') };

        # ZCARD
        is(run { $r->zcard('zset:key') }, 3, 'ZCARD correct');

        # ZSCORE
        is(run { $r->zscore('zset:key', 'two') }, 2, 'ZSCORE correct');

        # ZRANK
        is(run { $r->zrank('zset:key', 'one') }, 0, 'ZRANK correct');
        is(run { $r->zrank('zset:key', 'three') }, 2, 'ZRANK for third');

        # ZRANGE
        my $range = run { $r->zrange('zset:key', 0, -1) };
        is($range, ['one', 'two', 'three'], 'ZRANGE works');

        # ZRANGEBYSCORE
        my $by_score = run { $r->zrangebyscore('zset:key', 1, 2) };
        is($by_score, ['one', 'two'], 'ZRANGEBYSCORE works');

        # ZINCRBY
        is(run { $r->zincrby('zset:key', 10, 'one') }, 11, 'ZINCRBY works');
        is(run { $r->zrank('zset:key', 'one') }, 2, 'ZINCRBY changes rank');

        # ZREM
        run { $r->zrem('zset:key', 'two') };
        is(run { $r->zcard('zset:key') }, 2, 'ZREM removes member');

        run { cleanup_keys($r, 'zset:*') };
        $r->disconnect;
    };

    subtest 'keys operations' => sub {
        my $r = Async::Redis->new(
            host => $ENV{REDIS_HOST} // 'localhost',
        );
        run { $r->connect };

        # Setup
        run { $r->set('keys:a', '1') };
        run { $r->set('keys:b', '2') };
        run { $r->set('keys:c', '3') };

        # KEYS
        my $keys = run { $r->keys('keys:*') };
        is([sort @$keys], ['keys:a', 'keys:b', 'keys:c'], 'KEYS pattern works');

        # EXISTS
        ok(run { $r->exists('keys:a') }, 'EXISTS finds key');
        ok(!run { $r->exists('keys:nonexistent') }, 'EXISTS false for missing');

        # TYPE
        is(run { $r->type('keys:a') }, 'string', 'TYPE works');

        # RENAME
        run { $r->rename('keys:a', 'keys:renamed') };
        ok(run { $r->exists('keys:renamed') }, 'RENAME works');
        ok(!run { $r->exists('keys:a') }, 'old key gone after RENAME');

        # EXPIRE/TTL
        run { $r->expire('keys:b', 100) };
        my $ttl = run { $r->ttl('keys:b') };
        ok($ttl > 0 && $ttl <= 100, 'EXPIRE/TTL work');

        # DEL
        run { $r->del('keys:b', 'keys:c') };
        ok(!run { $r->exists('keys:b') }, 'DEL removes key');
        ok(!run { $r->exists('keys:c') }, 'DEL removes multiple');

        run { cleanup_keys($r, 'keys:*') };
        $r->disconnect;
    };

    $redis->disconnect;
}

done_testing;
