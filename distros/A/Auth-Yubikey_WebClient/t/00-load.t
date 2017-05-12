#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Auth::Yubikey_WebClient' );
}

diag( "Testing Auth::Yubikey_WebClient $Auth::Yubikey_WebClient::VERSION, Perl $], $^X" );
