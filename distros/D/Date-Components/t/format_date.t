# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 84;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(format_date);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# TBD ( add more tests as more formats are added )



# Check for faulty input
eval {format_date('Mon Sep  17  08:50:519 2007',        'A')};
ok(($@),      '<null>  is invalid input.  Number is too large for seconds.');

eval {format_date('Mon Sep  17  08:a:51 2007',          'A')};
ok(($@),      '<null>  is invalid input.  Minutes of <a> is incorrect.');

eval {format_date('Mon Sep  17 -25:50:51 2007',         'A')};
ok(($@),      '<null>  is invalid input.  Negative hours is incorrect.');

eval {format_date('Mon Sep  31  08:50:51 2007',         'A')};
ok(($@),      '<null>  is invalid input.  September does NOT have 31 days.');

eval {format_date('Mon Sep   0  08:50:51 2007',         'A')};
ok(($@),      '<null>  is invalid input.  Zero is NOT a valid day of month.');

eval {format_date('Mon Sept 17 08:50:51 2007',          'A')};
ok(($@),      '<null>  is invalid input.  Only three letter month abbreviations are recognized.');

eval {format_date('5   Sep  17 08:50:51 2007',          'A')};
ok(($@),      '<null>  is invalid input.  Only ALPHA month names are recognized.');

eval {format_date('Mon Sep  17 08:50:51 1999AD',        'A')};
ok(($@),      '<null>  is invalid input.  Year CANNOT have units such as AD.');

eval {format_date('12/31/-401.7',                       'A')};
ok(($@),      '<null>  is invalid input.  Fractional years are NOT recognized.');

eval {format_date('12/32/-401',                         'A')};
ok(($@),      '<null>  is invalid input.  There are NOT 32 days in a month.');

eval {format_date('0/5/2001',                           'A')};
ok(($@),      '<null>  is invalid input.  Allowable month numbers are 1-12.');

eval {format_date('-8/19/1999',                         'A')};
ok(($@),      '<null>  is invalid input.  Allowable month numbers are 1-12.');

eval {format_date('11/0/1977',                          'A')};
ok(($@),      '<null>  is invalid input.  Allowable day of month numbers are 1-31.');

eval {format_date('9/21/2000',                           '')};
ok(($@),      '<null>  is invalid input.  Date format parameter is undefined.');

eval {format_date('',                                   'A')};
ok(($@),      '<null>  is invalid input.  Date string is undefined.');

eval {format_date('9/21/2000,                           A')};
ok(($@),      '<null>  is invalid input.  Date and format parameter CANNOT be combined into one string.');

eval {format_date([], 'A')};
ok(($@),      'SCALAR value is REQUIRED for date.');

eval {format_date('11/6/1777', {})};
ok(($@),      'SCALAR value is REQUIRED for format selection.');

eval {format_date('12/31/-401', 'A', 67                             )};
ok(($@),      'Too many parameters are given.');

eval {format_date()};
ok(($@),      'NO many parameters are given.');

eval {format_date(1599, 7, 4)};
ok(($@),      'Parameters are out of order.');

eval {format_date('B', 7, 4, 1599)};
ok(($@),      'Parameters are out of order.');

eval {format_date('B', 7, 4, 1599, 'c')};
ok(($@),      'Too many parameters.');

eval {format_date('12/30/1999', 7, 4, 1599)};
ok(($@),      'Incorrect set of parameters.');

eval {format_date(7, 4, 1599.9,  'B')};
ok(($@),      'Invalid year.');

eval {format_date(0, 4, 1599,  'B')};
ok(($@),      'Invalid month.');

eval {format_date(13, 4, 1599,  'B')};
ok(($@),      'Invalid month.');

eval {format_date(7, 0, 1599,  'B')};
ok(($@),      'Invalid day of month.');

eval {format_date(7, 32, 1599,  'B')};
ok(($@),      'Invalid day of month.');

