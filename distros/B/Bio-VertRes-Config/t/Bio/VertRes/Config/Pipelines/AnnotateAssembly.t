#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::AnnotateAssembly');
}
my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::Pipelines::AnnotateAssembly->new(
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

is($obj->toplevel_action, '__VRTrack_AnnotateAssembly__', 'toplevel action name');
is_deeply(
    $obj->to_hash,
    {
              'limits' => {
                            'project' => ['Abc\ def\ \\(ghi123\\)']
                          },
              'max_failures' => 3,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'data' => {
                          'tmp_directory' => '/lustre/scratch108/pathogen/pathpipe/tmp',
                          'memory'        => 3000,
                          'db' => {
                                    'database' => 'my_database',
                                    'password' => 'some_password',
                                    'user' => 'some_user',
                                    'port' => 1234,
                                    'host' => 'some_hostname'
                                  },
                          'dbdir' => '/lustre/scratch108/pathogen/pathpipe/prokka',
                          'annotation_tool' => 'Prokka',
                          'dont_wait' => 0,
                          'assembler' => 'velvet',
                          'pipeline_version' => 1,
                          'kingdom'        => 'Bacteria'
                        },
              'max_lanes_to_search' => 1000,
              'vrtrack_processed_flags' => {
                                             'assembled' => 1,
                                             'annotated' => 0
                                           },
              'root' => '/path/to/root/my_database/seq-pipelines',
              'log' => '/path/to/log/my_database/annotate_assembly_Abc_def_ghi123_velvet.log',
              'limit' => 100,
              'module' => 'VertRes::Pipelines::AnnotateAssembly',
              'prefix' => '_annotate_'
            },
    'output hash constructed correctly'
);

is(
    $obj->config,
    $destination_directory . '/my_database/annotate_assembly/annotate_assembly_Abc_def_ghi123_velvet.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );

# Test limits
ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::AnnotateAssembly->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            limits                => {
                project     => [ 'study 1',  'study 2' ],
                sample      => [ 'sample 1', 'sample 2' ],
                species     => ['species 1'],
                other_stuff => ['some other stuff']
            },
            root_base           => '/path/to/root',
            log_base            => '/path/to/log',
            config_base         => '/path/to/config_base'
        )
    ),
    'initialise annotation config with multiple limits'
);

is_deeply(
    $obj->_escaped_limits,
    {
        'project'     => [ 'study\ 1',  'study\ 2' ],
        'sample'      => [ 'sample\ 1', 'sample\ 2' ],
        'species'     => [ 'species\ 1' ],
        'other_stuff' => [ 'some\ other\ stuff' ]
    },
    'Check escaped limits are as expected'
);
is_deeply(
    $obj->limits,
    {
        'project'     => [ 'study 1',  'study 2' ],
        'sample'      => [ 'sample 1', 'sample 2' ],
        'species'     => ['species 1'],
        'other_stuff' => ['some other stuff']
    },
    'Check the input limits are unchanged'
);

# check config file name
is(
    $obj->config,
    '/path/to/config_base/my_database/annotate_assembly/annotate_assembly_study_1_study_2_sample_1_sample_2_species_1_velvet.conf',
    'config file name in expected format'
);

done_testing();
