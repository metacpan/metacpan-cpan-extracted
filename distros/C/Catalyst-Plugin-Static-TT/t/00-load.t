#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Static::TT' );
}

diag( "Testing Catalyst::Plugin::Static::TT $Catalyst::Plugin::Static::TT::VERSION, Perl $], $^X" );
