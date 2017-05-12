use Test::Most 0.25;

use Date::Easy;


my $FMT = '%m/%d/%Y';


# simple math stuff first

my $d = date("2001-01-04");
is $d->strftime($FMT), '01/04/2001', 'sanity check: base date';

my $d2 = $d + 1;
isa_ok $d2, 'Date::Easy::Date', 'object after addition';
is $d2->strftime($FMT), '01/05/2001', 'simple addition test';

$d2 = $d - 1;
isa_ok $d2, 'Date::Easy::Date', 'object after subtraction';
is $d2->strftime($FMT), '01/03/2001', 'simple subtraction test';


# slightly more complex
# let's cross some month and year boundaries

$d2 = $d + 30;
is $d2->strftime($FMT), '02/03/2001', 'math across month boundary';

$d2 = $d - 5;
is $d2->strftime($FMT), '12/30/2000', 'math across year boundary';


# seriously trickty
# let's cross some DST boundaries

$d2 = $d + 90;
is $d2->strftime($FMT), '04/04/2001', 'addition across DST boundary';
is $d2->hour,   0, "time remains zero after crossing DST (add, hour)";
is $d2->minute, 0, "time remains zero after crossing DST (add, min)";
is $d2->second, 0, "time remains zero after crossing DST (add, sec)";

$d2 = $d - 92;
is $d2->strftime($FMT), '10/04/2000', 'subtraction across DST boundary';
is $d2->hour,   0, "time remains zero after crossing DST (sub, hour)";
is $d2->minute, 0, "time remains zero after crossing DST (sub, min)";
is $d2->second, 0, "time remains zero after crossing DST (sub, sec)";


# type checks for things
isa_ok $d  + 1, 'Date::Easy::Date', 'addition result';
isa_ok $d2 - 5, 'Date::Easy::Date', 'subtraction result';


# adding months is, obviously harder

$d2 = $d->add_months(2);
is $d2->strftime($FMT), '03/04/2001', 'month addition';
$d2 = $d->add_months(-2);
is $d2->strftime($FMT), '11/04/2000', 'month subtraction';


done_testing;
