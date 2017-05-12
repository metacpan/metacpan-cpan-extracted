use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CHI/Driver/LMDB.pm',
    'lib/CHI/Driver/LMDB/t/CHIDriverTests.pm',
    't/00-compile/lib_CHI_Driver_LMDB_pm.t',
    't/00-compile/lib_CHI_Driver_LMDB_t_CHIDriverTests_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/CHI-driver-tests.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
