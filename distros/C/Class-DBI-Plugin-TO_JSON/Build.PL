use strict;
use warnings;
use Module::Build;

Module::Build->new(
    'module_name'       => 'Class::DBI::Plugin::TO_JSON',
    'dist_author'       => 'Graham TerMarsch (cpan@howlingfrog.com)',
    'license'           => 'perl',
    'create_makefile_pl'=> 'traditional',
    'requires'          => {
        'Class::DBI'        => 0,
        },
    'build_requires'    => {
        'Test::More'        => 0,
        'DBD::SQLite'       => 0,
        'JSON::XS'          => 2.0,
        },
    )->create_build_script();
