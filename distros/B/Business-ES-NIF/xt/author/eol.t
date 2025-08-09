use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Business/ES/NIF.pm',
    't/00-compile.t',
    't/00-load.t',
    't/boilerplate.t',
    't/cif.t',
    't/funcs.t',
    't/iso3166.t',
    't/manifest.t',
    't/nif.t',
    't/pod.t',
    't/vies.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
