use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/update_sanctions_csv',
    'lib/Data/Validate/Sanctions.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/05_basic.t',
    't/10_env.t',
    't/15_oo.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
