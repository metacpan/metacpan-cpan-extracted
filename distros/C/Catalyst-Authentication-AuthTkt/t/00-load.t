#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'Catalyst::Authentication::AuthTkt' );
	use_ok( 'Catalyst::Authentication::Realm::AuthTkt' );
	use_ok( 'Catalyst::Authentication::Credential::AuthTkt' );
	use_ok( 'Catalyst::Authentication::Store::AuthTkt' );
	use_ok( 'Catalyst::Authentication::User::AuthTkt' );
        use_ok( 'Catalyst' );
}

diag( "Testing Catalyst::Authentication::AuthTkt $Catalyst::Authentication::AuthTkt::VERSION, Perl $], $^X" );
diag( "Testing Catalyst $Catalyst::VERSION" );
