#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
  require Test::More;
  plan(skip_all => 'these tests are for release candidate testing');
}

#---------------------------------------------------------------------

eval 'use Test::Pod 1.41';  ## no critic (eval)
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
