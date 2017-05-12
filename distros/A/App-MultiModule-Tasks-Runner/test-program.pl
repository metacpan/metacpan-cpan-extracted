#!/usr/bin/perl

use strict;use warnings;
$| = 1;

my $arg = shift || 'nothing';
my $start = time;

for (1..5) {
    my $delta = time - $start;
    my $sleep = $_;
    print "$arg : ct = $_ : sleep = $sleep : delta = $delta\n";
    sleep $sleep;
}
