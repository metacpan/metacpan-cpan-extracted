#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Crypt::OTP26' );
}

diag( "Testing Crypt::OTP26 $Crypt::OTP26::VERSION, Perl $], $^X" );
