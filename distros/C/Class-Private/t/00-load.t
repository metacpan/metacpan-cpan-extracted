#!perl -T

use Test::More tests => 2;
use Test::NoWarnings;

BEGIN {
	use_ok( 'Class::Private' );
}

diag( "Testing Class::Private $Class::Private::VERSION, Perl $], $^X" );
