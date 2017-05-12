# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 36;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(compare_year1_and_year2);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {compare_year1_and_year2('4/11/2002,   12/25/2007')};
ok(($@),      'Two arguments CANNOT be combined into one');

eval {compare_year1_and_year2('whatever')};
ok(($@),      'Invalid parameter');

eval {compare_year1_and_year2([])};
ok(($@),      'Array reference is NOT allowed.');

eval {compare_year1_and_year2({})};
ok(($@),      'Hash reference is NOT allowed.');

eval {compare_year1_and_year2('')};
ok(($@),      'Null reference is NOT allowed.');

eval {compare_year1_and_year2()};
ok(($@),      'TWO date strings are required.');

eval {compare_year1_and_year2('8/15/3003',  '09/11/1336',  '11/16/1001')};
ok(($@),      'TOO many parameters supplied');

eval {compare_year1_and_year2('4/32/2002, 12/25/2007')};
ok(($@),      'Two dates CANNOT be combined into one string.');

eval {compare_year1_and_year2({}, '12/25/2007')};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {compare_year1_and_year2('12/25/2007', [])};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {compare_year1_and_year2('', '12/25/2007')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {compare_year1_and_year2('12/25/2007', '')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {compare_year1_and_year2('13/25/2007', '9.7.3000')};
ok(($@),      'Date CANNOT be parsed.');

eval {compare_year1_and_year2('12/25/2007', '9.0.3000')};
ok(($@),      'Date CANNOT be parsed.');





is(compare_year1_and_year2('4/11/2002',                 '12/25/2007'),                 '-1',          ' 4/11/2002                <   12/25/2007');
is(compare_year1_and_year2('12/25/2007',                 '4/11/2002'),                    1,          '12/25/2007                >    4/11/2002');
is(compare_year1_and_year2('7/22/1952',                 '07/22/1952'),                  '0',          ' 7/22/1952                ==  07/22/1952');
is(compare_year1_and_year2('9/23/1967',                   '4/7/1967'),                  '0',          'These years, 9/23/1967 and 4/7/1967, are the same');
is(compare_year1_and_year2('1/7/2004',                  '12/19/2003'),                  '1',          'Year 2004 is greater than year 2003');
is(compare_year1_and_year2('Fri May 18 08:50:51 1387',  'Wed Feb 23 08:50:51 1555'),   '-1',          'Fri May 18 08:50:51 1387  <   Wed Feb 23 08:50:51 1555');
is(compare_year1_and_year2('Tue Feb 23 08:50:51 -300',  'Tue Feb 29 08:50:51 2000'),   '-1',          'Tue Feb 23 08:50:51 -300  <   Tue Feb 29 08:50:51 2000');
is(compare_year1_and_year2('Mon Jul 12 08:50:51 2055',  'Wed Feb  7 08:50:51  -27'),      1,          'Mon Jul 12 08:50:51 2055  >   Wed Feb  7 08:50:51  -27');
is(compare_year1_and_year2('Fri Jan  1 08:50:51   -1',  'Fri Jan  1 08:50:51   -1'),    '0',          'Fri Jan  1 08:50:51   -1  ==  Fri Jan  1 08:50:51   -1');
is(compare_year1_and_year2('Mon Jan  1 08:50:51    1',  'Sat Jan  1 08:50:51    0'),      1,          'Mon Jan  1 08:50:51    1  >   Sat Jan  1 08:50:51    0');
is(compare_year1_and_year2('Sat Jan  1 08:50:51    0',  'Fri Jan  1 08:50:51   -1'),      1,          'Sat Jan  1 08:50:51    0  >   Fri Jan  1 08:50:51   -1');
is(compare_year1_and_year2('Fri Jan  1 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),   '-1',          'Fri Jan  1 08:50:51   -1  <   Sat Jan  1 08:50:51    0');
is(compare_year1_and_year2('Sat Jan  1 08:50:51    0',  'Mon Jan  1 08:50:51    1'),   '-1',          'Sat Jan  1 08:50:51    0  <   Mon Jan  1 08:50:51    1');
is(compare_year1_and_year2('Tue Feb 29 08:50:51 2000',  'Tue Feb 29 08:50:51 2000'),    '0',          'Tue Feb 29 08:50:51 2000  ==  Tue Feb 29 08:50:51 2000');
is(compare_year1_and_year2('Fri Dec 31 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),   '-1',          'Fri Dec 31 08:50:51   -1  <   Sat Jan  1 08:50:51    0');
is(compare_year1_and_year2('Sun Dec 31 08:50:51    0',  'Mon Jan  1 08:50:51    1'),   '-1',          'Sun Dec 31 08:50:51    0  <   Mon Jan  1 08:50:51    1');
