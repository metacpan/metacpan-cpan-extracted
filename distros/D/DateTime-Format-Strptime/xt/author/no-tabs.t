use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DateTime/Format/Strptime.pm',
    'lib/DateTime/Format/Strptime/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/edge.t',
    't/errors.t',
    't/format-datetime.t',
    't/format-with-locale.t',
    't/import.t',
    't/lib/T.pm',
    't/locale-de.t',
    't/locale-en.t',
    't/locale-ga.t',
    't/locale-pt.t',
    't/locale-zh.t',
    't/zones.t'
);

notabs_ok($_) foreach @files;
done_testing;
