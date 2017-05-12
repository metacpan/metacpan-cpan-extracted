#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Grep2D' );
}

diag( "Testing Acme::Grep2D $Acme::Grep2D::VERSION, Perl $], $^X" );
