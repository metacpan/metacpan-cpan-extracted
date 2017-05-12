use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/stream_ttyrec',
    'bin/termcast',
    'lib/App/Termcast.pm',
    't/00-compile.t',
    't/basic.t',
    't/read-write.t',
    't/write-to-termcast.t'
);

notabs_ok($_) foreach @files;
done_testing;
