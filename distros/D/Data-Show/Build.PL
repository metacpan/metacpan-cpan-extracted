use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Show',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Data/Show.pm',
    requires => {
        'Test::More' => 0,
        'Data::Dump' => 1.17,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Data-Show-*' ],
);

$builder->create_build_script();
