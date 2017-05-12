
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
    'lib/DateTime/Format/PGN.pm',
    't/01-default.t',
    't/02-fix-errors.t',
    't/03-incomplete.t',
    't/04-month-length.t',
    't/05-chess-pgn-parse.t',
    't/author-no-tabs.t',
    't/release-kwalitee.t'
);

notabs_ok($_) foreach @files;
done_testing;
