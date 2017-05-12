
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => "Author testing disabled");
  }
}

use Test::More;
eval "use Test::Version { is_strict => 1, has_version => 1 }";
plan skip_all => "Test::Version required" if $@;

version_all_ok();
done_testing;
