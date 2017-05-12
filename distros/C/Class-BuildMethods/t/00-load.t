#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::BuildMethods' );
}

diag( "Testing Class::BuildMethods $Class::BuildMethods::VERSION, Perl $], $^X" );
