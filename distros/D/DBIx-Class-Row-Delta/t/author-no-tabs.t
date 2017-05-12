
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DBIx/Class/Row/Delta.pm',
    't/00-load.t',
    't/dbic_row_delta.t',
    't/manifest.t'
);

notabs_ok($_) foreach @files;
done_testing;
