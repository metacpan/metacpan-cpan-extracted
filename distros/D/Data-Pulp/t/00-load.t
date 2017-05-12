#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Pulp' );
}

diag( "Testing Data::Pulp $Data::Pulp::VERSION, Perl $], $^X" );
