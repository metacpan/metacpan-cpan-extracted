#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::LogDeep' );
}

diag( "Testing Catalyst::Plugin::LogDeep $Catalyst::Plugin::LogDeep::VERSION, Perl $], $^X" );
