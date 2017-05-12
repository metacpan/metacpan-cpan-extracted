#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Root' );
}

diag( "Testing Class::Root $Class::Root::VERSION, Perl $], $^X" );
