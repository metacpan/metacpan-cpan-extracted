
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
    'bin/dpath',
    'lib/App/DPath.pm',
    't/00-compile.t',
    't/00-load.t',
    't/app_dpath.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/example.yaml10',
    't/flatabledata.yaml',
    't/subs.t',
    't/taparchive.t',
    't/testdata.cfggeneral',
    't/testdata.dumper',
    't/testdata.empty',
    't/testdata.ini',
    't/testdata.json',
    't/testdata.tap',
    't/testdata.xml',
    't/testdata.yaml',
    't/yaml.t'
);

notabs_ok($_) foreach @files;
done_testing;
