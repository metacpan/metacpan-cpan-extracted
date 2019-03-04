use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DateTime/Format/Builder.pm',
    'lib/DateTime/Format/Builder/Parser.pm',
    'lib/DateTime/Format/Builder/Parser/Dispatch.pm',
    'lib/DateTime/Format/Builder/Parser/Quick.pm',
    'lib/DateTime/Format/Builder/Parser/Regex.pm',
    'lib/DateTime/Format/Builder/Parser/Strptime.pm',
    'lib/DateTime/Format/Builder/Parser/generic.pm',
    'lib/DateTime/Format/Builder/Tutorial.pod',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/99pod.t',
    't/altcon.t',
    't/basic.t',
    't/clone.t',
    't/create.t',
    't/dispatch.t',
    't/extra.t',
    't/fall.t',
    't/import.t',
    't/lengths.t',
    't/memory-cycle.t',
    't/mergecb.t',
    't/newclass.t',
    't/nocon.t',
    't/noredef.t',
    't/on_fail.t',
    't/on_fail_regex.t',
    't/on_fail_sub.t',
    't/param.t',
    't/quick.t',
    't/self.t',
    't/strptime.t',
    't/taint.t',
    't/verbose.t',
    't/wholeclass.t'
);

notabs_ok($_) foreach @files;
done_testing;
