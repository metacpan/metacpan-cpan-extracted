#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Acme::PlayCode' );
	use_ok( 'Acme::PlayCode::Plugin::DoubleToSingle' );
}

diag( "Testing Acme::PlayCode $Acme::PlayCode::VERSION, Perl $], $^X" );
