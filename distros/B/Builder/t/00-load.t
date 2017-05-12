#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Builder' );
	use_ok( 'Builder::Utils' );
	use_ok( 'Builder::XML' );
	use_ok( 'Builder::XML::Utils' );
}

diag( "Testing Builder $Builder::VERSION, Perl $], $^X" );
