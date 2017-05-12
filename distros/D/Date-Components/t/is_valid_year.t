# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 37;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_year);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



is(is_valid_year('Whatever'),     '',      'year is obviously invalid');
is(is_valid_year('1900 '),        '',      'year is obviously invalid');
is(is_valid_year(' 2005'),        '',      'year is obviously invalid');
is(is_valid_year(' 1962 '),       '',      'year is obviously invalid');
is(is_valid_year(' -1775'),       '',      'year is obviously invalid');
is(is_valid_year('Nov'),          '',      'year is obviously invalid');
is(is_valid_year('October'),      '',      'year is obviously invalid');
is(is_valid_year('Thur'),         '',      'year is obviously invalid');
is(is_valid_year(' Fri'),         '',      'year is obviously invalid');
is(is_valid_year('Sat '),         '',      'year is obviously invalid');
is(is_valid_year(' Sun '),        '',      'year is obviously invalid');
is(is_valid_year('Wednesdayy'),   '',      'year is obviously invalid');
is(is_valid_year('e Monday'),     '',      'year is obviously invalid');
is(is_valid_year({}),             '',      'year is obviously invalid');
is(is_valid_year([]),             '',      'year is obviously invalid');
is(is_valid_year(''),             '',      'year is obviously invalid');
is(is_valid_year(),               '',      'year is obviously invalid');
is(is_valid_year('2007', '2008'), '',      'year is obviously invalid');
is(is_valid_year('2007.55'),      '',      'year is obviously invalid');
is(is_valid_year('-1600 BC'),     '',      'year is obviously invalid');
is(is_valid_year('785AD'),        '',      'year is obviously invalid');
is(is_valid_year('-2020'),         1,      'year   -2020    is obviously valid');
is(is_valid_year('-33'),           1,      'year     -33    is obviously valid');
is(is_valid_year('-1'),            1,      'year      -1    is obviously valid');
is(is_valid_year('0'),             1,      'year       0    is obviously valid');
is(is_valid_year(15),              1,      'year      15    is obviously valid');
is(is_valid_year('1300'),          1,      'year    1300    is obviously valid');
is(is_valid_year(1457),            1,      'year    1457    is obviously valid');
is(is_valid_year(1999),            1,      'year    1999    is obviously valid');
is(is_valid_year('2642'),          1,      'year    2642    is obviously valid');
is(is_valid_year(0),               1,      'year       0    is obviously valid');
