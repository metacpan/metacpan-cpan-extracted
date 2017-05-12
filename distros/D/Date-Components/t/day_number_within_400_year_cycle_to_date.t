# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(day_number_within_400_year_cycle_to_date);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {day_number_within_400_year_cycle_to_date(2000,   146098)};
ok(($@),      'Day number is out of range. The number of days in the four hundred year cycle is 14607');

eval {day_number_within_400_year_cycle_to_date(2000,        0)};
ok(($@),      'Day number is out of range. The minimum day number in the four hundred year cycle is 1');

eval {day_number_within_400_year_cycle_to_date(2001,        7)};
ok(($@),      '2001 is not a 400 year cycle.  It must be a multiple of 400');

eval {day_number_within_400_year_cycle_to_date(1800,        7)};
ok(($@),      '1800 is not a 400 year cycle.  It must be a multiple of 400');

eval {day_number_within_400_year_cycle_to_date(-17,        46)};
ok(($@),      '-17 is not a 400 year cycle.  It must be a multiple of 400');

eval {day_number_within_400_year_cycle_to_date(305)};
ok(($@),      'TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date(2000.0)};
ok(($@),      'TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date('')};
ok(($@),      'Null Parameter is NOT allowed.  TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date([800])};
ok(($@),      'Array reference is NOT allowed.  TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date({})};
ok(($@),      'Hash reference is NOT allowed.  TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date('3000 ', 842)};
ok(($@),      'Leading and trailing spaces are NOT allowed.  TWO and ONLY TWO parameters must be given (specific 400 year cycle, day number within that cycle');

eval {day_number_within_400_year_cycle_to_date([], 842)};
ok(($@),      'SCALAR value is REQUIRED for 400 year cycle.');

eval {day_number_within_400_year_cycle_to_date('', 842)};
ok(($@),      'NULL value is NOT allowed for 400 year cycle.');

eval {day_number_within_400_year_cycle_to_date(2000, {})};
ok(($@),      'SCALAR value is REQUIRED for day number.');

eval {day_number_within_400_year_cycle_to_date(2000, '')};
ok(($@),      'NULL value is NOT allowed for day number.');

eval {day_number_within_400_year_cycle_to_date(2000, 18.7)};
ok(($@),      'Integer value is REQUIRED for day number.');



is(day_number_within_400_year_cycle_to_date(2000,   146097),     '12/31/2399',       'day 146097 within the 2000 400 year cycle is date 12/31/2399');
is(day_number_within_400_year_cycle_to_date(2000,        1),     '01/01/2000',       'day      1 within the 2000 400 year cycle is date   1/1/2000');
is(day_number_within_400_year_cycle_to_date(0,           1),        '01/01/0',       'day      1 within the    0 400 year cycle is date      1/1/0');
is(day_number_within_400_year_cycle_to_date(-400,   146097),       '12/31/-1',       'day 146097 within the -400 400 year cycle is date   12/31/-1');
is(day_number_within_400_year_cycle_to_date(2000,    36527),     '01/02/2100',       'day  36527 within the 2000 400 year cycle is date   1/2/2100');
is(day_number_within_400_year_cycle_to_date(1600,   130416),     '01/24/1957',       'day 130416 within the 1600 400 year cycle is date  1/24/1957');
