use Test;
BEGIN { plan tests => 17 }

use Data::Type qw(:all +DB);

$Data::Type::debug = 1;

# VARCHAR

ok dvalid( 'one two three', $_ ) for ( DB::VARCHAR( 20 ) );

ok dvalid( ' ' x 20 , DB::VARCHAR( 20 ) );

# DB types

ok dvalid( '2001-01-01', DB::DATE( 'DB' ) );

ok dvalid( '9999-12-31 23:59:59', DB::DATETIME );

ok dvalid( '1970-01-01 00:00:00', DB::TIMESTAMP );

ok dvalid( '-838:59:59', DB::TIME );

# year: 1901 to 2155, 0000 in the 4-digit

ok dvalid( '1901', DB::YEAR );

ok dvalid( '0000', DB::YEAR );

ok dvalid( '2155', DB::YEAR );

# year: 1970-2069 if you use the 2-digit format (70-69);

ok dvalid( '70', DB::YEAR(2) );

ok dvalid( '69', DB::YEAR(2) );

ok dvalid( '0' x 20, DB::TINYTEXT );

ok dvalid( '0' x 20, DB::MEDIUMTEXT );

ok dvalid( '0' x 20, DB::LONGTEXT );

ok dvalid( '0' x 20, DB::TEXT );

ok dvalid( 'one', DB::ENUM( qw(one two three) ) );

ok dvalid( [qw(two six)], DB::SET( qw(one two three four five six) ) );

