#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Chart::EPS_graph' );
	use_ok( 'Chart::EPS_graph::Test' );
}

diag( "Testing Chart::EPS_graph $Chart::EPS_graph::VERSION, Perl $], $^X" );
