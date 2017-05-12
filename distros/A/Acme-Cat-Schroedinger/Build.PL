use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Cat::Schroedinger',
    license             => 'perl',
    dist_author         => q{Daniel Perrett <perrettdl@googlemail.com>},
    dist_version_from   => 'lib/Acme/Cat/Schroedinger.pm',
    build_requires => {
        'Test::More' => 0.98,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Acme-Cat-Schroedinger-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
