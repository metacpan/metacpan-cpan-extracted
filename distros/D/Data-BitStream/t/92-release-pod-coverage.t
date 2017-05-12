#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

#---------------------------------------------------------------------


use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

my @modules = Test::Pod::Coverage::all_modules();
plan tests => scalar @modules;

foreach my $m (@modules) {
  if ($m eq 'Data::BitStream::Base') {
    pod_coverage_ok( $m, { also_private => [ qr/^(BUILD|DEMOLISH)$/ ] } );
  } else {
    pod_coverage_ok( $m);
  }
}
