use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Astro/FITS/CFITSIO/FileName.pm',
    'lib/Astro/FITS/CFITSIO/FileName/Regexp.pm',
    'lib/Astro/FITS/CFITSIO/FileName/Types.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/bin_spec.t',
    't/leaves.t',
    't/new.t',
    't/types.t'
);

notabs_ok($_) foreach @files;
done_testing;
