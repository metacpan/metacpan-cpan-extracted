#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(usleep);

my $num=$ARGV[0];
open(FH, "output_sample_$num");
my $x;

while (<FH>) {
    $x .= $_;
    if (/B:/) {
        print $x; $x='';
        usleep(100000);
        print "\n"x24;
    }
}
