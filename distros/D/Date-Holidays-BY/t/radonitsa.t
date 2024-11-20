#!perl

use utf8;
use Test::More tests => 6;

BEGIN {
	use_ok( 'Date::Holidays::BY' );
}

is Date::Holidays::BY::_radonitsa_mmdd(2021)->[0], '0511';
isnt Date::Holidays::BY::is_holiday(2021,5,11), undef;
is Date::Holidays::BY::_radonitsa_mmdd(2028)->[0], '0425';
is Date::Holidays::BY::_radonitsa_mmdd(2030)->[0], '0507';
is Date::Holidays::BY::is_holiday(2025,4,29), 'Radunica';

done_testing();
