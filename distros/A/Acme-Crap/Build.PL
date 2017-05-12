use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Crap',
    license             => 'perl',
    dist_author         => 'Damian Conway <DCONWAY@CPAN.org>',
    dist_version_from   => 'lib/Acme/Crap.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Acme-Crap-*' ],
);

$builder->create_build_script();
