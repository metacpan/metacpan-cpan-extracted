#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Convert::Cisco' );
}

diag( "Testing Convert::Cisco $Convert::Cisco::VERSION, Perl $], $^X" );
