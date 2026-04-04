#!/usr/local/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Business::UPS;

print "UPS Version " . $Business::UPS::VERSION . "\n\n";

# Track a package using UPStrack()
#
# NOTE: Replace the tracking number below with a real one.
# This will contact UPS servers and return live tracking data.
#
my $tracking_number = shift || '1Z12345E0205271688';

print "Tracking package: $tracking_number\n\n";

my %t = eval { UPStrack($tracking_number) };
if ($@) {
    die "ERROR: $@";
}

print "Current Status: $t{'Current Status'}\n";
print "Service Type:   $t{'Service Type'}\n"   if $t{'Service Type'};
print "Weight:         $t{'Weight'}\n"         if $t{'Weight'};
print "Shipped To:     $t{'Shipped To'}\n"     if $t{'Shipped To'};
print "Delivery Date:  $t{'Delivery Date'}\n"  if $t{'Delivery Date'};
print "Signed By:      $t{'Signed By'}\n"      if $t{'Signed By'};
print "Location:       $t{'Location'}\n"       if $t{'Location'};

if (my $count = $t{'Activity Count'}) {
    print "\nPackage activity ($count events):\n";
    my %activities = %{ $t{'Scanning'} };
    for my $num (1 .. $count) {
        printf "  %s %s - %s (%s)\n",
            $activities{$num}{'date'}     || '',
            $activities{$num}{'time'}     || '',
            $activities{$num}{'activity'} || '',
            $activities{$num}{'location'} || '';
    }
}

print "\n$t{'Notice'}\n";
