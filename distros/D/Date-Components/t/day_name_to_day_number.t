# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 26;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(day_name_to_day_number);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {day_name_to_day_number()};
ok(($@),      'Parameters are missing.');

eval {day_name_to_day_number('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {day_name_to_day_number(['Friday'])};
ok(($@),      'Array reference is not allowed.');

eval {day_name_to_day_number({})};
ok(($@),      'Hash reference is not allowed.');

eval {day_name_to_day_number(' Mon')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {day_name_to_day_number(5)};
ok(($@),      'Numeric day is NOT allowed.');



is(day_name_to_day_number('Mon'),             1,   'day name Mon       to day_number is 1');
is(day_name_to_day_number('Tue'),             2,   'day name Tue       to day_number is 2');
is(day_name_to_day_number('Wed'),             3,   'day name Wed       to day_number is 3');
is(day_name_to_day_number('Thu'),             4,   'day name Thu       to day_number is 4');
is(day_name_to_day_number('Fri'),             5,   'day name Fri       to day_number is 5');
is(day_name_to_day_number('Sat'),             6,   'day name Sat       to day_number is 6');
is(day_name_to_day_number('Sun'),             7,   'day name Sun       to day_number is 7');
is(day_name_to_day_number('Monday'),          1,   'day name Monday    to day_number is 1');
is(day_name_to_day_number('Tuesday'),         2,   'day name Tuesday   to day_number is 2');
is(day_name_to_day_number('Wednesday'),       3,   'day name Wednesday to day_number is 3');
is(day_name_to_day_number('Thursday'),        4,   'day name Thursday  to day_number is 4');
is(day_name_to_day_number('Friday'),          5,   'day name Friday    to day_number is 5');
is(day_name_to_day_number('Saturday'),        6,   'day name Saturday  to day_number is 6');
is(day_name_to_day_number('Sunday'),          7,   'day name Sunday    to day_number is 7');
