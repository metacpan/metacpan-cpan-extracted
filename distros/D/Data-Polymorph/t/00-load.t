#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Polymorph' );
}

diag( "Testing Data::Polymorph $Data::Polymorph::VERSION, Perl $], $^X" );
