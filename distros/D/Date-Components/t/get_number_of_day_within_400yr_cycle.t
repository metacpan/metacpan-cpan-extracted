# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 32;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_number_of_day_within_400yr_cycle);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");


# Check for faulty input
eval {get_number_of_day_within_400yr_cycle(0,1,2000)};
ok(($@),      'Invalid Month');

eval {get_number_of_day_within_400yr_cycle(5,0,2000)};
ok(($@),      'Invalid day of month');

eval {get_number_of_day_within_400yr_cycle(13,7,1223)};
ok(($@),      'Invalid Month');

eval {get_number_of_day_within_400yr_cycle(2,29,2003)};
ok(($@),      'Invalid day of month');

eval {get_number_of_day_within_400yr_cycle(2,30,2004)};
ok(($@),      'Invalid day of month');

eval {get_number_of_day_within_400yr_cycle(7,11,6.7)};
ok(($@),      'Fractional years are INVALID');

eval {get_number_of_day_within_400yr_cycle([12],11,1992)};
ok(($@),      'Array references are NOT allowed');

eval {get_number_of_day_within_400yr_cycle('J',11,1992)};
ok(($@),      'Only three letter month abbreviations are allowed');

eval {get_number_of_day_within_400yr_cycle('Feb ',11,1992)};
ok(($@),      'Leading and trailing spaces are NOT allowed in parameters');

eval {get_number_of_day_within_400yr_cycle('July 3',11,1992)};
ok(($@),      'Invalid Input');

eval {get_number_of_day_within_400yr_cycle('Aug 17,1544')};
ok(($@),      'Three parameters CANNOT be combined into one string');

eval {get_number_of_day_within_400yr_cycle('', 18,1942)};
ok(($@),      'NULL value for month is NOT allowed.');

eval {get_number_of_day_within_400yr_cycle('February', 6,{})};
ok(($@),      'Hash references are NOT allowed');

eval {get_number_of_day_within_400yr_cycle('Nov', 8,'')};
ok(($@),      'NULL value for year is NOT allowed.');

eval {get_number_of_day_within_400yr_cycle('February', [],1888)};
ok(($@),      'Hash references are NOT allowed');

eval {get_number_of_day_within_400yr_cycle('Nov', '',1587)};
ok(($@),      'NULL value for day of month is NOT allowed.');





is(get_number_of_day_within_400yr_cycle(2,1,2000),                                         32,   'date  2, 1,2000  is day number                                    32 within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(2,1,2001),                                        398,   'date  2, 1,2001  is day number                                   398 within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(12,31,1999),          ((300 * 365) + (100 * 366) - 3),   'date 12,31,1999  is day number       ((300 * 365) + (100 * 366) - 3) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(12,31,199),           ((150 * 365) +  (50 * 366) - 1),   'date 12,31, 199  is day number       ((150 * 365) +  (50 * 366) - 1) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(12,31,-201),          ((150 * 365) +  (50 * 366) - 1),   'date 12,31,-201  is day number       ((150 * 365) +  (50 * 366) - 1) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(12,31,-1),            ((300 * 365) + (100 * 366) - 3),   'date 12,31,  -1  is day number       ((300 * 365) + (100 * 366) - 3) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(1,1,0),                                           (1),   'date  1, 1,   0  is day number                                   (1) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(12,30,-201),      ((150 * 365) +  (50 * 366) - 1 - 1),   'date 12,30,-201  is day number   ((150 * 365) +  (50 * 366) - 1 - 1) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle(11,25,-201),     ((150 * 365) +  (50 * 366) - 1 - 36),   'date 11,25,-201  is day number  ((150 * 365) +  (50 * 366) - 1 - 36) within the 400 year calendar cycle');
is(get_number_of_day_within_400yr_cycle('Feb',1,1999),  ((300 * 365) + (100 * 366) - 3 - 333),   'date Feb,1,1999  is day number ((300 * 365) + (100 * 366) - 3 - 333) within the 400 year calendar cycle');
