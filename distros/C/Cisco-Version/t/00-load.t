#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cisco::Version' );
}

diag( "Testing Cisco::Version $Cisco::Version::VERSION, Perl $], $^X" );
