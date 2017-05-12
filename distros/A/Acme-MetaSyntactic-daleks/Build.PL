use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::MetaSyntactic::daleks',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Acme/MetaSyntactic/daleks.pm',
    requires => {
        'Acme::MetaSyntactic'   => '0.99',
    },
    build_requires => {
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'Acme-MetaSyntactic-daleks-*' ],
);

$builder->create_build_script();
