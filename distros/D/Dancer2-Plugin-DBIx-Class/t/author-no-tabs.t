
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
    'lib/Dancer2/Plugin/DBIx/Class/ExportBuilder.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_core_keywords.t',
    't/01_both_using_rsnames.t',
    't/02_first_using_rsnames.t',
    't/03_second_using_rsnames.t',
    't/04_neither_using_rsnames.t',
    't/lib/FirstSchemaWith.pm',
    't/lib/FirstSchemaWith/Result/Car.pm',
    't/lib/FirstSchemaWith/Result/Human.pm',
    't/lib/FirstSchemaWith/Result/Session.pm',
    't/lib/FirstSchemaWithout.pm',
    't/lib/FirstSchemaWithout/Result/Car.pm',
    't/lib/FirstSchemaWithout/Result/Human.pm',
    't/lib/FirstSchemaWithout/Result/Session.pm',
    't/lib/SecondSchemaWith.pm',
    't/lib/SecondSchemaWith/Result/Beverage.pm',
    't/lib/SecondSchemaWith/Result/Human.pm',
    't/lib/SecondSchemaWith/Result/Mug.pm',
    't/lib/SecondSchemaWithout.pm',
    't/lib/SecondSchemaWithout/Result/Beverage.pm',
    't/lib/SecondSchemaWithout/Result/Human.pm',
    't/lib/SecondSchemaWithout/Result/Mug.pm',
    't/lib/TestAppBothWith.pm',
    't/lib/TestAppFirstWith.pm',
    't/lib/TestAppNeitherWith.pm',
    't/lib/TestAppSecondWith.pm'
);

notabs_ok($_) foreach @files;
done_testing;
