
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/BenchmarkAnything/Storage/Backend/SQL.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/SQLite.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/common.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Query/mysql.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Search.pm',
    'lib/BenchmarkAnything/Storage/Backend/SQL/Search/MCE.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/release-pod-coverage.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
