#!perl
use 5.10.0;
use strict;
use warnings;
use Test::More;

# Mandate the POD tests, contrary to the dagolden no-pod-tests fad. I rank
# documentation on par with the code, not something one can maybe remember to
# maybe run the release testing for.
use Test::Pod::Coverage;
use Pod::Coverage;

all_pod_coverage_ok();
