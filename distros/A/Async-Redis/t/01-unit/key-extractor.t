# t/01-unit/key-extractor.t
use strict;
use warnings;
use Test2::V0;
use Async::Redis::KeyExtractor;

subtest 'simple single-key commands' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices('GET', 'mykey');
    is(\@indices, [0], 'GET: key at index 0');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('SET', 'mykey', 'value');
    is(\@indices, [0], 'SET: key at index 0');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('DEL', 'key1');
    is(\@indices, [0], 'DEL single: key at index 0');
};

subtest 'multi-key commands' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices('MGET', 'k1', 'k2', 'k3');
    is(\@indices, [0, 1, 2], 'MGET: all args are keys');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('DEL', 'k1', 'k2', 'k3');
    is(\@indices, [0, 1, 2], 'DEL multi: all args are keys');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('EXISTS', 'k1', 'k2');
    is(\@indices, [0, 1], 'EXISTS: all args are keys');
};

subtest 'MSET - even indices only' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices('MSET', 'k1', 'v1', 'k2', 'v2');
    is(\@indices, [0, 2], 'MSET: only even indices are keys');
};

subtest 'hash commands - first arg is key' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices('HSET', 'hash', 'field', 'value');
    is(\@indices, [0], 'HSET: first arg is key');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('HGET', 'hash', 'field');
    is(\@indices, [0], 'HGET: first arg is key');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('HGETALL', 'hash');
    is(\@indices, [0], 'HGETALL: first arg is key');
};

subtest 'list commands - first arg is key' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices('LPUSH', 'list', 'item1', 'item2');
    is(\@indices, [0], 'LPUSH: first arg is key');

    @indices = Async::Redis::KeyExtractor::extract_key_indices('LRANGE', 'list', 0, -1);
    is(\@indices, [0], 'LRANGE: first arg is key');
};

subtest 'EVAL/EVALSHA - dynamic numkeys' => sub {
    # EVAL script numkeys key1 key2 arg1 arg2
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'EVAL', 'return 1', 2, 'key1', 'key2', 'arg1', 'arg2'
    );
    is(\@indices, [2, 3], 'EVAL: keys at indices 2,3 (numkeys=2)');

    @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'EVALSHA', 'abc123', 1, 'mykey', 'arg1'
    );
    is(\@indices, [2], 'EVALSHA: key at index 2 (numkeys=1)');

    @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'EVAL', 'return 1', 0, 'arg1', 'arg2'
    );
    is(\@indices, [], 'EVAL with numkeys=0: no keys');
};

subtest 'BITOP - skip operation arg' => sub {
    # BITOP operation destkey srckey1 [srckey2 ...]
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'BITOP', 'AND', 'dest', 'src1', 'src2'
    );
    is(\@indices, [1, 2, 3], 'BITOP: keys start at index 1');
};

subtest 'OBJECT subcommands' => sub {
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'OBJECT', 'ENCODING', 'mykey'
    );
    is(\@indices, [1], 'OBJECT ENCODING: key at index 1');
};

subtest 'XREAD - keys between STREAMS and IDs' => sub {
    # XREAD [COUNT n] [BLOCK ms] STREAMS stream1 stream2 id1 id2
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'XREAD', 'STREAMS', 's1', 's2', '0', '0'
    );
    is(\@indices, [1, 2], 'XREAD: streams at indices 1,2');

    @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'XREAD', 'COUNT', '10', 'BLOCK', '1000', 'STREAMS', 's1', 's2', 's3', '0', '0', '0'
    );
    is(\@indices, [5, 6, 7], 'XREAD with options: streams after STREAMS keyword');
};

subtest 'MIGRATE - single key or KEYS keyword' => sub {
    # MIGRATE host port key db timeout [COPY] [REPLACE] [AUTH pw] [KEYS k1 k2]
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'MIGRATE', 'host', '6379', 'mykey', '0', '5000'
    );
    is(\@indices, [2], 'MIGRATE single: key at index 2');

    @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'MIGRATE', 'host', '6379', '', '0', '5000', 'KEYS', 'k1', 'k2'
    );
    is(\@indices, [6, 7], 'MIGRATE multi: keys after KEYS keyword');
};

subtest 'apply_prefix' => sub {
    my @args = Async::Redis::KeyExtractor::apply_prefix(
        'myapp:', 'GET', 'key1'
    );
    is(\@args, ['myapp:key1'], 'GET with prefix');

    @args = Async::Redis::KeyExtractor::apply_prefix(
        'myapp:', 'SET', 'key1', 'value'
    );
    is(\@args, ['myapp:key1', 'value'], 'SET: value not prefixed');

    @args = Async::Redis::KeyExtractor::apply_prefix(
        'myapp:', 'MGET', 'k1', 'k2', 'k3'
    );
    is(\@args, ['myapp:k1', 'myapp:k2', 'myapp:k3'], 'MGET: all keys prefixed');

    @args = Async::Redis::KeyExtractor::apply_prefix(
        'myapp:', 'MSET', 'k1', 'v1', 'k2', 'v2'
    );
    is(\@args, ['myapp:k1', 'v1', 'myapp:k2', 'v2'], 'MSET: only keys prefixed');
};

subtest 'no prefix when empty' => sub {
    my @args = Async::Redis::KeyExtractor::apply_prefix(
        '', 'GET', 'key1'
    );
    is(\@args, ['key1'], 'empty prefix: unchanged');

    @args = Async::Redis::KeyExtractor::apply_prefix(
        undef, 'GET', 'key1'
    );
    is(\@args, ['key1'], 'undef prefix: unchanged');
};

subtest 'unknown command - no prefix, warn in debug' => sub {
    local $ENV{REDIS_DEBUG} = 0;  # Suppress warning
    my @indices = Async::Redis::KeyExtractor::extract_key_indices(
        'UNKNOWNCMD', 'arg1', 'arg2'
    );
    is(\@indices, [], 'unknown command: no indices returned');
};

done_testing;
