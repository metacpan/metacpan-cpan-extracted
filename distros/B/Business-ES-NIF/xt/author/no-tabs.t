use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
