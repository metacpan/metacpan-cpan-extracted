#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::FromSub::Hash' );
}

diag( "Testing Catalyst::Authentication::Store::FromSub::Hash $Catalyst::Authentication::Store::FromSub::Hash::VERSION, Perl $], $^X" );
