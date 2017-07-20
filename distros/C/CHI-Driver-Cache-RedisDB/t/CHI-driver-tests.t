use strict;
use warnings;
use version;

use Test::Most;
use CHI::Driver::Cache::RedisDB::t::CHIDriverTests;
use Test::RedisDB;

my $server      = Test::RedisDB->new;
my $min_version = version->parse("2.6.12"); # Need to be able to use PX with SET

if ($server && version->parse($server->redisdb_client->version) > $min_version)
{
    plan tests => 2;
} else {
    plan skip_all => "No proper redis-server for testing";
}

my $prev_env = $ENV{REDIS_CACHE_SERVER};

$ENV{REDIS_CACHE_SERVER} = $server->url;

subtest 'CHI provided tests' => sub {
    CHI::Driver::Cache::RedisDB::t::CHIDriverTests->runtests;
};

subtest 'flush_all' => sub {
    ok(CHI->new(driver => 'Cache::RedisDB')->flush_all, 'Flushed all');
};

$ENV{REDIS_CACHE_SERVER} = $prev_env;

done_testing;
