#!/usr/bin/perl -w

use strict;
use blib;
use Convert::SciEng;

my $sp = Convert::SciEng->new('spice');
my $si = Convert::SciEng->new('si');
my $cs = Convert::SciEng->new('cs');

print "Scalar\n";
print $sp->unfix('2.34u'), "\n\n";

print "Array\n";
print join "\n", $sp->unfix(qw( 30.6k  10x  0.03456m  123n 45o)), "\n";

##Note, default format is 5.5g
print "Default format is %5.5g\n";
print join "\n", $sp->fix(qw( 35e5 0.123e-4 200e3 )), "";
$sp->format('%8.2f');
print "Change the format is %8.2g\n";
print join "\n", $sp->fix(qw( 35e5 0.123e-4 200e3 )), "";

print "Check out the SI conversion\n";
print join "\n", $si->unfix(qw( 30.6K  10M  0.03456m  123n 45o)), "";

print "Check out the CS conversion\n";
print join "\n", $cs->unfix(qw( 1K  2K  5M )), "";

print "Check out the CS conversion\n";
print join "\n", $cs->fix(qw( 1023 0.15 1024 1000000 )), "";

