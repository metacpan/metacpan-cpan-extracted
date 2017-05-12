use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ACME::THEDANIEL::Utils',
    license             => 'artistic_2',
    dist_author         => q{Daniel jones <dtj@someplace.com>},
    dist_version_from   => 'lib/ACME/THEDANIEL/Utils.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::Exception' => 0
    },
    requires => {
    },
    add_to_cleanup     => [ 'ACME-THEDANIEL-Utils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
