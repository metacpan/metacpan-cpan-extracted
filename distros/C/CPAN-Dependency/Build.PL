use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CPAN::Dependency',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/CPAN/Dependency.pm',
    requires => {
        'CPANPLUS'      => '0.82',
        'DBI'           => '1.0',
        'DBD::SQLite'   => '1.0',
        'File::Slurp'   => '9999.12',
        'File::Spec'    => 0,
        'Module::CoreList'  => '2.12',
        'YAML'          => '0.66',
    },
    build_requires => {
        'Test::Deep'    => 0,
        'Test::More'    => 0,
        'Test::Warn'    => 0,
    },
    add_to_cleanup      => [ 'CPAN-Dependency-*' ],
);

$builder->create_build_script();
