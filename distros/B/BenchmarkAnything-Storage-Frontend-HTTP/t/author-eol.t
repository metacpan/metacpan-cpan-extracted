
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
    'bin/benchmarkanything-storage-frontend-http',
    'lib/BenchmarkAnything/Storage/Frontend/HTTP.pm',
    'lib/BenchmarkAnything/Storage/Frontend/HTTP/Controller/Search.pm',
    'lib/BenchmarkAnything/Storage/Frontend/HTTP/Controller/Submit.pm',
    't/00-compile.t',
    't/api.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/basic.t',
    't/benchmarkanything-mysql.cfg',
    't/benchmarkanything.cfg',
    't/query-benchmark-anything-01.json',
    't/query-benchmark-anything-02.json',
    't/query-benchmark-anything-03-expectedresult.json',
    't/query-benchmark-anything-03.json',
    't/query-benchmark-anything-04.json',
    't/release-pod-coverage.t',
    't/valid-benchmark-anything-data-01.json',
    't/valid-benchmark-anything-data-02.json'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
