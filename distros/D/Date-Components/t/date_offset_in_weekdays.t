# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 97;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(date_offset_in_weekdays);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {date_offset_in_weekdays('12/31/2007',   57.5)};
ok(($@),      'Fractional offset days are NOT allowed');

eval {date_offset_in_weekdays('Tue Sep 17 08:50:51 2007',   57)};
ok(($@),      'Date does not parse for correct day of week, Sept 17 2007 is a Monday');

eval {date_offset_in_weekdays('12/31/2007,   57')};
ok(($@),      'CANNOT combine two parameters into one string');

eval {date_offset_in_weekdays(57, '12/31/2007')};
ok(($@),      'Parameters are out of order, date comes first');

eval {date_offset_in_weekdays('12/31/2007')};
ok(($@),      'TWO and ONLY TWO parameters are to be supplied.  There is NO default for the number of days.');

eval {date_offset_in_weekdays('12/31/2007',   57, 96)};
ok(($@),      'TWO and ONLY TWO parameters are to be supplied');

eval {date_offset_in_weekdays()};
ok(($@),      'Null is NOT allowed.  TWO and ONLY TWO scalar parameters are to be supplied');

eval {date_offset_in_weekdays([])};
ok(($@),      'Array reference is not an allowed parameter');

eval {date_offset_in_weekdays({})};
ok(($@),      'Hash reference is not an allowed parameter');

eval {date_offset_in_weekdays({}, 1)};
ok(($@),      'SCALAR parameters only allowed.');

eval {date_offset_in_weekdays('12/31/1999', [])};
ok(($@),      'SCALAR parameters only allowed.');

eval {date_offset_in_weekdays('', 1)};
ok(($@),      'NULL parameters are NOT allowed.');

eval {date_offset_in_weekdays('12/31/1999', '')};
ok(($@),      'NULL parameters are NOT allowed.');




eval {date_offset_in_weekdays('Sat Oct 16 08:50:51 202',  3)};
ok(($@),      'Starting date is NOT a weekday');

eval {date_offset_in_weekdays('Sun Oct 16 08:50:51 202',  3)};
ok(($@),      'Starting date is NOT a weekday');


is(date_offset_in_weekdays('Mon Oct 18 08:50:51 202',  3),     '10/21/202',       'date_offset_in_weekdays');





is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -7),     '06/30/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -6),     '07/01/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -5),     '07/04/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -4),     '07/05/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -3),     '07/06/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -2),     '07/07/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -1),     '07/08/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  0),     '07/11/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  1),     '07/12/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  2),     '07/13/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  3),     '07/14/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  4),     '07/15/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  5),     '07/18/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  6),     '07/19/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Mon Jul 11 08:50:51 1977',  7),     '07/20/1977',       'date_offset_in_weekdays');

is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -7),     '07/01/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -6),     '07/04/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -5),     '07/05/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -4),     '07/06/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -3),     '07/07/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -2),     '07/08/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -1),     '07/11/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  0),     '07/12/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  1),     '07/13/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  2),     '07/14/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  3),     '07/15/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  4),     '07/18/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  5),     '07/19/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  6),     '07/20/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Tue Jul 12 08:50:51 1977',  7),     '07/21/1977',       'date_offset_in_weekdays');

is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -7),     '07/04/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -6),     '07/05/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -5),     '07/06/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -4),     '07/07/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -3),     '07/08/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -2),     '07/11/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977', -1),     '07/12/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  0),     '07/13/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  1),     '07/14/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  2),     '07/15/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  3),     '07/18/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  4),     '07/19/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  5),     '07/20/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  6),     '07/21/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  7),     '07/22/1977',       'date_offset_in_weekdays');

is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -7),     '07/05/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -6),     '07/06/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -5),     '07/07/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -4),     '07/08/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -3),     '07/11/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -2),     '07/12/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977', -1),     '07/13/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  0),     '07/14/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  1),     '07/15/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  2),     '07/18/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  3),     '07/19/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  4),     '07/20/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  5),     '07/21/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  6),     '07/22/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  7),     '07/25/1977',       'date_offset_in_weekdays');

is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -7),     '07/06/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -6),     '07/07/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -5),     '07/08/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -4),     '07/11/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -3),     '07/12/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -2),     '07/13/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977', -1),     '07/14/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  0),     '07/15/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  1),     '07/18/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  2),     '07/19/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  3),     '07/20/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  4),     '07/21/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  5),     '07/22/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  6),     '07/25/1977',       'date_offset_in_weekdays');
is(date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  7),     '07/26/1977',       'date_offset_in_weekdays');
