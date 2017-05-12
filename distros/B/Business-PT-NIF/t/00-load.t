#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::PT::NIF' );
}

diag( "Testing Business::PT::NIF $Business::PT::NIF::VERSION, Perl $], $^X" );
