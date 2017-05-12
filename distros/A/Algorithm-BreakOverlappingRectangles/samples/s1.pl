#!/usr/bin/perl

use warnings;
use strict;

use Algorithm::BreakOverlappingRectangles;

my $a = Algorithm::BreakOverlappingRectangles->new;

while(<DATA>) {
    next if /^\s*$/;
    chomp;
    $a->add_rectangle(split/,/);
}

$a->dump;

# 10,10,13,11,f
# 10,10,11,13,g

__DATA__
0,1,5,5,a
2,2,6,6,b
2,2,3,3,c
1,0,2,10,d
0,2,7,3,e
0,0,1,10,f