eval {format_date(7, 4, 1599,  '')};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date(7, 4, '',  'B')};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date(7, '', 1599,  'B')};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date('', 4, 1599,  'B')};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date(7, 4, '')};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date(7, '', 1599)};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date('', 4, 1599)};
ok(($@),      'Null parameters are NOT allowed.');

eval {format_date(7, 4, 1599,  {})};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date(7, 4, {},  'B')};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date(7, {}, 1599,  'B')};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date({}, 4, 1599,  'B')};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date(7, 4, {})};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date(7, {}, 1599)};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date({}, 4, 1599)};
ok(($@),      'ONLY SCALAR parameters are allowed.');

eval {format_date('7/4/3122',  'E')};
ok(($@),      'ONLY RECOGNIZED parameters are allowed.');












is(format_date('Mon Sep 17 08:50:51 2007'),     '09/17/2007',         'format_date');
is(format_date('Sun Feb 29 08:50:51 2004'),     '02/29/2004',         'format_date');
is(format_date('12/31/-401'              ),     '12/31/-401',         'format_date');
is(format_date('1/1/0'                   ),     '01/01/0',            'format_date');
is(format_date('12/30/1999'              ),     '12/30/1999',         'format_date');
is(format_date('12/31/1999'              ),     '12/31/1999',         'format_date');
is(format_date('12/30/1999'              ),     '12/30/1999',         'format_date');
is(format_date('1/4/2001'                ),     '01/04/2001',         'format_date');
is(format_date('1/1/-400'                ),     '01/01/-400',         'format_date');
is(format_date('12/31/-401'              ),     '12/31/-401',         'format_date');
is(format_date('1/1/0'                   ),     '01/01/0',            'format_date');
is(format_date('12/31/-1'                ),     '12/31/-1',           'format_date');
is(format_date('1/1/2000'                ),     '01/01/2000',         'format_date');
is(format_date('12/31/1999'              ),     '12/31/1999',         'format_date');
is(format_date('1/1/2001'                ),     '01/01/2001',         'format_date');
is(format_date('9/21/2000'               ),     '09/21/2000',         'format_date');
is(format_date('9/21/2000'               ),     '09/21/2000',         'format_date');


is(format_date('3/17/2005'),          '03/17/2005',                    'Default format is used when none is given.');

is(format_date('7/4/1599'),           '07/04/1599',                    'format_date');
is(format_date('7/4/1599'),           '07/04/1599',                    'format_date');
is(format_date('7/4/1599',  'A'),     'Sun Jul  4 12:00:00 1599',      'format_date');


is(format_date(7, 4, 1599),           '07/04/1599',                    'format_date');
is(format_date(7, 4, 1599,  'A'),     'Sun Jul  4 12:00:00 1599',      'format_date');


is(format_date(2, 29, 1604,  'A'),     'Sun Feb 29 12:00:00 1604',      'format_date');

is(format_date( 2, 29, 1604,  'B'),     'February 29, 1604',      'format_date');
is(format_date( 2, 29, 1604,  'C'),     '29 February, 1604',      'format_date');
is(format_date( 2, 29, 1604,  'D'),     '1604-02-29',             'format_date');
is(format_date(11,  4, 1604,  'D'),     '1604-11-04',             'format_date');
is(format_date( 3,  7, 1604,  'D'),     '1604-03-07',             'format_date');


is(format_date('15 January, 1596', 'D'),     '1596-01-15',             'format_date');
is(format_date('15 January,  -87', 'D'),      '-87-01-15',             'format_date');

is(format_date( 1,   1, 0, 'A'),     'Sat Jan  1 12:00:00 0',      'format_date');
is(format_date( 8,  16, 0, 'A'),     'Wed Aug 16 12:00:00 0',      'format_date');
is(format_date(12,  31, 0, 'A'),     'Sun Dec 31 12:00:00 0',      'format_date');
