#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Meta::Declare' );
}

diag( "Testing Class::Meta::Declare $Class::Meta::Declare::VERSION, Perl $], $^X" );
