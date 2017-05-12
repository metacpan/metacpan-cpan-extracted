use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Rad::Plugin::ConfigLoader',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/App/Rad/Plugin/ConfigLoader.pm',
    build_requires => {
        'Test::More'  => 0,
        'App::Rad'    => 1.0,
        'Config::Any' => 0,
    },
    add_to_cleanup      => [ 'App-Rad-Plugin-ConfigLoader-*' ],
    create_makefile_pl => 'traditional',
    'dist_abstract' => 'Load config files of various types',
);

$builder->create_build_script();
