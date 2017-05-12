# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 28;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_400_year_cycle);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



is(is_valid_400_year_cycle('2004 '),       '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(2004.7),        '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(''),            '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle([1998]),        '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle({}),            '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle('Feb', 1941),   '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(),              '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-901),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-900),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-899),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-1),            '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(1),             '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(1566),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(2037),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(1924),          '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(67789),         '',       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-24800),         1,       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(-1200),          1,       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(0),              1,       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(1600),           1,       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(2000),           1,       'is_valid_400_year_cycle');
is(is_valid_400_year_cycle(64000),          1,       'is_valid_400_year_cycle');
