
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.07

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dancer2/Template/TextTemplate.pm',
    'lib/Dancer2/Template/TextTemplate/FakeEngine.pm',
    't/000-report-versions-tiny.t',
    't/00_base.t',
    't/01_engine.t',
    't/02_fails.t',
    't/03_prepend.t',
    't/04_safe.t',
    't/author-critic.t',
    't/author-pod-spell.t',
    't/release-changes_has_content.t',
    't/release-distmeta.t',
    't/release-eol.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/test.template'
);

notabs_ok($_) foreach @files;
done_testing;
