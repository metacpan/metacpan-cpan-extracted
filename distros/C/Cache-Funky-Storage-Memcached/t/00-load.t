#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cache::Funky::Storage::Memcached' );
}

diag( "Testing Cache::Funky::Storage::Memcached $Cache::Funky::Storage::Memcached::VERSION, Perl $], $^X" );
