use Test::Most 0.25;

use Date::Easy 'GMT';								# makes the epoch predictable


##########
# DATETIME
##########

# test datetime: 3 Feb 2001, 04:05:06
my $dt = Date::Easy::Datetime->new(2001, 2, 3, 4, 5, 6);
# epoch works out to:
my $epoch = 981173106;
# time zone should match whatever the local zone is
my $zone = now->strftime("%Z");

# basic accessors
is $dt->year,       2001,     "year accessor is correct for datetime";
is $dt->month,         2,    "month accessor is correct for datetime";
is $dt->day,           3,      "day accessor is correct for datetime";
is $dt->hour,          4,     "hour accessor is correct for datetime";
is $dt->minute,        5,   "minute accessor is correct for datetime";
is $dt->second,        6,   "second accessor is correct for datetime";
is $dt->epoch,    $epoch,    "epoch accessor is correct for datetime";
is $dt->time_zone, $zone, "timezone accessor is correct for datetime";

# simple split test
eq_or_diff [$dt->split], [2001, 2, 3, 4, 5, 6], "can split datetime into component pieces";

# try every day of the week, to insure we're getting the proper range
# start with the first Monday in 2000 (Jan 3rd)
for (1..7)
{
	$dt = Date::Easy::Datetime->new(2000, 1, $_ + 2, 0, 0, 0);
	is $dt->day_of_week, $_, "dow accessor is correct for datetime on " . $dt->strftime('%a');
}

# day of year: just test every day for two years (one leap year, one non-leap year)
# starting with: 1 Jan 2015
my $start = Date::Easy::Datetime->new(2015, 1, 1, 0, 0, 0);
my $DAYS = 60 * 60 * 24;
my @expected = (1..365, 1..366);
foreach (0..$#expected)
{
	$dt = $start + $_ * $DAYS;
	is $dt->day_of_year, $expected[$_], "day of year correct for $dt";
}

# make sure we try the full range of quarters as well
# in this case, we'll just try every month
my %MONTH_TO_QUARTER =
(
	 1	=>	1,		 2	=>	1,		 3	=>	1,
	 4	=>	2,		 5	=>	2,		 6	=>	2,
	 7	=>	3,		 8	=>	3,		 9	=>	3,
	10	=>	4,		11	=>	4,		12	=>	4,
);

for (sort { $a <=> $b } keys %MONTH_TO_QUARTER)
{
	$dt = Date::Easy::Datetime->new(2000, $_, 1, 0, 0, 0);
	is $dt->quarter, $MONTH_TO_QUARTER{$_}, "quarter accessor is correct for datetime in " . $dt->strftime('%b');
}


######
# DATE
######

# test date: 3 Feb 2001
my $d = Date::Easy::Date->new(2001, 2, 3);
# epoch works out to:
$epoch = 981158400;

# basic accessors
is $d->year,        2001,     "year accessor is correct for date";
is $d->month,          2,    "month accessor is correct for date";
is $d->day,            3,      "day accessor is correct for date";
is $d->hour,           0,     "hour accessor is correct for date";
is $d->minute,         0,   "minute accessor is correct for date";
is $d->second,         0,   "second accessor is correct for date";
is $d->epoch,     $epoch,    "epoch accessor is correct for date";
is $d->time_zone,  'UTC', "timezone accessor is correct for date"
	or diag "Time::Piece is v$Time::Piece::VERSION (must be at least 1.30)";

# simple split test
eq_or_diff [$d->split], [2001, 2, 3], "can split date into component pieces";

# just like datetimes (see above)
for (1..7)
{
	$d = Date::Easy::Date->new(2000, 1, $_ + 2);
	is $d->day_of_week, $_, "dow accessor is correct for date on " . $d->strftime('%a');
}

# just like datetimes (see above)
$start = Date::Easy::Date->new(2015, 1, 1);
@expected = (1..365, 1..366);
foreach (0..$#expected)
{
	$d = $start + $_;
	is $d->day_of_year, $expected[$_], "day of year correct for $d";
}

# just like datetimes (see above)
for (sort { $a <=> $b } keys %MONTH_TO_QUARTER)
{
	$d = Date::Easy::Date->new(2000, $_, 1);
	is $d->quarter, $MONTH_TO_QUARTER{$_}, "quarter accessor is correct for date in " . $d->strftime('%b');
}


done_testing;
