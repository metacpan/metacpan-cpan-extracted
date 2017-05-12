#!perl

use Test::More;

eval "use Test::HasVersion";
plan skip_all => "Test::HasVersion required for testing version numbers"
  if $@;
all_pm_version_ok();
