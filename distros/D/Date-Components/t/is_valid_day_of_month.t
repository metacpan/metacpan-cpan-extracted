# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 81;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(is_valid_day_of_month);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
is(is_valid_day_of_month('May', [],    -3),        '',      'Day of month MUST be a SCALAR.');
is(is_valid_day_of_month('May', '',    -3),        '',      'Day of month MUST be a SCALAR.');


is(is_valid_day_of_month( 2,  28,   1559),         1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month( 2,  29,   1559),        '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month( 2,  30,   1555),        '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month( 8, '0',   1555),        '',      'mm/dd/yyyy is a valid day of month');


is(is_valid_day_of_month('Whatever'),    '',      'invalid day of month');
is(is_valid_day_of_month('1900'),        '',      'invalid day of month');
is(is_valid_day_of_month('Sat'),         '',      'invalid day of month');
is(is_valid_day_of_month(0),             '',      'invalid day of month');
is(is_valid_day_of_month('0'),           '',      'invalid day of month');
is(is_valid_day_of_month(' 7'),          '',      'invalid day of month');
is(is_valid_day_of_month('9 '),          '',      'invalid day of month');
is(is_valid_day_of_month(' 11 '),        '',      'invalid day of month');
is(is_valid_day_of_month('-1'),          '',      'invalid day of month');
is(is_valid_day_of_month('13'),          '',      'invalid day of month');
is(is_valid_day_of_month('Friday'),      '',      'invalid day of month');
is(is_valid_day_of_month('Janu'),        '',      'invalid day of month');
is(is_valid_day_of_month(' Feb'),        '',      'invalid day of month');
is(is_valid_day_of_month('Mar '),        '',      'invalid day of month');
is(is_valid_day_of_month(' Apr '),       '',      'invalid day of month');
is(is_valid_day_of_month('Juney'),       '',      'invalid day of month');
is(is_valid_day_of_month('e June'),      '',      'invalid day of month');
is(is_valid_day_of_month('Janu'),        '',      'invalid day of month');
is(is_valid_day_of_month({}),            '',      'invalid day of month');
is(is_valid_day_of_month([]),            '',      'invalid day of month');
is(is_valid_day_of_month(''),            '',      'invalid day of month');
is(is_valid_day_of_month(),              '',      'invalid day of month');
is(is_valid_day_of_month('Feb', 'Mar'),  '',      'invalid day of month');
is(is_valid_day_of_month(-1, 'Jan', 2003),        '',      'invalid day of month');
is(is_valid_day_of_month(3, 'Feb ', 2003),        '',      'invalid day of month');
is(is_valid_day_of_month('6, Jun, 2001'),         '',      'invalid day of month');
is(is_valid_day_of_month(3, 'Marc', 2003),        '',      'invalid day of month');
is(is_valid_day_of_month(3, 'Apr', 2003.7),       '',      'invalid day of month');
is(is_valid_day_of_month(2009, 3, 'May'),         '',      'invalid day of month');
is(is_valid_day_of_month('July', 7),              '',      'invalid day of month');
is(is_valid_day_of_month(32, 'Jan', 2008),        '',      'invalid day of month');
is(is_valid_day_of_month(29, 'Feb', 2001),        '',      'invalid day of month');
is(is_valid_day_of_month('Jan', 32,  1885),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Feb', 30,  1924),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Mar', 32,  1652),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Apr', 31,   602),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('May', 32,    -3),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Jun', 31,     0),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Jul', 32, 50032),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Aug', 32,   107),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Sep', 31, -3699),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Oct', 32,  1999),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Nov', 31,  2400),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Dec', 32,  2401),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Feb', 29,  1925),       '',      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Jan', 31,  1885),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Feb', 29,  1924),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Mar', 31,  1652),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Apr', 30,   602),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('May', 31,    -3),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Jun', 30,     0),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Jul', 31, 50032),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Aug', 31,   107),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Sep', 30, -3699),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Oct', 31,  1999),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Nov', 30,  2400),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('Dec', 31,  2401),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month( 'January', 31,   1165),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(         2, 29,   -456),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(         3, 31,      0),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(   'April', 30,   1401),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(         5, 31,    -17),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(    'June', 30,      0),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(    'July', 31,     32),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(  'August', 31,   1888),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(         9, 30,   2077),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month(        10, 31,    867),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('November', 30,  -1055),        1,      'mm/dd/yyyy is a valid day of month');
is(is_valid_day_of_month('December', 31,   2222),        1,      'mm/dd/yyyy is a valid day of month');
