# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 60;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_year_phase);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_year_phase()};
ok(($@),      'Parameters are missing.');

eval {get_year_phase('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {get_year_phase(['7'])};
ok(($@),      'Array reference is not allowed.');

eval {get_year_phase({})};
ok(($@),      'Hash reference is not allowed.');

eval {get_year_phase(' 2')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {get_year_phase('5/7/1922')};
ok(($@),      'Date string is NOT allowed.');

eval {get_year_phase(1966.66)};
ok(($@),      'Fractional year is NOT allowed.');



is(get_year_phase(1900),       300, 'year 1900 is year phase 300');
is(get_year_phase(1904),       304, 'year 1904 is year phase 304');
is(get_year_phase(1990),       390, 'year 1990 is year phase 390');
is(get_year_phase(1999),       399, 'year 1999 is year phase 399');
is(get_year_phase(2000),         0, 'year 2000 is year phase   0');
is(get_year_phase(2001),         1, 'year 2001 is year phase   1');
is(get_year_phase(2002),         2, 'year 2002 is year phase   2');
is(get_year_phase(2003),         3, 'year 2003 is year phase   3');
is(get_year_phase(2004),         4, 'year 2004 is year phase   4');
is(get_year_phase(2005),         5, 'year 2005 is year phase   5');
is(get_year_phase(2010),        10, 'year 2010 is year phase  10');
is(get_year_phase(2099),        99, 'year 2099 is year phase  99');
is(get_year_phase(2100),       100, 'year 2100 is year phase 100');
is(get_year_phase(2101),       101, 'year 2101 is year phase 101');
is(get_year_phase(2199),       199, 'year 2199 is year phase 199');
is(get_year_phase(2200),       200, 'year 2200 is year phase 200');
is(get_year_phase(2201),       201, 'year 2201 is year phase 201');
is(get_year_phase(2299),       299, 'year 2299 is year phase 299');
is(get_year_phase(2300),       300, 'year 2300 is year phase 300');
is(get_year_phase(2301),       301, 'year 2301 is year phase 301');
is(get_year_phase(2399),       399, 'year 2399 is year phase 399');
is(get_year_phase(2400),         0, 'year 2400 is year phase   0');
is(get_year_phase(2401),         1, 'year 2401 is year phase   1');
is(get_year_phase(-801),       399, 'year -801 is year phase 399');
is(get_year_phase(-800),         0, 'year -800 is year phase   0');
is(get_year_phase(-799),         1, 'year -799 is year phase   1');
is(get_year_phase(-101),       299, 'year -101 is year phase 299');
is(get_year_phase(-100),       300, 'year -100 is year phase 300');
is(get_year_phase( -99),       301, 'year  -99 is year phase 301');
is(get_year_phase(  -5),       395, 'year   -5 is year phase 395');
is(get_year_phase(  -4),       396, 'year   -4 is year phase 396');
is(get_year_phase(  -3),       397, 'year   -3 is year phase 397');
is(get_year_phase(  -2),       398, 'year   -2 is year phase 398');
is(get_year_phase(  -1),       399, 'year   -1 is year phase 399');
is(get_year_phase(   0),         0, 'year    0 is year phase   0');
is(get_year_phase(   1),         1, 'year    1 is year phase   1');
is(get_year_phase(   2),         2, 'year    2 is year phase   2');
is(get_year_phase(   3),         3, 'year    3 is year phase   3');
is(get_year_phase(   4),         4, 'year    4 is year phase   4');
is(get_year_phase(   5),         5, 'year    5 is year phase   5');
is(get_year_phase(   6),         6, 'year    6 is year phase   6');
is(get_year_phase( 300),       300, 'year  300 is year phase 300');
is(get_year_phase( 399),       399, 'year  399 is year phase 399');
is(get_year_phase( 400),         0, 'year  400 is year phase   0');
is(get_year_phase( 401),         1, 'year  401 is year phase   1');
is(get_year_phase(2017),        17, 'year 2017 is year phase  17');
is(get_year_phase(2052),        52, 'year 2052 is year phase  52');
