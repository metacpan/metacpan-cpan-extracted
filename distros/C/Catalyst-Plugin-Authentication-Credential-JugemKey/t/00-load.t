#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Authentication::Credential::JugemKey' );
}

diag( "Testing Catalyst::Plugin::Authentication::Credential::JugemKey $Catalyst::Plugin::Authentication::Credential::JugemKey::VERSION, Perl $], $^X" );
