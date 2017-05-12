use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'DBIx::Migration',
    requires           => {
        'File::Slurp'           => 0,
        'File::Spec'            => 0,
        'DBI'                   => 0,
        'DBD::SQLite'           => 0,
        'Class::Accessor::Fast' => 0
    },
    create_readme => 1,
    script_files  => [ glob('script/*') ],
    test_files    => [ glob('t/*.t') ]
);
$build->create_build_script;
