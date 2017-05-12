use Test::Most 0.25;

use Date::Easy;

use Time::Local;
use Date::Parse;
use Time::ParseDate;

use List::Util 1.39 qw< pairs >;					# minimum version for pairs returning objects

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< compare_times generate_times_and_compare >;
use DateParseTests qw< %DATE_PARSE_TESTS _date_parse_has_timezone >;
use TimeParseDateTests qw< @TIME_PARSE_DATE_TESTS >;


# Check to make sure epoch seconds are not pumped through a parser.
# (This somewhat mirrors the first set of tests in t/date.t,
# except we don't have to worry about datestrings.)

my %TEST_DATES =
(
	1426446360		=>	'2015-03-15',				# simple epoch
	-99590400		=>	'1966-11-05',				# epoch (negative)
);

my $t;
foreach (keys %TEST_DATES)
{
	lives_ok { $t = datetime($_) } "parse survival: $_";
	compare_times($t, local => $_, "successful parse: $_");

	# now try the UTC version
	lives_ok { $t = datetime(UTC => $_) } "parse survival: $_";
	compare_times($t, UTC => $_, "successful parse: $_");
}


# now rifle through everything that str2time can handle

# This is the same method used in t/date-parse.t to make sure we don't fallback to parsing with
# Time::ParseDate.  See full comments over there.
my $using_fallback;
{
	no warnings 'redefine';
	*Date::Easy::Date::_parsedate_orig = \&Date::Easy::Date::_parsedate;
	*Date::Easy::Date::_parsedate = sub { $using_fallback = 1; &Date::Easy::Date::_parsedate_orig };
}

foreach (keys %DATE_PARSE_TESTS)
{
	$using_fallback = 0;							# always reset this before calling datetime() (see above)
	# local
	lives_ok { $t = datetime($_) } "parse survival: $_";
	compare_times($t, local => local_adjusted($_, $DATE_PARSE_TESTS{$_}), "successful default parse: $_");
	# and UTC
	lives_ok { $t = datetime(UTC => $_) } "parse survival: $_";
	compare_times($t, UTC => $DATE_PARSE_TESTS{$_}, "successful UTC parse: $_");
	# explicit local
	lives_ok { $t = datetime(local => $_) } "parse survival: $_";
	compare_times($t, local => local_adjusted($_, $DATE_PARSE_TESTS{$_}), "successful local parse: $_");
	{
		# tricky one:
		local $Date::Easy::Datetime::DEFAULT_ZONE = 'UTC';
		compare_times(datetime($_), UTC => $DATE_PARSE_TESTS{$_}, "successful default UTC parse: $_");
	}
	is $using_fallback, 0, "parsed $_ without resorting to fallback";
}


# now rifle through everything that parsedate can handle

foreach (pairs @TIME_PARSE_DATE_TESTS)
{
	my ($str, $orig_t, @args) = ( $_->key, @{ $_->value } );
	# anything which str2date can successfully parse would be handled by it, not parsedate
	# so skip those
	next if defined str2time($str);

	# In the calls to parsedate() below, we have to force scalar context.  Remember, parsedate
	# called in list context also returns the "remainder" of the parsed string (which would always
	# be undef, which could wreak havoc with a function call which just used the rerturn value(s),
	# particularly one to _mktime).

	# If parsedate() won't parse this (e.g. because it requires PREFER_PAST or PREFER_FUTURE, which
	# we're not going to supply, or because it's just expected to fail), skip this test.
	next unless defined scalar parsedate($str);

	# We have to use `generate_times_and_compare` as opposed to `compare_times`, because some of our
	# test values are relative, meaning relative to the current time, meaning that if the clock
	# happens to roll over between the call to `datetime` and the call to `parsedate`, the seconds
	# won't match.  Which is exactly what `generate_times_and_compare` is designed to fix.

	# local
	generate_times_and_compare
	{
		lives_ok { $t = datetime($str) } "parse survival (local): $str";
		$t, local => scalar parsedate($str)
	}
		"successful default parse: $str";
	# and UTC
	generate_times_and_compare
	{
		lives_ok { $t = datetime(UTC => $str) } "parse survival (UTC): $str";
		$t, UTC => scalar parsedate($str, GMT => 1)
	}
		"successful UTC parse: $str";
	# just to be safe
	{
		local $Date::Easy::Datetime::DEFAULT_ZONE = 'UTC';
		generate_times_and_compare { datetime($str), UTC => scalar parsedate($str, GMT => 1) }
				"successful default UTC parse: $str";
	}
}


# these are the same tests for 0 epoch seconds we do in ::Date (and for the same reasons)
foreach (
			0,										# handled internally (epoch seconds)
			'1970-1-1-00:00:00 GMT',				# handled by Date::Parse
			'1970/01/01 GMT foo',					# handled by Time::ParseDate (zero in UTC)
		)
{
	compare_times(datetime(UTC => $_), UTC => 0, "successful 0 parse: $_");
}

# we need to deal with both 0 UTC and whatever actual day 0 local time is
# (however, local time can only return 0 differently than UTC in the case of Time::ParseDate)
foreach (
			# handled by Time::ParseDate (zero in localtime)
			Time::Piece->_mktime(0, 1)->strftime("%Y/%m/%d %H:%M:%S foo"),
		)
{
	TODO:
	{
		# This test only works if the local timezone is not currently in DST.
		# See: https://github.com/muir/Time-modules/issues/8
		local $TODO = "wating for a bug fix in Time::ParseDate" if (localtime)[8];
		compare_times(datetime($_), local => 0, "successful local 0 parse: $_");
	}
}


done_testing;


sub local_adjusted
{
	my ($string, $time) = @_;

	# First, figure out whether this datetime needs to be local-adjusted or not.
	# The Parse::Date unit tests did this by knowing how many tests needed to be adjusted and just
	# using a hardcoded number (i.e. the first N tests get adjusted).
	# That seems too fragile to me, so I'm going to use the same method I did when testing `date`:
	# use a regex to figure out whether the string contains a timezone specifier or not.
	# If it does, no adjustment is necessary.
	return $time if _date_parse_has_timezone($string);

	# This code is lifted from GBARR/TimeDate-1.17/t/getdate.t, lines 177-192.
	# ( https://github.com/gbarr/perl-TimeDate/blob/v1.17/t/getdate.t#L177-L192 )
	# Some changes were made:
	# 	*	The original code adjusted the returned time.  I'm adjusting the expected time instead.
	# 		Because of this, the last line of the original code uses -=; my code uses +=.
	# 	*	The original code takes the localtime and gmtime of the expected time; I use the
	# 		returned time.  Since these are only used for the delta between the two, this shouldn't
	# 		make any difference.  I suppose if the DST cutover time had reached UTC but not the
	# 		local time (or vice-versa?), it _could_, theoretically, maybe?  But that situation
	# 		doesn't seem to exist in the current test data set.
	# Other than that the code is identical.
	my @lt = localtime($time);
	my @gt = gmtime($time);

	my $tzsec = ($gt[1] - $lt[1]) * 60 + ($gt[2] - $lt[2]) * 3600;

	my($lday,$gday) = ($lt[7],$gt[7]);
	if($lt[5] > $gt[5]) {
		$tzsec -= 24 * 3600;
	}
	elsif($gt[5] > $lt[5]) {
		$tzsec += 24 * 3600;
	}
	else {
		$tzsec += ($gt[7] - $lt[7]) * (24 * 3600);
	}
	$time += $tzsec;
	# END STOLEN CODE

	return $time;
}
