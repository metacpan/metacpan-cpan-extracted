#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Credential::YubiKey' );
}

diag( "Testing Catalyst::Authentication::Credential::YubiKey $Catalyst::Authentication::Credential::YubiKey::VERSION, Perl $], $^X" );
