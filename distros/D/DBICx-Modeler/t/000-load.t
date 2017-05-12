#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBICx::Modeler' );
}

diag( "Testing DBICx::Modeler $DBICx::Modeler::VERSION, Perl $], $^X" );
