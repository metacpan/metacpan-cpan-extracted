
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
    'lib/Data/Password/zxcvbn.pm',
    'lib/Data/Password/zxcvbn/AdjacencyGraph.pm',
    'lib/Data/Password/zxcvbn/Combinatorics.pm',
    'lib/Data/Password/zxcvbn/Match.pm',
    'lib/Data/Password/zxcvbn/Match/BruteForce.pm',
    'lib/Data/Password/zxcvbn/Match/Date.pm',
    'lib/Data/Password/zxcvbn/Match/Dictionary.pm',
    'lib/Data/Password/zxcvbn/Match/Regex.pm',
    'lib/Data/Password/zxcvbn/Match/Repeat.pm',
    'lib/Data/Password/zxcvbn/Match/Sequence.pm',
    'lib/Data/Password/zxcvbn/Match/Spatial.pm',
    'lib/Data/Password/zxcvbn/Match/UserInput.pm',
    'lib/Data/Password/zxcvbn/MatchList.pm',
    'lib/Data/Password/zxcvbn/RankedDictionaries.pm',
    'lib/Data/Password/zxcvbn/TimeEstimate.pm',
    'scripts/zxcvbn-password-strength',
    't/author-critic.t',
    't/data/regression-data.json',
    't/lib/Test/MyVisitor.pm',
    't/lib/Test/zxcvbn.pm',
    't/tests/data/password/zxcvbn.t',
    't/tests/data/password/zxcvbn/combinatorics.t',
    't/tests/data/password/zxcvbn/match/date.t',
    't/tests/data/password/zxcvbn/match/dictionary.t',
    't/tests/data/password/zxcvbn/match/regex.t',
    't/tests/data/password/zxcvbn/match/repeat.t',
    't/tests/data/password/zxcvbn/match/sequence.t',
    't/tests/data/password/zxcvbn/match/spatial.t',
    't/tests/data/password/zxcvbn/match/user_input.t',
    't/tests/data/password/zxcvbn/scoring.t',
    't/tests/data/password/zxcvbn/time_estimate.t'
);

notabs_ok($_) foreach @files;
done_testing;
