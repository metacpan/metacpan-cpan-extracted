# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_days_remaining_in_400yr_cycle);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_days_remaining_in_400yr_cycle('11/7/1212')};
ok(($@),      'THREE and ONLY THREE parameters must be given (month, day_of_month, year)');

eval {get_days_remaining_in_400yr_cycle(0,16,2345)};
ok(($@),      'Invalid month');

eval {get_days_remaining_in_400yr_cycle(13,2,2009)};
ok(($@),      'Invalid month');

eval {get_days_remaining_in_400yr_cycle(9,0,1977)};
ok(($@),      'Invalid day of month');

eval {get_days_remaining_in_400yr_cycle(10,32,1775)};
ok(($@),      'Invalid day of month');

eval {get_days_remaining_in_400yr_cycle('Mar ',22,1608)};
ok(($@),      'No leading or trailing spaces are allowed in parameters');

eval {get_days_remaining_in_400yr_cycle('February ',11,201)};
ok(($@),      'No leading or trailing spaces are allowed in parameters');

eval {get_days_remaining_in_400yr_cycle({},11,201)};
ok(($@),      'SCALAR value is required for month.');

eval {get_days_remaining_in_400yr_cycle('',11,201)};
ok(($@),      'NULL value is NOT allowed for month.');

eval {get_days_remaining_in_400yr_cycle(7,11,{})};
ok(($@),      'SCALAR value is required for year.');

eval {get_days_remaining_in_400yr_cycle(7,11,'')};
ok(($@),      'NULL value is NOT allowed for year.');

eval {get_days_remaining_in_400yr_cycle(7,11,1971.8)};
ok(($@),      'Fractional value is NOT allowed for year.');

eval {get_days_remaining_in_400yr_cycle(5,[],2001)};
ok(($@),      'SCALAR value is required for day of month.');

eval {get_days_remaining_in_400yr_cycle(5,'',2001)};
ok(($@),      'NULL value is NOT allowed for day of month.');






is(get_days_remaining_in_400yr_cycle(12,30,1999),                                                         1,      'there are                                                      1 days remaining in the 400 year cycle AFTER date 12,30,1999');
is(get_days_remaining_in_400yr_cycle(1,1,2000),                             ((300 * 365) + (100 * 366) - 4),      'there are                        ((300 * 365) + (100 * 366) - 4) days remaining in the 400 year cycle AFTER date 1,1,2000  ');
is(get_days_remaining_in_400yr_cycle(2,2,2000),                        ((300 * 365) + (100 * 366) - 3 - 33),      'there are                   ((300 * 365) + (100 * 366) - 3 - 33) days remaining in the 400 year cycle AFTER date 2,2,2000  ');
is(get_days_remaining_in_400yr_cycle(1,5,0),                            ((300 * 365) + (100 * 366) - 3 - 5),      'there are                    ((300 * 365) + (100 * 366) - 3 - 5) days remaining in the 400 year cycle AFTER date 1,5,0     ');
is(get_days_remaining_in_400yr_cycle(12,31,-401),                                                       (0),      'there are                                                    (0) days remaining in the 400 year cycle AFTER date 12,31,-401');
is(get_days_remaining_in_400yr_cycle('Jan',1,-400),                     ((300 * 365) + (100 * 366) - 3 - 1),      'there are                    ((300 * 365) + (100 * 366) - 3 - 1) days remaining in the 400 year cycle AFTER date Jan,1,-400');
is(get_days_remaining_in_400yr_cycle('Mar',1,-5),               ((3 * 365) + (1 * 366) + 365 - 31 - 28 - 1),      'there are            ((3 * 365) + (1 * 366) + 365 - 31 - 28 - 1) days remaining in the 400 year cycle AFTER date Mar,1,-5  ');
is(get_days_remaining_in_400yr_cycle('May',1,2100),  ((225 * 365) + (75 * 366) - 3 - 31 - 28 - 31 - 30 - 1),      'there are ((225 * 365) + (75 * 366) - 3 - 31 - 28 - 31 - 30 - 1) days remaining in the 400 year cycle AFTER date May,1,2100');
