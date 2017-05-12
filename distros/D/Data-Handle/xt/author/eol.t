use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Data/Handle.pm',
    'lib/Data/Handle/Exception.pm',
    'lib/Data/Handle/IO.pm',
    't/00-compile/lib_Data_Handle_Exception_pm.t',
    't/00-compile/lib_Data_Handle_IO_pm.t',
    't/00-compile/lib_Data_Handle_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_lowlevel.t',
    't/02_example.t',
    't/03_mess_with_seek.t',
    't/04_things_that_fail.t',
    't/alternative_techniques/03_fdup_test.t',
    't/alternative_techniques/03_fdup_test_cowns.t',
    't/alternative_techniques/04_fopen.t',
    't/alternative_techniques/05_new_from_fd.t',
    't/lib/Data.pm',
    't/lib/SectionData.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
