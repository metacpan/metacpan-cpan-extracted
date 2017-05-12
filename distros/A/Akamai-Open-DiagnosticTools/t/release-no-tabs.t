
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
    'lib/Akamai/Open/DiagnosticTools.pm',
    't/0003-diagnostictools.t',
    't/release-no-tabs.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
