use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();
plan(tests => 1);

{
    $cache->disconnect_all;
    ok(1);
}

1;