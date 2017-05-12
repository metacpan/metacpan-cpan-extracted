#!perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use Test::More;

plan skip_all => "Test::Pod::Coverage - AUTHOR_TESTING not set"
  unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod::Coverage 1.04";
plan skip_all =>
  "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;

all_pod_coverage_ok();
