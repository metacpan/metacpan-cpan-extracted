use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CPAN/Distribution/ReleaseHistory.pm',
    'lib/CPAN/Distribution/ReleaseHistory/Release.pm',
    'lib/CPAN/Distribution/ReleaseHistory/ReleaseIterator.pm',
    't/00-compile/lib_CPAN_Distribution_ReleaseHistory_ReleaseIterator_pm.t',
    't/00-compile/lib_CPAN_Distribution_ReleaseHistory_Release_pm.t',
    't/00-compile/lib_CPAN_Distribution_ReleaseHistory_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/live-moo-history.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
