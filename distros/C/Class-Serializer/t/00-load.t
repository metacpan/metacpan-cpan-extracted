#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Serializer' );
}

diag( "Testing Class::Serializer $Class::Serializer::VERSION, Perl $], $^X" );
