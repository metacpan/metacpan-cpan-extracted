use Test::Most 0.25;

use Date::Easy;


my $FMT = '%m/%d/%Y';
my $CLASS = 'Date::Easy::Date';


# simple math stuff first

my $d = date("2001-01-04");
is $d->strftime($FMT), '01/04/2001', 'sanity check: base date';

my $d2 = $d + 1;
isa_ok $d2, $CLASS, 'object after addition' or diag('    isa ', ref $d2);
is $d2->strftime($FMT), '01/05/2001', 'simple addition test';
test_date_subtract_date($d, $d2, 1);

$d2 = $d - 1;
isa_ok $d2, $CLASS, 'object after subtraction' or diag('    isa ', ref $d2);
is $d2->strftime($FMT), '01/03/2001', 'simple subtraction test';
test_date_subtract_date($d, $d2, -1);


# slightly more complex
# let's cross some month and year boundaries
# at every point, make sure we can subtract dates from each other

$d2 = $d + 30;
is $d2->strftime($FMT), '02/03/2001', 'math across month boundary';
test_date_subtract_date($d, $d2, 30);

$d2 = $d - 5;
is $d2->strftime($FMT), '12/30/2000', 'math across year boundary';
test_date_subtract_date($d, $d2, -5);


# seriously trickty
# let's cross some DST boundaries

$d2 = $d + 90;
is $d2->strftime($FMT), '04/04/2001', 'addition across DST boundary';
test_date_subtract_date($d, $d2, 90);
is $d2->hour,   0, "time remains zero after crossing DST (add, hour)";
is $d2->minute, 0, "time remains zero after crossing DST (add, min)";
is $d2->second, 0, "time remains zero after crossing DST (add, sec)";

$d2 = $d - 92;
is $d2->strftime($FMT), '10/04/2000', 'subtraction across DST boundary';
test_date_subtract_date($d, $d2, -92);
is $d2->hour,   0, "time remains zero after crossing DST (sub, hour)";
is $d2->minute, 0, "time remains zero after crossing DST (sub, min)";
is $d2->second, 0, "time remains zero after crossing DST (sub, sec)";


# type checks for things
isa_ok $d  + 1, $CLASS, 'addition result';
isa_ok $d2 - 5, $CLASS, 'subtraction result';


# adding months is, obviously harder

$d2 = $d->add_months(2);
isa_ok $d2, $CLASS, 'add_months result' or diag('    isa ', ref $d2);
is $d2->strftime($FMT), '03/04/2001', 'month addition';
$d2 = $d->add_months(-2);
is $d2->strftime($FMT), '11/04/2000', 'month subtraction';


# adding years is not quite as bad
# just make sure we cross at least one leap year boundary

$d2 = $d->add_years(12);
isa_ok $d2, $CLASS, 'add_years result' or diag('    isa ', ref $d2);
is $d2->strftime($FMT), '01/04/2013', 'year addition';
$d2 = $d->add_years(-3);
is $d2->strftime($FMT), '01/04/1998', 'year subtraction';


# for adding and subtracting days and weeks,
# we can just test against adding the equivalent integers
# (since we've already established that that part works)
for (0..120)					# just for consistency with the datetime tests, really
{
	is $d->add_days($_),    	$d + $_,		"adding $_ days works";
	is $d->add_weeks($_),   	$d + $_ * 7,	"adding $_ weeks works";

	is $d->subtract_days($_),	$d - $_,		"subtracting $_ days works";
	is $d->subtract_weeks($_),	$d - $_ * 7,	"subtracting $_ weeks works";
}

# on the other hand, you *can't* add or subtract hours, minutes, or seconds
# because that would break the contract of dates always having a time component of midnight
throws_ok { $d->$_ } qr/cannot call $_ on a Date value/, "::Date properly disallows $_"
		foreach map { ("add_$_", "subtract_$_") } qw< seconds minutes hours >;


done_testing;


sub test_date_subtract_date
{
	my ($d1, $d2, $expected) = @_;

	is $d2 - $d1,      $expected, "date subtraction (positive  days) for $d1/$d2";
	is $d1 - $d2,     -$expected, "date subtraction (negative  days) for $d1/$d2";
	is $d1 - $d1,              0, "date subtraction (zero      days) for $d1/$d2";
	is $d2 - $d1, int($d2 - $d1), "date subtraction (integer result) for $d1/$d2";
}
