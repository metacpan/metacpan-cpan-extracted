#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Helper::View::TTSimple' );
}

diag( "Testing Catalyst::Helper::View::TTSimple $Catalyst::Helper::View::TTSimple::VERSION, Perl $], $^X" );
