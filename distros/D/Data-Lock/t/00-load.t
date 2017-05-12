#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Data::Lock' );
	use_ok( 'Attribute::Constant' );
}

diag( "Testing Data::Lock $Data::Lock::VERSION, Perl $], $^X" );
