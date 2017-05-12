use strict;
use Module::Build;

my %arguments = (
    license            => 'perl',
    module_name        => 'Catalyst::View::Chart::Strip',
    requires           => {
        'UNIVERSAL::require' => 0,
        'Chart::Strip'       => 1.01,
    },
    build_requires      => {
        'Test::More'         => 0,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
);

Module::Build->new(%arguments)->create_build_script;

