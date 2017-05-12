#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::NestedSet' );
}

diag( "Testing Data::NestedSet $Data::NestedSet::VERSION, Perl $], $^X" );
