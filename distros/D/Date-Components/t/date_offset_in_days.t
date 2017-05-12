# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 36;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(date_offset_in_days);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");


# Check for faulty input
eval {date_offset_in_days('12/31/2007',   57.5)};
ok(($@),      'Fractional offset days are NOT allowed');

eval {date_offset_in_days('Tue Sep 17 08:50:51 2007',   57)};
ok(($@),      'Date does not parse for correct day of week, Sept 17 2007 is a Monday');

eval {date_offset_in_days('12/31/2007,   57')};
ok(($@),      'CANNOT combine two parameters into one string');

eval {date_offset_in_days(57, '12/31/2007')};
ok(($@),      'Parameters are out of order, date comes first');

eval {date_offset_in_days('12/31/2007')};
ok(($@),      'TWO and ONLY TWO parameters are to be supplied.  There is NO default for the number of days.');

eval {date_offset_in_days('12/31/2007',   57, 96)};
ok(($@),      'TWO and ONLY TWO parameters are to be supplied');

eval {date_offset_in_days()};
ok(($@),      'Null is NOT allowed.  TWO and ONLY TWO scalar parameters are to be supplied');

eval {date_offset_in_days([])};
ok(($@),      'Array reference is not an allowed parameter');

eval {date_offset_in_days({})};
ok(($@),      'Hash reference is not an allowed parameter');

eval {date_offset_in_days({}, 1)};
ok(($@),      'SCALAR parameters only allowed.');

eval {date_offset_in_days('12/31/1999', [])};
ok(($@),      'SCALAR parameters only allowed.');

eval {date_offset_in_days('', 1)};
ok(($@),      'NULL parameters are NOT allowed.');

eval {date_offset_in_days('12/31/1999', '')};
ok(($@),      'NULL parameters are NOT allowed.');







is(date_offset_in_days('Mon Sep 17 08:50:51 2007',                       0),     '09/17/2007',       'date_offset_in_days');
is(date_offset_in_days('12/31/-401',   ((300 * 365) + (100 * 366) - 3 + 1)),        '01/01/0',       'date_offset_in_days');
is(date_offset_in_days('1/1/0',       -((300 * 365) + (100 * 366) - 3 + 1)),     '12/31/-401',       'date_offset_in_days');
is(date_offset_in_days('12/30/1999',                                     1),     '12/31/1999',       'date_offset_in_days');
is(date_offset_in_days('12/31/1999',                                    -1),     '12/30/1999',       'date_offset_in_days');
is(date_offset_in_days('12/30/1999',                         (2 + 366 + 3)),     '01/04/2001',       'date_offset_in_days');
is(date_offset_in_days('1/4/2001',                          -(2 + 366 + 3)),     '12/30/1999',       'date_offset_in_days');
is(date_offset_in_days('1/1/-400',                                      -1),     '12/31/-401',       'date_offset_in_days');
is(date_offset_in_days('12/31/-401',                                     1),     '01/01/-400',       'date_offset_in_days');
is(date_offset_in_days('1/1/0',                                         -1),       '12/31/-1',       'date_offset_in_days');
is(date_offset_in_days('12/31/-1',                                       1),        '01/01/0',       'date_offset_in_days');
is(date_offset_in_days('1/1/2000',                                      -1),     '12/31/1999',       'date_offset_in_days');
is(date_offset_in_days('12/31/1999',                                     1),     '01/01/2000',       'date_offset_in_days');
is(date_offset_in_days('1/1/2001',                                      15),     '01/16/2001',       'date_offset_in_days');
is(date_offset_in_days('1/1/2001',                                     -15),     '12/17/2000',       'date_offset_in_days');
is(date_offset_in_days('1/1/2000',                                       1),     '01/02/2000',       'date_offset_in_days');
is(date_offset_in_days('1/21/2000',                                     -5),     '01/16/2000',       'date_offset_in_days');
