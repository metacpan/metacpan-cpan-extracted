use strict;
use warnings;
use Test::Most tests => 2;
use CHI::Driver::Cache::RedisDB::t::CHIDriverTests;

subtest 'CHI provided tests' => sub {
    CHI::Driver::Cache::RedisDB::t::CHIDriverTests->runtests;
};

subtest 'flush_all' => sub {
    ok(CHI->new(driver => 'Cache::RedisDB')->flush_all, 'Flushed all');
};
