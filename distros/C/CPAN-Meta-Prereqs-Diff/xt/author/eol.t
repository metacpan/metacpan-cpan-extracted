use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CPAN/Meta/Prereqs/Diff.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Addition.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Change.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Downgrade.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Removal.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Role/Change.pm',
    'lib/CPAN/Meta/Prereqs/Diff/Upgrade.pm',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Addition_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Change_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Downgrade_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Removal_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Role_Change_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_Upgrade_pm.t',
    't/00-compile/lib_CPAN_Meta_Prereqs_Diff_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/constructors.t',
    't/realworld.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
