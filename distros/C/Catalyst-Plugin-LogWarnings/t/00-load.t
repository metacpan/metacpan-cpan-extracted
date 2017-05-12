#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::LogWarnings' );
}

diag( "Testing Catalyst::Plugin::LogWarnings $Catalyst::Plugin::LogWarnings::VERSION, Perl $], $^X" );
