
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
    'lib/Data/Password/zxcvbn/AdjacencyGraph/French.pm',
    'lib/Data/Password/zxcvbn/French.pm',
    'lib/Data/Password/zxcvbn/French/AdjacencyGraph.pm',
    'lib/Data/Password/zxcvbn/French/RankedDictionaries.pm',
    'lib/Data/Password/zxcvbn/RankedDictionaries/French.pm',
    't/basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
