#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Plugin::SecureSessionID' );
}

diag( "Testing Dancer-Plugin-SecureSessionID $Dancer::Plugin::SecureSessionID::VERSION, Perl $], $^X" );
