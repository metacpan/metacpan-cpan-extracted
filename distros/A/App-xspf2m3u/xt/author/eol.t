use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/xspf2m3u',
    'lib/App/xspf2m3u.pm',
    'lib/App/xspf2m3u/Command/convert.pm',
    't/00-compile.t',
    't/cmd-line.t',
    't/data/test1.m3u',
    't/data/test1.xspf'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
