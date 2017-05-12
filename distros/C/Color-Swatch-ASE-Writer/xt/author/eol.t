use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Color/Swatch/ASE/Writer.pm',
    't/00-compile/lib_Color_Swatch_ASE_Writer_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic-blockgroup.t',
    't/basic-color-CMYK.t',
    't/basic-color-Gray.t',
    't/basic-color-LAB.t',
    't/basic-color-RGB.t',
    't/basic-end.t',
    't/basic-labels.t',
    't/basic-noblocks.t',
    't/basic-start.t',
    't/io-file.t',
    't/io-filehandle.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
