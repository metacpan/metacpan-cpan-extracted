
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::Most 0.25;

use Date::Easy;
use POSIX qw< tzset >;


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
}


done_testing;
