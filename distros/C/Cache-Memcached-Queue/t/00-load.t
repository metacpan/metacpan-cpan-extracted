#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cache::Memcached::Queue' ) || print "Bail out!\n";
}

diag( "Testing Cache::Memcached::Queue $Cache::Memcached::Queue::VERSION, Perl $], $^X" );
