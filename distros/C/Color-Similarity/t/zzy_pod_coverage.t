#!/usr/bin/perl -w

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
plan( tests => 3 );
pod_coverage_ok( 'Color::Similarity' );
pod_coverage_ok( 'Color::Similarity::RGB' );
pod_coverage_ok( 'Color::Similarity::Lab' );
