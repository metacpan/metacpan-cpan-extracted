
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::Most 0.25;

use Date::Easy;
use POSIX qw< tzset >;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< compare_times date_parse_test_cases date_parse_result >;


my $zoneinfo = "/usr/share/zoneinfo";
die("can't find timezone files to test with!") unless -d $zoneinfo;

foreach (`find $zoneinfo -type f`)
{
	chomp;
	s{^$zoneinfo/}{};
	$ENV{TZ} = $_;
	# For maximum compatibility with all versions of Perl.
	# see: http://stackoverflow.com/questions/753346/how-do-i-set-the-timezone-for-perls-localtime#753424
	tzset();

	my $td = date("04/95 00:22:12 PDT");
	is join('-', $td->year, $td->month, $td->day), '1995-4-1', "simple parse in timezone: $_";

	# Make sure we get correct answers for values our unit tests will parse for date testing, since
	# those can vary by timezone.  Except ignore timezones with leap seconds, since those are never
	# going to work anyway.
	unless ( m|^right/| )
	{
		foreach my $t (date_parse_test_cases())
		{
			compare_times(date($t), date_parse_result($t), "date parse correct for $t in timezone $_")
					or diag "timezone offset: ", datetime($t)->strftime("%z");
		}
	}
}


done_testing;
