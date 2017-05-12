use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'DBIx::Class::CompressColumns',
    requires           => {
        'DBIx::Class'               => 0.06002,
        'Compress::Zlib'            => 2.008,
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files         => [ glob('t/*.t')]
);

Module::Build->new(%arguments)->create_build_script;
