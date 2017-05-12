# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 36;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(month_name_to_month_number);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {month_name_to_month_number()};
ok(($@),      'Parameters are missing.');

eval {month_name_to_month_number('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {month_name_to_month_number(['October'])};
ok(($@),      'Array reference is not allowed.');

eval {month_name_to_month_number({})};
ok(($@),      'Hash reference is not allowed.');

eval {month_name_to_month_number('Jun ')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {month_name_to_month_number(11)};
ok(($@),      'Numeric month is NOT allowed.');



is(month_name_to_month_number('Jan'),             1,   'month_name Jan       to month_number   1');
is(month_name_to_month_number('Feb'),             2,   'month_name Feb       to month_number   2');
is(month_name_to_month_number('Mar'),             3,   'month_name Mar       to month_number   3');
is(month_name_to_month_number('Apr'),             4,   'month_name Apr       to month_number   4');
is(month_name_to_month_number('May'),             5,   'month_name May       to month_number   5');
is(month_name_to_month_number('Jun'),             6,   'month_name Jun       to month_number   6');
is(month_name_to_month_number('Jul'),             7,   'month_name Jul       to month_number   7');
is(month_name_to_month_number('Aug'),             8,   'month_name Aug       to month_number   8');
is(month_name_to_month_number('Sep'),             9,   'month_name Sep       to month_number   9');
is(month_name_to_month_number('Oct'),            10,   'month_name Oct       to month_number  10');
is(month_name_to_month_number('Nov'),            11,   'month_name Nov       to month_number  11');
is(month_name_to_month_number('Dec'),            12,   'month_name Dec       to month_number  12');
is(month_name_to_month_number('January'),         1,   'month_name January   to month_number   1');
is(month_name_to_month_number('February'),        2,   'month_name February  to month_number   2');
is(month_name_to_month_number('March'),           3,   'month_name March     to month_number   3');
is(month_name_to_month_number('April'),           4,   'month_name April     to month_number   4');
is(month_name_to_month_number('May'),             5,   'month_name May       to month_number   5');
is(month_name_to_month_number('June'),            6,   'month_name June      to month_number   6');
is(month_name_to_month_number('July'),            7,   'month_name July      to month_number   7');
is(month_name_to_month_number('August'),          8,   'month_name August    to month_number   8');
is(month_name_to_month_number('September'),       9,   'month_name September to month_number   9');
is(month_name_to_month_number('October'),        10,   'month_name October   to month_number  10');
is(month_name_to_month_number('November'),       11,   'month_name November  to month_number  11');
is(month_name_to_month_number('December'),       12,   'month_name December  to month_number  12');
