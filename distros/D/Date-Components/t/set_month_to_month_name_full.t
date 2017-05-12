# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 29;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_month_to_month_name_full);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_month_to_month_name_full()};
ok(($@),      'Parameters are missing.');

eval {set_month_to_month_name_full('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_month_to_month_name_full(['3'])};
ok(($@),      'Array reference is not allowed.');

eval {set_month_to_month_name_full({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_month_to_month_name_full('2 ')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_month_to_month_name_full(-1)};
ok(($@),      'Month is out of range');

eval {set_month_to_month_name_full(0)};
ok(($@),      'Month is out of range');

eval {set_month_to_month_name_full(13)};
ok(($@),      'Month is out of range');

eval {set_month_to_month_name_full(7.5)};
ok(($@),      'Fractional months are NOT allowed.');




is(set_month_to_month_name_full(1),         'January',    'month number  1 to month name January');
is(set_month_to_month_name_full(2),         'February',   'month number  2 to month name February');
is(set_month_to_month_name_full(3),         'March',      'month number  3 to month name March');
is(set_month_to_month_name_full(4),         'April',      'month number  4 to month name April');
is(set_month_to_month_name_full(5),         'May',        'month number  5 to month name May');
is(set_month_to_month_name_full(6),         'June',       'month number  6 to month name June');
is(set_month_to_month_name_full(7),         'July',       'month number  7 to month name July');
is(set_month_to_month_name_full(8),         'August',     'month number  8 to month name August');
is(set_month_to_month_name_full(9),         'September',  'month number  9 to month name September');
is(set_month_to_month_name_full(10),        'October',    'month number 10 to month name October');
is(set_month_to_month_name_full(11),        'November',   'month number 11 to month name November');
is(set_month_to_month_name_full(12),        'December',   'month number 12 to month name December');
is(set_month_to_month_name_full('Apr'),     'April',      'month Apr month name April');
is(set_month_to_month_name_full('August'),  'August',     'month August  8 to month name August');
