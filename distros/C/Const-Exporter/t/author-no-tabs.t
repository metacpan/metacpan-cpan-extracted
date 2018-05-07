
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
    'lib/Const/Exporter.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-basic.t',
    't/11-tags.t',
    't/12-blessed.t',
    't/20-example.t',
    't/21-example.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/empty-with-const.t',
    't/enums.t',
    't/etc/perlcritic.rc',
    't/lib/Test/Const/Exporter/Empty.pm',
    't/lib/Test/Const/Exporter/Enums.pm',
    't/lib/Test/Const/Exporter/Strictures.pm',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-trailing-space.t',
    't/strictures.t'
);

notabs_ok($_) foreach @files;
done_testing;
