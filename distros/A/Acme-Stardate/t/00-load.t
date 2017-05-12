#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Stardate' );
}

diag( "Testing Acme::Stardate $Acme::Stardate::VERSION, Perl $], $^X" );
