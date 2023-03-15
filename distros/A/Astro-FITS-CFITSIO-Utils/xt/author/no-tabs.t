use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Astro/FITS/CFITSIO/Utils.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/colkeys.t',
    't/fptr.t',
    't/keypar.t'
);

notabs_ok($_) foreach @files;
done_testing;
