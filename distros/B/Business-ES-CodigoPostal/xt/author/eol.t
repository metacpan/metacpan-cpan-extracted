use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Business/ES/CodigoPostal.pm',
    't/00-compile.t',
    't/basic.t',
    't/codigos.t',
    't/function.t',
    't/pod.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
