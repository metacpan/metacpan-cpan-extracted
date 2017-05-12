use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
