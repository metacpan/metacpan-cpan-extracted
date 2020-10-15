use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/analyze-du',
    'lib/App/Du/Analyze.pm',
    'lib/App/Du/Analyze/Filter.pm',
    't/00-compile.t',
    't/app.t',
    't/data/fc-solve-git-du-output.txt',
    't/filter.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
