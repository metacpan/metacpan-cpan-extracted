# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 79;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(number_of_weekdays_in_range);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {number_of_weekdays_in_range('4/11/2002,   12/25/2007')};
ok(($@),      'Two arguments CANNOT be combined into one');

eval {number_of_weekdays_in_range('whatever')};
ok(($@),      'Invalid parameter');

eval {number_of_weekdays_in_range([])};
ok(($@),      'Array reference is NOT allowed.');

eval {number_of_weekdays_in_range({})};
ok(($@),      'Hash reference is NOT allowed.');

eval {number_of_weekdays_in_range('')};
ok(($@),      'Null reference is NOT allowed.');

eval {number_of_weekdays_in_range()};
ok(($@),      'TWO date strings are required.');

eval {number_of_weekdays_in_range('8/15/3003',  '09/11/1336',  '11/16/1001')};
ok(($@),      'TOO many parameters supplied');

eval {number_of_weekdays_in_range('4/32/2002, 12/25/2007')};
ok(($@),      'Invalid day of month');

eval {number_of_weekdays_in_range({}, '12/25/2007')};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {number_of_weekdays_in_range('12/25/2007', [])};
ok(($@),      'SCALAR value for date is REQUIRED.');

eval {number_of_weekdays_in_range('', '12/25/2007')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {number_of_weekdays_in_range('12/25/2007', '')};
ok(($@),      'NULL value for date is NOT allowed.');

eval {number_of_weekdays_in_range('13/25/2007', '9.7.3000')};
ok(($@),      'Date CANNOT be parsed.');

eval {number_of_weekdays_in_range('12/25/2007', '9.0.3000')};
ok(($@),      'Date CANNOT be parsed.');





is(number_of_weekdays_in_range('Thu Jul 10 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),   -1,                                             'number of week days from Thu Jul 10 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is  -1                                 ');
is(number_of_weekdays_in_range('Fri Jul 11 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),    0,                                             'number of week days from Fri Jul 11 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is   0                                 ');
is(number_of_weekdays_in_range('Sat Jul 12 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),    0,                                             'number of week days from Sat Jul 12 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is   0                                 ');
is(number_of_weekdays_in_range('Sun Jul 13 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),    0,                                             'number of week days from Sun Jul 13 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is   0                                 ');
is(number_of_weekdays_in_range('Mon Jul 14 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),    1,                                             'number of week days from Mon Jul 14 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is   1                                 ');
is(number_of_weekdays_in_range('Tue Jul 15 08:50:51 2003',     'Fri Jul 11 08:50:51 2003'),    2,                                             'number of week days from Tue Jul 15 08:50:51 2003   to Fri Jul 11 08:50:51 2003 is   2                                 ');











is(number_of_weekdays_in_range('10/22/2007',                                 '10/05/2007'),   11,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/06/2007'),   11,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/07/2007'),   11,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/08/2007'),   10,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/09/2007'),    9,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/10/2007'),    8,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/11/2007'),    7,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/12/2007'),    6,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/13/2007'),    6,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/14/2007'),    6,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/15/2007'),    5,                                             'number of week days from 10/22/2007                 to               10/15/2007 is    5                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/16/2007'),    4,                                             'number of week days from 10/22/2007                 to               10/16/2007 is    4                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/17/2007'),    3,                                             'number of week days from 10/22/2007                 to               10/17/2007 is    3                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/18/2007'),    2,                                             'number of week days from 10/22/2007                 to               10/18/2007 is    2                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/19/2007'),    1,                                             'number of week days from 10/22/2007                 to               10/19/2007 is    1                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/20/2007'),    1,                                             'number of week days from 10/22/2007                 to               10/20/2007 is    1                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/21/2007'),    1,                                             'number of week days from 10/22/2007                 to               10/21/2007 is    1                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/22/2007'),    0,                                             'number of week days from 10/22/2007                 to               10/22/2007 is    0                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/23/2007'),   -1,                                             'number of week days from 10/22/2007                 to               10/23/2007 is   -1                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/24/2007'),   -2,                                             'number of week days from 10/22/2007                 to               10/24/2007 is   -2                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/25/2007'),   -3,                                             'number of week days from 10/22/2007                 to               10/25/2007 is   -3                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/26/2007'),   -4,                                             'number of week days from 10/22/2007                 to               10/26/2007 is   -4                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/27/2007'),   -5,                                             'number of week days from 10/22/2007                 to               10/27/2007 is   -5                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/28/2007'),   -5,                                             'number of week days from 10/22/2007                 to               10/28/2007 is   -5                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/29/2007'),   -5,                                             'number of week days from 10/22/2007                 to               10/29/2007 is   -5                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/30/2007'),   -6,                                             'number of week days from 10/22/2007                 to               10/30/2007 is   -6                                ');
is(number_of_weekdays_in_range('10/22/2007',                                 '10/31/2007'),   -7,                                             'number of week days from 10/22/2007                 to               10/31/2007 is   -7                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/1/2007'),   -8,                                             'number of week days from 10/22/2007                 to                11/1/2007 is   -8                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/2/2007'),   -9,                                             'number of week days from 10/22/2007                 to                11/2/2007 is   -9                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/3/2007'),   -10,                                            'number of week days from 10/22/2007                 to                11/3/2007 is  -10                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/4/2007'),   -10,                                            'number of week days from 10/22/2007                 to                11/4/2007 is  -10                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/5/2007'),   -10,                                            'number of week days from 10/22/2007                 to                11/5/2007 is  -10                                ');
is(number_of_weekdays_in_range('10/22/2007',                                  '11/6/2007'),   -11,                                            'number of week days from 10/22/2007                 to                11/6/2007 is  -11                                ');


