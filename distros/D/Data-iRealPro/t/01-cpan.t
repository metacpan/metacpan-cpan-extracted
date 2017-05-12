#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'Font::TTF' );
	use_ok( 'PDF::API2' );
	use_ok( 'Data::Struct' );
	use_ok( 'Text::CSV_XS' );
}

diag( "Good. We can generate PDF images." );
