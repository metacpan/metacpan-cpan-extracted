#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::AuthenNIS' );
}

diag( "Testing Apache2::AuthenNIS $Apache2::AuthenNIS::VERSION, Perl $], $^X" );
