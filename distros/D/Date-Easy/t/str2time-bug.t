use Test::Most 0.25;

use Date::Easy;

use Time::Local;
use Date::Parse;

# local test modules
use File::Spec;
use Cwd 'abs_path';
use File::Basename;
use lib File::Spec->catdir(dirname(abs_path($0)), 'lib');
use DateEasyTestUtil qw< is_32bit >;


# Date::Parse has a bug where any year from 1901 to [49 years ago] (inclusive) is mishandled during
# the trip through `strptime`.  This bug has been reported multiple times: RT/53413, RT/84075,
# RT/105031, and possibly others.  In the first of those, notice that Graham Barr says this is not a
# bug.  However, given this:
#
# 	perl -MDate::Parse -le 'print "$_ => ", scalar localtime str2time($_) for "1923-01-01"'
# 	1923-01-01 => Sun Jan  1 00:00:00 2023
#
# I'm not sure how to consider it anything *but* a bug.  At some point I may wade into that debate
# and try to convince someone to fix it (and hopefully even submit a patch!).  For now, though, it
# looks like we just need to come up with a workaround.
#
# This unit test file tests every year from 1000 to 2899, which are the bounds of what Time::Local
# can handle.  Of course, a 32-bit machine running < Perl 5.12 will have a smaller range, so
# anything outside the 1901 - 2038 range is skipped when we can detect that situation.


# Using a string eval here in case the Perl is so old it can't understand v# notation.
# Of course, if the Perl is truly that old, we likely have much bigger problems, but still.
my $use_smaller_range = is_32bit() && !eval "require v5.12";

foreach (1000..2899)
{
	SKIP:
	{
		skip "out of range for 32-bit machines in older Perls"
				# these might need to be <= and/or >= ... waiting for a verdict from CPAN Testers
				if $use_smaller_range and ( $_ < 1901 or $_ > 2038-00-00 );
		is datetime("$_-01-01")->year, $_, "survived Date::Parse bug for year $_";
	}
}


done_testing;
