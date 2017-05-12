use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::GRYLLIDA::Utils',
    license             => 'perl',
    dist_author         => q{Gryllida <Gryllida@gmail.com>},
    dist_version_from   => 'lib/Acme/GRYLLIDA/Utils.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Acme-GRYLLIDA-Utils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
