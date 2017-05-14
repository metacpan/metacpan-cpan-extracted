#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Recipes::BacteriaAssemblySingleCell');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
            my $obj = Bio::VertRes::Config::Recipes::BacteriaAssemblySingleCell->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'] },
        )
    ),
    'initalise creating files'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files' );

# Check assembly file
ok( -e $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_spades.conf', 'assembly toplevel file' );
my $text = read_file( $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_spades.conf' );
my $input_config_file = eval($text);

is_deeply($input_config_file,{
  'max_failures' => 3,
  'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user' => 'some_user',
            'port' => 1234,
            'host' => 'some_hostname'
          },
  'data' => {
              'genome_size' => 10000000,
              'remove_primers' => 0,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'assembler_exec' => '/software/pathogen/external/apps/usr/bin/spades.py',
              'error_correct' => 0,
              'seq_pipeline_root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
              'assembler' => 'spades',
              'primers_file' => '/nfs/pathnfs05/conf/primers/virus_primers',
              'normalise' => 0,
              'tmp_directory' => '/lustre/scratch108/pathogen/pathpipe/tmp',
              'sga_exec' => '/software/pathogen/external/apps/usr/bin/sga',
              'max_threads' => 2,
              'pipeline_version' => '5',
              'single_cell' => 1,
              'dont_wait' => 0,
              'post_contig_filtering' => 300,
              'optimiser_exec' => '/software/pathogen/external/apps/usr/bin/spades.py'
            },
  'max_lanes_to_search' => 200,
  'limits' => {
                'project' => [
                               'ABC\\ study\\(\\ EFG\\ \\)'
                             ]
              },
  'vrtrack_processed_flags' => {
                                 'assembled' => 0,
                                 'rna_seq_expression' => 0,
                                 'stored' => 1
                               },
  'limit' => 100,
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'log' => '/nfs/pathnfs05/log/my_database/assembly_ABC_study_EFG_spades.log',
  'prefix' => '_assembly_',
  'module' => 'VertRes::Pipelines::Assembly'
},'Config file as expected');

# Check annotation file
ok( -e $destination_directory . '/my_database/annotate_assembly/annotate_assembly_ABC_study_EFG_spades.conf', 'annotate assembly toplevel file' );
$text = read_file( $destination_directory . '/my_database/annotate_assembly/annotate_assembly_ABC_study_EFG_spades.conf' );
$input_config_file = eval($text);

is_deeply($input_config_file,{
  'max_failures' => 3,
  'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user' => 'some_user',
            'port' => 1234,
            'host' => 'some_hostname'
          },
  'data' => {
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'annotation_tool' => 'Prokka',
              'dont_wait' => 0,
              'assembler' => 'spades',
              'memory' => 3000,
              'tmp_directory' => '/lustre/scratch108/pathogen/pathpipe/tmp',
              'dbdir' => '/lustre/scratch108/pathogen/pathpipe/prokka',
              'pipeline_version' => 1,
              'kingdom' => 'Bacteria',
            },
  'max_lanes_to_search' => 1000,
  'limits' => {
                'project' => [
                               'ABC\\ study\\(\\ EFG\\ \\)'
                             ]
              },
  'vrtrack_processed_flags' => {
                                 'assembled' => 1,
                                 'annotated' => 0
                               },
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'log' => '/nfs/pathnfs05/log/my_database/annotate_assembly_ABC_study_EFG_spades.log',
  'limit' => 100,
  'module' => 'VertRes::Pipelines::AnnotateAssembly',
  'prefix' => '_annotate_'
},'Config file as expected');

done_testing();
