# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 35;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_day_to_day_number);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_day_to_day_number()};
ok(($@),      'Parameters are missing.');

eval {set_day_to_day_number('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_day_to_day_number(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {set_day_to_day_number({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_day_to_day_number(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_day_to_day_number(0)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_number(8)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_number(-1)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');



is(set_day_to_day_number      ('Monday'),      1,   'set day Monday     to day number  1');
is(set_day_to_day_number      ('Tuesday'),     2,   'set day Tuesday    to day number  2');
is(set_day_to_day_number      ('Wednesday'),   3,   'set day Wednesday  to day number  3');
is(set_day_to_day_number      ('Thursday'),    4,   'set day Thursday   to day number  4');
is(set_day_to_day_number      ('Friday'),      5,   'set day Friday     to day number  5');
is(set_day_to_day_number      ('Saturday'),    6,   'set day Saturday   to day number  6');
is(set_day_to_day_number      ('Sunday'),      7,   'set day Sunday     to day number  7');
is(set_day_to_day_number      ('Mon'),         1,   'set day Mon        to day number  1');
is(set_day_to_day_number      ('Tue'),         2,   'set day Tue        to day number  2');
is(set_day_to_day_number      ('Wed'),         3,   'set day Wed        to day number  3');
is(set_day_to_day_number      ('Thu'),         4,   'set day Thu        to day number  4');
is(set_day_to_day_number      ('Fri'),         5,   'set day Fri        to day number  5');
is(set_day_to_day_number      ('Sat'),         6,   'set day Sat        to day number  6');
is(set_day_to_day_number      ('Sun'),         7,   'set day Sun        to day number  7');
is(set_day_to_day_number      (1),             1,   'set day   1        to day number  1');
is(set_day_to_day_number      (2),             2,   'set day   2        to day number  2');
is(set_day_to_day_number      (3),             3,   'set day   3        to day number  3');
is(set_day_to_day_number      (4),             4,   'set day   4        to day number  4');
is(set_day_to_day_number      (5),             5,   'set day   5        to day number  5');
is(set_day_to_day_number      (6),             6,   'set day   6        to day number  6');
is(set_day_to_day_number      (7),             7,   'set day   7        to day number  7');
