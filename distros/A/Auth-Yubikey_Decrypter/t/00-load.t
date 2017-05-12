#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Auth::Yubikey_Decrypter' );
}

diag( "Testing Auth::Yubikey_Decrypter $Auth::Yubikey_Decrypter::VERSION, Perl $], $^X" );
