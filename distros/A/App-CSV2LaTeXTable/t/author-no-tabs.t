
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
    'bin/csv2latextable',
    'lib/App/CSV2LaTeXTable.pm',
    't/base.t',
    't/croak.t',
    't/data/test.csv',
    't/latex-params.t',
    't/rotate.t',
    't/split_tables.t'
);

notabs_ok($_) foreach @files;
done_testing;
