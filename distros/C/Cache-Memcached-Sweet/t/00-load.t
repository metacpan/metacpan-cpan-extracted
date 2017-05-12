#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Cache::Memcached::Sweet' ) || print "Bail out!\n";
}

diag( "Testing Cache::Memcached::Sweet $Cache::Memcached::Sweet::VERSION, Perl $], $^X" );
