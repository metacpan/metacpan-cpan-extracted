#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Algorithm::FloodControl' );
}

diag( "Testing Algorithm::FloodControl $Algorithm::FloodControl::VERSION, Perl $], $^X" );
