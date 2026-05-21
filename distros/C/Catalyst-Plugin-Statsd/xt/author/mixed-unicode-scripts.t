use strict;
use warnings;

# This test was generated with Dist::Zilla::Plugin::Test::MixedScripts v0.2.4.

use Test2::Tools::Basic 1.302200;

use Test::MixedScripts qw( file_scripts_ok );

my @scxs = (  );

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

file_scripts_ok($_, { scripts => \@scxs } ) for @files;

done_testing;
