use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Catalyst/Plugin/Statsd.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/100-basic.t',
    't/101-disable-stats-report.t',
    't/etc/perlcritic.rc',
    't/lib/MockStatsd.pm',
    't/lib/StatsApp.pm',
    't/lib/StatsApp/Controller/Root.pm'
);

notabs_ok($_) foreach @files;
done_testing;
