#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Advent::Bundles' );
}

diag( "Testing Advent::Bundles $Advent::Bundles::VERSION, Perl $], $^X" );
