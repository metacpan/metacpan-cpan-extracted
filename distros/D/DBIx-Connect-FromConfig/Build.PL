use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Connect::FromConfig',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/DBIx/Connect/FromConfig.pm',
    requires => {
        'perl'              => 5,
        'Carp'              => 0,
        'DBI'               => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Module::Build'     => 0,
    },
    build_recommends => {
        'DBD::Mock'         => 0,
        'Test::DatabaseRow' => 0,
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'DBIx-Connect-FromConfig-*' ],
);

$builder->create_build_script();
