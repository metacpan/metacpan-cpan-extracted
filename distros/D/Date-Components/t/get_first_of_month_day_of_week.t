# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 39;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_first_of_month_day_of_week);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_first_of_month_day_of_week('Dec')};
ok(($@),      'Missing year parameter');

eval {get_first_of_month_day_of_week('Nov',3,1991)};
ok(($@),      'TWO and ONLY TWO parameters must be given (month, year');

eval {get_first_of_month_day_of_week('Jul',{})};
ok(($@),      'Hash reference is NOT allowed');

eval {get_first_of_month_day_of_week([],1996)};
ok(($@),      'Array reference is NOT allowed');

eval {get_first_of_month_day_of_week('M',1996)};
ok(($@),      'Single letter month abreviations are NOT allowed');

eval {get_first_of_month_day_of_week('June ',1996)};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {get_first_of_month_day_of_week(' Feb',1996)};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {get_first_of_month_day_of_week('Aug',16.7)};
ok(($@),      'Fractional years are NOT allowed.');

eval {get_first_of_month_day_of_week(1996, 'Dec')};
ok(($@),      'Parameters are out of order.');

eval {get_first_of_month_day_of_week('', 1996)};
ok(($@),      'NULL value for month is NOT allowed.');

eval {get_first_of_month_day_of_week('Apr', '')};
ok(($@),      'NULL value for year is NOT allowed.');




is(get_first_of_month_day_of_week('Feb',1700),            1,     'day of week for first of Feb in year 1700 is Monday   ');
is(get_first_of_month_day_of_week('Feb',1600),            2,     'day of week for first of Feb in year 1600 is Tuesday  ');
is(get_first_of_month_day_of_week('Feb',2300),            4,     'day of week for first of Feb in year 2300 is Thursday ');
is(get_first_of_month_day_of_week('Feb',  -1),            1,     'day of week for first of Feb in year   -1 is Monday   ');
is(get_first_of_month_day_of_week('Feb',1999),            1,     'day of week for first of Feb in year 1999 is Monday   ');
is(get_first_of_month_day_of_week('Jan',1996),            1,     'day of week for first of Jan in year 1996 is Monday   ');
is(get_first_of_month_day_of_week('Feb',1996),            4,     'day of week for first of Feb in year 1996 is Thursday ');
is(get_first_of_month_day_of_week('Mar',1996),            5,     'day of week for first of Mar in year 1996 is Friday   ');
is(get_first_of_month_day_of_week('Apr',1996),            1,     'day of week for first of Apr in year 1996 is Monday   ');
is(get_first_of_month_day_of_week('May',1996),            3,     'day of week for first of May in year 1996 is Wednesday');
is(get_first_of_month_day_of_week('Jun',1996),            6,     'day of week for first of Jun in year 1996 is Saturday ');
is(get_first_of_month_day_of_week('Jul',1996),            1,     'day of week for first of Jul in year 1996 is Monday   ');
is(get_first_of_month_day_of_week('Aug',1996),            4,     'day of week for first of Aug in year 1996 is Thursday ');
is(get_first_of_month_day_of_week('Sep',1996),            7,     'day of week for first of Sep in year 1996 is Sunday   ');
is(get_first_of_month_day_of_week('Oct',1996),            2,     'day of week for first of Oct in year 1996 is Tuesday  ');
is(get_first_of_month_day_of_week('Nov',1996),            5,     'day of week for first of Nov in year 1996 is Friday   ');
is(get_first_of_month_day_of_week('Dec',1996),            7,     'day of week for first of Dec in year 1996 is Sunday   ');
is(get_first_of_month_day_of_week('1',  1011),            2,     'day of week for first of Jan in year 1011 is Tuesday  ');
is(get_first_of_month_day_of_week('2',   -57),            1,     'day of week for first of Feb in year  -57 is Monday   ');

is(get_first_of_month_day_of_week( 1,   0),            6,     'day of week for first of Jan in year  0 is Saturday  ');
is(get_first_of_month_day_of_week('8',  0),            2,     'day of week for first of Aug in year  0 is Tuesday   ');
is(get_first_of_month_day_of_week(12,   0),            5,     'day of week for first of Dec in year  0 is Friday    ');
