#!perl

use utf8;
use Test::More tests => 5;

BEGIN {
	use_ok( 'Date::Holidays::BY' );
}

is Date::Holidays::BY::is_holiday(2024,1,1), 'New Year';

$Date::Holidays::BY::lang='be';
is Date::Holidays::BY::is_holiday(2024,1,1), 'Новы год';

$Date::Holidays::BY::lang='ru';
is Date::Holidays::BY::is_holiday(2024,1,1), 'Новый год';

$Date::Holidays::BY::lang='be';
is Date::Holidays::BY::is_holiday(2013,1,2), 'Перанос працоўнага дня';

done_testing();
