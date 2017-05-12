#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::TT::Filters::LazyLoader' );
}

diag( "Testing Catalyst::View::TT::Filters::LazyLoader $Catalyst::View::TT::Filters::LazyLoader::VERSION, Perl $], $^X" );
