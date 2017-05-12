#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Constant' );
}

diag( "Testing Class::Constant $Class::Constant::VERSION, Perl $], $^X" );
