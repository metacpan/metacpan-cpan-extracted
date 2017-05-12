#!/usr/bin/perl -w

use strict;
use if !$ENV{AUTHOR_TESTS}, 'Test::More' => skip_all => 'Author tests';
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
plan( tests => 1 );
pod_coverage_ok( 'Color::Similarity::HCL' );
