use strict;
use Module::Build;

my %arguments = (
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Authentication::Credential::Facebook',
    requires           => {
        'DBIx::Class'               => 0.06002,
        'WWW::Facebook::API'       => "0.4.17",
    },
    create_makefile_pl => 'passthrough',
    create_readme      => 1,
    test_files         => [ glob('t/*.t')]
);

Module::Build->new(%arguments)->create_build_script;
