# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 32;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(get_days_remaining_in_year);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {get_days_remaining_in_year([7],30,1542)};
ok(($@),      'Array ref is NOT allowed');

eval {get_days_remaining_in_year(25,2004)};
ok(($@),      'Month parameter is missing');

eval {get_days_remaining_in_year('Jun',15)};
ok(($@),      'Year parameter is missing');

eval {get_days_remaining_in_year(10,32,2004)};
ok(($@),      'Number of days in month is NOT valid');

eval {get_days_remaining_in_year(0,30,1999)};
ok(($@),      'Month number is NOT valid');

eval {get_days_remaining_in_year(1,32,2000)};
ok(($@),      'Number of days in month is NOT valid');

eval {get_days_remaining_in_year(13,1,1900)};
ok(($@),      'Month number is NOT valid');

eval {get_days_remaining_in_year(12,0,1542)};
ok(($@),      'Day of month is NOT valid');

eval {get_days_remaining_in_year(12,31,5.5)};
ok(($@),      'Fractional years are INVALID');

eval {get_days_remaining_in_year(10,-7,0)};
ok(($@),      'Day of month CANNOT be negative');

eval {get_days_remaining_in_year('Sept',2,1401)};
ok(($@),      'Only THREE character abbreviations of month are allowed');

eval {get_days_remaining_in_year('February ',7,1865)};
ok(($@),      'NO leading or trailing spaces in parameters are allowed');

eval {get_days_remaining_in_year('',6,1701)};
ok(($@),      'NULL value for month is NOT allowed.');

eval {get_days_remaining_in_year('Oct',6,[])};
ok(($@),      'SCALAR value for year is REQUIRED.');

eval {get_days_remaining_in_year('Oct',6,'')};
ok(($@),      'NULL value for year is NOT allowed.');

eval {get_days_remaining_in_year('Oct',{},2007)};
ok(($@),      'SCALAR value for day of month is REQUIRED.');

eval {get_days_remaining_in_year('Oct','',1999)};
ok(($@),      'NULL value for day of month is NOT allowed.');




is(get_days_remaining_in_year(10,         25,2004),                 67,      'there are       67 days remaining after date 10,       25,2004');
is(get_days_remaining_in_year( 6,         30,1999),           (6*31-2),      'there are (6*31-2) days remaining after date  6,       30,1999');
is(get_days_remaining_in_year( 1,          1,2000),                365,      'there are      365 days remaining after date  1,        1,2000');
is(get_days_remaining_in_year( 1,          1,1900),                364,      'there are      364 days remaining after date  1,        1,1900');
is(get_days_remaining_in_year(12,         30,1542),                  1,      'there are        1 days remaining after date 12,       30,1542');
is(get_days_remaining_in_year(12,         31, -88),                  0,      'there are        0 days remaining after date 12,       31, -88');
is(get_days_remaining_in_year(10,         15,   0),                 77,      'there are       77 days remaining after date 10,       15,   0');
is(get_days_remaining_in_year('Sep',       2,1401),                120,      'there are      120 days remaining after date Sep,       2,1401');
is(get_days_remaining_in_year('February',  7,1865),           (365-38),      'there are (365-38) days remaining after date February,  7,1865');
