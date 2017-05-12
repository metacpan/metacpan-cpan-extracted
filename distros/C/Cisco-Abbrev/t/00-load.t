#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cisco::Abbrev' );
}

diag( "Testing Cisco::Abbrev $Cisco::Abbrev::VERSION, Perl $], $^X" );
