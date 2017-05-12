use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Crypt/Curve25519.pm',
    't/00-compile.t',
    't/01-exceptions.t',
    't/02-synopsis-proc.t',
    't/03-synopsis-oo.t',
    't/04-proc-vs-oo.t',
    't/05-primitive.t',
    't/Crypt-Curve25519.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
