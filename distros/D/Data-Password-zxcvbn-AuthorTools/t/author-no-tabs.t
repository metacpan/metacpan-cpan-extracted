
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
    'lib/Data/Password/zxcvbn/AuthorTools.pm',
    'lib/Data/Password/zxcvbn/AuthorTools/BuildAdjacencyGraphs.pm',
    'lib/Data/Password/zxcvbn/AuthorTools/BuildRankedDictionaries.pm',
    'lib/Data/Password/zxcvbn/AuthorTools/PackageWriter.pm',
    'lib/Dist/Zilla/MintingProfile/zxcvbn.pm',
    'scripts/zxcvbn-build-data-leipzig',
    'scripts/zxcvbn-build-names-data-fb-leak'
);

notabs_ok($_) foreach @files;
done_testing;
