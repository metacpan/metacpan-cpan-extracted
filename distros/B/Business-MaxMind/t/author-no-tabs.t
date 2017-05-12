
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
    'lib/Business/MaxMind.pm',
    'lib/Business/MaxMind/CreditCardFraudDetection.pm',
    'lib/Business/MaxMind/HTTPBase.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/1.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-test-version.t',
    't/release-cpan-changes.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-tidyall.t'
);

notabs_ok($_) foreach @files;
done_testing;
