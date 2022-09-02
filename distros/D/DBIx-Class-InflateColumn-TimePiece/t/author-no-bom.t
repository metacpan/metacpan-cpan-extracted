
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/DBIx/Class/InflateColumn/TimePiece.pm',
    't/00_base.t',
    't/01_deflate.t',
    't/lib/TimePieceDB.pm',
    't/lib/TimePieceDB/TestUser.pm'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
