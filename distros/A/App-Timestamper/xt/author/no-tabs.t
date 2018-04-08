use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/timestamper',
    'lib/App/Timestamper.pm',
    'lib/App/Timestamper/Filter/TS.pm',
    't/00-compile.t',
    't/pod-sanity.t',
    't/test-filter.t'
);

notabs_ok($_) foreach @files;
done_testing;
