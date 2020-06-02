#!/usr/bin/perl -w

use strict;

my @integers = qw(0 1 2);

foreach (@integers) {
    print "integer $_ % 2 = ";
    print $_%2;
    print "\n";
}