use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();
plan(tests => 22);
isa_ok($cache, "Cache::Memcached::libmemcached");

{
    $cache->set("num", 0);

    for my $i (1..10) {
        my $num = $cache->incr("num");
        is($num, $i);
    }
}

{
    $cache->remove("num");
    ok( ! $cache->incr("num") );
}

{
    $cache->set("num", 10);

    for my $i (reverse (1..9) ){
        my $num = $cache->decr("num");
        is($num, $i);
    }
}

{
    $cache->remove("num");
    ok( ! $cache->decr("num") );
}
