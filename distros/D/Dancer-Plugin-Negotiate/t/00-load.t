#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Plugin::Negotiate' );
}

diag( "Testing Dancer-Plugin-Negotiate $Dancer::Plugin::Negotiate::VERSION, Perl $], $^X" );
