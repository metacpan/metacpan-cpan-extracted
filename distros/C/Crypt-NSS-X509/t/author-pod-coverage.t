
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => "Author testing disabled");
  }
}

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD Coverage" if $@;
all_pod_coverage_ok( { also_private => ['dl_load_flags'] } );
