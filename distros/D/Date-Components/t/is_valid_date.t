# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 65;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_date);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
is(is_valid_date   ('Jan,  15, 2005, Sat'),  '', 'Day of week is out of range.');
is(is_valid_date   ('0/14/1988'),            '', 'Month is out of range.');
is(is_valid_date   ('13/14/1988'),           '', 'Month is out of range.');
is(is_valid_date   ('7/0/1988'),             '', 'Day of month is out of range.');
is(is_valid_date   ('4/31/1988'),            '', 'Day of month is out of range.');
is(is_valid_date   ('8/13/1988.9'),          '', 'Fractional year is NOT allowed.');
is(is_valid_date   (''),                     '', 'Null parameter is NOT allowed.');
is(is_valid_date   ({}),                     '', 'ONLY SCALAR parameters are allowed.');
is(is_valid_date   (0,  7, 47),              '', 'Month is out of range.');
is(is_valid_date   (13, 7, 47),              '', 'Month is out of range.');

is(is_valid_date   (6, '0', 47),              '', 'Day of month is out of range.');
is(is_valid_date   (6, 32, 47),               '', 'Day of month is out of range.');




  is(is_valid_date   (),                         '', 'Incorrect number of parameters');
  is(is_valid_date   (2,  15),                   '', 'Incorrect number of parameters');
  is(is_valid_date   (2,  15, 2002, 5, 'dd'),    '', 'Incorrect number of parameters');
  is(is_valid_date   (0,  15, 2005, 'Sat'),      '', 'Month is out of range');
  is(is_valid_date   ('Jan',  15, 2005, '0'),    '', 'Four SEPARATE input parameters are required');
  is(is_valid_date   ('Jan',  15, 2005,   8),    '', 'Day of week is out of range.');
  is(is_valid_date   ('Jan',  15, 2005, '0'),    '', 'Day of week is out of range.');
  is(is_valid_date   ('Jan',  15, 2005, 3),      '', 'Day of week is out of range.');
  is(is_valid_date   ('Jan',  15, 2005, 4),      '', 'Day of week is out of range.');
  is(is_valid_date   ('Jan',  15, 2005.9),       '', 'Fractional year is NOT allowed.');
  is(is_valid_date   ('Sep',  27, 2005.8, 2),    '', 'Fractional year is NOT allowed.');
  is(is_valid_date   (2,   0, 2005, 7),          '', 'Month is out of range');
  is(is_valid_date   (2,  29, 2005, 7),          '', 'Month is out of range');


  is(is_valid_date   ('Jan',  15, 2005, 'Sat'), 1, 'Date is good');
  is(is_valid_date   (8,  15, 1964),        1, '7,  27, 1999, Tue is valid date');
  is(is_valid_date   (2,  15, 2002),              1, 'Incorrect number of parameters');
  is(is_valid_date   ('Sep',  27, 2005, 2),       1, 'Fractional year is NOT allowed.');
  is(is_valid_date   (7,  27, 1999, 'Tue'), 1, '7,  27, 1999, Tue is valid date');
  is(is_valid_date   (2,  29, 2000, 'Tue'), 1, '2,  29, 2000, Tue is valid date');
  is(is_valid_date   (3,   1, 2000, 'Wed'), 1, '3,   1, 2000, Wed is valid date');
  is(is_valid_date   (3,   2, 2000, 'Thu'), 1, '3,   2, 2000, Thu is valid date');
  is(is_valid_date   (3,   3, 2000, 'Fri'), 1, '3,   3, 2000, Fri is valid date');
  is(is_valid_date   (3,   4, 2000, 'Sat'), 1, '3,   4, 2000, Sat is valid date');
  is(is_valid_date   (3,   5, 2000, 'Sun'), 1, '3,   5, 2000, Sun is valid date');
  is(is_valid_date   (3,   6, 2000, 'Mon'), 1, '3,   6, 2000, Mon is valid date');
  is(is_valid_date   (3,   7, 2000, 'Tue'), 1, '3,   7, 2000, Tue is valid date');
  is(is_valid_date   (3,   8, 2000, 'Wed'), 1, '3,   8, 2000, Wed is valid date');
  is(is_valid_date   (3,   9, 2000, 'Thu'), 1, '3,   9, 2000, Thu is valid date');
  is(is_valid_date   (3,  10, 2000, 'Fri'), 1, '3,  10, 2000, Fri is valid date');
  is(is_valid_date   (3,  11, 2000, 'Sat'), 1, '3,  11, 2000, Sat is valid date');
  is(is_valid_date   (3,  12, 2000, 'Sun'), 1, '3,  12, 2000, Sun is valid date');
  is(is_valid_date   (3,  13, 2000, 'Mon'), 1, '3,  13, 2000, Mon is valid date');
  is(is_valid_date   (3,  14, 2000, 'Tue'), 1, '3,  14, 2000, Tue is valid date');
  is(is_valid_date   (3,  15, 2000, 'Wed'), 1, '3,  15, 2000, Wed is valid date');
  is(is_valid_date   (3,  16, 2000, 'Thu'), 1, '3,  16, 2000, Thu is valid date');
  is(is_valid_date   (3,  17, 2000, 'Fri'), 1, '3,  17, 2000, Fri is valid date');
  is(is_valid_date   (3,  18, 2000, 'Sat'), 1, '3,  18, 2000, Sat is valid date');
  is(is_valid_date   (3,  15, -1),          1, '3,  15, 2000, Wed is valid date');
  is(is_valid_date   (3,  15,  0),          1, '3,  15, 2000, Wed is valid date');
  is(is_valid_date   (3,  15,  1),          1, '3,  15, 2000, Wed is valid date');
isnt(is_valid_date   (2,  29, 2100),        1, 'xxxxxxxxxxxxxxxxx is NOT a valid date');
isnt(is_valid_date   (2,  29, 2200),        1, 'xxxxxxxxxxxxxxxxx is NOT a valid date');
isnt(is_valid_date   (2,  29, 2300),        1, 'xxxxxxxxxxxxxxxxx is NOT a valid date');
  is(is_valid_date   (8,  37, 2300),        '','xxxxxxxxxxxxxxxxx is NOT a valid date');
  is(is_valid_date   (6, 3, 47),            1, 'Day of month is out of range.');


  is(is_valid_date   ('5/14/1988'),                1,'zzzzzzzzzzz');
  is(is_valid_date   ('Sun Feb 29 12:00:00 1604'), 1,'zzzzzzzzzzz');

