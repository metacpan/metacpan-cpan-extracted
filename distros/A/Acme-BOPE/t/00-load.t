#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::BOPE' );
}

diag( "Testing Acme::BOPE $Acme::BOPE::VERSION, Perl $], $^X" );
