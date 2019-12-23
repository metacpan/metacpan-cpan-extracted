use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/xspf2m3u',
    'lib/App/xspf2m3u.pm',
    'lib/App/xspf2m3u/Command/convert.pm',
    't/00-compile.t',
    't/cmd-line.t',
    't/data/test1.m3u',
    't/data/test1.xspf'
);

notabs_ok($_) foreach @files;
done_testing;
