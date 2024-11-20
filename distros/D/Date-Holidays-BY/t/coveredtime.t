#!perl

use utf8;
use Test::More;
use Test::Exception;

BEGIN {
	use_ok('Date::Holidays::BY');
}

$testing=15;

isnt($Date::Holidays::BY::HOLIDAYS_VALID_SINCE, undef, 'declared vars'); #deprecated
isnt($Date::Holidays::BY::ref->{'HOLIDAYS_VALID_SINCE'}, undef, 'declared vars');
isnt($Date::Holidays::BY::ref->{'INACCURATE_TIMES_BEFORE'}, undef, 'declared vars');
isnt($Date::Holidays::BY::INACCURATE_TIMES_SINCE, undef, 'declared vars'); #deprecated
isnt($Date::Holidays::BY::ref->{'INACCURATE_TIMES_SINCE'}, undef, 'declared vars');
is($Date::Holidays::BY::strict, 0, 'declared vars');

$Date::Holidays::BY::strict=1;
is($Date::Holidays::BY::strict, 1, 'change of declared vars');
$Date::Holidays::BY::strict=0;

dies_ok { Date::Holidays::BY::is_holiday( ) }, 'bad param';
dies_ok { Date::Holidays::BY::is_holiday( 2020 ) }, 'bad param';
dies_ok { Date::Holidays::BY::is_holiday( 1989, 1, 1 ) }, 'prehistoric time';
ok { Date::Holidays::BY::is_holiday( 2017, 1, 1 ) }, 'valid';
dies_ok { Date::Holidays::BY::is_holiday( 1349, 1, 1 ) }, 'before Gregorian calendar (Date::Easter)';

dies_ok {
	$Date::Holidays::BY::strict=0;
	Date::Holidays::BY::is_holiday( 1990, 1, 1 )
}, 'strict=0 before HOLIDAYS_VALID_SINCE';

dies_ok {
	$Date::Holidays::BY::strict=1;
	Date::Holidays::BY::is_holiday( 1993, 1, 1 )
}, 'strict=1 and outside INACCURATE_TIMES_BEFORE - INACCURATE_TIMES_SINCE';

if ("$]" < 5.012 && (eval{require Config; $Config::Config{ivsize}} < 8)) { # x86 with perl < 5.12 (i386-freebsd)
dies_ok { Date::Holidays::BY::is_holiday( 5000, 1, 1 ) }, 'grave';
$testing++;
}

done_testing($testing);
