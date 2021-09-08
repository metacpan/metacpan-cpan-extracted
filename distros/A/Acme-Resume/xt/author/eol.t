use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Acme/Resume.pm',
    'lib/Acme/Resume/Internal.pm',
    'lib/Acme/Resume/MoopsParserTrait.pm',
    'lib/Acme/Resume/Moose.pm',
    'lib/Acme/Resume/Output/ToPlain.pm',
    'lib/Acme/Resume/Types.pm',
    'lib/Acme/Resume/Types/Education.pm',
    'lib/Acme/Resume/Types/Job.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/01/lib/Acme/Resume/For/Tester.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
