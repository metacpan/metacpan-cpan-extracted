# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 49;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_month_to_month_name_abbrev);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_month_to_month_name_abbrev()};
ok(($@),      'Parameters are missing.');

eval {set_month_to_month_name_abbrev('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_month_to_month_name_abbrev(['October'])};
ok(($@),      'Array reference is not allowed.');

eval {set_month_to_month_name_abbrev({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_month_to_month_name_abbrev('Jun ')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_month_to_month_name_abbrev(0)};
ok(($@),      'Numeric month is out of range.');

eval {set_month_to_month_name_abbrev(13)};
ok(($@),      'Numeric month is out of range.');



is(set_month_to_month_name_abbrev     (1),          'Jan',   'set month  1        to month name Jan');
is(set_month_to_month_name_abbrev     (2),          'Feb',   'set month  2        to month name Feb');
is(set_month_to_month_name_abbrev     (3),          'Mar',   'set month  3        to month name Mar');
is(set_month_to_month_name_abbrev     (4),          'Apr',   'set month  4        to month name Apr');
is(set_month_to_month_name_abbrev     (5),          'May',   'set month  5        to month name May');
is(set_month_to_month_name_abbrev     (6),          'Jun',   'set month  6        to month name Jun');
is(set_month_to_month_name_abbrev     (7),          'Jul',   'set month  7        to month name Jul');
is(set_month_to_month_name_abbrev     (8),          'Aug',   'set month  8        to month name Aug');
is(set_month_to_month_name_abbrev     (9),          'Sep',   'set month  9        to month name Sep');
is(set_month_to_month_name_abbrev    (10),          'Oct',   'set month 10        to month name Oct');
is(set_month_to_month_name_abbrev    (11),          'Nov',   'set month 11        to month name Nov');
is(set_month_to_month_name_abbrev    (12),          'Dec',   'set month 12        to month name Dec');
is(set_month_to_month_name_abbrev    ('Jan'),       'Jan',   'set month Jan       to month name Jan');
is(set_month_to_month_name_abbrev    ('Feb'),       'Feb',   'set month Feb       to month name Feb');
is(set_month_to_month_name_abbrev    ('Mar'),       'Mar',   'set month Mar       to month name Mar');
is(set_month_to_month_name_abbrev    ('Apr'),       'Apr',   'set month Apr       to month name Apr');
is(set_month_to_month_name_abbrev    ('May'),       'May',   'set month May       to month name May');
is(set_month_to_month_name_abbrev    ('Jun'),       'Jun',   'set month Jun       to month name Jun');
is(set_month_to_month_name_abbrev    ('Jul'),       'Jul',   'set month Jul       to month name Jul');
is(set_month_to_month_name_abbrev    ('Aug'),       'Aug',   'set month Aug       to month name Aug');
is(set_month_to_month_name_abbrev    ('Sep'),       'Sep',   'set month Sep       to month name Sep');
is(set_month_to_month_name_abbrev    ('Oct'),       'Oct',   'set month Oct       to month name Oct');
is(set_month_to_month_name_abbrev    ('Nov'),       'Nov',   'set month Nov       to month name Nov');
is(set_month_to_month_name_abbrev    ('Dec'),       'Dec',   'set month Dec       to month name Dec');
is(set_month_to_month_name_abbrev    ('January'),   'Jan',   'set month January   to month name Jan');
is(set_month_to_month_name_abbrev    ('February'),  'Feb',   'set month February  to month name Feb');
is(set_month_to_month_name_abbrev    ('March'),     'Mar',   'set month March     to month name Mar');
is(set_month_to_month_name_abbrev    ('April'),     'Apr',   'set month April     to month name Apr');
is(set_month_to_month_name_abbrev    ('May'),       'May',   'set month May       to month name May');
is(set_month_to_month_name_abbrev    ('June'),      'Jun',   'set month June      to month name Jun');
is(set_month_to_month_name_abbrev    ('July'),      'Jul',   'set month July      to month name Jul');
is(set_month_to_month_name_abbrev    ('August'),    'Aug',   'set month August    to month name Aug');
is(set_month_to_month_name_abbrev    ('September'), 'Sep',   'set month September to month name Sep');
is(set_month_to_month_name_abbrev    ('October'),   'Oct',   'set month October   to month name Oct');
is(set_month_to_month_name_abbrev    ('November'),  'Nov',   'set month November  to month name Nov');
is(set_month_to_month_name_abbrev    ('December'),  'Dec',   'set month December  to month name Dec');
