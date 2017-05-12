# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 83;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(day_number_within_year_to_date);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {day_number_within_year_to_date(2004,   367)};
ok(($@),      'Day number within year is TOO large');

eval {day_number_within_year_to_date(2003,   366)};
ok(($@),      'Day number within year is TOO large');

eval {day_number_within_year_to_date(-7,     366)};
ok(($@),      'Day number within year is TOO large');

eval {day_number_within_year_to_date(434,      0)};
ok(($@),      'Day number within year starts at 1');

eval {day_number_within_year_to_date(1109,    -5)};
ok(($@),      'Day number within year must be positive');

eval {day_number_within_year_to_date('1109,  77')};
ok(($@),      'Two paramater CANNOT be combined into one string');

eval {day_number_within_year_to_date()};
ok(($@),      'TWO and ONLY TWO parameters are required, year and day within year');

eval {day_number_within_year_to_date({})};
ok(($@),      'Hash references are NOT allowed.');

eval {day_number_within_year_to_date([])};
ok(($@),      'Array references are NOT allowed.');

eval {day_number_within_year_to_date(582, 65.6)};
ok(($@),      'Fractional day number is NOT allowed.');

eval {day_number_within_year_to_date([], 52)};
ok(($@),      'Array references are not allowed.');

eval {day_number_within_year_to_date('', 52)};
ok(($@),      'NULL value for year is NOT allowed.');

eval {day_number_within_year_to_date(1558.99, 52)};
ok(($@),      'Fractional value for year is NOT allowed.');

eval {day_number_within_year_to_date(1675, [])};
ok(($@),      'Hash references are not allowed.');

eval {day_number_within_year_to_date(1911, '')};
ok(($@),      'NULL value for day number is NOT allowed.');

eval {day_number_within_year_to_date(1924, 52.5)};
ok(($@),      'Fractional value for day number is NOT allowed.');

eval {day_number_within_year_to_date(1924, 0)};
ok(($@),      'Day number is out of range.');





