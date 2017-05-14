#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::Mapping');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my $obj;
ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::Mapping->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'] },
            slx_mapper            => 'bwa',
            slx_mapper_exe        => '/path/to/mapper/mapper.exe',
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => $destination_directory
        )
    ),
    'initialise mapping config'
);
is( $obj->toplevel_action, '__VRTrack_Mapping__' );
my $returned_config_hash = $obj->to_hash;
my $prefix               = $returned_config_hash->{prefix};
$returned_config_hash->{prefix} = '_checked_elsewhere_';
ok( ( $prefix =~ m/_[\d]{10}_[\d]{1,4}_/ ), 'check prefix pattern is as expected' );

is_deeply(
    $returned_config_hash,
    {
        'limits' => {
            'project' => [ 'ABC\ study\(\ EFG\ \)' ]
        },
        'vrtrack_processed_flags' => {
            'qc'     => 1,
            'stored' => 1,
            'import' => 1
        },
        'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user'     => 'some_user',
            'port'     => 1234,
            'host'     => 'some_hostname'
        },
        'data' => {
            'do_recalibration'    => 0,
            'mark_duplicates'     => 1,
            'get_genome_coverage' => 1,
            'db'                  => {
                'database' => 'my_database',
                'password' => 'some_password',
                'user'     => 'some_user',
                'port'     => 1234,
                'host'     => 'some_hostname'
            },
            'dont_wait'            => 0,
            'assembly_name'        => 'ABC',
            'exit_on_errors'       => 0,
            'add_index'            => 1,
            'reference'            => '/path/to/ABC.fa',
            'do_cleanup'           => 1,
            'slx_mapper_exe'       => '/path/to/mapper/mapper.exe',
            'slx_mapper'           => 'bwa',
            'ignore_mapped_status' => 1
        },
        'log'                => '/path/to/log/my_database/mapping_ABC_study_EFG_ABC_bwa.log',
        'root'               => '/path/to/root/my_database/seq-pipelines',
        'prefix'             => '_checked_elsewhere_',
        'dont_use_get_lanes' => 1,
        'module'             => 'VertRes::Pipelines::Mapping'
    },
    'Expected base config file'
);

is(
    $obj->config,
    $destination_directory . '/my_database/mapping/mapping_ABC_study_EFG_ABC_bwa.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );

ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::Mapping->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'], lane => [ '1234_5#6', 'abc_efg' ] },
            slx_mapper            => 'bwa',
            slx_mapper_exe        => '/path/to/mapper/mapper.exe',
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => $destination_directory
        )
    ),
    'initialise mapping config with lane limits'
);

is_deeply(
    $obj->to_hash->{limits},
    {

        'lane'    => [ '1234_5#6', 'abc_efg' ],
        'project' => [ 'ABC\ study\(\ EFG\ \)' ]

    },
    'lane limits shouldnt be backslashed but everything else should be'
);

done_testing();
