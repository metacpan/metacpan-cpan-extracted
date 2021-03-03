
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
    'lib/DBIx/Class/Schema/ResultSetNames.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01schema.t',
    't/lib/TestSchema.pm',
    't/lib/TestSchema/Result/Car.pm',
    't/lib/TestSchema/Result/Human.pm'
);

notabs_ok($_) foreach @files;
done_testing;
