
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
    'bin/benchmarkanything-schema',
    'lib/BenchmarkAnything/Schema.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/basic.t',
    't/invalid-benchmark-anything-data-01.json',
    't/invalid-benchmark-anything-data-02.json',
    't/invalid-benchmark-anything-data-03.json',
    't/invalid-benchmark-anything-data-04.json',
    't/release-pod-coverage.t',
    't/valid-benchmark-anything-data-01.json',
    't/valid-benchmark-anything-data-02.json',
    't/valid-benchmark-anything-data-03.json',
    't/validate.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
