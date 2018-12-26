#!perl -T

use utf8;
use Test::More tests => 8;
use Test::Exception;

BEGIN {
	use_ok('Date::Holidays::BY');
}

isnt($Date::Holidays::BY::HOLIDAYS_VALID_SINCE, '', 'declared vars');
isnt($Date::Holidays::BY::INACCURATE_TIMES_SINCE, '', 'declared vars');
isnt($Date::Holidays::BY::strict, '', 'declared vars');

dies_ok { Date::Holidays::BY::is_holiday( 1989, 1, 1 ) }, 'prehistoric time';
ok { Date::Holidays::BY::is_holiday( 2017, 1, 1 ) }, 'valid';

ok { Date::Holidays::BY::is_holiday( 5000, 1, 1 ) }, 'valid but weird';
dies_ok {
	$Date::Holidays::BY::strict=1;
	Date::Holidays::BY::is_holiday( 2030, 1, 1 )
}, 'no cover time';
