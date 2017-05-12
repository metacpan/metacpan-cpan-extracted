use Test;
BEGIN { plan tests => 1 }

use Data::Type qw(:all);
use Error qw(:try);

	try
	{
			# VARCHAR

		verify( 'one two three', Type::Proxy::VARCHAR( 20 ), Facet::Proxy::match( qw/one/ ) );

		verify( ' ' x 20 , VARCHAR( 20 ) );

			# BOOL

		verify( '1' , BOOL( 'true' ) );

			# MYSQL types

		verify( '2001-01-01', DATE( 'MYSQL' ) );

		verify( '9999-12-31 23:59:59', DATETIME );

		verify( '1970-01-01 00:00:00', TIMESTAMP );

		verify( '-838:59:59', TIME );

			# year: 1901 to 2155, 0000 in the 4-digit

		verify( '1901', YEAR );

		verify( '0000', YEAR );

		verify( '2155', YEAR );

			# year: 1970-2069 if you use the 2-digit format (70-69);

		verify( '70', YEAR(2) );

		verify( '69', YEAR(2) );

		verify( '0' x 20, TINYTEXT );

		verify( '0' x 20, MEDIUMTEXT );

		verify( '0' x 20, LONGTEXT );

		verify( '0' x 20, TEXT );

		verify( 'one', ENUM( qw(one two three) ) );

		verify( [qw(two six)], SET( qw(one two three four five six) ) );
		
		ok(1);
	}
	catch Type::Exception with
	{
		ok(0);
	};

