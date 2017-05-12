#!/usr/bin/perl

use strict;
use warnings;

sub get_inhours_time {
    # pick a date that's during business hours
    my $starttime = 0;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    while ($wday == 0  || $wday == 6) {
        $starttime += ( 24 * 60 * 60);
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    }
    while ( $hour < 9 || $hour >= 18 ) {
        $starttime += ( 4 * 60);
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    }
    return $starttime;
}

sub get_outofhours_time {
    
    # pick a date that's not during business hours
    my $starttime = 0;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    while ( $wday != 0 ) {
        $starttime += ( 24 * 60 * 60);
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($starttime);
    }
    return $starttime;
}

1;
