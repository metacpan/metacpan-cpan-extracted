#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Properties' );
}

diag( "Testing Data::Properties $Data::Properties::VERSION, Perl $], $^X" );
