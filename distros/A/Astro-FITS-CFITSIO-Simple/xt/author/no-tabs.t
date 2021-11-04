use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Astro/FITS/CFITSIO/Simple.pm',
    'lib/Astro/FITS/CFITSIO/Simple/Image.pm',
    'lib/Astro/FITS/CFITSIO/Simple/PDL.pm',
    'lib/Astro/FITS/CFITSIO/Simple/PrintStatus.pm',
    'lib/Astro/FITS/CFITSIO/Simple/Table.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/binbits.t',
    't/image_auto.t',
    't/image_dtype.t',
    't/lib/My/Test/common.pm',
    't/namedhdu.t',
    't/ndim.t',
    't/reset.t',
    't/ret.t',
    't/rfilter.t',
    't/sub_cols.t',
    't/table_dtypes.t',
    't/zero_rows.t'
);

notabs_ok($_) foreach @files;
done_testing;
