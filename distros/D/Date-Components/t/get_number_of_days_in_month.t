# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 52;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_number_of_days_in_month);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");





# Check for faulty input
eval {get_number_of_days_in_month('1942AD')};
ok(($@),      'Units with year are NOT allowed');

eval {get_number_of_days_in_month('12/31/2007',   57)};
ok(($@),      'Invalid parameters');

eval {get_number_of_days_in_month()};
ok(($@),      'TWO and ONLY TWO can be given.  The month followed by the year');

eval {get_number_of_days_in_month('')};
ok(($@),      'Null input NOT allowed');

eval {get_number_of_days_in_month([])};
ok(($@),      'Array references are NOT allowed');

eval {get_number_of_days_in_month({})};
ok(($@),      'Hash references are NOT allowed');

eval {get_number_of_days_in_month('Dec')};
ok(($@),      'The second parameter, year number, is missing');

eval {get_number_of_days_in_month('Nov',3,1991)};
ok(($@),      'Too many parameters are given.  TWO and ONLY TWO can be given.  The month followed by the year');

eval {get_number_of_days_in_month('Jul',{})};
ok(($@),      'Hash references are NOT allowed');

eval {get_number_of_days_in_month([],1996)};
ok(($@),      'Array references are NOT allowed');

eval {get_number_of_days_in_month('M',1996)};
ok(($@),      'Incorrect abbreviation for month');

eval {get_number_of_days_in_month('June ',1996)};
ok(($@),      'No leading or trailing spaces are allowed');

eval {get_number_of_days_in_month(' Feb',1996)};
ok(($@),      'No leading or trailing spaces are allowed');

eval {get_number_of_days_in_month('  September ',1996)};
ok(($@),      'No leading or trailing spaces are allowed');

eval {get_number_of_days_in_month('Aug',16.7)};
ok(($@),      'Fractional years are NOT allowed');

eval {get_number_of_days_in_month('Augu',1966)};
ok(($@),      'Only Full or three letter abbreviations are allowed for month names');

eval {get_number_of_days_in_month(-1,1966)};
ok(($@),      'Month is out of range');

eval {get_number_of_days_in_month(0,1966)};
ok(($@),      'Month is out of range');

eval {get_number_of_days_in_month(13,1966)};
ok(($@),      'Month is out of range');

eval {get_number_of_days_in_month(6.3,1966)};
ok(($@),      'Fractional months are NOT allowed');

eval {get_number_of_days_in_month('',1966)};
ok(($@),      'Null month is NOT allowed.');

eval {get_number_of_days_in_month('October','')};
ok(($@),      'Null year is NOT allowed.');

eval {get_number_of_days_in_month('July',[])};
ok(($@),      'Year must be a SCALAR number.');




is(get_number_of_days_in_month('Feb',1700),    28,     'there are 28 days in month Feb of year 1700');
is(get_number_of_days_in_month('Feb',1600),    29,     'there are 29 days in month Feb of year 1600');
is(get_number_of_days_in_month('Feb',2300),    28,     'there are 28 days in month Feb of year 2300');
is(get_number_of_days_in_month('Feb',  -1),    28,     'there are 28 days in month Feb of year   -1');
is(get_number_of_days_in_month('Feb',1999),    28,     'there are 28 days in month Feb of year 1999');
is(get_number_of_days_in_month('Jan',1996),    31,     'there are 31 days in month Jan of year 1996');
is(get_number_of_days_in_month('Feb',1996),    29,     'there are 29 days in month Feb of year 1996');
is(get_number_of_days_in_month('Mar',1996),    31,     'there are 31 days in month Mar of year 1996');
is(get_number_of_days_in_month('Apr',1996),    30,     'there are 30 days in month Apr of year 1996');
is(get_number_of_days_in_month('May',1996),    31,     'there are 31 days in month May of year 1996');
is(get_number_of_days_in_month('Jun',1996),    30,     'there are 30 days in month Jun of year 1996');
is(get_number_of_days_in_month('Jul',1996),    31,     'there are 31 days in month Jul of year 1996');
is(get_number_of_days_in_month('Aug',1996),    31,     'there are 31 days in month Aug of year 1996');
is(get_number_of_days_in_month('Sep',1996),    30,     'there are 30 days in month Sep of year 1996');
is(get_number_of_days_in_month('Oct',1996),    31,     'there are 31 days in month Oct of year 1996');
is(get_number_of_days_in_month('Nov',1996),    30,     'there are 30 days in month Nov of year 1996');
is(get_number_of_days_in_month('Dec',1996),    31,     'there are 31 days in month Dec of year 1996');
is(get_number_of_days_in_month('1',  1011),    31,     'there are 31 days in month   1 of year 1011');
is(get_number_of_days_in_month('2',   -57),    28,     'there are 28 days in month   2 of year  -57');

is(get_number_of_days_in_month( 1,    0),      31,     'there are 31 days in month   1 of year 0');
is(get_number_of_days_in_month('Feb', 0),      29,     'there are 29 days in month   2 of year 0');
is(get_number_of_days_in_month('8',   0),      31,     'there are 31 days in month   8 of year 0');
is(get_number_of_days_in_month(12,    0),      31,     'there are 31 days in month  12 of year 0');
