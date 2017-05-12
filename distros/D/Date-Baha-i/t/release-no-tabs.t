
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Date/Baha/i.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-as_string.t',
    't/02-from_bahai.t',
    't/03-misc.t',
    't/04-to_bahai.t',
    't/author-pod-spell.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
