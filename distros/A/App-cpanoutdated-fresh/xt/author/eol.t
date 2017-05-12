use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/cpan-outdated-fresh',
    'lib/App/cpanoutdated/fresh.pm',
    't/00-compile/lib_App_cpanoutdated_fresh_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attributes.t',
    't/constructors.t',
    't/fresh_checker.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
