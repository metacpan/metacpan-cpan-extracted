# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(month_number_to_month_name);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {month_number_to_month_name()};
ok(($@),      'Parameters are missing.');

eval {month_number_to_month_name('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {month_number_to_month_name(['3'])};
ok(($@),      'Array reference is not allowed.');

eval {month_number_to_month_name({})};
ok(($@),      'Hash reference is not allowed.');

eval {month_number_to_month_name('2 ')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {month_number_to_month_name('Aug')};
ok(($@),      'Numeric month is NOT allowed.');

eval {month_number_to_month_name(-1)};
ok(($@),      'Month is out of range');

eval {month_number_to_month_name(0)};
ok(($@),      'Month is out of range');

eval {month_number_to_month_name(13)};
ok(($@),      'Month is out of range');

eval {month_number_to_month_name(7.5)};
ok(($@),      'Fractional months are NOT allowed.');




is(month_number_to_month_name(1),    'Jan',   'month_number  1 to month_name Jan');
is(month_number_to_month_name(2),    'Feb',   'month_number  2 to month_name Feb');
is(month_number_to_month_name(3),    'Mar',   'month_number  3 to month_name Mar');
is(month_number_to_month_name(4),    'Apr',   'month_number  4 to month_name Apr');
is(month_number_to_month_name(5),    'May',   'month_number  5 to month_name May');
is(month_number_to_month_name(6),    'Jun',   'month_number  6 to month_name Jun');
is(month_number_to_month_name(7),    'Jul',   'month_number  7 to month_name Jul');
is(month_number_to_month_name(8),    'Aug',   'month_number  8 to month_name Aug');
is(month_number_to_month_name(9),    'Sep',   'month_number  9 to month_name Sep');
is(month_number_to_month_name(10),   'Oct',   'month_number 10 to month_name Oct');
is(month_number_to_month_name(11),   'Nov',   'month_number 11 to month_name Nov');
is(month_number_to_month_name(12),   'Dec',   'month_number 12 to month_name Dec');
