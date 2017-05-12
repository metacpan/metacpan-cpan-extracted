use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Color/Swatch/ASE/Reader.pm',
    't/00-compile/lib_Color_Swatch_ASE_Reader_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/read-swatch.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
