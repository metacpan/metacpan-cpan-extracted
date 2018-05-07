use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Alien/libvas.pm',
    't/00-compile.t',
    't/00-report-buildlog.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/02-report-prereqs.t',
    't/03-query-lib.t',
    't/04-init-lib.t',
    't/10-use-lib-onself.t',
    't/11-use-lib-onchild.t'
);

notabs_ok($_) foreach @files;
done_testing;
