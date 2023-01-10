#!perl

use utf8;
use Test::More tests => 12;
use Test::Exception;

BEGIN {
	use_ok('Date::Holidays::BY');
}

isnt($Date::Holidays::BY::HOLIDAYS_VALID_SINCE, undef, 'declared vars');
isnt($Date::Holidays::BY::INACCURATE_TIMES_SINCE, undef, 'declared vars');
is($Date::Holidays::BY::strict, 0, 'declared vars');

$Date::Holidays::BY::strict=1;
is($Date::Holidays::BY::strict, 1, 'change of declared vars');
$Date::Holidays::BY::strict=0;

dies_ok { Date::Holidays::BY::is_holiday( ) }, 'bad param';
dies_ok { Date::Holidays::BY::is_holiday( 2020 ) }, 'bad param';
dies_ok { Date::Holidays::BY::is_holiday( 1989, 1, 1 ) }, 'prehistoric time';
ok { Date::Holidays::BY::is_holiday( 2017, 1, 1 ) }, 'valid';
dies_ok { Date::Holidays::BY::is_holiday( 1349, 1, 1 ) }, 'before Gregorian calendar (Date::Easter)';

ok { Date::Holidays::BY::is_holiday( 5000, 1, 1 ) }, 'valid but weird';
dies_ok {
	$Date::Holidays::BY::strict=1;
	Date::Holidays::BY::is_holiday( 2030, 1, 1 )
}, 'no cover time';
