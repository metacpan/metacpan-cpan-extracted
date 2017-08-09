
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
    'lib/AnyEvent/MockTCPServer.pm',
    't/01-simple.t',
    't/02-unexpected.t',
    't/03-two.t',
    't/04-timeout.t',
    't/05-error.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-no404s.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/release-common_spelling.t',
    't/release-kwalitee.t',
    't/release-pod-linkcheck.t'
);

notabs_ok($_) foreach @files;
done_testing;
