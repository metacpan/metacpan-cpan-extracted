
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
    'lib/Alien/TidyHTML5.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-tidy.t',
    't/author-clean-namespaces.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/etc/perlcritic.rc',
    't/release-check-manifest.t',
    't/release-trailing-space.t'
);

notabs_ok($_) foreach @files;
done_testing;
