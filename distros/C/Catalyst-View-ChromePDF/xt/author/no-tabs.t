use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Catalyst/View/ChromePDF.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-pdf.t',
    't/lib/App.pm',
    't/lib/App/Controller/Root.pm',
    't/lib/App/View/ChromePDF.pm',
    't/lib/App/View/TT.pm',
    't/lib/App/root/base.tt'
);

notabs_ok($_) foreach @files;
done_testing;
