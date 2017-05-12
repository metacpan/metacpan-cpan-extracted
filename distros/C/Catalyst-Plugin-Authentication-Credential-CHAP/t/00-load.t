#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Authentication::Credential::CHAP' );
}

diag( "Testing Catalyst::Plugin::Authentication::Credential::CHAP $Catalyst::Plugin::Authentication::Credential::CHAP::VERSION, Perl $], $^X" );
