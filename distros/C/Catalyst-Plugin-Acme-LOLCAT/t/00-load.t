#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Acme::LOLCAT' );
}

diag( "Testing Catalyst::Plugin::Acme::LOLCAT $Catalyst::Plugin::Acme::LOLCAT::VERSION, Perl $], $^X" );
