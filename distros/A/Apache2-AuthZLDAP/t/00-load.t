#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::AuthZLDAP' );
}

diag( "Testing Apache2::AuthZLDAP $Apache2::AuthZLDAP::VERSION, Perl $], $^X" );
