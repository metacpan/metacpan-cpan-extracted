# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 40;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(date_offset_in_years);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {date_offset_in_years('Mon Aug  3 08:50:51 1931',  )};
ok(($@),      'Missing second parameter');

eval {date_offset_in_years('Tue Aug  3 08:50:51 1931',16)};
ok(($@),      'Invalid date, Monday is the correct day of week');

eval {date_offset_in_years('06/32/2005', 0)};
ok(($@),      'invalid day of month');

eval {date_offset_in_years('4/25/1776', 7.8)};
ok(($@),      'year offset must be an integer');

eval {date_offset_in_years('', 6)};
ok(($@),      'empty date');

eval {date_offset_in_years([])};
ok(($@),      'Array reference NOT allowed.');

eval {date_offset_in_years({})};
ok(($@),      'Hash reference NOT allowed.');



eval {date_offset_in_years({}, -76)};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {date_offset_in_years('9/8/4777', [])};
ok(($@),      'SCALAR value for delta years is REQUIRED.');

eval {date_offset_in_years('9/8/4777', '')};
ok(($@),      'NULL value for delta years is NOT allowed.');






is(date_offset_in_years('Mon Aug  3 08:50:51 1931',     16),  '08/03/1947',     'date Mon Aug  3 08:50:51 1931 offset    16 years is 08/03/1947');

is(date_offset_in_years('06/5/-3001',                    0),  '06/05/-3001',    'date 06/5/-3001               offset     0 years is 06/05/-3001');
is(date_offset_in_years('12/31/-401',                  376),  '12/31/-25',      'date 12/31/-401               offset   376 years is 12/31/-25  ');
is(date_offset_in_years('1/1/0',                       -59),  '01/01/-59',      'date 1/1/0                    offset   -59 years is 01/01/-59  ');
is(date_offset_in_years('12/30/1999',                    1),  '12/30/2000',     'date 12/30/1999               offset     1 years is 12/30/2000 ');
is(date_offset_in_years('12/31/1999',                   -1),  '12/31/1998',     'date 12/31/1999               offset    -1 years is 12/31/1998 ');
is(date_offset_in_years('12/30/1999',                   83),  '12/30/2082',     'date 12/30/1999               offset    83 years is 12/30/2082 ');
is(date_offset_in_years('1/4/1841',                  -2003),  '01/04/-162',     'date 1/4/1841                 offset -2003 years is 01/04/-162 ');





#  2/28  leap      to leap        forward
#  2/29  leap      to leap        forward
#  2/27  NONleap   to leap        forward
#  2/28  NONleap   to leap        forward

#  2/28  leap      to NONleap     forward
#  2/29  leap      to NONleap     forward
#  2/27  NONleap   to NONleap     forward
#  2/28  NONleap   to NONleap     forward

#  2/28  leap      to leap        backward
#  2/29  leap      to leap        backward
#  2/27  NONleap   to leap        backward
#  2/28  NONleap   to leap        backward

#  2/28  leap      to NONleap     backward
#  2/29  leap      to NONleap     backward
#  2/27  NONleap   to NONleap     backward
#  2/28  NONleap   to NONleap     backward

is(date_offset_in_years('2/28/1780',  8),  '02/28/1788',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/29/1780',  8),  '02/29/1788',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/27/1779',  9),  '02/27/1788',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/28/1779',  9),  '02/29/1788',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');

is(date_offset_in_years('2/28/1780',  7),  '02/28/1787',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/29/1780',  7),  '02/28/1787',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/27/1779',  8),  '02/27/1787',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/28/1779',  8),  '02/28/1787',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');



is(date_offset_in_years('2/28/1780', -8),  '02/28/1772',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/29/1780', -8),  '02/29/1772',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/27/1779', -7),  '02/27/1772',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/28/1779', -7),  '02/29/1772',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');

is(date_offset_in_years('2/28/1780', -7),  '02/28/1773',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/29/1780', -7),  '02/28/1773',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/27/1779', -6),  '02/27/1773',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
is(date_offset_in_years('2/28/1779', -6),  '02/28/1773',     'date 2/28/1781                offset   443 years is 02/29/2224 (Feb 28 NON leap year is mapped to Feb 29 leap year) ');
