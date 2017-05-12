#!/usr/bin/perl

use Test::Harness qw<runtests>;

my @cores = qw<DumbCache DecisionTree>;   
# Slow is already tested by "make test"
# Because it is default

for my $core (@cores) {
    $ENV{CMMP_DEFAULT_MULTI_CORE} = $core;
    print "*** $core core ***\n";
    runtests(glob 't/*.t');
}
