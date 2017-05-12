# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 54;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_num_days_in_year);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_num_days_in_year()};
ok(($@),      'Parameters are missing.');

eval {get_num_days_in_year('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {get_num_days_in_year(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {get_num_days_in_year({})};
ok(($@),      'Hash reference is not allowed.');

eval {get_num_days_in_year(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {get_num_days_in_year('5/7/1922')};
ok(($@),      'Date string is NOT allowed.');

eval {get_num_days_in_year(4067.66)};
ok(($@),      'Fractional year is NOT allowed.');



is(get_num_days_in_year(1900), 365, 'year 1900 has 365 days');
is(get_num_days_in_year(1904), 366, 'year 1904 has 366 days');
is(get_num_days_in_year(1990), 365, 'year 1990 has 365 days');
is(get_num_days_in_year(1999), 365, 'year 1999 has 365 days');
is(get_num_days_in_year(2000), 366, 'year 2000 has 366 days');
is(get_num_days_in_year(2001), 365, 'year 2001 has 365 days');
is(get_num_days_in_year(2002), 365, 'year 2002 has 365 days');
is(get_num_days_in_year(2003), 365, 'year 2003 has 365 days');
is(get_num_days_in_year(2004), 366, 'year 2004 has 366 days');
is(get_num_days_in_year(2005), 365, 'year 2005 has 365 days');
is(get_num_days_in_year(2010), 365, 'year 2010 has 365 days');
is(get_num_days_in_year(2099), 365, 'year 2099 has 365 days');
is(get_num_days_in_year(2100), 365, 'year 2100 has 365 days');
is(get_num_days_in_year(2101), 365, 'year 2101 has 365 days');
is(get_num_days_in_year(2199), 365, 'year 2199 has 365 days');
is(get_num_days_in_year(2200), 365, 'year 2200 has 365 days');
is(get_num_days_in_year(2201), 365, 'year 2201 has 365 days');
is(get_num_days_in_year(2299), 365, 'year 2299 has 365 days');
is(get_num_days_in_year(2300), 365, 'year 2300 has 365 days');
is(get_num_days_in_year(2301), 365, 'year 2301 has 365 days');
is(get_num_days_in_year(2399), 365, 'year 2399 has 365 days');
is(get_num_days_in_year(2400), 366, 'year 2400 has 366 days');
is(get_num_days_in_year(2401), 365, 'year 2401 has 365 days');
is(get_num_days_in_year(-800), 366, 'year -800 has 366 days');
is(get_num_days_in_year(-100), 365, 'year -100 has 365 days');
is(get_num_days_in_year(  -5), 365, 'year   -5 has 365 days');
is(get_num_days_in_year(  -4), 366, 'year   -4 has 366 days');
is(get_num_days_in_year(  -3), 365, 'year   -3 has 365 days');
is(get_num_days_in_year(  -2), 365, 'year   -2 has 365 days');
is(get_num_days_in_year(  -1), 365, 'year   -1 has 365 days');
is(get_num_days_in_year(   0), 366, 'year    0 has 366 days');
is(get_num_days_in_year(   1), 365, 'year    1 has 365 days');
is(get_num_days_in_year(   2), 365, 'year    2 has 365 days');
is(get_num_days_in_year(   3), 365, 'year    3 has 365 days');
is(get_num_days_in_year(   4), 366, 'year    4 has 366 days');
is(get_num_days_in_year(   5), 365, 'year    5 has 365 days');
is(get_num_days_in_year(   6), 365, 'year    6 has 365 days');
is(get_num_days_in_year( 300), 365, 'year  300 has 365 days');
is(get_num_days_in_year( 400), 366, 'year  400 has 366 days');
ok(get_num_days_in_year(2017) == 365, 'year 2017 has 365 days');
ok(get_num_days_in_year(2052) == 366, 'year 2052 has 366 days');
