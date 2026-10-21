#!perl

use utf8;
use Test::More;

BEGIN {
	use_ok('Date::Holidays::BY');
}

$testing=13;

isnt($Date::Holidays::BY::ref->{'HOLIDAYS_VALID_SINCE'}, undef, 'declared vars');
isnt($Date::Holidays::BY::ref->{'INACCURATE_TIMES_BEFORE'}, undef, 'declared vars');
isnt($Date::Holidays::BY::ref->{'INACCURATE_TIMES_SINCE'}, undef, 'declared vars');
is($Date::Holidays::BY::strict, 0, 'declared vars');

$Date::Holidays::BY::strict=1;
is($Date::Holidays::BY::strict, 1, 'change of declared vars');
$Date::Holidays::BY::strict=0;

ok !eval { Date::Holidays::BY::is_holiday( ); 1 }, 'bad param';
ok !eval { Date::Holidays::BY::is_holiday( 2020 ); 1 }, 'bad param';
ok !eval { Date::Holidays::BY::is_holiday( 1989, 1, 1 ); 1 }, 'prehistoric time';
ok Date::Holidays::BY::is_holiday( 2017, 1, 1 ), 'valid';
ok !eval { Date::Holidays::BY::is_holiday( 1349, 1, 1 ); 1 }, 'before Gregorian calendar';

ok !eval {
	$Date::Holidays::BY::strict=0;
	Date::Holidays::BY::is_holiday( 1990, 1, 1 );
	1
}, 'strict=0 before HOLIDAYS_VALID_SINCE';

ok !eval {
	$Date::Holidays::BY::strict=1;
	Date::Holidays::BY::is_holiday( 2100, 1, 1 );
	1
}, 'strict=1 and after INACCURATE_TIMES_SINCE';

done_testing($testing);
