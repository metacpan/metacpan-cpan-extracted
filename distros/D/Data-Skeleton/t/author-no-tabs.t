
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
    'lib/Data/Delete.pm',
    'lib/Data/Skeleton.pm',
    't/00-compile.t',
    't/author-critic.t',
    't/author-no-tabs.t',
    't/author-test-version.t',
    't/basic.t',
    't/circular_references.t',
    't/delete.t',
    't/release-cpan-changes.t',
    't/release-distmeta.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
