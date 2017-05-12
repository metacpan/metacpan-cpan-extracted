use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Model::CDBI::Sweet',
    requires           => {
        'Catalyst'          => 5.24,
        'Class::DBI::Sweet' => 0
    },
    create_makefile_pl => 'passthrough',
    test_files         => [ glob('t/*.t') ],
    create_readme      => 1
);


Module::Build->new(%arguments)->create_build_script;
