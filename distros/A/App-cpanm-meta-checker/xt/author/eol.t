use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/cpanm-meta-checker',
    'lib/App/cpanm/meta/checker.pm',
    'lib/App/cpanm/meta/checker/State.pm',
    'lib/App/cpanm/meta/checker/State/Duplicates.pm',
    'lib/App/cpanm/meta/checker/State/Duplicates/Dist.pm',
    't/00-compile/lib_App_cpanm_meta_checker_State_Duplicates_Dist_pm.t',
    't/00-compile/lib_App_cpanm_meta_checker_State_Duplicates_pm.t',
    't/00-compile/lib_App_cpanm_meta_checker_State_pm.t',
    't/00-compile/lib_App_cpanm_meta_checker_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
