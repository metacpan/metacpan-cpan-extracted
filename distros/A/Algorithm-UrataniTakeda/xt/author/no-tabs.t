use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Algorithm/UrataniTakeda.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-search.t',
    't/02-errors.t',
    't/03-defects.t',
    't/04-memo-bounded.t',
    't/05-build-cost.t'
);

notabs_ok($_) foreach @files;
done_testing;
