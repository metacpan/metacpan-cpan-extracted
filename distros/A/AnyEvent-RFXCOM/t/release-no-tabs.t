
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/rfxcom-anyevent-rx',
    'bin/rfxcom-anyevent-tx',
    'bin/w800-anyevent-rx',
    'lib/AnyEvent/RFXCOM.pod',
    'lib/AnyEvent/RFXCOM/Base.pm',
    'lib/AnyEvent/RFXCOM/RX.pm',
    'lib/AnyEvent/RFXCOM/TX.pm',
    'lib/AnyEvent/W800.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-rx.t',
    't/01-tx.t',
    't/02-w800.t',
    't/author-critic.t',
    't/author-test-eol.t',
    't/release-common_spelling.t',
    't/release-kwalitee.t',
    't/release-no-tabs.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t',
    't/release-synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
