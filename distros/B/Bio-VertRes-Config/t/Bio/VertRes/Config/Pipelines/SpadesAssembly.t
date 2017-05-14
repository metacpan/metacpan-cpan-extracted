#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::SpadesAssembly');
}
my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::Pipelines::SpadesAssembly->new(
            database    => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            limits      => {project => ['Abc def (ghi123)']},
            root_base   => '/path/to/root',
            log_base    => '/path/to/log',
            config_base => $destination_directory
        )
    ),
    'initialise assembly config'
);

is($obj->toplevel_action, '__VRTrack_Assembly__');

is_deeply(
    $obj->to_hash,
    {
        'limits' => {
            'project' => ['Abc\ def\ \\(ghi123\\)']
                    },
        'max_failures' => 3,
        'db'           => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user'     => 'some_user',
            'port'     => 1234,
            'host'     => 'some_hostname'
        },
        'data' => {
            'genome_size' => 10000000,
            'db'          => {
                'database' => 'my_database',
                'password' => 'some_password',
                'user'     => 'some_user',
                'port'     => 1234,
                'host'     => 'some_hostname'
            },
            'assembler_exec'    => '/software/pathogen/external/apps/usr/bin/spades.py',
            'dont_wait'         => 0,
            'assembler'         => 'spades',
            'seq_pipeline_root' => '/path/to/root/my_database/seq-pipelines',
            'tmp_directory'     => '/lustre/scratch108/pathogen/pathpipe/tmp',
            'max_threads'       => 2,
            'pipeline_version'  => 2.1,
            'post_contig_filtering' => 300,
            'error_correct'     => 0,
            'sga_exec'          => '/software/pathogen/external/apps/usr/bin/sga',
            'optimiser_exec'    => '/software/pathogen/external/apps/usr/bin/spades.py',
            'primers_file'      => '/nfs/pathnfs05/conf/primers/virus_primers',
            'remove_primers'    => 0,
            'normalise'         => 0,
            'single_cell'       => 0
        },
        'max_lanes_to_search'     => 200,
        'vrtrack_processed_flags' => {
            'assembled'          => 0,
            'rna_seq_expression' => 0,
            'stored'             => 1
        },
        'root'   => '/path/to/root/my_database/seq-pipelines',
        'log'    => '/path/to/log/my_database/assembly_Abc_def_ghi123_spades.log',
        'limit'  => 100,
        'module' => 'VertRes::Pipelines::Assembly',
        'prefix' => '_assembly_'
    },
    'output hash constructed correctly'
);

is(
    $obj->config,
    $destination_directory . '/my_database/assembly/assembly_Abc_def_ghi123_spades.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );



done_testing();
