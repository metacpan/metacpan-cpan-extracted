# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 35;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(compare_date1_and_date2);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



eval {compare_date1_and_date2('4/11/2002,                   12/25/2007')};
ok(($@),      'Two parameters CANNOT be combined into one string');

eval {compare_date1_and_date2('whatever')};
ok(($@),      'TWO date string parameters are required');

eval {compare_date1_and_date2()};
ok(($@),      '<null>  is invalid input.  TWO date string parameters are required');

eval {compare_date1_and_date2([])};
ok(($@),      'Array ref is NOT an allowed parameter type');

eval {compare_date1_and_date2({})};
ok(($@),      'Hash ref is NOT an allowed parameter type');

eval {compare_date1_and_date2('8/15/3003',  '09/11/1336',  '11/16/1001')};
ok(($@),      'Only TWO date string parameters are required');

eval {compare_date1_and_date2('4/32/2002,                   12/25/2007')};
ok(($@),      'Number of days in a month CANNOT exceed 31');

eval {compare_date1_and_date2({},                   '12/25/2007')};
ok(($@),      'Only SCALAR parameters are allowed.');

eval {compare_date1_and_date2('4/22/2002',                   [])};
ok(($@),      'Only SCALAR parameters are allowed.');

eval {compare_date1_and_date2('',                   '12/25/2007')};
ok(($@),      'NULL parameters are NOT allowed.');

eval {compare_date1_and_date2('4/22/2002',                   '')};
ok(($@),      'NULL parameters are NOT allowed.');

eval {compare_date1_and_date2('4/32/2002',                   '12/25/2007')};
ok(($@),      'Dates with out of range paramters do NOT parse');

eval {compare_date1_and_date2('4/22/2002',                   '0/25/2007')};
ok(($@),      'Dates with out of range paramters do NOT parse');






is(compare_date1_and_date2('11/2/1482',                 '12/16/1482'),                  '-1',          '11/2/1482                <  12/16/1482');
is(compare_date1_and_date2('12/16/1482',                 '11/2/1482'),                   '1',          '12/16/1482               <  11/2/1482');
is(compare_date1_and_date2('4/11/2002',                 '12/25/2007'),                 '-1',          ' 4/11/2002                <   12/25/2007');
is(compare_date1_and_date2('12/25/2007',                '4/11/2002'),                     1,          '12/25/2007                >    4/11/2002');
is(compare_date1_and_date2('7/22/1952',                 '07/22/1952'),                  '0',          ' 7/22/1952                ==  07/22/1952');
is(compare_date1_and_date2('Tue Feb 23 08:50:51 -300',  'Tue Feb 29 08:50:51 2000'),   '-1',          'Tue Feb 23 08:50:51 -300  <   Tue Feb 29 08:50:51 2000');
is(compare_date1_and_date2('Fri May 18 08:50:51 1387',  'Wed Feb 23 08:50:51 1555'),   '-1',          'Fri May 18 08:50:51 1387  <   Wed Feb 23 08:50:51 1555');
is(compare_date1_and_date2('Mon Jul 12 08:50:51 2055',  'Wed Feb  7 08:50:51  -27'),      1,          'Mon Jul 12 08:50:51 2055  >   Wed Feb  7 08:50:51  -27');
is(compare_date1_and_date2('Fri Jan  1 08:50:51   -1',  'Fri Jan  1 08:50:51   -1'),    '0',          'Fri Jan  1 08:50:51   -1  ==  Fri Jan  1 08:50:51   -1');
is(compare_date1_and_date2('Mon Jan  1 08:50:51    1',  'Sat Jan  1 08:50:51    0'),      1,          'Mon Jan  1 08:50:51    1  >   Sat Jan  1 08:50:51    0');
is(compare_date1_and_date2('Sat Jan  1 08:50:51    0',  'Fri Jan  1 08:50:51   -1'),      1,          'Sat Jan  1 08:50:51    0  >   Fri Jan  1 08:50:51   -1');
is(compare_date1_and_date2('Fri Jan  1 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),   '-1',          'Fri Jan  1 08:50:51   -1  <   Sat Jan  1 08:50:51    0');
is(compare_date1_and_date2('Sat Jan  1 08:50:51    0',  'Mon Jan  1 08:50:51    1'),   '-1',          'Sat Jan  1 08:50:51    0  <   Mon Jan  1 08:50:51    1');
is(compare_date1_and_date2('Tue Feb 29 08:50:51 2000',  'Tue Feb 29 08:50:51 2000'),    '0',          'Tue Feb 29 08:50:51 2000  ==  Tue Feb 29 08:50:51 2000');
is(compare_date1_and_date2('Fri Dec 31 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),   '-1',          'Fri Jan  1 08:50:51   -1  <   Sat Jan  1 08:50:51    0');
is(compare_date1_and_date2('Sun Dec 31 08:50:51    0',  'Mon Jan  1 08:50:51    1'),   '-1',          'Sat Jan  1 08:50:51    0  <   Mon Jan  1 08:50:51    1');
