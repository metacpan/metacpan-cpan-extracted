#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Mixin' );
}

diag( "Testing Class::Mixin $Class::Mixin::VERSION, Perl $], $^X" );
