# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 30;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_global_year_cycle);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_global_year_cycle(57.5)};
ok(($@),      'Fractional years are NOT allowed');

eval {get_global_year_cycle('1942AD')};
ok(($@),      'Units with year are NOT allowed');

eval {get_global_year_cycle('12/31/2007',   57)};
ok(($@),      'Extra parameters are NOT allowed');

eval {get_global_year_cycle('-17 ')};
ok(($@),      'No leading or trailing spaces allowed');

eval {get_global_year_cycle('')};
ok(($@),      'Null input NOT allowed');

eval {get_global_year_cycle([])};
ok(($@),      'Array references are NOT allowed');

eval {get_global_year_cycle({})};
ok(($@),      'Hash references are NOT allowed');





is(get_global_year_cycle(-17),           -400,             'year  -17 is in the  -400 four hundred year cycle');
is(get_global_year_cycle(-801),         -1200,             'year -801 is in the -1200 four hundred year cycle');
is(get_global_year_cycle(-800),          -800,             'year -800 is in the  -800 four hundred year cycle');
is(get_global_year_cycle(-799),          -800,             'year -799 is in the  -800 four hundred year cycle');
is(get_global_year_cycle(-1),            -400,             'year   -1 is in the  -400 four hundred year cycle');
is(get_global_year_cycle(0),                0,             'year    0 is in the     0 four hundred year cycle');
is(get_global_year_cycle(1),                0,             'year    1 is in the     0 four hundred year cycle');
is(get_global_year_cycle(1899),          1600,             'year 1899 is in the  1600 four hundred year cycle');
is(get_global_year_cycle(1900),          1600,             'year 1900 is in the  1600 four hundred year cycle');
is(get_global_year_cycle(1901),          1600,             'year 1901 is in the  1600 four hundred year cycle');
is(get_global_year_cycle(1999),          1600,             'year 1999 is in the  1600 four hundred year cycle');
is(get_global_year_cycle(2000),          2000,             'year 2000 is in the  2000 four hundred year cycle');
is(get_global_year_cycle(2001),          2000,             'year 2001 is in the  2000 four hundred year cycle');
is(get_global_year_cycle(1999),          1600,             'year 1999 is in the  1600 four hundred year cycle');
is(get_global_year_cycle(2000),          2000,             'year 2000 is in the  2000 four hundred year cycle');
is(get_global_year_cycle(2001),          2000,             'year 2001 is in the  2000 four hundred year cycle');
is(get_global_year_cycle(1937),          1600,             'year 1937 is in the  1600 four hundred year cycle');
