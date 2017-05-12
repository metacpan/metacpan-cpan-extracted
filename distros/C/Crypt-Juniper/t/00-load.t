#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::Juniper' );
}

diag( "Testing Crypt::Juniper $Crypt::Juniper::VERSION, Perl $], $^X" );
