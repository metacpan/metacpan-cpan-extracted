#!perl -T

use Test::More;

plan skip_all => "Test::Pod - AUTHOR_TESTING not set"
  unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

all_pod_files_ok();
