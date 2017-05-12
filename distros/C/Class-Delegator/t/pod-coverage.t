#!perl -w

# $Id: pod-coverage.t 1168 2005-01-28 00:04:16Z david $

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.06";
plan skip_all => "Test::Pod::Coverage 1.06 required for testing POD coverage"
  if $@;

all_pod_coverage_ok();
