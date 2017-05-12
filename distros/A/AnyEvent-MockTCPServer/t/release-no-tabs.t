
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
    'lib/AnyEvent/MockTCPServer.pm',
    't/01-simple.t',
    't/02-unexpected.t',
    't/03-two.t',
    't/04-timeout.t',
    't/05-error.t',
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
