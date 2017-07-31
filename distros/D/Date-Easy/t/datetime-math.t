use Test::Most 0.25;

use Date::Easy;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_true is_false >;


my $FMT = '%Y/%m/%d %H:%M:%S';
my $CLASS = 'Date::Easy::Datetime';

# test datetimes
my $dt1 = datetime("2010-01-01 13:06:00");
my $dt2 = datetime("2010-01-01 13:06:00");
my $dt3 = datetime("2010-01-01 13:06:30");


# comparison operators

is_true $dt1 == $dt2, "datetime equality";
is_true $dt1 != $dt3, "datetime inequality";
is_true $dt1 <  $dt3, "datetime less than";
is_true $dt1 <= $dt2, "datetime less than/equal to";
is_true $dt3 >  $dt1, "datetime greater than";
is_true $dt1 >= $dt2, "datetime greater than/equal to";

is $dt1 <=> $dt2,  0, "datetime spaceship (equals)";
is $dt1 <=> $dt3, -1, "datetime spaceship (less than)";
is $dt3 <=> $dt1,  1, "datetime spaceship (greater than)";


# simple addition / subtraction

is $dt1 + 30, $dt3, "datetimes add seconds";
is $dt3 - 30, $dt1, "datetimes subtract seconds";


# type checks for things
isa_ok $dt1 + 30, $CLASS, 'addition result';
isa_ok $dt3 - 30, $CLASS, 'subtraction result';


# adding/subtracting months is, obviously, harder

my $dt4 = $dt3->add_months(2);
isa_ok $dt4, $CLASS, 'add_months result' or diag('    isa ', ref $dt4);
is $dt4->strftime($FMT), '2010/03/01 13:06:30', 'month addition';
$dt4 = $dt3->add_months(-2);
is $dt4->strftime($FMT), '2009/11/01 13:06:30', 'month negative addition';
$dt4 = $dt3->subtract_months(2);
isa_ok $dt4, $CLASS, 'subtract_months result' or diag('    isa ', ref $dt4);
is $dt4->strftime($FMT), '2009/11/01 13:06:30', 'month subtraction';

# cross a DST boundary
$dt4 = $dt3->add_months(3);
is $dt4->strftime($FMT), '2010/04/01 13:06:30', 'month addition across DST boundary';

# cross a year boundary
$dt4 = $dt3->add_months(13);
is $dt4->strftime($FMT), '2011/02/01 13:06:30', 'month addition across year boundary';


# adding/subtracting years is not quite as bad
# just make sure we cross at least one leap year boundary

my $dt5 = $dt3->add_years(3);
isa_ok $dt5, $CLASS, 'add_years result' or diag('    isa ', ref $dt5);
is $dt5->strftime($FMT), '2013/01/01 13:06:30', 'year addition';
$dt5 = $dt3->add_years(-12);
is $dt5->strftime($FMT), '1998/01/01 13:06:30', 'year negative addition';
$dt5 = $dt3->subtract_years(12);
isa_ok $dt5, $CLASS, 'subtract_years result' or diag('    isa ', ref $dt5);
is $dt5->strftime($FMT), '1998/01/01 13:06:30', 'year subtraction';


# for adding and subtracting seconds, minutes, hours, days, and weeks,
# we can just test against adding the equivalent integers
# (since we've already established that that part works)
for (0..120)					# 120 is _mostly_ arbirtary; it's big enough to be 2 of
{								# the next highest unit for every possible unit
	is $dt1->add_seconds($_), 		$dt1 + $_,						"adding $_ seconds works";
	is $dt1->add_minutes($_), 		$dt1 + $_ * 60,					"adding $_ minutes works";
	is $dt1->add_hours($_),   		$dt1 + $_ * 60 * 60,			"adding $_ hours works";
	is $dt1->add_days($_),    		$dt1 + $_ * 60 * 60 * 24,		"adding $_ days works";
	is $dt1->add_weeks($_),   		$dt1 + $_ * 60 * 60 * 24 * 7,	"adding $_ weeks works";

	is $dt1->subtract_seconds($_),	$dt1 - $_,						"subtracting $_ seconds works";
	is $dt1->subtract_minutes($_),	$dt1 - $_ * 60,					"subtracting $_ minutes works";
	is $dt1->subtract_hours($_),	$dt1 - $_ * 60 * 60,			"subtracting $_ hours works";
	is $dt1->subtract_days($_),		$dt1 - $_ * 60 * 60 * 24,		"subtracting $_ days works";
	is $dt1->subtract_weeks($_),	$dt1 - $_ * 60 * 60 * 24 * 7,	"subtracting $_ weeks works";
}


done_testing;
