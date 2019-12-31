#!perl

use utf8;
use Test::More tests => 9;
use Test::Exception;

BEGIN {
	use_ok('Date::Holidays::KZ');
}

isnt($Date::Holidays::KZ::HOLIDAYS_VALID_SINCE, undef, 'declared vars');
isnt($Date::Holidays::KZ::INACCURATE_TIMES_SINCE, undef, 'declared vars');
is($Date::Holidays::KZ::strict, 0, 'declared vars');

$Date::Holidays::KZ::strict=1;
is($Date::Holidays::KZ::strict, 1, 'change of declared vars');
$Date::Holidays::KZ::strict=0;

dies_ok { Date::Holidays::KZ::is_holiday( 1989, 1, 1 ) }, 'prehistoric time';
ok { Date::Holidays::KZ::is_holiday( 2017, 1, 1 ) }, 'valid';

ok { Date::Holidays::KZ::is_holiday( 5000, 1, 1 ) }, 'valid but weird';
dies_ok {
	$Date::Holidays::KZ::strict=1;
	Date::Holidays::KZ::is_holiday( 2030, 1, 1 )
}, 'no cover time';
