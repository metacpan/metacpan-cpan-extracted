use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/ts-format',
    'lib/App/Timestamper/Format.pm',
    'lib/App/Timestamper/Format/Filter/TS.pm',
    't/00-compile.t',
    't/test-filter.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
