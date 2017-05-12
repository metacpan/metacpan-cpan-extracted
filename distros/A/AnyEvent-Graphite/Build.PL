use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AnyEvent::Graphite',
    license             => 'perl',
    dist_author         => 'Joshua Barratt <josh@mediatemple.net>',
    dist_version_from   => 'lib/AnyEvent/Graphite.pm',
    script_files        => [ 'script/graphite_client' ],
    requires => {
        'AnyEvent' => 0,
        'AnyEvent::SNMP' => 0,
        'Net::SNMP' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'AnyEvent-Graphite-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
