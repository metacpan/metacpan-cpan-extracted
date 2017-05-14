#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Recipes::EukaryotesMappingUsingSsaha2');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::Recipes::EukaryotesMappingUsingSsaha2->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC'
        )
    ),
    'initalise creating files'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files' );

# Are all the nessisary top level files there?
ok( -e $destination_directory . '/my_database/my_database.ilm.studies' , 'study names file exists');
ok( -e $destination_directory . '/my_database/my_database_stored_pipeline.conf', 'stored toplevel file');
ok( -e $destination_directory . '/my_database/my_database_import_pipeline.conf', 'import toplevel file');
ok( -e $destination_directory . '/my_database/my_database_qc_pipeline.conf', 'qc toplevel file');
ok( -e $destination_directory . '/my_database/my_database_mapping_pipeline.conf', 'mapping toplevel file');


# Individual config files
ok((-e "$destination_directory/my_database/stored/stored_global.conf"), 'stored config file exists');
ok((-e "$destination_directory/my_database/import/import_global.conf"), 'import config file exists');
ok((-e "$destination_directory/my_database/qc/qc_ABC_study_EFG.conf"), 'QC config file exists' );
ok((-e "$destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_ssaha.conf"), 'mapping config file exists' );


my $text = read_file( "$destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_ssaha.conf" );
my $input_config_file = eval($text);
$input_config_file->{prefix} = '_checked_elsewhere_';
is_deeply($input_config_file,{
  'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user' => 'some_user',
            'port' => 1234,
            'host' => 'some_hostname'
          },
  'data' => {
              'mark_duplicates' => 1,
              'do_recalibration' => 0,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'get_genome_coverage' => 1,
              'dont_wait' => 0,
              'assembly_name' => 'ABC',
              'exit_on_errors' => 0,
              'add_index' => 1,
              'reference' => '/path/to/ABC.fa',
              'do_cleanup' => 1,
              'ignore_mapped_status' => 1,
              'slx_mapper' => 'ssaha',
              'slx_mapper_exe' => '/software/pathogen/external/apps/usr/local/ssaha2/ssaha2',
              '454_mapper_exe' => '/software/pathogen/external/apps/usr/local/ssaha2/ssaha2',
              '454_mapper' => 'ssaha'
            },
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
  'log' => '/nfs/pathnfs05/log/my_database/mapping_ABC_study_EFG_ABC_ssaha.log',
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'prefix' => '_checked_elsewhere_',
  'dont_use_get_lanes' => 1,
  'module' => 'VertRes::Pipelines::Mapping'
},'Mapping Config file as expected');


done_testing();
