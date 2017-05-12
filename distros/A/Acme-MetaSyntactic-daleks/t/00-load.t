#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::MetaSyntactic::daleks' );
}

diag( "Testing Acme::MetaSyntactic::daleks $Acme::MetaSyntactic::daleks::VERSION, Perl $], $^X" );
