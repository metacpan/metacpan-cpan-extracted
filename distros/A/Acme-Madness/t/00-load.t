#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Madness' );
}

diag( "Testing Acme::Madness $Acme::Madness::VERSION, Perl $], $^X" );
