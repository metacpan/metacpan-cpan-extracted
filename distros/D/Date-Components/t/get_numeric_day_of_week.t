# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 82;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_numeric_day_of_week);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_numeric_day_of_week(-1, 'Jan', 2003)};
ok(($@),      'Invalid day of week.  It must be 1-7 where 1 represents Monday');

eval {get_numeric_day_of_week(3, 'Feb ', 2003)};
ok(($@),      'Leading and trailing spaces in parameters are NOT allowed');

eval {get_numeric_day_of_week('Marc', 3, 2003)};
ok(($@),      'Only THREE letter month abbreviations are allowed.');

eval {get_numeric_day_of_week('Apr', 3, 2003.7)};
ok(($@),      'Fractional years are NOT allowed.');

eval {get_numeric_day_of_week(2009, 3, 'May')};
ok(($@),      'Parameters are out of order');

eval {get_numeric_day_of_week('July', 7)};
ok(($@),      'Missing year parameter');

eval {get_numeric_day_of_week('Jan', 32, 2008)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Feb', 29, 2001)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Jan', 32,  1885)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Feb', 30,  1924)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Mar', 32,  1652)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Apr', 31,   602)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('May', 32,    -3)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Jun', 31,     0)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Jul', 32, 50032)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Aug', 32,   107)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Sep', 31, -3699)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Oct', 32,  1999)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Nov', 31,  2400)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Dec', 32,  2401)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week('Feb', 29,  1925)};
ok(($@),      'Invalid day of month');

eval {get_numeric_day_of_week({}, 28,  1925)};
ok(($@),      'SCALAR value expected for month');

eval {get_numeric_day_of_week('Feb', {},  1925)};
ok(($@),      'SCALAR value expected for day of month');

eval {get_numeric_day_of_week('Feb', 28,  [])};
ok(($@),      'SCALAR value expected for year');

eval {get_numeric_day_of_week('', 28,  1925)};
ok(($@),      'NULL value NOT allowed for month');

eval {get_numeric_day_of_week('Feb', '',  1925)};
ok(($@),      'NULL value NOT allowed for day of month');

eval {get_numeric_day_of_week('Feb', 28,  '')};
ok(($@),      'NULL value NOT allowed for year');

eval {get_numeric_day_of_week({})};
ok(($@),      'Only SCALAR values are allowed.');

eval {get_numeric_day_of_week([6,3,2007])};
ok(($@),      'Only SCALAR values are allowed.');

eval {get_numeric_day_of_week()};
ok(($@),      'Empty parameter list is NOT allowed.');

eval {get_numeric_day_of_week('')};
ok(($@),      'Empty first parameter is NOT allowed.');

eval {get_numeric_day_of_week('February  29, 1995')};
ok(($@),      'Invalid date.');





