use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Relate',
    license             => 'perl',
    dist_author         => q{Joseph Brenner <doom@kzsu.stanford.edu>},
    dist_version_from   => 'lib/App/Relate.pm',
    build_requires => {
                       'strict'       => 0,
                       'warnings'     => 0,
                       'Test::More'   => 0,
                       'Data::Dumper' => 0,
                       'FindBin'      => 0,
                       'lib'          => 0,
    },
    requires => {
                 'strict'       => 0,
                 'warnings'     => 0,
                 'Carp'         => 0,
                 'Data::Dumper' => 0,
                 'Exporter'     => 0,
                },
    script_files => [ 'bin/relate', ],

    add_to_cleanup      => [ 'App-Relate-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
