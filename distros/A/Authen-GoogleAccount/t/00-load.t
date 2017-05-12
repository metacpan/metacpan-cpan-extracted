#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Authen::GoogleAccount' );
}

diag( "Testing Authen::GoogleAccount $Authen::GoogleAccount::VERSION, Perl $], $^X" );
