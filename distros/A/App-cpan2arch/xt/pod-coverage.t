#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::Require::Module qw< Test::Pod::Coverage >;
use Test::Pod::Coverage;

all_pod_coverage_ok();
