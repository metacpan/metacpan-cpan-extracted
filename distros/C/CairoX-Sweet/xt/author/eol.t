use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CairoX/Sweet.pm',
    'lib/CairoX/Sweet/Color.pm',
    'lib/CairoX/Sweet/Core/CurveTo.pm',
    'lib/CairoX/Sweet/Core/LineTo.pm',
    'lib/CairoX/Sweet/Core/MoveTo.pm',
    'lib/CairoX/Sweet/Core/Point.pm',
    'lib/CairoX/Sweet/Elk.pm',
    'lib/CairoX/Sweet/Path.pm',
    'lib/CairoX/Sweet/Role/PathCommand.pm',
    'lib/Types/CairoX/Sweet.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
