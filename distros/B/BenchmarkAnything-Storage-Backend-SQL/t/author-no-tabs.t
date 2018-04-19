
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/BenchmarkAnything/Storage/Backend/SQL.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/SQLite.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/common.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/mysql.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Search.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Search/MCE.pm',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/release-pod-coverage.t'
);

notabs_ok($_) foreach @files;
done_testing;
