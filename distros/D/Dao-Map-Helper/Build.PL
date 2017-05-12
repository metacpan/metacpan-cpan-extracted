use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Dao::Map::Helper',
    license             => 'perl',
    dist_author         => q{Arjun Surendra <arjuns@cpan.org>},
    dist_version_from   => 'lib/Dao/Map/Helper.pm',
    script_files        => 'bin/dao-map-helper', 
    build_requires => {
        'Test::More'            => 0,
        'Test::Harness'         => 0.21,
        'ExtUtils::Command'     => 0,
        'File::Spec'            => 0,
        'Getopt::Long'          => 0,
        'Pod::Usage'            => 1.21,
        'DBI'                   => 0,
        'DBD::mysql'            => 0,
        'Error'                 => 0,
        'Carp'                  => 0
    },
    add_to_cleanup      => [ 'Dao-Map-Helper-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
