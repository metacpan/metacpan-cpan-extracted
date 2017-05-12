#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Padre::PlayCode' );
}

diag( "Testing Acme::Padre::PlayCode $Acme::Padre::PlayCode::VERSION, Perl $], $^X" );
