#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Authen::CAS::External' );
}

diag( "Testing Authen::CAS::External $Authen::CAS::External::VERSION, Perl $], $^X" );
