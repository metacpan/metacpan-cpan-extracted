# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 35;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_day_to_day_name_abbrev);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_day_to_day_name_abbrev()};
ok(($@),      'Parameters are missing.');

eval {set_day_to_day_name_abbrev('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_day_to_day_name_abbrev(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {set_day_to_day_name_abbrev({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_day_to_day_name_abbrev(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_day_to_day_name_abbrev(0)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_name_abbrev(8)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');

eval {set_day_to_day_name_abbrev(-1)};
ok(($@),      'Invalid number for day of week.  1-7 is expected.');



is(set_day_to_day_name_abbrev        ('Monday'),      'Mon',   'set day Monday     to day name  Mon');
is(set_day_to_day_name_abbrev        ('Tuesday'),     'Tue',   'set day Tuesday    to day name  Tue');
is(set_day_to_day_name_abbrev        ('Wednesday'),   'Wed',   'set day Wednesday  to day name  Wed');
is(set_day_to_day_name_abbrev        ('Thursday'),    'Thu',   'set day Thursday   to day name  Thu');
is(set_day_to_day_name_abbrev        ('Friday'),      'Fri',   'set day Friday     to day name  Fri');
is(set_day_to_day_name_abbrev        ('Saturday'),    'Sat',   'set day Saturday   to day name  Sat');
is(set_day_to_day_name_abbrev        ('Sunday'),      'Sun',   'set day Sunday     to day name  Sun');
is(set_day_to_day_name_abbrev        ('Mon'),         'Mon',   'set day Mon        to day name  Mon');
is(set_day_to_day_name_abbrev        ('Tue'),         'Tue',   'set day Tue        to day name  Tue');
is(set_day_to_day_name_abbrev        ('Wed'),         'Wed',   'set day Wed        to day name  Wed');
is(set_day_to_day_name_abbrev        ('Thu'),         'Thu',   'set day Thu        to day name  Thu');
is(set_day_to_day_name_abbrev        ('Fri'),         'Fri',   'set day Fri        to day name  Fri');
is(set_day_to_day_name_abbrev        ('Sat'),         'Sat',   'set day Sat        to day name  Sat');
is(set_day_to_day_name_abbrev        ('Sun'),         'Sun',   'set day Sun        to day name  Sun');
is(set_day_to_day_name_abbrev        (1),             'Mon',   'set day   1        to day name  Mon');
is(set_day_to_day_name_abbrev        (2),             'Tue',   'set day   2        to day name  Tue');
is(set_day_to_day_name_abbrev        (3),             'Wed',   'set day   3        to day name  Wed');
is(set_day_to_day_name_abbrev        (4),             'Thu',   'set day   4        to day name  Thu');
is(set_day_to_day_name_abbrev        (5),             'Fri',   'set day   5        to day name  Fri');
is(set_day_to_day_name_abbrev        (6),             'Sat',   'set day   6        to day name  Sat');
is(set_day_to_day_name_abbrev        (7),             'Sun',   'set day   7        to day name  Sun');
