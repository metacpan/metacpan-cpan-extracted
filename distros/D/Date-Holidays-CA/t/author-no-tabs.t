
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
    'lib/Date/Holidays/CA.pm',
    't/01usage.t',
    't/02stress.t',
    't/03sanity.t',
    't/04correctness.t',
    't/05internals.t',
    't/10pod.t',
    't/11pod-coverage.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
