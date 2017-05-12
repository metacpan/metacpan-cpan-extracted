#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Data::Freezer' );
	use_ok( 'Data::Freezer::FreezingBag' );
}

diag( "Testing Data::Freezer $Data::Freezer::VERSION, Perl $], $^X" );
