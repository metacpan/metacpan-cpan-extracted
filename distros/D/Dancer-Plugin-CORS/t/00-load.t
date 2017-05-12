#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Plugin::CORS' );
}

diag( "Testing Dancer-Plugin-CORS $Dancer::Plugin::CORS::VERSION, Perl $], $^X" );
