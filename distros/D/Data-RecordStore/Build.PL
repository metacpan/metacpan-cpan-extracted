use strict;
use warnings;
use Module::Build;


my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Data-RecordStore-*' ],
    build_requires => {
        'Test::More'            => 0,
        'Module::Build'         => 0,
    },
    dist_abstract      => 'Simple and fast record based data store',
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Data::RecordStore',
    release_status     => 'stable',
    test_files         => [ 't/recordstore.t',
                            't/silo.t',
                            't/transactions.t',
                        ],
    requires => {
        'perl'       => 'v5.9.4',
        'Make::Path' => '2.07',
    },
    );

$builder->create_build_script();
