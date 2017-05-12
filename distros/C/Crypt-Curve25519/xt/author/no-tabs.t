use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
