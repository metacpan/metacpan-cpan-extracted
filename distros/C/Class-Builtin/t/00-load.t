#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Builtin' );
}

diag( "Testing Class::Builtin $Class::Builtin::VERSION, Perl $], $^X" );
