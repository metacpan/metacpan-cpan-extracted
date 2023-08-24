use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CIAO/Lib/Param.pm',
    'lib/CIAO/Lib/Param/Error.pod',
    'lib/CIAO/Lib/Param/Match.pod',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/CIAO-Lib-Param.t',
    't/bool.t'
);

notabs_ok($_) foreach @files;
done_testing;
