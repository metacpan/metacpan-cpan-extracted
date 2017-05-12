#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cache::BDB' );
}

diag( "Testing Cache::BDB $Cache::BDB::VERSION, Perl $], $^X" );
