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
use DateEasyTestUtil qw< is_32bit compare_times date_parse_test_cases date_parse_result >;
use DateParseTests qw< %DATE_PARSE_TESTS _date_parse_remove_timezone >;
use TimeParseDateTests qw< @TIME_PARSE_DATE_TESTS get_ymd_from_parsedate >;


# First go through stuff we handle specially: integers which may or not be interprested as epoch
# seconds, or else might be a datestring (that is, YYYYMMDD).  See the `%TEST_DATES` hash in
# t/lib/DateEasyTestUtil.pm for full details.

my $t;
my $on_32bit_machine = is_32bit();
foreach (date_parse_test_cases())
{
	TODO:
	{
		my $expected = date_parse_result($_);
		local $TODO = "out of range for 32-bit machines"
				if $on_32bit_machine and ( $expected le '1901-99-99' or $expected ge '2038-00-00' );
		lives_ok { $t = date($_) } "parse survival: $_";
		compare_times($t, $expected, "successful parse: $_")
				or diag "timezone offset: ", datetime($_)->strftime("%z");
	}
}


# now rifle through everything that str2time can handle

# If our invocation of str2time (or, more accurately, str2time's guts) fails, our fallback will be
# such that it will just pass the parsing on to parsedate, which might very well succeed.  However,
# for this loop, str2time should *not* fail, so we need to consider a parsedate success as a test
# failure.  In order to achieve this, we're going to wrap Date::Easy::Date::_parsedate with a local
# closure that notifies us if the fallback triggers.
my $using_fallback;
{
	no warnings 'redefine';
	*Date::Easy::Date::_parsedate_orig = \&Date::Easy::Date::_parsedate;
	*Date::Easy::Date::_parsedate = sub { $using_fallback = 1; &Date::Easy::Date::_parsedate_orig };
}

foreach (keys %DATE_PARSE_TESTS)
{
	$using_fallback = 0;							# always reset this before calling date() (see above)
	lives_ok { $t = date($_) } "parse survival: $_";
	# figure out what the proper date *should* be by dropping any timezone specifier
	my $proper = _date_parse_remove_timezone($_);
	compare_times($t, local => str2time($proper), "successful parse: $_")
			or diag("compared against parse of: $proper");
	is $using_fallback, 0, "parsed $_ without resorting to fallback";
}
# could undo our monkey patch here, but it isn't hurting anything, and we might find it useful later


# a few basic tests for the parsedate side of it

my $tomorrow = today + 1;
$t = date("tomorrow");
compare_times($t, $tomorrow, "successful parse: tomorrow");

# this one is known to be unparseable by str2time()
# (taken from MUIR/Time-ParseDate-2013.1113/t/datetime.t)
$t = date('950404 00:22:12 "EDT');
compare_times($t, '1995-04-04', "successful parse: funky datestring plus time");


# now rifle through everything that parsedate can handle

foreach (pairs @TIME_PARSE_DATE_TESTS)
{
	my ($str, $orig_t, @args) = ( $_->key, @{ $_->value } );
	# anything which str2date can successfully parse would be handled by it, not parsedate
	# so skip those
	next if defined str2time($str);

	# If parsedate() won't parse this (e.g. because it requires PREFER_PAST or PREFER_FUTURE, which
	# we're not going to supply, or because it's just expected to fail), skip this test.
	next unless defined parsedate($str);

	# If the only thing that would cause parsedate to fail is not having a date (e.g. "now +4 secs"),
	# let's test that and make sure date() fails as well.
	unless ( defined parsedate($str, DATE_REQUIRED => 1) )
	{
		throws_ok { date($str) } qr/Illegal date/, "correctly refused to parse: $str";
		next;
	}

	# if we got this far, the parse shouldn't blow up
	lives_ok { $t = date($str) } "parse survival: $str";

	# and the date generated should be the same date that we would generate from the year, month,
	# and day that we *would* get out of parsedate if it actually returned those things
	# (since it doesn't, we have to use our hacky simulation of how that would work, if it worked;
	# see get_ymd_from_parsedate in TimeParseDateTests)
	my $d; lives_ok { $d = Date::Easy::Date->new(get_ymd_from_parsedate($str)) }
			"[sanity check] test parse survival: $str";
	compare_times($t, $d, "successful parse: $str");
}


# insure we properly handle a time of 0 (i.e. the exact day of the epoch)
my $local_epoch = timelocal gmtime 0;				# for whatever timezone we happen to be in
foreach (
			$local_epoch,							# handled internally (epoch seconds)
			'19700101',								# handled internally (compact datestring)
			'1970-1-1-00:00:00 GMT',				# handled by Date::Parse
			'1970/01/01 foo',						# handled by Time::ParseDate (zero in UTC)
		)
{
	compare_times(date($_), UTC => 0, "successful 0 parse: $_");
}

# we need to deal with both 0 UTC and whatever actual day 0 local time is
# (however, local time can only return 0 differently than UTC in the case of Time::ParseDate)
foreach (
			# handled by Time::ParseDate (zero in localtime)
			Time::Piece->_mktime(0, 1)->strftime("%Y/%m/%d %H:%M:%S foo"),
		)
{
	compare_times(date($_), local => 0, "successful local 0 parse: $_");
}


done_testing;
