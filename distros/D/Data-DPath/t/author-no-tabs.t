
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Data/DPath.pm',
    'lib/Data/DPath/Attrs.pm',
    'lib/Data/DPath/Context.pm',
    'lib/Data/DPath/Filters.pm',
    'lib/Data/DPath/Path.pm',
    'lib/Data/DPath/Point.pm',
    'lib/Data/DPath/Step.pm',
    't/00-compile.t',
    't/00-load.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/basics_without_overload.t',
    't/bigdata.dump',
    't/bigdata2.dump',
    't/cyclic_structures.t',
    't/data_dpath.t',
    't/data_dpath_path_unescape.t',
    't/iterator.t',
    't/matchr.t',
    't/optimization.t',
    't/parallel.t',
    't/path.t',
    't/references.t',
    't/regressions.t',
    't/release-pod-coverage.t',
    't/zeros.t'
);

notabs_ok($_) foreach @files;
done_testing;
