#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::KeyDiff' );
}

diag( "Testing Data::KeyDiff $Data::KeyDiff::VERSION, Perl $], $^X" );
