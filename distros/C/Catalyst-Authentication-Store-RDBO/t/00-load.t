#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::RDBO' );
}

diag( "Testing Catalyst::Authentication::Store::RDBO $Catalyst::Authentication::Store::RDBO::VERSION, Perl $], $^X" );
