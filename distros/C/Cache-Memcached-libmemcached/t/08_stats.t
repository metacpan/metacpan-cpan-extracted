use strict;
use lib 't/lib';
use libmemcached_test;
use Test::More;

my $cache = libmemcached_test_create();
plan tests => 1;

{
    my $h1 = $cache->stats();
    ok( scalar keys %{$h1->{hosts}} > 0 );
}