use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::SuperForm',
    requires           => {
        'Catalyst'        => 5.20,
        'HTML::SuperForm' => 1.04
    },
    create_makefile_pl => 'passthrough',
    test_files         => [ glob('t/*.t') ]
);

Module::Build->new(%arguments)->create_build_script;
