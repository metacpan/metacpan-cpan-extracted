#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::Axelerator' );
}

diag( "Testing Class::Axelerator $Class::Axelerator::VERSION, Perl $], $^X" );
