# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 46;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_month_from_string);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_month_from_string(-1, 'Jan', 2003)};
ok(($@),      'Invalid day of week.  It must be 1-7 where 1 represents Monday');

eval {get_month_from_string(3, 'Feb ', 2003)};
ok(($@),      'Leading and trailing spaces in parameters are NOT allowed');

eval {get_month_from_string('Marc', 3, 2003)};
ok(($@),      'Only THREE letter month abbreviations are allowed.');

eval {get_month_from_string('Apr', 3, 2003.7)};
ok(($@),      'Fractional years are NOT allowed.');

eval {get_month_from_string(2009, 3, 'May')};
ok(($@),      'Parameters are out of order');

eval {get_month_from_string('July', 7)};
ok(($@),      'Missing year parameter');

eval {get_month_from_string('Jan', 32, 2008)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Feb', 29, 2001)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Jan', 32,  1885)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Feb', 30,  1924)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Mar', 32,  1652)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Apr', 31,   602)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('May', 32,    -3)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Jun', 31,     0)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Jul', 32, 50032)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Aug', 32,   107)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Sep', 31, -3699)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Oct', 32,  1999)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Nov', 31,  2400)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Dec', 32,  2401)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string('Feb', 29,  1925)};
ok(($@),      'Invalid day of month');

eval {get_month_from_string({}, 28,  1925)};
ok(($@),      'SCALAR value expected for month');

eval {get_month_from_string('Feb', {},  1925)};
ok(($@),      'SCALAR value expected for day of month');

eval {get_month_from_string('Feb', 28,  [])};
ok(($@),      'SCALAR value expected for year');

eval {get_month_from_string('', 28,  1925)};
ok(($@),      'NULL value NOT allowed for month');

eval {get_month_from_string('Feb', '',  1925)};
ok(($@),      'NULL value NOT allowed for day of month');

eval {get_month_from_string('Feb', 28,  '')};
ok(($@),      'NULL value NOT allowed for year');

eval {get_month_from_string({})};
ok(($@),      'Only SCALAR values are allowed.');

eval {get_month_from_string([6,3,2007])};
ok(($@),      'Only SCALAR values are allowed.');

eval {get_month_from_string()};
ok(($@),      'Empty parameter list is NOT allowed.');

eval {get_month_from_string('')};
ok(($@),      'Empty first parameter is NOT allowed.');

eval {get_month_from_string('February  29, 1995')};
ok(($@),      'Invalid date.');




is(get_month_from_string('12/31/1795'),                 12,   'date  12/31/1795               is month 12');
is(get_month_from_string('Sat Oct 22 08:50:51 1577'),   10,   'date  Sat Oct 22 08:50:51 1577 is month 10');
is(get_month_from_string('June  6, 2001'),               6,   'date  June  6, 2001            is month  6');
is(get_month_from_string('Sep  23, 1541'),               9,   'date  Sep  23, 1541            is month  9');
is(get_month_from_string('February  28, 1995'),          2,   'date  February  28, 1995       is month  2');
is(get_month_from_string('-1755-08-15'),                 8,   'date  -1755-08-15              is month  8');
is(get_month_from_string('19 May, 227'),                 5,   'date  19 May, 227              is month  5');
is(get_month_from_string('04/27/0'),                     4,   'date  04/27/0                  is month  4');
