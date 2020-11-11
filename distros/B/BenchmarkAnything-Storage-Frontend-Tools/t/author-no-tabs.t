
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
    'bin/benchmarkanything-storage',
    'lib/BenchmarkAnything/Storage/Frontend/Tools.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/benchmarkanything-mysql.cfg',
    't/benchmarkanything.cfg',
    't/cli.t',
    't/query-benchmark-anything-01-expectedresult.json',
    't/query-benchmark-anything-01.json',
    't/query-benchmark-anything-02-expectedresult.json',
    't/query-benchmark-anything-02.json',
    't/query-benchmark-anything-03-expectedresult.json',
    't/query-benchmark-anything-03.json',
    't/query-benchmark-anything-04-expectedresult.json',
    't/query-benchmark-anything-04.json',
    't/release-pod-coverage.t',
    't/valid-benchmark-anything-data-01.json',
    't/valid-benchmark-anything-data-02.json'
);

notabs_ok($_) foreach @files;
done_testing;
