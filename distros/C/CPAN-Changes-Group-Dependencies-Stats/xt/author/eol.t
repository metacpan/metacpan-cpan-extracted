use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CPAN/Changes/Group/Dependencies/Stats.pm',
    't/00-compile/lib_CPAN_Changes_Group_Dependencies_Stats_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attach.t',
    't/basic.t',
    't/complex.t',
    't/fails.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
