#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Acme::Scramble' );
}

diag( "Testing Catalyst::Plugin::Acme::Scramble $Catalyst::Plugin::Acme::Scramble::VERSION, Perl $], $^X" );
