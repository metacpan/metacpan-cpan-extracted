use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DateTime/Format/ISO8601.pm',
    'lib/DateTime/Format/ISO8601/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bad-formats.t',
    't/base-datetime.t',
    't/cut-off-year.t',
    't/date.t',
    't/datetime.t',
    't/format-datetime.t',
    't/legacy-year.t',
    't/time.t'
);

notabs_ok($_) foreach @files;
done_testing;
