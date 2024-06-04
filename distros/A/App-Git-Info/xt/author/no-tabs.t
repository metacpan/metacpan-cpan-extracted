use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/git-info',
    'lib/App/Git/Info.pm',
    't/00-compile.t'
);

notabs_ok($_) foreach @files;
done_testing;
