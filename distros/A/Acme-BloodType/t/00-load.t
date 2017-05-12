#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::BloodType' );
}

diag( "Testing Acme::BloodType $Acme::BloodType::VERSION, Perl $], $^X" );
