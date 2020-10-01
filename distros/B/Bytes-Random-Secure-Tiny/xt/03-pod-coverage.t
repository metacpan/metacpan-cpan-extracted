#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# Minimum versions:
my $min_tpc = '1.08';   # Test::Pod::Coverage minimum.

# Older versions of Pod::Coverage don't recognize some common POD styles.
my $min_pc  = '0.18';   # Pod::Coverage minimum.


unless(
  $ENV{RELEASE_TESTING}
  && eval "use Test::Pod::Coverage $min_tpc; 1;"  ## no critic (eval)
  && eval "use Pod::Coverage $min_pc; 1;"         ## no critic (eval)
) {
  plan skip_all =>
  "POD Coverage tests only run when RELEASE_TESTING is set, *and*\n" .
  "both Test::Pod::Coverage and Pod::Coverage are available on target system.";
}

all_pod_coverage_ok();
