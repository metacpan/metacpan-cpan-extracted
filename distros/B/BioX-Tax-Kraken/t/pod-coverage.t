#!perl -T

use strict;
use warnings;
use 5.016;

use Test2::V0;
use Test::Pod::Coverage 1.08;

# Automatically checks all modules found in your distribution's lib/ directory
all_pod_coverage_ok();
