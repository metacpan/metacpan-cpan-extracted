#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::AnyBoolean' );
}

diag( "Testing Data::AnyBoolean $Data::AnyBoolean::VERSION, Perl $], $^X" );
