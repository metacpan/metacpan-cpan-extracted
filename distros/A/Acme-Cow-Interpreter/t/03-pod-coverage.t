#!/usr/bin/perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-02-28 19:51:37 +01:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

use Test::More;

# Ensure a recent version of Test::Pod::Coverage

my $tpc     = 'Test::Pod::Coverage';
my $min_tpc = 1.08;
eval "use $tpc $min_tpc";
plan skip_all => "$tpc $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles

my $pc     = 'Pod::Coverage';
my $min_pc = 0.18;
eval "use $pc $min_pc";
plan skip_all => "$pc $min_pc required for testing POD coverage"
    if $@;

all_pod_coverage_ok();

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
