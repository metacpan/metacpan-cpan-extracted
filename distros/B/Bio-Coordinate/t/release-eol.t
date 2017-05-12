
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Bio/Coordinate.pm',
    'lib/Bio/Coordinate/Chain.pm',
    'lib/Bio/Coordinate/Collection.pm',
    'lib/Bio/Coordinate/ExtrapolatingPair.pm',
    'lib/Bio/Coordinate/GeneMapper.pm',
    'lib/Bio/Coordinate/Graph.pm',
    'lib/Bio/Coordinate/MapperI.pm',
    'lib/Bio/Coordinate/Pair.pm',
    'lib/Bio/Coordinate/Result.pm',
    'lib/Bio/Coordinate/Result/Gap.pm',
    'lib/Bio/Coordinate/Result/Match.pm',
    'lib/Bio/Coordinate/ResultI.pm',
    'lib/Bio/Coordinate/Utils.pm',
    't/00-compile.t',
    't/CoordinateBoundaryTest.t',
    't/CoordinateGraph.t',
    't/CoordinateMapper.t',
    't/GeneCoordinateMapper.t',
    't/author-mojibake.t',
    't/author-pod-syntax.t',
    't/release-eol.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
