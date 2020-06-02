#!/usr/bin/perl

use strict;
use warnings;
use Business::DK::CPR qw(validate2007);

my %series = (
    10 => 9994,
    8  => 9998,
    12 => 9996,
    7  => 9997,
    9  => 9999,
    11 => 9995,
);


while (my ($key, $value)  = each %series) {
    foreach ( $key .. $value ) {
        my $n = sprintf( "%04s", $_ );
        my $controlnumber = '150172'.$n;
        
        if (! validate2007($controlnumber)) {
            print STDERR "Invalid = $controlnumber\n";
        }
    }
}