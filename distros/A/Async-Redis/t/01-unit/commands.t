# t/01-unit/commands.t
use Test2::V0;
use Async::Redis::Commands;

subtest 'module loads' => sub {
    ok(Async::Redis::Commands->can('get'), 'has get method');
    ok(Async::Redis::Commands->can('set'), 'has set method');
    ok(Async::Redis::Commands->can('del'), 'has del method');
    ok(Async::Redis::Commands->can('exists'), 'has exists method');
};

subtest 'string commands exist' => sub {
    for my $cmd (qw(get set append getrange setrange strlen incr decr incrby decrby)) {
        ok(Async::Redis::Commands->can($cmd), "has $cmd method");
    }
};

subtest 'hash commands exist' => sub {
    for my $cmd (qw(hset hget hdel hexists hlen hkeys hvals hgetall hmset hmget hsetnx hincrby)) {
        ok(Async::Redis::Commands->can($cmd), "has $cmd method");
    }
};

subtest 'list commands exist' => sub {
    for my $cmd (qw(lpush rpush lpop rpop llen lrange lindex lset lrem linsert)) {
        ok(Async::Redis::Commands->can($cmd), "has $cmd method");
    }
};

subtest 'set commands exist' => sub {
    for my $cmd (qw(sadd srem smembers sismember scard sinter sunion sdiff spop srandmember)) {
        ok(Async::Redis::Commands->can($cmd), "has $cmd method");
    }
};

subtest 'sorted set commands exist' => sub {
    for my $cmd (qw(zadd zrem zscore zrank zrange zrangebyscore zcard zincrby)) {
        ok(Async::Redis::Commands->can($cmd), "has $cmd method");
    }
};

subtest 'subcommand methods exist' => sub {
    ok(Async::Redis::Commands->can('client_setname'), 'has client_setname');
    ok(Async::Redis::Commands->can('client_getname'), 'has client_getname');
    ok(Async::Redis::Commands->can('config_get'), 'has config_get');
    ok(Async::Redis::Commands->can('config_set'), 'has config_set');
};

done_testing;