is(number_of_weekdays_in_range('1/1/-399',                                   '12/31/-400'),    1,                                             'number of week days from 1/1/-399                   to               12/31/-400 is   1                                 ');
is(number_of_weekdays_in_range('12/31/-401',                                   '1/1/-400'),   -1,                                             'number of week days from 12/31/-401                 to                 1/1/-400 is  -1                                 ');
is(number_of_weekdays_in_range('4/11/2002',                                    '4/9/2002'),    2,                                             'number of week days from 4/11/2002                  to                 4/9/2002 is   2                                 ');
is(number_of_weekdays_in_range('12/25/2005',                                 '12/29/2005'),   -3,                                             'number of week days from 12/25/2005                 to               12/29/2005 is  -3                                 ');
is(number_of_weekdays_in_range('12/25/2007',                                 '12/25/2003'),  int((365*4 + 1) * 5 / 7),                        'number of week days from 12/25/2007                 to               12/25/2003 is int((365*4 + 1) * 5 / 7)            ');
is(number_of_weekdays_in_range('1/1/2000',                                     '1/1/2399'),  int((-400*365.25 + 3 + 365) * 5 / 7),            'number of week days from 1/1/2000                   to                 1/1/2399 is int((-400*365.25 + 3 + 365) * 5 / 7)');
is(number_of_weekdays_in_range('1/1/2000',                                     '1/1/2400'),  int((-400*365.25 + 3) * 5 / 7),                  'number of week days from 1/1/2000                   to                 1/1/2400 is int((-400*365.25 + 3) * 5 / 7)      ');
is(number_of_weekdays_in_range('1/1/0',                                        '1/1/2400'),  int(((-400*365.25 + 3)*6) * 5 / 7),              'number of week days from 1/1/0                      to                 1/1/2400 is int(((-400*365.25 + 3)*6) * 5 / 7)  ');
is(number_of_weekdays_in_range('1/1/1999',                                   '12/31/1998'),  1,                                               'number of week days from 1/1/1999                   to               12/31/1998 is 1                                   ');
is(number_of_weekdays_in_range('1/1/1',                                         '12/31/0'),  1,                                               'number of week days from 1/1/1                      to                  12/31/0 is 1                                   ');
is(number_of_weekdays_in_range('1/2/0',                                           '1/1/0'),  0,                                               'number of week days from 1/2/0                      to                    1/1/0 is 0                                   ');
is(number_of_weekdays_in_range('1/1/0',                                        '12/31/-1'),  0,                                               'number of week days from 1/1/0                      to                 12/31/-1 is 0                                   ');
is(number_of_weekdays_in_range('1/1/-1',                                       '12/31/-2'),  1,                                               'number of week days from 1/1/-1                     to                 12/31/-2 is 1                                   ');
is(number_of_weekdays_in_range('1/1/-199',                                   '12/31/-200'),  1,                                               'number of week days from 1/1/-199                   to               12/31/-200 is 1                                   ');
is(number_of_weekdays_in_range('1/1/-299',                                   '12/31/-300'),  0,                                               'number of week days from 1/1/-299                   to               12/31/-300 is 0                                   ');
is(number_of_weekdays_in_range('Sat Jan  7 08:50:51   1995',                   '1/8/1996'),  (int((-366) * 5 / 7) + 1),                       'number of week days from Sat Jan  7 08:50:51   1995 to                 1/8/1996 is (int((-366) * 5 / 7) + 1)           ');
is(number_of_weekdays_in_range('3/24/1995',                                   '3/25/1996'),  (int((-367) * 5 / 7) + 1),                       'number of week days from 3/24/1995                  to                3/25/1996 is (int((-367) * 5 / 7) + 1)           ');
is(number_of_weekdays_in_range('2/3/2001',                                     '3/1/1995'),  int((6*365 + 2 - 26) * 5 / 7),                   'number of week days from 2/3/2001                   to                 3/1/1995 is int((6*365 + 2 - 26) * 5 / 7)       ');
is(number_of_weekdays_in_range('3/1/1995',                                     '2/3/2001'),  (int((-6*365 - 2 + 26) * 5 / 7) - 1),            'number of week days from 3/1/1995                   to                 2/3/2001 is (int((-6*365 - 2 + 26) * 5 / 7) - 1)');
is(number_of_weekdays_in_range('12/11/1544',                                 '12/11/1544'),  (0),                                             'number of week days from 12/11/1544                 to               12/11/1544 is (0)                                 ');





