# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 48;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(calculate_day_of_week_for_first_of_month_in_next_year);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {calculate_day_of_week_for_first_of_month_in_next_year()};
ok(($@),      'Parameters are missing.');

eval {calculate_day_of_week_for_first_of_month_in_next_year([2005])};
ok(($@),      'Array reference is not allowed.');

eval {calculate_day_of_week_for_first_of_month_in_next_year({})};
ok(($@),      'Hash reference is not allowed.');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365)};
ok(($@),      'The month parameter is missing.');

eval {calculate_day_of_week_for_first_of_month_in_next_year(364, 3)};
ok(($@),      'Too few days in a year');

eval {calculate_day_of_week_for_first_of_month_in_next_year(367, 5)};
ok(($@),      'Too many days in a year');

eval {calculate_day_of_week_for_first_of_month_in_next_year(7, 365)};
ok(($@),      'Parameters are out of order');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365, 7, 9)};
ok(($@),      'Too many parameters');

eval {calculate_day_of_week_for_first_of_month_in_next_year({}, 5)};
ok(($@),      'Number of days in year must be SCALAR');

eval {calculate_day_of_week_for_first_of_month_in_next_year('', 5)};
ok(($@),      'Null number of days in year is NOT allowed');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365, {})};
ok(($@),      'Day of week must be SCALAR');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365, '')};
ok(($@),      'Null day of week is NOT allowed');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365, 0)};
ok(($@),      'Day of week is out of range.');

eval {calculate_day_of_week_for_first_of_month_in_next_year(365, 8)};
ok(($@),      'Day of week is out of range.');



# TBD ( add more tests to cover boundary conditions)
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           1), 2,   'One year from Monday,    the first of month N, with leap year NOT in between is a Tuesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           2), 3,   'One year from Tuesday,   the first of month N, with leap year NOT in between is a Wednesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           3), 4,   'One year from Wednesday, the first of month N, with leap year NOT in between is a Thursday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           4), 5,   'One year from Thursday,  the first of month N, with leap year NOT in between is a Friday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           5), 6,   'One year from Friday,    the first of month N, with leap year NOT in between is a Saturday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           6), 7,   'One year from Saturday,  the first of month N, with leap year NOT in between is a Sunday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,           7), 1,   'One year from Sunday,    the first of month N, with leap year NOT in between is a Monday');

is(calculate_day_of_week_for_first_of_month_in_next_year(366,           1), 3,   'One year from Monday,    the first of month N, with leap year in between is a Wednesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           2), 4,   'One year from Tuesday,   the first of month N, with leap year in between is a Thursday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           3), 5,   'One year from Wednesday, the first of month N, with leap year in between is a Friday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           4), 6,   'One year from Thursday,  the first of month N, with leap year in between is a Saturday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           5), 7,   'One year from Friday,    the first of month N, with leap year in between is a Sunday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           6), 1,   'One year from Saturday,  the first of month N, with leap year in between is a Monday');
is(calculate_day_of_week_for_first_of_month_in_next_year(366,           7), 2,   'One year from Sunday,    the first of month N, with leap year in between is a Tuesday');

is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Mon'), 2,   'One year from Monday,    the first of month N, with leap year NOT in between is a Tuesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Tue'), 3,   'One year from Tuesday,   the first of month N, with leap year NOT in between is a Wednesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Wed'), 4,   'One year from Wednesday, the first of month N, with leap year NOT in between is a Thursday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Thu'), 5,   'One year from Thursday,  the first of month N, with leap year NOT in between is a Friday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Fri'), 6,   'One year from Friday,    the first of month N, with leap year NOT in between is a Saturday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Sat'), 7,   'One year from Saturday,  the first of month N, with leap year NOT in between is a Sunday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,       'Sun'), 1,   'One year from Sunday,    the first of month N, with leap year NOT in between is a Monday');

is(calculate_day_of_week_for_first_of_month_in_next_year(365,    'Monday'), 2,   'One year from Monday,    the first of month N, with leap year NOT in between is a Tuesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,   'Tuesday'), 3,   'One year from Tuesday,   the first of month N, with leap year NOT in between is a Wednesday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365, 'Wednesday'), 4,   'One year from Wednesday, the first of month N, with leap year NOT in between is a Thursday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,  'Thursday'), 5,   'One year from Thursday,  the first of month N, with leap year NOT in between is a Friday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,    'Friday'), 6,   'One year from Friday,    the first of month N, with leap year NOT in between is a Saturday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,  'Saturday'), 7,   'One year from Saturday,  the first of month N, with leap year NOT in between is a Sunday');
is(calculate_day_of_week_for_first_of_month_in_next_year(365,    'Sunday'), 1,   'One year from Sunday,    the first of month N, with leap year NOT in between is a Monday');
