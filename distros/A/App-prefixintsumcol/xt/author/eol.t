use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/prefixintsumcol',
    'lib/App/prefixintsumcol.pm',
    't/00-compile.t',
    't/data/samples/bigints.txt',
    't/data/samples/simple.txt',
    't/test-exe.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
