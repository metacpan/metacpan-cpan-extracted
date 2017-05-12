use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dancer::Plugin::ProxyPath',
    license             => 'perl',
    dist_author         => q{Alex Kalderimis <alex kalderimis at gmail dot com>},
    dist_version_from   => 'lib/Dancer/Plugin/ProxyPath.pm',
    requires => {
        'Dancer' => '1.2',
        'Dancer::Plugin' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::MockObject' => 0,
    },
    add_to_cleanup      => [ 'Dancer-Plugin-ProxyPath-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
