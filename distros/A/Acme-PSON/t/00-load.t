#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::PSON' );
}

diag( "Testing Acme::PSON $Acme::PSON::VERSION, Perl $], $^X" );
