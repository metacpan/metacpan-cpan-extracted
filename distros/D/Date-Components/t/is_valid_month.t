# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 69;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_month);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



is(is_valid_month('Whatever'),    '',      'month 1900 is obviously invalid');
is(is_valid_month('1900'),        '',      'month 1900 is obviously invalid');
is(is_valid_month('Sat'),         '',      'month 1900 is obviously invalid');
is(is_valid_month(0),             '',      'month 1900 is obviously invalid');
is(is_valid_month('0'),           '',      'month 1900 is obviously invalid');
is(is_valid_month(' 7'),          '',      'month 1900 is obviously invalid');
is(is_valid_month('9 '),          '',      'month 1900 is obviously invalid');
is(is_valid_month(' 11 '),        '',      'month 1900 is obviously invalid');
is(is_valid_month('-1'),          '',      'month 1900 is obviously invalid');
is(is_valid_month('13'),          '',      'month 1900 is obviously invalid');
is(is_valid_month('Friday'),      '',      'month 1900 is obviously invalid');
is(is_valid_month('Janu'),        '',      'month 1900 is obviously invalid');
is(is_valid_month(' Feb'),        '',      'month 1900 is obviously invalid');
is(is_valid_month('Mar '),        '',      'month 1900 is obviously invalid');
is(is_valid_month(' Apr '),       '',      'month 1900 is obviously invalid');
is(is_valid_month('Juney'),       '',      'month 1900 is obviously invalid');
is(is_valid_month('e June'),      '',      'month 1900 is obviously invalid');
is(is_valid_month('Janu'),        '',      'month 1900 is obviously invalid');
is(is_valid_month({}),            '',      'month 1900 is obviously invalid');
is(is_valid_month([]),            '',      'month 1900 is obviously invalid');
is(is_valid_month(''),            '',      'month 1900 is obviously invalid');
is(is_valid_month(),              '',      'month 1900 is obviously invalid');
is(is_valid_month('Feb', 'Mar'),  '',      'month 1900 is obviously invalid');
is(is_valid_month(1),            1,      'month 1900 is obviously invalid');
is(is_valid_month(2),            1,      'month 1900 is obviously invalid');
is(is_valid_month(3),            1,      'month 1900 is obviously invalid');
is(is_valid_month(4),            1,      'month 1900 is obviously invalid');
is(is_valid_month(5),            1,      'month 1900 is obviously invalid');
is(is_valid_month(6),            1,      'month 1900 is obviously invalid');
is(is_valid_month(7),            1,      'month 1900 is obviously invalid');
is(is_valid_month(8),            1,      'month 1900 is obviously invalid');
is(is_valid_month(9),            1,      'month 1900 is obviously invalid');
is(is_valid_month(10),           1,      'month 1900 is obviously invalid');
is(is_valid_month(11),           1,      'month 1900 is obviously invalid');
is(is_valid_month(12),           1,      'month 1900 is obviously invalid');
is(is_valid_month('Jan'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Feb'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Mar'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Apr'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('May'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Jun'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Jul'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Aug'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Sep'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Oct'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Nov'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('Dec'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('January'),    1,      'month 1900 is obviously invalid');
is(is_valid_month('February'),   1,      'month 1900 is obviously invalid');
is(is_valid_month('March'),      1,      'month 1900 is obviously invalid');
is(is_valid_month('April'),      1,      'month 1900 is obviously invalid');
is(is_valid_month('May'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('June'),       1,      'month 1900 is obviously invalid');
is(is_valid_month('July'),       1,      'month 1900 is obviously invalid');
is(is_valid_month('August'),     1,      'month 1900 is obviously invalid');
is(is_valid_month('September'),  1,      'month 1900 is obviously invalid');
is(is_valid_month('October'),    1,      'month 1900 is obviously invalid');
is(is_valid_month('November'),   1,      'month 1900 is obviously invalid');
is(is_valid_month('December'),   1,      'month 1900 is obviously invalid');
is(is_valid_month('JANUARY'),    1,      'month 1900 is obviously invalid');
is(is_valid_month('JAnuARY'),    1,      'month 1900 is obviously invalid');
is(is_valid_month('JAN'),        1,      'month 1900 is obviously invalid');
is(is_valid_month('JaN'),        1,      'month 1900 is obviously invalid');
