#!perl

use utf8;
use Test::More tests => 5;

BEGIN {
	use_ok( 'Date::Holidays::BY' );
}

is Date::Holidays::BY::_radonitsa_mmdd(2021), '0511';
isnt Date::Holidays::BY::is_holiday(2021,5,11), undef;
is Date::Holidays::BY::_radonitsa_mmdd(2028), '0425';
is Date::Holidays::BY::_radonitsa_mmdd(2030), '0507';

done_testing();
