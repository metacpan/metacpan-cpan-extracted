use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/CXC/Astro/Regions.pm',
    'lib/CXC/Astro/Regions/CFITSIO.pm',
    'lib/CXC/Astro/Regions/CFITSIO/Types.pm',
    'lib/CXC/Astro/Regions/CFITSIO/Variant.pm',
    'lib/CXC/Astro/Regions/CIAO.pm',
    'lib/CXC/Astro/Regions/CIAO/Types.pm',
    'lib/CXC/Astro/Regions/CIAO/Variant.pm',
    'lib/CXC/Astro/Regions/DS9.pm',
    'lib/CXC/Astro/Regions/DS9/Types.pm',
    'lib/CXC/Astro/Regions/DS9/Variant.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/CFITSIO/regions.t',
    't/CFITSIO/types.t',
    't/CIAO/regions.t',
    't/CIAO/types.t',
    't/DS9/regions.t',
    't/DS9/types.t'
);

notabs_ok($_) foreach @files;
done_testing;
