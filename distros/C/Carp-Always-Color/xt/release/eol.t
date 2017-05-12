use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Carp/Always/Color.pm',
    'lib/Carp/Always/Color/HTML.pm',
    'lib/Carp/Always/Color/Term.pm',
    't/00-compile.t',
    't/detect.t',
    't/eval.t',
    't/html.t',
    't/lib/TestHelpers.pm',
    't/object.t',
    't/term.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
