#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'Set RELEASE_TESTING=1 to run this test'
  if not $ENV{RELEASE_TESTING};
eval "use Test::Pod";
plan skip_all => 'Needs Test::Pod'
  if $@;
all_pod_files_ok();
