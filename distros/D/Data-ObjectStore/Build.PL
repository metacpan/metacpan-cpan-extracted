use strict;
use warnings;
use Module::Build;


my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Data-ObjectStore-*' ],
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.40,
    },
    dist_abstract      => 'Object store',
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Data::ObjectStore',
    release_status     => 'stable',
    test_files         => [ 't/object_store.t', ],
    requires => {
        'perl'       => 'v5.20',
        'Data::RecordStore'     => 3.20,
    },
    );

$builder->create_build_script();
