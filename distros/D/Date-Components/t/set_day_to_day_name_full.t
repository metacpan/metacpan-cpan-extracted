# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_day_to_day_name_full);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_day_to_day_name_full()};
ok(($@),      'Parameters are missing.');

eval {set_day_to_day_name_full('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_day_to_day_name_full(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {set_day_to_day_name_full({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_day_to_day_name_full(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_day_to_day_name_full(0)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_name_full(8)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_name_full(-1)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');



is(set_day_to_day_name_full(1),          'Monday',    'day number  1 to day name is Monday');
is(set_day_to_day_name_full(2),          'Tuesday',   'day number  2 to day name is Tuesday');
is(set_day_to_day_name_full(3),          'Wednesday', 'day number  3 to day name is Wednesday');
is(set_day_to_day_name_full(4),          'Thursday',  'day number  4 to day name is Thursday');
is(set_day_to_day_name_full(5),          'Friday',    'day number  5 to day name is Friday');
is(set_day_to_day_name_full(6),          'Saturday',  'day number  6 to day name is Saturday');
is(set_day_to_day_name_full(7),          'Sunday',    'day number  7 to day name is Sunday');
is(set_day_to_day_name_full('Tuesday'),  'Tuesday',   'day Tuesday to day name is Tuesday');
is(set_day_to_day_name_full('Sun'),      'Sunday',    'day Sun to day name is Sunday');
