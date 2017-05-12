#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Realm::Adaptor' );
}

diag( "Testing Catalyst::Authentication::Realm::Adaptor $Catalyst::Authentication::Realm::Adaptor::VERSION, Perl $], $^X" );
