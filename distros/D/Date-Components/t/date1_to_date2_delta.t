# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 90;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(date1_to_date2_delta);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {date1_to_date2_delta('4/11/2002,   12/25/2007')};
ok(($@),      'Two arguments CANNOT be combined into one');

eval {date1_to_date2_delta('whatever')};
ok(($@),      'Invalid parameter');

eval {date1_to_date2_delta([])};
ok(($@),      'Array reference is NOT allowed.');

eval {date1_to_date2_delta({})};
ok(($@),      'Hash reference is NOT allowed.');

eval {date1_to_date2_delta('')};
ok(($@),      'Null reference is NOT allowed.');

eval {date1_to_date2_delta()};
ok(($@),      'TWO date strings are required.');

eval {date1_to_date2_delta('8/15/3003',  '09/11/1336',  '11/16/1001')};
ok(($@),      'TOO many parameters supplied');

eval {date1_to_date2_delta('4/32/2002, 12/25/2007')};
ok(($@),      'Invalid day of month');

eval {date1_to_date2_delta({}, '12/25/2007')};
ok(($@),      'Date MUST be SCALAR');

eval {date1_to_date2_delta('4/32/2002', [])};
ok(($@),      'Date MUST be SCALAR');

eval {date1_to_date2_delta('', '12/25/2007')};
ok(($@),      'NULL is NOT allowed.');

eval {date1_to_date2_delta('4/32/2002', '')};
ok(($@),      'NULL is NOT allowed.');

eval {date1_to_date2_delta('4/32/2002', '12/25/2007')};
ok(($@),      'Dates do not parse successfully.');

eval {date1_to_date2_delta('4/30/2002', '0/25/2007')};
ok(($@),      'Dates do not parse successfully.');




is(date1_to_date2_delta('1/1/-399',                      '12/31/-400'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('12/31/-401',                      '1/1/-400'),  (-1),                    'date1 minus date2 = -1                     ');
is(date1_to_date2_delta('4/11/2002',                       '4/9/2002'),    2,                     'date1 minus date2 =  2                     ');
is(date1_to_date2_delta('12/25/2005',                    '12/29/2005'),  -4,                      'date1 minus date2 = -4                     ');
is(date1_to_date2_delta('12/25/2007',                    '12/25/2003'),  (365*4 + 1),             'date1 minus date2 = (365*4 + 1)            ');
is(date1_to_date2_delta('1/1/2000',                        '1/1/2399'),  (-400*365.25 + 3 + 365), 'date1 minus date2 = (-400*365.25 + 3 + 365)');
is(date1_to_date2_delta('1/1/2000',                        '1/1/2400'),  (-400*365.25 + 3),       'date1 minus date2 = (-400*365.25 + 3)      ');
is(date1_to_date2_delta('1/1/0',                           '1/1/2400'),  ((-400*365.25 + 3)*6),   'date1 minus date2 = ((-400*365.25 + 3)*6)  ');
is(date1_to_date2_delta('1/1/1999',                      '12/31/1998'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/1/1',                            '12/31/0'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/2/0',                              '1/1/0'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/1/0',                           '12/31/-1'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/1/-1',                          '12/31/-2'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/1/-199',                      '12/31/-200'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('1/1/-299',                      '12/31/-300'),  (1),                     'date1 minus date2 = 1                      ');
is(date1_to_date2_delta('Sat Jan  7 08:50:51   1995',      '1/8/1996'),  (-366),                  'date1 minus date2 = -366                   ');
is(date1_to_date2_delta('3/24/1995',                      '3/25/1996'),  (-367),                  'date1 minus date2 = -367                   ');
is(date1_to_date2_delta('2/3/2001',                        '3/1/1995'),  (6*365 + 2 - 26),        'date1 minus date2 = (6*365 + 2 - 26)       ');
is(date1_to_date2_delta('3/1/1995',                        '2/3/2001'),  (-6*365 - 2 + 26),       'date1 minus date2 = (-6*365 - 2 + 26)      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1544'),  (0),                     'date1 minus date2 = 0                      ');





# Double check the expected outputs for this group
is(date1_to_date2_delta('12/11/1544',                    '12/11/2001'),  -166916,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/2000'),  -166551,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1999'),  -166185,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1601'),  -20819 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1600'),  -20454 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1599'),  -20088 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1543'),  366    ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1201'),  125278 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1200'),  125643 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1199'),  126009 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/801'),   271375 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/800'),   271740 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/799'),   272106 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/401'),   417472 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/400'),   417837 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/399'),   418203 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/1'),     563569 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/0'),     563934 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-1'),    564300 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-399'),  709666 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-400'),  710031 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-401'),  710397 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-799'),  855763 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-800'),  856128 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('12/11/1544',                    '12/11/-801'),  856494 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/2001'),   -801118,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/2000'),   -800753,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1999'),   -800387,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1601'),   -655021,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1600'),   -654656,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1599'),   -654290,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1543'),   -633836,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1201'),   -508924,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1200'),   -508559,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1199'),   -508193,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/801'),    -362827,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/800'),    -362462,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/799'),    -362096,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/401'),    -216730,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/400'),    -216365,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/399'),    -215999,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/1'),      -70633 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/0'),      -70268 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-1'),     -69902 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-399'),   75464  ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-400'),   75829  ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-401'),   76195  ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-799'),   221561 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-800'),   221926 ,                     'date1 minus date2 = 0                      ');
is(date1_to_date2_delta('7/23/-192',                    '12/11/-801'),   222292 ,                     'date1 minus date2 = 0                      ');
