
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
    'lib/Bot/Cobalt/Plugin/Ohm.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_loadable.t',
    't/02_calc.t',
    't/author-no-tabs.t',
    't/release-cpan-changes.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
