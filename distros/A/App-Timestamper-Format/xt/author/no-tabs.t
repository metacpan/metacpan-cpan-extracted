use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/ts-format',
    'lib/App/Timestamper/Format.pm',
    'lib/App/Timestamper/Format/Filter/TS.pm',
    't/00-compile.t',
    't/test-filter.t'
);

notabs_ok($_) foreach @files;
done_testing;
