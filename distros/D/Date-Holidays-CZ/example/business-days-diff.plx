#!/usr/bin/perl -w
use strict;
use warnings;
use Date::Holidays::CZ qw(holidays);
use Date::Business;

# Sample script for integration of Date::Holidays::CZ with Date::Business

# Original script for Date::Holidays::DE by Martin Schmitt <mas at scsy dot de>
# modified by Nathan Cutler <ncutler@suse.com>

# Calculate the difference between two dates using three different
# methods from Date::Business

my $startdate = "20100329";    # Monday before Easter 2010
my $enddate   = "20100412";    # Monday after Easter monday 2010
my $year      = "2010";        # Not particularly elaborate, but okay for now

print "Distance between $startdate and $enddate...\n";

# 1. Not excluding weekends and holidays (Should be 14 days difference)
#
# Initialize start and ending dates
my $start1    = new Date::Business(DATE => $startdate);
my $end1      = new Date::Business(DATE => $enddate);
my $diff1     = $end1->diff($start1);
print "$diff1 days (weekends and holidays included)\n";

# 2. Excluding weekends (Should be 10 days difference)
#
# Initialize start and ending dates
my $start2    = new Date::Business(DATE => $startdate);
my $end2      = new Date::Business(DATE => $enddate);
my $diff2     = $end2->diffb($start2);
print "$diff2 days (holidays included, weekends excluded)\n";

# 3. Excluding weekends and holidays (Should be 8 days difference)
#
# Prepare a subroutine for use by Date::Business
sub business_holiday{
	my ($start, $end) = @_;
	my $count;
	# Get the holiday list from Date::Holidays::DE
	my @holidays = @{holidays(YEAR=>$year, 
				  FORMAT => "%Y%m%d", # This is important here
				  WEEKENDS => 0)};
	foreach (@holidays){
		# Count holidays between the start and end dates
		$count++ if (($start <= $_) and ($_ <= $end));
	}
	return $count;
}

# Initialize start and ending dates including reference to the above subroutine
my $start3    = new Date::Business(DATE => $startdate,
				   HOLIDAY => \&business_holiday);
my $end3      = new Date::Business(DATE => $enddate,
				   HOLIDAY => \&business_holiday);
my $diff3     = $end3->diffb($start3);
print "$diff3 days (holidays and weekends excluded)\n";

exit 0;
