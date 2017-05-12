# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 123;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(date_only_parse);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");


eval {date_only_parse('')};
ok(($@),      '<null>  is invalid input.  A date string must be used.');

eval {date_only_parse()};
ok(($@),      'NO paramters  is invalid input.  A date string must be used.');

eval {date_only_parse('1959', 3)};
ok(($@),      'more than one parameter is given.  A date string must be used.');

eval {date_only_parse({})};
ok(($@),      'hash reference  is invalid input.  A date string must be used.');

eval {date_only_parse([])};
ok(($@),      'array reference  is invalid input.  A date string must be used.');



ok(!date_only_parse('2/29/2005'),                 'Invalid date cannot be parsed');
ok(!date_only_parse('Mon Feb 27 08:50:51 2005'),  'Invalid date cannot be parsed');


ok(date_only_parse('1/15/1911'),  'date only parsed  1/15/1911 ');
ok(date_only_parse('4/22/1800'),  'date only parsed  4/22/1800 ');
ok(date_only_parse('5/31/1492'),  'date only parsed  5/31/1492 ');
ok(date_only_parse('12/2/0'),     'date only parsed  12/2/0    ');
ok(date_only_parse('5/06/-77'),   'date only parsed  5/06/-77  ');
ok(date_only_parse('10/23/80'),   'date only parsed  10/23/80  ');
ok(date_only_parse('11/11/2003'), 'date only parsed  11/11/2003');
ok(date_only_parse('3/14/2099'),  'date only parsed  3/14/2099 ');
ok(date_only_parse('6/19/3675'),  'date only parsed  6/19/3675 ');
ok(date_only_parse('7/7/1'),      'date only parsed  7/7/1     ');
ok(date_only_parse('8/08/-1'),    'date only parsed  8/08/-1   ');
ok(date_only_parse('Fri Jan  1 08:50:51   -1'),           'date only parsed  1/15/1911 ');
ok(date_only_parse('Sat Jan  1 08:50:51    0'),           'date only parsed  1/15/1911 ');
ok(date_only_parse('Mon Jan  1 08:50:51    1'),           'date only parsed  1/15/1911 ');
ok(date_only_parse('Tue Feb 29 08:50:51 2000'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Sun Jan  1 08:50:51 -5'),             'date only parsed  dddddddddddd');
ok(date_only_parse('Wed Feb  3 08:50:51 -3077'),          'date only parsed  dddddddddddd');
ok(date_only_parse('Sat Sep  8 08:50:51 1900'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Mon Jul  2 08:50:51 1066'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Thu Mar 11 08:50:51 -1'),             'date only parsed  dddddddddddd');
ok(date_only_parse('Mon Apr 17 08:50:51 0'),              'date only parsed  dddddddddddd');
ok(date_only_parse('Sat May 19 08:50:51 1'),              'date only parsed  dddddddddddd');
ok(date_only_parse('Sat Jun 29 08:50:51 120'),            'date only parsed  dddddddddddd');
ok(date_only_parse('Fri Aug  4 08:50:51 1865'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Fri Oct 22 08:50:51 1999'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Tue Feb 29 08:50:51 2000'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Fri Nov 28 08:50:51 5000'),          'date only parsed  dddddddddddd');
ok(date_only_parse('Mon Nov 26 08:50:51 7500'),          'date only parsed  dddddddddddd');
ok(date_only_parse('Thu Jul 12 08:50:51 9500'),          'date only parsed  dddddddddddd');
ok(date_only_parse('Wed May  3 08:50:51 12000'),            'date only parsed  dddddddddddd');
ok(date_only_parse('Wed Dec 31 08:50:51 87'),            'date only parsed  dddddddddddd');
ok(date_only_parse('Tue Jan 14 08:50:51 1997'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Fri Jan 14 08:50:51 1200'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Thu Jan 14 08:50:51 900'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Mon Jan 14 08:50:51 999'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Sat Jan 14 08:50:51 1065'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Mon Jan 14 08:50:51 1067'),           'date only parsed  dddddddddddd');
ok(date_only_parse('Sun Jan 14 08:50:51 1066'),           'date only parsed  dddddddddddd');




# Unique format
ok(date_only_parse('1619-10-09'),  '????????');
ok(date_only_parse('-49-12-09'),   '????????');
ok(date_only_parse('1984-02-27'),  '????????');

ok(!date_only_parse('1984-2-27'),   'Month number MUST be two digits');
ok(!date_only_parse('1619-10-9'),   'Day number MUST be two digits');
ok(!date_only_parse('1984-00-27'),  'Month out of range');
ok(!date_only_parse('1984-13-27'),  'Month out of range');
ok(!date_only_parse('1984-02-00'),  'Day of month out of range');
ok(!date_only_parse('1984-02-30'),  'Day of month out of range');




# Unique format
ok(date_only_parse('September 17, 2007'),  '????????');
ok(date_only_parse('Feb 29, 2004'),        '????????');
ok(date_only_parse('December 5, 45'),      '????????');
ok(date_only_parse('Jun 8, -17'),          '????????');
ok(date_only_parse('Oct 3, 203'),          '????????');

ok(!date_only_parse('December 0, 45'),     'Day of month out of range');
ok(!date_only_parse('December 32, 45'),    'Day of month out of range');
ok(!date_only_parse('December 5, 2006.6'), 'Fractional year NOT allowed');
ok(!date_only_parse('Decmber 5, 2006'),    'Misspelled month');



# Unique format
ok(date_only_parse('17 September, 2007'),   '????????');
ok(date_only_parse('29 Feb, 2004'),         '????????');
ok(date_only_parse('5 December, 45'),       '????????');
ok(date_only_parse('8 Jun, -17'),           '????????');
ok(date_only_parse('3 Oct, 203'),           '????????');

ok(!date_only_parse('0 Oct, 203'),      'Day of month out of range');
ok(!date_only_parse('32 Oct, 203'),     'Day of month out of range');
ok(!date_only_parse('31 Oct, 203.3'),   'Fractional year NOT allowed');
ok(!date_only_parse('31 Octobor, 203'), 'Misspelled month');







my @date_parse_set;

@date_parse_set = date_only_parse('Sun Jan 14 08:50:51 1066');
is($date_parse_set[0],    1, 'month should be 1 (Jan)');
is($date_parse_set[1],   14, 'day of month should be 14');
is($date_parse_set[2], 1066, 'year should be 1066');
is($date_parse_set[3],    7, 'day of week should be 7 (Sun)');
is(@date_parse_set,       4, 'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('2/29/1996');
is($date_parse_set[0],    2, 'month should be 2 (Feb)');
is($date_parse_set[1],   29, 'day of month should be 29');
is($date_parse_set[2], 1996, 'year should be 1996');
is($date_parse_set[3],    4, 'day of week should be 4 (Thu)');
is(@date_parse_set,       4, 'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('2/29/2000');
is($date_parse_set[0],    2, 'month should be 2 (Feb)');
is($date_parse_set[1],   29, 'day of month should be 29');
is($date_parse_set[2], 2000, 'year should be 2000');
is($date_parse_set[3],    2, 'day of week should be 2 (Tue)');
is(@date_parse_set,       4, 'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('2/29/2004');
is($date_parse_set[0],    2, 'month should be 2 (Feb)');
is($date_parse_set[1],   29, 'day of month should be 29');
is($date_parse_set[2], 2004, 'year should be 2004');
is($date_parse_set[3],    7, 'day of week should be 7 (Sun)');
is(@date_parse_set,       4, 'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('Mon Jul 31 08:50:51 1865');
is($date_parse_set[0],    7, 'month should be 7 (Jul)');
is($date_parse_set[1],   31, 'day of month should be 31');
is($date_parse_set[2], 1865, 'year should be 1865');
is($date_parse_set[3],    1, 'day of week should be 1 (Mon)');
is(@date_parse_set,       4, 'date parse should return list of 4 scalars');





@date_parse_set = date_only_parse('1876-12-18');
is($date_parse_set[0],    12,   'month should be 12 (Dec)');
is($date_parse_set[1],    18,   'day of month should be 18');
is($date_parse_set[2],  1876,   'year should be 1876');
is($date_parse_set[3],     1,   'day of week should be 1 (Mon)');
is(@date_parse_set,        4,   'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('-407-06-03');
is($date_parse_set[0],     6,   'month should be 6 (Jun)');
is($date_parse_set[1],     3,   'day of month should be 3');
is($date_parse_set[2],  -407,   'year should be -407');
is($date_parse_set[3],     4,   'day of week should be 4 (Thu)');
is(@date_parse_set,        4,   'date parse should return list of 4 scalars');


@date_parse_set = date_only_parse('July 9, 2089');
is($date_parse_set[0],     7,   'month should be 7 (Jul)');
is($date_parse_set[1],     9,   'day of month should be 9');
is($date_parse_set[2],  2089,   'year should be 2089');
is($date_parse_set[3],     6,   'day of week should be 6 (Sat)');
is(@date_parse_set,        4,   'date parse should return list of 4 scalars');

@date_parse_set = date_only_parse('23 March, 30004');
is($date_parse_set[0],     3,   'month should be 3 (Mar)');
is($date_parse_set[1],    23,   'day of month should be 23');
is($date_parse_set[2], 30004,   'year should be 30004');
is($date_parse_set[3],     2,   'day of week should be 2 (Tue)');
is(@date_parse_set,        4,   'date parse should return list of 4 scalars');
