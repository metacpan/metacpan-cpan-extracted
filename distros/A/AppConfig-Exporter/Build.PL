use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AppConfig::Exporter',
    license             => 'perl',
    dist_author         => 'Ben H Kram <bkram@dce.harvard.edu>',
    dist_version_from   => 'lib/AppConfig/Exporter.pm',
    build_requires => {
        'Test::More' => 0,
	'AppConfig'  => 0,
    },
    add_to_cleanup      => [ 'AppConfig-Exporter-*' ],
);

$builder->create_build_script();
