# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Holidays-EnglandWales.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 22;
BEGIN { use_ok('Date::Holidays::EnglandWales') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(!is_uk_holiday(2010, 6, 1), "2010-06-01 is not a holiday");

# Christmas Day & Boxing Day 2010 were on Sat & Sun, check they're not holidays,
# but the following Monday and Tuesday are:
ok(!is_uk_holiday(2010 ,12, 25), "2010-12-25 is not a holiday");
ok(!is_uk_holiday(2010 ,12, 26), "2010-12-26 is not a holiday");
ok( is_uk_holiday(2010, 12, 27), "2010-12-27 is a holiday");
ok( is_uk_holiday(2010, 12, 28), "2010-12-28 is a holiday");
ok(!is_uk_holiday(2010, 12, 29), "2010-12-29 is not a holiday");

# New Year's Day 2011 was a Saturday, so the following Monday is a holiday:
ok(!is_uk_holiday(2011, 1, 1), "2011-01-01 is not a holiday");
ok(!is_uk_holiday(2011, 1, 2), "2011-01-02 is not a holiday");
ok( is_uk_holiday(2011, 1, 3), "2011-01-03 is a holiday");

ok(is_uk_holiday("2011-04-22"), "2011-04-22 is a holiday (Good Friday)");
ok(is_uk_holiday("2011-04-25"), "2011-04-25 is a holiday (Easter Monday)");
ok(is_uk_holiday('2011-04-29'), 
    "2011-04-29 is a holiday (William & Kate's wedding");

ok(is_uk_holiday("2011-05-02"), 
    "2011-05-02 is a holiday (Early May Bank Holiday)");
ok(is_uk_holiday("2011-05-30"),
    "2011-05-30 is a holiday (Spring Bank Holiday)");
ok(is_uk_holiday("2011-08-29"),
    "2011-08-29 is a holiday (Late Summer Holiday)");

# 2022 is a special year. The spring bank holiday moved to 2nd June and extra day added for Queen's Jubilee
ok(!is_uk_holiday("2022-05-27"),
    "2022-05-27 is not a holiday (moved to 2nd June)");
ok(is_uk_holiday("2022-06-02"),
    "2022-06-02 is a holiday (Spring Bank Holiday)");
ok(is_uk_holiday("2022-06-03"),
    "2022-06-03 is a holiday (Queen's Platinum Jubilee)");
ok(is_uk_holiday("2022-09-19"), "2022-09-19 is a public holiday (State Funeral of Queen Elizabeth II)");
ok(is_uk_holiday(2022, 9, 19), "State Funeral of Queen Elizabeth II passed in as separate elements");
ok(is_uk_holiday(2023, 5, 8), "Coronation of King Charles III");
