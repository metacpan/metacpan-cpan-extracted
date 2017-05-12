#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Apache::Session::libmemcached' );
	use_ok( 'Apache::Session::Store::libmemcached' );
}

diag( "Testing Apache::Session::libmemcached $Apache::Session::libmemcached::VERSION, Perl $], $^X" );
