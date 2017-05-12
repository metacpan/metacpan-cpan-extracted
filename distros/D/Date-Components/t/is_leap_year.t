# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 59;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_leap_year);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {is_leap_year()};
ok(($@),      'ONE and ONLY ONE parameter must be given, the year');

eval {is_leap_year([2004])};
ok(($@),      'Array reference is NOT allowed.');

eval {is_leap_year({})};
ok(($@),      'Hash reference is NOT allowed.');

eval {is_leap_year('')};
ok(($@),      'Null parameter is NOT allowed.');

eval {is_leap_year(' 1990')};
ok(($@),      'Leading and trailing spaces are not allowed');

eval {is_leap_year(1742.9)};
ok(($@),      'Fractional years are not allowed.');

eval {is_leap_year('2/4/1666')};
ok(($@),      'Date strings are NOT allowed.  Only a year number is allowed.');

eval {is_leap_year(56, 77)};
ok(($@),      'More than one parameter is NOT allowed.');




is(is_leap_year((54 + 76)),     '',      'year  130 has 365    days');
is(is_leap_year(1900),          '',      'year 1900 has 365    days');
is(is_leap_year(1904),          'yes',   'year 1904 has 366    days and is a leap year');
is(is_leap_year(1990),          '',      'year 1990 has 365    days');
is(is_leap_year(1999),          '',      'year 1999 has 365    days');
is(is_leap_year(2000),          'yes',   'year 2000 has 366    days and is a leap year');
is(is_leap_year(2001),          '',      'year 2001 has 365    days');
is(is_leap_year(2002),          '',      'year 2002 has 365    days');
is(is_leap_year(2003),          '',      'year 2003 has 365    days');
is(is_leap_year(2004),          'yes',   'year 2004 has 366    days and is a leap year');
is(is_leap_year(2005),          '',      'year 2005 has 365    days');
is(is_leap_year(2010),          '',      'year 2010 has 365    days');
is(is_leap_year(2099),          '',      'year 2099 has 365    days');
is(is_leap_year(2100),          '',      'year 2100 has 365    days');
is(is_leap_year(2101),          '',      'year 2101 has 365    days');
is(is_leap_year(2199),          '',      'year 2199 has 365    days');
is(is_leap_year(2200),          '',      'year 2200 has 365    days');
is(is_leap_year(2201),          '',      'year 2201 has 365    days');
is(is_leap_year(2299),          '',      'year 2299 has 365    days');
is(is_leap_year(2300),          '',      'year 2300 has 365    days');
is(is_leap_year(2301),          '',      'year 2301 has 365    days');
is(is_leap_year(2399),          '',      'year 2399 has 365    days');
is(is_leap_year(2400),          'yes',   'year 2400 has 366    days and is a leap year');
is(is_leap_year(2401),          '',      'year 2401 has 365    days');
is(is_leap_year(-800),          'yes',   'year -800 has 366    days and is a leap year');
is(is_leap_year(-100),          '',      'year -100 has 365    days');
is(is_leap_year(-5),            '',      'year   -5 has 365    days');
is(is_leap_year(-4),            'yes',   'year   -4 has 366    days and is a leap year');
is(is_leap_year(-3),            '',      'year   -3 has 365    days');
is(is_leap_year(-2),            '',      'year   -2 has 365    days');
is(is_leap_year(-1),            '',      'year   -1 has 365    days');
is(is_leap_year(0),             'yes',   'year    0 has 366    days and is a leap year');
is(is_leap_year(1),             '',      'year    1 has 365    days');
is(is_leap_year(2),             '',      'year    2 has 365    days');
is(is_leap_year(3),             '',      'year    3 has 365    days');
is(is_leap_year(4),             'yes',   'year    4 has 366    days and is a leap year');
is(is_leap_year(5),             '',      'year    5 has 365    days');
is(is_leap_year(6),             '',      'year    6 has 365    days');
is(is_leap_year(300),           '',      'year 300  has 365    days');
is(is_leap_year(400),           'yes',   'year 400  has 366    days and is a leap year');
ok(is_leap_year(2017)  ne       'yes',   'year 2017 has 365    days');
ok(is_leap_year(2052)  eq       'yes',   'year 2052 has 366    days and is a leap year');
ok(is_leap_year(1947)  eq       '',      'year 1947 has 365    days');
ok(is_leap_year(1960)  ne       '',      'year 1960 has 366    days and is a leap year');
ok(!(is_leap_year(66)),                  'year 66 has 365    days');
