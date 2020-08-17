use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/rshasum',
    'lib/App/rshasum.pm',
    't/00-compile.t',
    't/argv.t',
    't/data/1/0.txt',
    't/data/1/2.txt',
    't/data/1/foo/empty',
    't/data/1/zempty',
    't/run.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
