# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 56;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_days_remaining_in_month);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_days_remaining_in_month('Oct',27)};
ok(($@),      'THREE and ONLY THREE parameters must be given, (month, day_of_month, and year)');

eval {get_days_remaining_in_month('Jan',{},1599)};
ok(($@),      'Hash references are NOT allowed');

eval {get_days_remaining_in_month('Jan',17,{})};
ok(($@),      'Hash references are NOT allowed');

eval {get_days_remaining_in_month([],17,1599)};
ok(($@),      'Array references are NOT allowed');

eval {get_days_remaining_in_month('Jan',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Feb',30,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Mar',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Apr',31,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('May',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Jun',31,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Jul',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Aug',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Sep',31,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Oct',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Nov',31,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('Dec',32,2004)};
ok(($@),      'Number of days in month is exceeded');

eval {get_days_remaining_in_month('', 1, 2000)};
ok(($@),      'NULL value is NOT allowed for month.');

eval {get_days_remaining_in_month(0, 1, 2000)};
ok(($@),      'Month value is out of range.');

eval {get_days_remaining_in_month(6, 1, '')};
ok(($@),      'NULL value is NOT allowed for year.');

eval {get_days_remaining_in_month(6, 1, 507.66)};
ok(($@),      'Fractional values are NOT allowed for year.');

eval {get_days_remaining_in_month(6, '', 1866)};
ok(($@),      'NULL value is NOT allowed for day of month.');




# Check february in leap years
is(get_days_remaining_in_month('Feb',28,1800),             0,     'Feb,28,1800 is the last day of the month, zero days remain.');
eval {get_days_remaining_in_month('Feb',29,1800)};
ok(($@),      'Year 1800 is NOT a leap year');

is(get_days_remaining_in_month('Feb',29,2000),             0,     'Feb,29,2000 is the last day of the month, zero days remain.');
eval {get_days_remaining_in_month('Feb',30,2000)};
ok(($@),      'There are only 29 days in leap year 2000');

is(get_days_remaining_in_month('Feb',28,2100),             0,     'Feb,28,2100 is the last day of the month, zero days remain.');
eval {get_days_remaining_in_month('Feb',29,2100)};
ok(($@),      'Year 2100 is NOT a leap year');

is(get_days_remaining_in_month('Feb',28,1),                0,     'Feb,28,1 is the last day of the month, zero days remain.');
eval {get_days_remaining_in_month('Feb',29,1)};
ok(($@),      'Year 1 is NOT a leap year');





is(get_days_remaining_in_month(         01,    1,2004),             30,     'there are 30 days remaining in the month from date         01,    1,2004');
is(get_days_remaining_in_month(          2,    3,2004),             26,     'there are 26 days remaining in the month from date          2,    3,2004');
is(get_days_remaining_in_month(         03,    5,2004),             26,     'there are 26 days remaining in the month from date         03,    5,2004');
is(get_days_remaining_in_month(          4,    7,2004),             23,     'there are 23 days remaining in the month from date          4,    7,2004');
is(get_days_remaining_in_month(         05,   11,2004),             20,     'there are 20 days remaining in the month from date         05,   11,2004');
is(get_days_remaining_in_month(          6,   13,2004),             17,     'there are 17 days remaining in the month from date          6,   13,2004');
is(get_days_remaining_in_month(         07,   17,2004),             14,     'there are 14 days remaining in the month from date         07,   17,2004');
is(get_days_remaining_in_month(          8,   19,2004),             12,     'there are 12 days remaining in the month from date          8,   19,2004');
is(get_days_remaining_in_month(       '09',    1,2004),             29,     'there are 29 days remaining in the month from date         09,    1,2004');
is(get_days_remaining_in_month(         10,   29,2004),              2,     'there are  2 days remaining in the month from date         10,   29,2004');
is(get_days_remaining_in_month(         11,   12,2004),             18,     'there are 18 days remaining in the month from date         11,   12,2004');
is(get_days_remaining_in_month(         12,   14,2004),             17,     'there are 17 days remaining in the month from date         12,   14,2004');
is(get_days_remaining_in_month(         10,   25,2004),              6,     'there are  6 days remaining in the month from date         10,   25,2004');
is(get_days_remaining_in_month(          6,   30,1999),              0,     'there are  0 days remaining in the month from date          6,   30,1999');
is(get_days_remaining_in_month(          2,    1,2000),             28,     'there are 28 days remaining in the month from date          2,    1,2000');
is(get_days_remaining_in_month(          2,    1,1900),             27,     'there are 27 days remaining in the month from date          2,    1,1900');
is(get_days_remaining_in_month(         12,   30,1542),              1,     'there are  1 days remaining in the month from date         12,   30,1542');
is(get_days_remaining_in_month(         12,   31, -88),              0,     'there are  0 days remaining in the month from date         12,   31, -88');
is(get_days_remaining_in_month(         10,   15,   0),             16,     'there are 16 days remaining in the month from date         10,   15,   0');
is(get_days_remaining_in_month(      'Sep',    2,1401),             28,     'there are 28 days remaining in the month from date        Sep,    2,1401');
is(get_days_remaining_in_month( 'February',    7,1865),             21,     'there are 21 days remaining in the month from date   February,    7,1865');
