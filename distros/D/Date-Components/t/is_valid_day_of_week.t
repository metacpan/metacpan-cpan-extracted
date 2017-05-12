# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 53;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_day_of_week);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



is(is_valid_day_of_week('Whatever'),    '',      'day of week is obviously invalid');
is(is_valid_day_of_week('1900'),        '',      'day of week is obviously invalid');
is(is_valid_day_of_week('Nov'),         '',      'day of week is obviously invalid');
is(is_valid_day_of_week(0),             '',      'day of week is obviously invalid');
is(is_valid_day_of_week('0'),           '',      'day of week is obviously invalid');
is(is_valid_day_of_week(' 7'),          '',      'day of week is obviously invalid');
is(is_valid_day_of_week('9 '),          '',      'day of week is obviously invalid');
is(is_valid_day_of_week(' 11 '),        '',      'day of week is obviously invalid');
is(is_valid_day_of_week('-1'),          '',      'day of week is obviously invalid');
is(is_valid_day_of_week('8'),           '',      'day of week is obviously invalid');
is(is_valid_day_of_week('October'),     '',      'day of week is obviously invalid');
is(is_valid_day_of_week('Thur'),        '',      'day of week is obviously invalid');
is(is_valid_day_of_week(' Fri'),        '',      'day of week is obviously invalid');
is(is_valid_day_of_week('Sat '),        '',      'day of week is obviously invalid');
is(is_valid_day_of_week(' Sun '),       '',      'day of week is obviously invalid');
is(is_valid_day_of_week('Wednesdayy'),  '',      'day of week is obviously invalid');
is(is_valid_day_of_week('e Monday'),    '',      'day of week is obviously invalid');
is(is_valid_day_of_week({}),            '',      'day of week is obviously invalid');
is(is_valid_day_of_week([]),            '',      'day of week is obviously invalid');
is(is_valid_day_of_week(''),            '',      'day of week is obviously invalid');
is(is_valid_day_of_week(),              '',      'day of week is obviously invalid');
is(is_valid_day_of_week('Mon', 'Tue'),  '',      'day of week is obviously invalid');
is(is_valid_day_of_week(1),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(2),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(3),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(4),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(5),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(6),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week(7),            1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Mon'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Tue'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Wed'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Thu'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Fri'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Sat'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Sun'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Monday'),     1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Tuesday'),    1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Wednesday'),  1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Thursday'),   1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Friday'),     1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Saturday'),   1,      'day of week is obviously invalid');
is(is_valid_day_of_week('Sunday'),     1,      'day of week is obviously invalid');
is(is_valid_day_of_week('TUESDAY'),    1,      'day of week is obviously invalid');
is(is_valid_day_of_week('TueSDay'),    1,      'day of week is obviously invalid');
is(is_valid_day_of_week('TUE'),        1,      'day of week is obviously invalid');
is(is_valid_day_of_week('TUe'),        1,      'day of week is obviously invalid');
