#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::AutoAccess' );
}

diag( "Testing Class::AutoAccess $Class::AutoAccess::VERSION, Perl $], $^X" );
