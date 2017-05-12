#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::MyFirstModule::WWILLIS' );
}

diag( "Testing Acme::MyFirstModule::WWILLIS $Acme::MyFirstModule::WWILLIS::VERSION, Perl $], $^X" );
