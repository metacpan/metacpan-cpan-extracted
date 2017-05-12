#!/usr/bin/perl -w
use strict;
use warnings;
use Date::Holidays::CZ qw(holidays);

# Sample script for Date::Holidays::CZ

# Original script for Date::Holidays::DE by Martin Schmitt <mas at scsy dot de>
# modified by Nathan Cutler <ncutler@suse.com>

# Assign full names to the internal aliases from Date::Holidays::CZ
# See the manpage for a list of all aliases.
my %svatky_full_names = (
    'obss' => 'Restoration Day of the Independent Czech State',
    'veln' => 'Easter Sunday',
    'velp' => 'Easter Monday', 
    'svpr' => 'Labor Day', 
    'dvit' => 'Liberation Day',
    'cyme' => 'Saints Cyril and Methodius Day',
    'mhus' => 'Jan Hus Day',
    'wenc' => 'Feast of St. Wenceslas (Czech Statehood Day)',
    'vzcs' => 'Independent Czechoslovak State Day',
    'bojs' => 'Struggle for Freedom and Democracy Day',
    'sted' => 'Christmas Eve',
    'van1' => 'Christmas Day',
    'van2' => 'Feast of St. Stephen',
);

# This year is $tento
my $tento    = (localtime(time()))[5] + 1900;

# Next year is $pristi
my $pristi = $tento + 1;

# Get the list of holidays for next year
my @svatky = @{holidays( WHERE  => ['all'], 
                         FORMAT => "%#:%d.%m.%Y (%s seconds since the epoch)",
                         YEAR   => $pristi
             )};

print "Czech holidays in $pristi:\n";
print "-----------------------\n";

foreach (@svatky){
	# Split name and date
	my ($name, $datum) = split /:/;
	# Print name from $svatky_full_names along with the date
	printf ("%-46s: %10s\n", $svatky_full_names{$name}, $datum);
}

exit 0;
