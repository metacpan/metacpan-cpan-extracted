use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/prefixintsumcol',
    'lib/App/prefixintsumcol.pm',
    't/00-compile.t',
    't/data/samples/bigints.txt',
    't/data/samples/simple.txt',
    't/test-exe.t'
);

notabs_ok($_) foreach @files;
done_testing;