#is(number_of_weekdays_in_range('4/20/2007',        '4/21/2007'),   -1,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');
#is(number_of_weekdays_in_range('4/20/2007',        '4/14/2007'),    5,                                             'number of week days from 10/22/2007                 to               10/14/2007 is    6                                ');


#is(number_of_weekdays_in_range('04/06/2007',       '04/06/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/07/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/08/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/09/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/10/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/11/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/12/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/13/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/14/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/15/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/16/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/17/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/18/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/19/2007'),    -9 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/20/2007'),    -10,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/06/2007',       '04/21/2007'),    -11,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/06/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/07/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/08/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/09/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/10/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/11/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/12/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/13/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/14/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/15/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/16/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/17/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/18/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/19/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/20/2007'),    -9 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/07/2007',       '04/21/2007'),    -10,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/06/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/07/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/08/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/09/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/10/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/11/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/12/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/13/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/14/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/15/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/16/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/17/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/18/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/19/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/20/2007'),    -9 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/08/2007',       '04/21/2007'),    -10,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/06/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/07/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/08/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/09/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/10/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/11/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/12/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/13/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/14/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/15/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/16/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/17/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/18/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/19/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/20/2007'),    -9 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/09/2007',       '04/21/2007'),    -10,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/06/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/07/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/08/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/09/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/10/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/11/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/12/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/13/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/14/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/15/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/16/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/17/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/18/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/19/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/20/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/10/2007',       '04/21/2007'),    -9 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/06/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/07/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/08/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/09/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/10/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/11/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/12/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/13/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/14/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/15/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/16/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/17/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/18/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/19/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/20/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/11/2007',       '04/21/2007'),    -8 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/06/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/07/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/08/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/09/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/10/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/11/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/12/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/13/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/14/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/15/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/16/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/17/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/18/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/19/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/20/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/12/2007',       '04/21/2007'),    -7 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/06/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/07/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/08/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/09/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/10/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/11/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/12/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/13/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/14/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/15/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/16/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/17/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/18/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/19/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/20/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/13/2007',       '04/21/2007'),    -6 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/06/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/07/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/08/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/09/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/10/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/11/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/12/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/13/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/14/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/15/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/16/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/17/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/18/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/19/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/20/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/14/2007',       '04/21/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/06/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/07/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/08/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/09/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/10/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/11/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/12/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/13/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/14/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/15/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/16/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/17/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/18/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/19/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/20/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/15/2007',       '04/21/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/06/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/07/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/08/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/09/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/10/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/11/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/12/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/13/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/14/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/15/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/16/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/17/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/18/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/19/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/20/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/16/2007',       '04/21/2007'),    -5 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/06/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/07/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/08/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/09/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/10/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/11/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/12/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/13/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/14/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/15/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/16/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/17/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/18/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/19/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/20/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/17/2007',       '04/21/2007'),    -4 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/06/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/07/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/08/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/09/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/10/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/11/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/12/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/13/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/14/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/15/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/16/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/17/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/18/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/19/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/20/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/18/2007',       '04/21/2007'),    -3 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/06/2007'),    9  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/07/2007'),    9  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/08/2007'),    9  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/09/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/10/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/11/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/12/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/13/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/14/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/15/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/16/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/17/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/18/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/19/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/20/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/19/2007',       '04/21/2007'),    -2 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/06/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/07/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/08/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/09/2007'),    9  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/10/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/11/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/12/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/13/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/14/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/15/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/16/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/17/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/18/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/19/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/20/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/20/2007',       '04/21/2007'),    -1 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/06/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/07/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/08/2007'),    10 ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/09/2007'),    9  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/10/2007'),    8  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/11/2007'),    7  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/12/2007'),    6  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/13/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/14/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/15/2007'),    5  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/16/2007'),    4  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/17/2007'),    3  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/18/2007'),    2  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/19/2007'),    1  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/20/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
#is(number_of_weekdays_in_range('04/21/2007',       '04/21/2007'),    0  ,  'number of week days from 10/22/2007                 to          10/14/2007 is    6       ');
