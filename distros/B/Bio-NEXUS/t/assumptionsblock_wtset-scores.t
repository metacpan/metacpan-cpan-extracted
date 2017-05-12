#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: assumptionsblock_wtset-scores.t,v 1.9 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.9 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu), Mikhail Bezruchko
# Refernce: http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 31th October 2006

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;


############################################
# This file tests the "WTSET CORE_column_scores"
# vector(values) of the "Assumptions" block
############################################
#
# Associated input file: 
# t/data/compliant/02_specific_assumptions-01.nex
#
############################################

print "\n";
print "--- Testing wtset scores ---\n";

my ($nexus_1, $nexus_2, $assumptions, $assumptions_block, $wt_set, $wts);


# Read in the test input
# ...
$nexus_1 = new Bio::NEXUS("t/data/compliant/02_wtset-scores.nex");

$assumptions_block = $nexus_1->get_block("assumptions", "proteinweight");

$assumptions = $assumptions_block->get_assumptions();


# Read in the weightset we need
$wt_set = $assumptions->[0];
$wts = $wt_set->get_weights;

# Check if it matches the expected value
is($wts->[4], '0', "the weight for 3rd character is 0");
is($wts->[16], '1', "...");

my @expected_wts = split (/\s*/, "- - 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 3 0 0 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 0 1 1 1 1 1 2 1 1 1 1 3 3 3 3 3 3 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 3 3 3 3 3 3 3 3 3 3 4 4 3 4 3 3 3 3 3 5 5 5 3 4 4 4 4 4 4 4 4 4 3 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 2 0 1 0 1 0 0 - - -");
my $is_eq = eq_array ($wts, \@expected_wts);

print @expected_wts, "\n";
print @{$wts}, "\n";

is ($is_eq, 1, "the contents match expected");
print Dumper $wts->[3];


# Check if the wtset is what we expect
# this should be:
# - - 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 3 0 0 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 0 1 1 1 1 1 2 1 1 1 1 3 3 3 3 3 3 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 3 3 3 3 3 3 3 3 3 3 4 4 3 4 3 3 3 3 3 5 5 5 3 4 4 4 4 4 4 4 4 4 3 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 2 0 1 0 1 0 0 - - -
#
# add the code after the get(), set() methods
# have been implemented
# ... something like
# my $expected = "- - 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 3 0 0 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 0 1 1 1 1 1 2 1 1 1 1 3 3 3 3 3 3 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 3 3 3 3 3 3 3 3 3 3 4 4 3 4 3 3 3 3 3 5 5 5 3 4 4 4 4 4 4 4 4 4 3 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 2 2 0 1 0 1 0 0 - - -";
#
# wholesome check
# ok(assumptions->get_weight() eq $expected);
#
# individual check
# ok(assumptions->get_weight(column=3) eq "0");

print "write a test that will check [Notokens]\n";


