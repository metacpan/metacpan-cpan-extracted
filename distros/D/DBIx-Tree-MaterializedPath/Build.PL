use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'DBIx::Tree::MaterializedPath',
    license              => 'perl',
    dist_author          => 'Larry Leszczynski <larryl@cpan.org>',
    dist_version_from    => 'lib/DBIx/Tree/MaterializedPath.pm',
    requires             => {
                                'Clone' => 0,
                                'DBI' => 0,
                                'Readonly' => 0,
                                'Scalar::Util' => 0,
                                'SQL::Abstract' => 0,
                                'version' => 0.74,
                            },
    build_requires       => {
                                'Test::More' => 0,
                                'File::Spec' => 0,
                            },
    recommends           => {
                                'DBD::SQLite' => 0,
                                'Pod::Coverage' => 0,
                                'Test::Pod' => 0,
                                'Test::Pod::Coverage' => 0,
                            },
    add_to_cleanup       => [
                                'DBIx-Tree-MaterializedPath-*',
                                'Debian_CPANTS.txt',
                                '*.bak',
                                '*.tmp',
                                'lib/*/*.bak',
                                'lib/*/*/*.bak',
                                'lib/*/*/*/*.bak',
                                't/*.bak',
                                't/*/*.bak',
                                't/test_data_dir',
                                '\.DS_Store',
                                '*/\.DS_Store',
                                '*/*/\.DS_Store',
                                '*/*/*/\.DS_Store',
                            ],
    create_makefile_pl   => 'traditional',
    recursive_test_files => 1,
);

$builder->create_build_script();
