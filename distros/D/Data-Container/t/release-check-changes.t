#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::CheckChanges";
plan skip_all => "Test::CheckChanges required for testing changes"
  if $@;
ok_changes();