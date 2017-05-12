use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::DBI::MSAccess',
    license             => 'perl',
    dist_version_from   => 'lib/Class/DBI/MSAccess.pm',
    sign                => 1,
    create_makefile_pl  => 'passthrough',
    requires => {
        'Class::DBI' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Class-DBI-MSAccess-*' ],
);

$builder->create_build_script();
