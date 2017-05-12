# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 49;
#use Test::More qw(no_plan);
BEGIN { use_ok('Date::Components') };
BEGIN { use_ok('Test::Manifest') };
use Date::Components qw(set_month_to_month_number);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(1, '1 is true');
is(2+2, 4, ' The sum is four');
isnt(2*3, 5, 'The product is five');
isnt(2 ** 3, 6, "The results is not six");



# Check for faulty input
eval {set_month_to_month_number()};
ok(($@),      'Parameters are missing.');

eval {set_month_to_month_number('')};
ok(($@),      'Null Parameter is NOT allowed.');

eval {set_month_to_month_number(['October'])};
ok(($@),      'Array reference is not allowed.');

eval {set_month_to_month_number({})};
ok(($@),      'Hash reference is not allowed.');

eval {set_month_to_month_number('Jun ')};
ok(($@),      'Leading and trailing spaces are NOT allowed.');

eval {set_month_to_month_number(0)};
ok(($@),      'Numeric month is out of range.');

eval {set_month_to_month_number(13)};
ok(($@),      'Numeric month is out of range.');



is(set_month_to_month_number     (1),           (1),   'set month  1        to month number  1');
is(set_month_to_month_number     (2),           (2),   'set month  2        to month number  2');
is(set_month_to_month_number     (3),           (3),   'set month  3        to month number  3');
is(set_month_to_month_number     (4),           (4),   'set month  4        to month number  4');
is(set_month_to_month_number     (5),           (5),   'set month  5        to month number  5');
is(set_month_to_month_number     (6),           (6),   'set month  6        to month number  6');
is(set_month_to_month_number     (7),           (7),   'set month  7        to month number  7');
is(set_month_to_month_number     (8),           (8),   'set month  8        to month number  8');
is(set_month_to_month_number     (9),           (9),   'set month  9        to month number  9');
is(set_month_to_month_number    (10),          (10),   'set month 10        to month number 10');
is(set_month_to_month_number    (11),          (11),   'set month 11        to month number 11');
is(set_month_to_month_number    (12),          (12),   'set month 12        to month number 12');
is(set_month_to_month_number    ('Jan'),        (1),   'set month Jan       to month number  1');
is(set_month_to_month_number    ('Feb'),        (2),   'set month Feb       to month number  2');
is(set_month_to_month_number    ('Mar'),        (3),   'set month Mar       to month number  3');
is(set_month_to_month_number    ('Apr'),        (4),   'set month Apr       to month number  4');
is(set_month_to_month_number    ('May'),        (5),   'set month May       to month number  5');
is(set_month_to_month_number    ('Jun'),        (6),   'set month Jun       to month number  6');
is(set_month_to_month_number    ('Jul'),        (7),   'set month Jul       to month number  7');
is(set_month_to_month_number    ('Aug'),        (8),   'set month Aug       to month number  8');
is(set_month_to_month_number    ('Sep'),        (9),   'set month Sep       to month number  9');
is(set_month_to_month_number    ('Oct'),       (10),   'set month Oct       to month number 10');
is(set_month_to_month_number    ('Nov'),       (11),   'set month Nov       to month number 11');
is(set_month_to_month_number    ('Dec'),       (12),   'set month Dec       to month number 12');
is(set_month_to_month_number    ('January'),    (1),   'set month January   to month number  1');
is(set_month_to_month_number    ('February'),   (2),   'set month February  to month number  2');
is(set_month_to_month_number    ('March'),      (3),   'set month March     to month number  3');
is(set_month_to_month_number    ('April'),      (4),   'set month April     to month number  4');
is(set_month_to_month_number    ('May'),        (5),   'set month May       to month number  5');
is(set_month_to_month_number    ('June'),       (6),   'set month June      to month number  6');
is(set_month_to_month_number    ('July'),       (7),   'set month July      to month number  7');
is(set_month_to_month_number    ('August'),     (8),   'set month August    to month number  8');
is(set_month_to_month_number    ('September'),  (9),   'set month September to month number  9');
is(set_month_to_month_number    ('October'),   (10),   'set month October   to month number 10');
is(set_month_to_month_number    ('November'),  (11),   'set month November  to month number 11');
is(set_month_to_month_number    ('December'),  (12),   'set month December  to month number 12');
