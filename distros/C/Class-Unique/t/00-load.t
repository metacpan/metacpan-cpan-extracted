#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Unique' );
}

diag( "Testing Class::Unique $Class::Unique::VERSION, Perl $], $^X" );