# date components input
is(get_numeric_day_of_week(    1,       31,   665),        2,      'date    1       31   665 is a Tuesday  ');
is(get_numeric_day_of_week(    2,       29,  1492),        1,      'date    2       29  1492 is a Monday   ');
is(get_numeric_day_of_week(    3,       31,   -75),        2,      'date    3       31   -75 is a Tuesday  ');
is(get_numeric_day_of_week(    4,       30,  2211),        2,      'date    4       30  2211 is a Tuesday  ');
is(get_numeric_day_of_week(    5,       31,    -3),        6,      'date    5       31    -3 is a Saturday ');
is(get_numeric_day_of_week(    6,       30,     0),        5,      'date    6       30     0 is a Friday   ');
is(get_numeric_day_of_week(    7,       31,     2),        3,      'date    7       31     2 is a Wednesday');
is(get_numeric_day_of_week(    8,       31,  1212),        5,      'date    8       31  1212 is a Friday   ');
is(get_numeric_day_of_week(    9,       30,  1553),        3,      'date    9       30  1553 is a Wednesday');
is(get_numeric_day_of_week(   10,       31,  1992),        6,      'date   10       31  1992 is a Saturday ');
is(get_numeric_day_of_week(   11,       30,  2312),        6,      'date   11       30  2312 is a Saturday ');
is(get_numeric_day_of_week(   12,       31,  1795),        4,      'date   12       31  1795 is a Thursday ');
is(get_numeric_day_of_week(    2,       29, -2000),        2,      'date    2       29 -2000 is a Tuesday  ');
is(get_numeric_day_of_week('Jan',       31,   665),        2,      'date  Jan       31   665 is a Tuesday  ');
is(get_numeric_day_of_week('Feb',       29,  1492),        1,      'date  Feb       29  1492 is a Monday   ');
is(get_numeric_day_of_week('Mar',       31,   -75),        2,      'date  Mar       31   -75 is a Tuesday  ');
is(get_numeric_day_of_week('Apr',       30,  2211),        2,      'date  Apr       30  2211 is a Tuesday  ');
is(get_numeric_day_of_week('May',       31,    -3),        6,      'date  May       31    -3 is a Saturday ');
is(get_numeric_day_of_week('Jun',       30,     0),        5,      'date  Jun       30     0 is a Friday   ');
is(get_numeric_day_of_week('Jul',       31,     2),        3,      'date  Jul       31     2 is a Wednesday');
is(get_numeric_day_of_week('Aug',       31,  1212),        5,      'date  Aug       31  1212 is a Friday   ');
is(get_numeric_day_of_week('Sep',       30,  1553),        3,      'date  Sep       30  1553 is a Wednesday');
is(get_numeric_day_of_week('Oct',       31,  1992),        6,      'date  Oct       31  1992 is a Saturday ');
is(get_numeric_day_of_week('Nov',       30,  2312),        6,      'date  Nov       30  2312 is a Saturday ');
is(get_numeric_day_of_week('Dec',       31,  1795),        4,      'date  Dec       31  1795 is a Thursday ');
is(get_numeric_day_of_week('Feb',       29, -2000),        2,      'date  Feb       29 -2000 is a Tuesday  ');
is(get_numeric_day_of_week('January',   31,   665),        2,      'date  January   31   665 is a Tuesday  ');
is(get_numeric_day_of_week('February',  29,  1492),        1,      'date  February  29  1492 is a Monday   ');
is(get_numeric_day_of_week('March',     31,   -75),        2,      'date  March     31   -75 is a Tuesday  ');
is(get_numeric_day_of_week('April',     30,  2211),        2,      'date  April     30  2211 is a Tuesday  ');
is(get_numeric_day_of_week('May',       31,    -3),        6,      'date  May       31    -3 is a Saturday ');
is(get_numeric_day_of_week('June',      30,     0),        5,      'date  June      30     0 is a Friday   ');
is(get_numeric_day_of_week('July',      31,     2),        3,      'date  July      31     2 is a Wednesday');
is(get_numeric_day_of_week('August',    31,  1212),        5,      'date  August    31  1212 is a Friday   ');
is(get_numeric_day_of_week('September', 30,  1553),        3,      'date  September 30  1553 is a Wednesday');
is(get_numeric_day_of_week('October',   31,  1992),        6,      'date  October   31  1992 is a Saturday ');
is(get_numeric_day_of_week('November',  30,  2312),        6,      'date  November  30  2312 is a Saturday ');
is(get_numeric_day_of_week('December',  31,  1795),        4,      'date  December  31  1795 is a Thursday ');
is(get_numeric_day_of_week('February',  29, -2000),        2,      'date  February  29 -2000 is a Tuesday  ');
is(get_numeric_day_of_week('Jun',       11,  1995),        7,      'date  Jun       11  1995 is a Sunday   ');
is(get_numeric_day_of_week('January',    1,  2000),        6,      'date  January    1  2000 is a Saturday ');

# date string input
is(get_numeric_day_of_week('June  6, 2001'),               3,      'date  June       6  2001 is a Wednesday');
is(get_numeric_day_of_week('Sep  23, 1541'),               2,      'date  Sep       23  1541 is a Tuesday  ');
is(get_numeric_day_of_week('February  28, 1995'),          2,      'date  February  28  1995 is a Tuesday  ');
