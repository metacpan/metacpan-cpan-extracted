# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 63;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(year1_to_year2_delta);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {year1_to_year2_delta('4/11/2002,   12/25/2007')};
ok(($@),      'Two arguments CANNOT be combined into one');

eval {year1_to_year2_delta('whatever')};
ok(($@),      'Invalid parameter');

eval {year1_to_year2_delta([])};
ok(($@),      'Array reference is NOT allowed.');

eval {year1_to_year2_delta({})};
ok(($@),      'Hash reference is NOT allowed.');

eval {year1_to_year2_delta('')};
ok(($@),      'Null reference is NOT allowed.');

eval {year1_to_year2_delta()};
ok(($@),      'TWO date strings are required.');

eval {year1_to_year2_delta('8/15/3003',  '09/11/1336',  '11/16/1001')};
ok(($@),      'TOO many parameters supplied');

eval {year1_to_year2_delta('4/32/2002, 12/25/2007')};
ok(($@),      'Invalid day of month');

eval {year1_to_year2_delta({}, '12/25/2007')};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {year1_to_year2_delta('12/25/2007', [])};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {year1_to_year2_delta('', '12/25/2007')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {year1_to_year2_delta('12/25/2007', '')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {year1_to_year2_delta('13/25/2007', '9.7.3000')};
ok(($@),      'Date CANNOT be parsed.');

eval {year1_to_year2_delta('12/25/2007', '9.0.3000')};
ok(($@),      'Date CANNOT be parsed.');






is(year1_to_year2_delta('4/11/2002',                 '12/25/2007'),                        -5,          '4/11/2002                     -    12/25/2007                =       -5   whole year(s)');
is(year1_to_year2_delta('12/25/2007',                '4/11/2002'),                          5,          '12/25/2007                    -    4/11/2002                 =        5   whole year(s)');
is(year1_to_year2_delta('7/22/1952',                 '07/22/1952'),                         0,          '7/22/1952                     -    07/22/1952                =        0   whole year(s)');
is(year1_to_year2_delta('Tue Feb 23 08:50:51 -300',  'Tue Feb 29 08:50:51 2000'),       -2300,          'Tue Feb 23 08:50:51 -300      -    Tue Feb 29 08:50:51 2000  =    -2300   whole year(s)');
is(year1_to_year2_delta('Fri May 18 08:50:51 1387',  'Wed Feb 23 08:50:51 1555'),        -167,          'Fri May 18 08:50:51 1387      -    Wed Feb 23 08:50:51 1555  =     -167   whole year(s)');
is(year1_to_year2_delta('Mon Jul 12 08:50:51 2055',  'Wed Feb  7 08:50:51  -27'),        2082,          'Mon Jul 12 08:50:51 2055      -    Wed Feb  7 08:50:51  -27  =     2082   whole year(s)');
is(year1_to_year2_delta('Fri Jan  1 08:50:51   -1',  'Fri Jan  1 08:50:51   -1'),           0,          'Fri Jan  1 08:50:51   -1      -    Fri Jan  1 08:50:51   -1  =        0   whole year(s)');
is(year1_to_year2_delta('Mon Jan  1 08:50:51    1',  'Sat Jan  1 08:50:51    0'),           1,          'Mon Jan  1 08:50:51    1      -    Sat Jan  1 08:50:51    0  =        1   whole year(s)');
is(year1_to_year2_delta('Sat Jan  1 08:50:51    0',  'Fri Jan  1 08:50:51   -1'),           1,          'Sat Jan  1 08:50:51    0      -    Fri Jan  1 08:50:51   -1  =        1   whole year(s)');
is(year1_to_year2_delta('Fri Jan  1 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),          -1,          'Fri Jan  1 08:50:51   -1      -    Sat Jan  1 08:50:51    0  =       -1   whole year(s)');
is(year1_to_year2_delta('Sat Jan  1 08:50:51    0',  'Mon Jan  1 08:50:51    1'),          -1,          'Sat Jan  1 08:50:51    0      -    Mon Jan  1 08:50:51    1  =       -1   whole year(s)');
is(year1_to_year2_delta('Tue Feb 29 08:50:51 2000',  'Tue Feb 29 08:50:51 2000'),           0,          'Tue Feb 29 08:50:51 2000      -    Tue Feb 29 08:50:51 2000  =        0   whole year(s)');
is(year1_to_year2_delta('Fri Dec 31 08:50:51   -1',  'Sat Jan  1 08:50:51    0'),           0,          'Fri Dec 31 08:50:51   -1      -    Sat Jan  1 08:50:51    0  =        0   whole year(s)');
is(year1_to_year2_delta('Sun Dec 31 08:50:51    0',  'Mon Jan  1 08:50:51    1'),           0,          'Sun Dec 31 08:50:51    0      -    Mon Jan  1 08:50:51    1  =        0   whole year(s)');


# Test NON Leap Year boundary condition
is(year1_to_year2_delta('6/07/1999',    '6/06/1998'),                                       1,          '6/07/1999                     -    6/06/1998                 =        1   whole year(s)');
is(year1_to_year2_delta('6/07/1999',    '6/07/1998'),                                       1,          '6/07/1999                     -    6/07/1998                 =        1   whole year(s)');
is(year1_to_year2_delta('6/07/1999',    '6/08/1998'),                                       0,          '6/07/1999                     -    6/08/1998                 =        0   whole year(s)');

is(year1_to_year2_delta('11/17/2012',  '11/16/2013'),                                       0,          '11/17/2012                    -   11/16/2013                 =        0   whole year(s)');
is(year1_to_year2_delta('11/17/2012',  '11/17/2013'),                                      -1,          '11/17/2012                    -   11/17/2013                 =       -1   whole year(s)');
is(year1_to_year2_delta('11/17/2012',  '11/18/2013'),                                      -1,          '11/17/2012                    -   11/18/2013                 =       -1   whole year(s)');

is(year1_to_year2_delta('04/03/-458',  '04/02/-457'),                                       0,          '04/03/-458                    -   04/02/-457                 =        0   whole year(s)');
is(year1_to_year2_delta('04/03/-458',  '04/03/-457'),                                      -1,          '04/03/-458                    -   04/03/-457                 =       -1   whole year(s)');
is(year1_to_year2_delta('04/03/-458',  '04/04/-457'),                                      -1,          '04/03/-458                    -   04/04/-457                 =       -1   whole year(s)');

is(year1_to_year2_delta('3/19/1993',  '7/15/1988'),                                         4,          '3/19/1993                     -   7/15/1988                  =       -1   whole year(s)');



# Test Leap Year Boundary Condition
is(year1_to_year2_delta('2/28/1996',  '2/28/1995'),                                         0,          '2/28/1996                     -   2/28/1995                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1996',  '2/28/1995'),                                         1,          '2/29/1996                     -   2/28/1995                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1996',  '2/28/1999'),                                        -3,          '2/29/1996                     -   2/28/1999                  =       -3   whole year(s)');
is(year1_to_year2_delta('2/29/1996',  '2/27/1999'),                                        -2,          '2/29/1996                     -   2/27/1999                  =       -3   whole year(s)');

is(year1_to_year2_delta('2/28/1995',  '2/28/1996'),                                         0,          '2/28/1995                     -   2/28/1996                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/28/1995',  '2/29/1996'),                                        -1,          '2/28/1995                     -   2/29/1996                  =       -1   whole year(s)');

is(year1_to_year2_delta('2/28/1994',  '2/28/1995'),                                        -1,          '2/28/1994                     -   2/28/1995                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/28/1995',  '2/28/1994'),                                         1,          '2/28/1995                     -   2/28/1994                  =       -1   whole year(s)');

