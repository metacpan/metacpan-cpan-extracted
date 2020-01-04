use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/csv2chart',
    'lib/App/CSV2Chart.pm',
    'lib/App/CSV2Chart/API/ToXLSX.pm',
    'lib/App/CSV2Chart/Command/svg.pm',
    'lib/App/CSV2Chart/Command/xlsx.pm',
    't/00-compile.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
