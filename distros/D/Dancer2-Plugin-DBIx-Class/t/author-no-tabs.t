
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
    'lib/Dancer2/Plugin/DBIx/Class.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_test_with_rsnames.t',
    't/02_test_without_rsnames.t',
    't/lib/TestApp.pm',
    't/lib/TestApp2.pm',
    't/lib/TestSchema.pm',
    't/lib/TestSchema/Result/Car.pm',
    't/lib/TestSchema/Result/Human.pm',
    't/lib/TestSchema2.pm',
    't/lib/TestSchema2/Result/Car.pm',
    't/lib/TestSchema2/Result/Human.pm'
);

notabs_ok($_) foreach @files;
done_testing;
