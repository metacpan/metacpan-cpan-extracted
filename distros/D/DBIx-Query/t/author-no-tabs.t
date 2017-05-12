
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DBIx/Query.pm',
    't/00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/library.t',
    't/release-kwalitee.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/sqlite.t'
);

notabs_ok($_) foreach @files;
done_testing;
