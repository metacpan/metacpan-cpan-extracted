#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::TransparentFactory' );
}

diag( "Testing Class::TransparentFactory $Class::TransparentFactory::VERSION, Perl $], $^X" );
