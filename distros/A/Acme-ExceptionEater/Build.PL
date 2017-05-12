use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::ExceptionEater',
    license             => 'perl',
    dist_author         => 'Kyle Hasselbacher <kyleha@gmail.com>',
    dist_version_from   => 'lib/Acme/ExceptionEater.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Acme-ExceptionEater-*' ],
);

$builder->create_build_script();
