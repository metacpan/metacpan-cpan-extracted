#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::PDF::Reuse' );
}

diag( "Testing Catalyst::View::PDF::Reuse $Catalyst::View::PDF::Reuse::VERSION, Perl $], $^X" );
