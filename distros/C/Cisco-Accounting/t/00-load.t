#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cisco::Accounting' );
}

diag( "Testing Cisco::Accounting $Cisco::Accounting::VERSION, Perl $], $^X" );
