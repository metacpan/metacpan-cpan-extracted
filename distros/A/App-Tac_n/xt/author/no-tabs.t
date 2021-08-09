use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/tac-n',
    'lib/App/Tac_n.pm',
    't/00-compile.t',
    't/01-results.t',
    't/data/cat/cat-n-1.txt',
    't/data/sort/ints1.txt',
    't/data/sort/letters1.txt',
    't/data/sort/three-words.txt',
    't/data/tac/a-sep.txt'
);

notabs_ok($_) foreach @files;
done_testing;
