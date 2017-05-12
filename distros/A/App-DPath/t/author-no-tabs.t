
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
    'bin/dpath',
    'lib/App/DPath.pm',
    't/00-compile.t',
    't/00-load.t',
    't/app_dpath.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/example.yaml10',
    't/flatabledata.yaml',
    't/release-pod-coverage.t',
    't/taparchive.t',
    't/testdata.cfggeneral',
    't/testdata.dumper',
    't/testdata.ini',
    't/testdata.json',
    't/testdata.tap',
    't/testdata.xml',
    't/testdata.yaml',
    't/yaml.t'
);

notabs_ok($_) foreach @files;
done_testing;
