#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Class::TLB' );
}

diag( "Testing Class::TLB $Class::TLB::VERSION, Perl $], $^X" );
