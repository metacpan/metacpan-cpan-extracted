#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Data::Validate::XSD' );
}

diag( "Testing Data::Validate::XSD $Data::Validate::XSD::VERSION, Perl $], $^X" );
