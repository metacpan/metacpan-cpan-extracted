use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/colorhexdump',
    'bin/colourhexdump',
    'lib/App/colourhexdump.pm',
    'lib/App/colourhexdump/ColourProfile.pm',
    'lib/App/colourhexdump/DefaultColourProfile.pm',
    'lib/App/colourhexdump/Formatter.pm',
    't/00-compile/lib_App_colourhexdump_ColourProfile_pm.t',
    't/00-compile/lib_App_colourhexdump_DefaultColourProfile_pm.t',
    't/00-compile/lib_App_colourhexdump_Formatter_pm.t',
    't/00-compile/lib_App_colourhexdump_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