is(day_number_within_year_to_date(2001,  31),  ('01/31/2001'),       'day number  31 within year to date of year 2001 translates to date  1/31/2001');
is(day_number_within_year_to_date(2001,  59),  ('02/28/2001'),       'day number  59 within year to date of year 2001 translates to date  2/28/2001');
is(day_number_within_year_to_date(2001,  90),  ('03/31/2001'),       'day number  90 within year to date of year 2001 translates to date  3/31/2001');
is(day_number_within_year_to_date(2001, 120),  ('04/30/2001'),       'day number 120 within year to date of year 2001 translates to date  4/30/2001');
is(day_number_within_year_to_date(2001, 151),  ('05/31/2001'),       'day number 151 within year to date of year 2001 translates to date  5/31/2001');
is(day_number_within_year_to_date(2001, 181),  ('06/30/2001'),       'day number 181 within year to date of year 2001 translates to date  6/30/2001');
is(day_number_within_year_to_date(2001, 212),  ('07/31/2001'),       'day number 212 within year to date of year 2001 translates to date  7/31/2001');
is(day_number_within_year_to_date(2001, 243),  ('08/31/2001'),       'day number 243 within year to date of year 2001 translates to date  8/31/2001');
is(day_number_within_year_to_date(2001, 273),  ('09/30/2001'),       'day number 273 within year to date of year 2001 translates to date  9/30/2001');
is(day_number_within_year_to_date(2001, 304),  ('10/31/2001'),       'day number 304 within year to date of year 2001 translates to date 10/31/2001');
is(day_number_within_year_to_date(2001, 334),  ('11/30/2001'),       'day number 334 within year to date of year 2001 translates to date 11/30/2001');
is(day_number_within_year_to_date(2001, 365),  ('12/31/2001'),       'day number 365 within year to date of year 2001 translates to date 12/31/2001');
is(day_number_within_year_to_date(1443,   1),  ('01/01/1443'),       'day number   1 within year to date of year 1443 translates to date   1/1/1443');
is(day_number_within_year_to_date(1443,  32),  ('02/01/1443'),       'day number  32 within year to date of year 1443 translates to date   2/1/1443');
is(day_number_within_year_to_date(1443,  60),  ('03/01/1443'),       'day number  60 within year to date of year 1443 translates to date   3/1/1443');
is(day_number_within_year_to_date(1443,  91),  ('04/01/1443'),       'day number  91 within year to date of year 1443 translates to date   4/1/1443');
is(day_number_within_year_to_date(1443, 121),  ('05/01/1443'),       'day number 121 within year to date of year 1443 translates to date   5/1/1443');
is(day_number_within_year_to_date(1443, 152),  ('06/01/1443'),       'day number 152 within year to date of year 1443 translates to date   6/1/1443');
is(day_number_within_year_to_date(1443, 182),  ('07/01/1443'),       'day number 182 within year to date of year 1443 translates to date   7/1/1443');
is(day_number_within_year_to_date(1443, 213),  ('08/01/1443'),       'day number 213 within year to date of year 1443 translates to date   8/1/1443');
is(day_number_within_year_to_date(1443, 244),  ('09/01/1443'),       'day number 244 within year to date of year 1443 translates to date   9/1/1443');
is(day_number_within_year_to_date(1443, 274),  ('10/01/1443'),       'day number 274 within year to date of year 1443 translates to date  10/1/1443');
is(day_number_within_year_to_date(1443, 305),  ('11/01/1443'),       'day number 305 within year to date of year 1443 translates to date  11/1/1443');
is(day_number_within_year_to_date(1443, 335),  ('12/01/1443'),       'day number 335 within year to date of year 1443 translates to date  12/1/1443');
is(day_number_within_year_to_date(-4,    31),    ('01/31/-4'),       'day number  31 within year to date of year -4   translates to date    1/31/-4');
is(day_number_within_year_to_date(-4,    60),    ('02/29/-4'),       'day number  60 within year to date of year -4   translates to date    2/29/-4');
is(day_number_within_year_to_date(-4,    91),    ('03/31/-4'),       'day number  91 within year to date of year -4   translates to date    3/31/-4');
is(day_number_within_year_to_date(-4,   121),    ('04/30/-4'),       'day number 121 within year to date of year -4   translates to date    4/30/-4');
is(day_number_within_year_to_date(-4,   152),    ('05/31/-4'),       'day number 152 within year to date of year -4   translates to date    5/31/-4');
is(day_number_within_year_to_date(-4,   182),    ('06/30/-4'),       'day number 182 within year to date of year -4   translates to date    6/30/-4');
is(day_number_within_year_to_date(-4,   213),    ('07/31/-4'),       'day number 213 within year to date of year -4   translates to date    7/31/-4');
is(day_number_within_year_to_date(-4,   244),    ('08/31/-4'),       'day number 244 within year to date of year -4   translates to date    8/31/-4');
is(day_number_within_year_to_date(-4,   274),    ('09/30/-4'),       'day number 274 within year to date of year -4   translates to date    9/30/-4');
is(day_number_within_year_to_date(-4,   305),    ('10/31/-4'),       'day number 305 within year to date of year -4   translates to date   10/31/-4');
is(day_number_within_year_to_date(-4,   335),    ('11/30/-4'),       'day number 335 within year to date of year -4   translates to date   11/30/-4');
is(day_number_within_year_to_date(-4,   366),    ('12/31/-4'),       'day number 366 within year to date of year -4   translates to date   12/31/-4');
is(day_number_within_year_to_date(2004,   1),  ('01/01/2004'),       'day number   1 within year to date of year 2004 translates to date   1/1/2004');
is(day_number_within_year_to_date(2004,  32),  ('02/01/2004'),       'day number  32 within year to date of year 2004 translates to date   2/1/2004');
is(day_number_within_year_to_date(2004,  61),  ('03/01/2004'),       'day number  61 within year to date of year 2004 translates to date   3/1/2004');
is(day_number_within_year_to_date(2004,  92),  ('04/01/2004'),       'day number  92 within year to date of year 2004 translates to date   4/1/2004');
is(day_number_within_year_to_date(2004, 122),  ('05/01/2004'),       'day number 122 within year to date of year 2004 translates to date   5/1/2004');
is(day_number_within_year_to_date(2004, 153),  ('06/01/2004'),       'day number 153 within year to date of year 2004 translates to date   6/1/2004');
is(day_number_within_year_to_date(2004, 183),  ('07/01/2004'),       'day number 183 within year to date of year 2004 translates to date   7/1/2004');
is(day_number_within_year_to_date(2004, 214),  ('08/01/2004'),       'day number 214 within year to date of year 2004 translates to date   8/1/2004');
is(day_number_within_year_to_date(2004, 245),  ('09/01/2004'),       'day number 245 within year to date of year 2004 translates to date   9/1/2004');
is(day_number_within_year_to_date(2004, 275),  ('10/01/2004'),       'day number 275 within year to date of year 2004 translates to date  10/1/2004');
is(day_number_within_year_to_date(2004, 306),  ('11/01/2004'),       'day number 306 within year to date of year 2004 translates to date  11/1/2004');
is(day_number_within_year_to_date(2004, 336),  ('12/01/2004'),       'day number 336 within year to date of year 2004 translates to date  12/1/2004');
is(day_number_within_year_to_date(0,      1),     ('01/01/0'),       'day number   1 within year to date of year 0    translates to date      1/1/0');
is(day_number_within_year_to_date(0,     32),     ('02/01/0'),       'day number  32 within year to date of year 0    translates to date      2/1/0');
is(day_number_within_year_to_date(0,     61),     ('03/01/0'),       'day number  61 within year to date of year 0    translates to date      3/1/0');
is(day_number_within_year_to_date(0,     92),     ('04/01/0'),       'day number  92 within year to date of year 0    translates to date      4/1/0');
is(day_number_within_year_to_date(0,    122),     ('05/01/0'),       'day number 122 within year to date of year 0    translates to date      5/1/0');
is(day_number_within_year_to_date(0,    153),     ('06/01/0'),       'day number 153 within year to date of year 0    translates to date      6/1/0');
is(day_number_within_year_to_date(0,    183),     ('07/01/0'),       'day number 183 within year to date of year 0    translates to date      7/1/0');
is(day_number_within_year_to_date(0,    214),     ('08/01/0'),       'day number 214 within year to date of year 0    translates to date      8/1/0');
is(day_number_within_year_to_date(0,    245),     ('09/01/0'),       'day number 245 within year to date of year 0    translates to date      9/1/0');
is(day_number_within_year_to_date(0,    275),     ('10/01/0'),       'day number 275 within year to date of year 0    translates to date     10/1/0');
is(day_number_within_year_to_date(0,    306),     ('11/01/0'),       'day number 306 within year to date of year 0    translates to date     11/1/0');
is(day_number_within_year_to_date(0,    336),     ('12/01/0'),       'day number 336 within year to date of year 0    translates to date     12/1/0');