is(year1_to_year2_delta('2/28/1996',  '2/28/1992'),                                         4,          '2/28/1996                     -   2/28/1992                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1996',  '2/28/1992'),                                         4,          '2/29/1996                     -   2/28/1992                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/28/1996',  '2/29/1992'),                                         3,          '2/28/1996                     -   2/29/1992                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1996',  '2/29/1992'),                                         4,          '2/29/1996                     -   2/29/1992                  =       -1   whole year(s)');

is(year1_to_year2_delta('2/28/1992',  '2/28/1996'),                                        -4,          '2/28/1992                     -   2/28/1996                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1992',  '2/28/1996'),                                        -3,          '2/29/1992                     -   2/28/1996                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/28/1992',  '2/29/1996'),                                        -4,          '2/28/1992                     -   2/29/1996                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/29/1992',  '2/29/1996'),                                        -4,          '2/29/1992                     -   2/29/1996                  =       -1   whole year(s)');


is(year1_to_year2_delta('2/28/1992',  '2/27/1989'),                                         3,          '2/28/1992                     -   2/27/1989                  =       -1   whole year(s)');


is(year1_to_year2_delta('2/28/1993',  '2/29/1988'),                                         5,          '2/28/1993                     -   2/29/1988                  =       -1   whole year(s)');
is(year1_to_year2_delta('2/28/1993',  '2/28/1988'),                                         5,          '2/28/1993                     -   2/28/1988                  =       -1   whole year(s)');
