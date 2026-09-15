use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Business/PT/CodigoPostal.pm',
    'lib/Business/PT/CodigoPostal/Datos.pm',
    'lib/Business/PT/CodigoPostal/Localidades.pm',
    't/00-compile.t',
    't/basic.t',
    't/distritos.t',
    't/localidades.t',
    't/paridade.t'
);

notabs_ok($_) foreach @files;
done_testing;
