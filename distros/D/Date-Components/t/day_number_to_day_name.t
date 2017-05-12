# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 22;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(day_number_to_day_name);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {day_number_to_day_name()};
ok(($@),      'Parameters are missing.');

eval {day_number_to_day_name('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {day_number_to_day_name(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {day_number_to_day_name({})};
ok(($@),      'Hash reference is not allowed.');

eval {day_number_to_day_name(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {day_number_to_day_name('Saturday')};
ok(($@),      'Numeric day is NOT allowed.');

eval {day_number_to_day_name(0)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {day_number_to_day_name(8)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {day_number_to_day_name(-1)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');



is(day_number_to_day_name(1),  'Mon',   'day number  1 to day name is Mon');
is(day_number_to_day_name(2),  'Tue',   'day number  2 to day name is Tue');
is(day_number_to_day_name(3),  'Wed',   'day number  3 to day name is Wed');
is(day_number_to_day_name(4),  'Thu',   'day number  4 to day name is Thu');
is(day_number_to_day_name(5),  'Fri',   'day number  5 to day name is Fri');
is(day_number_to_day_name(6),  'Sat',   'day number  6 to day name is Sat');
is(day_number_to_day_name(7),  'Sun',   'day number  7 to day name is Sun');
