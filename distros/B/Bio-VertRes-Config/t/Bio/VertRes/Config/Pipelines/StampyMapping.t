#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::StampyMapping');
}

my $obj;
ok(
    (
        $obj = Bio::VertRes::Config::Pipelines::StampyMapping->new(
            database              => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            limits                => { project => ['ABC study( EFG )'] },
            root_base             => '/path/to/root',
            log_base              => '/path/to/log',
            config_base           => '/tmp'
        )
    ),
    'initialise stampy mapping config'
);
is($obj->toplevel_action, '__VRTrack_Mapping__');
my $returned_config_hash = $obj->to_hash;
my $prefix               = $returned_config_hash->{prefix};
$returned_config_hash->{prefix} = '_checked_elsewhere_';

is_deeply(
    $returned_config_hash,
    {
      'limits' => {
                              'project' => [
                                             'ABC\ study\(\ EFG\ \)'
                                           ]
                            },
              'vrtrack_processed_flags' => {
                                             'qc' => 1,
                                             'stored' => 1,
                                             'import' => 1
                                           },
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'data' => {
                          'do_recalibration' => 0,
                          'mark_duplicates' => 1,
                          'get_genome_coverage' => 1,
                          'db' => {
                                    'database' => 'my_database',
                                    'password' => 'some_password',
                                    'user' => 'some_user',
                                    'port' => 1234,
                                    'host' => 'some_hostname'
                                  },
                          'dont_wait' => 0,
                          'assembly_name' => 'ABC',
                          'exit_on_errors' => 0,
                          'add_index' => 1,
                          'reference' => '/path/to/ABC.fa',
                          'do_cleanup' => 1,
                          'slx_mapper_exe' => 'python2.7 /software/pathogen/external/apps/usr/local/stampy-1.0.22/stampy.py',
                          'slx_mapper' => 'stampy',
                          
                          'ignore_mapped_status' => 1
                        },
              'log' => '/path/to/log/my_database/mapping_ABC_study_EFG_ABC_stampy.log',
              'root' => '/path/to/root/my_database/seq-pipelines',
              'prefix' => '_checked_elsewhere_',
              'dont_use_get_lanes' => 1,
              'module' => 'VertRes::Pipelines::Mapping'
            },
    'Expected stampy base config file'
);


done_testing();
