#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Dumper::Names' );
}

diag( "Testing Data::Dumper::Names $Data::Dumper::Names::VERSION, Perl $], $^X" );
