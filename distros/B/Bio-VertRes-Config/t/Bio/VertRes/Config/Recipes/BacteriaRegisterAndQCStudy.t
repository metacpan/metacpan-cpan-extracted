#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Recipes::BacteriaRegisterAndQCStudy');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
            my $obj = Bio::VertRes::Config::Recipes::BacteriaRegisterAndQCStudy->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
        )
    ),
    'initalise creating files'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files' );

ok((-e $destination_directory.'/my_database/my_database.ilm.studies'), 'study names file exists');
my $text = read_file( $destination_directory.'/my_database/my_database.ilm.studies' );
chomp($text);
is($text, "ABC study( EFG )", 'Study is in file');

ok( -e $destination_directory . '/my_database/qc/qc_ABC_study_EFG.conf', 'QC toplevel file' );
$text = read_file( $destination_directory . '/my_database/qc/qc_ABC_study_EFG.conf' );
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
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'chr_regex' => '.*',
              'mapper' => 'bwa',
              'glf' => '/software/pathogen/external/apps/usr/bin/glf',
              'do_samtools_rmdup' => 1,
              'fai_ref' => '/path/to/ABC.fa.fai',
              'gtype_confidence' => '1.2',
              'bwa_ref' => '/path/to/ABC.fa',
              'assembly' => 'ABC',
              'skip_genotype' => 1,
              'dont_wait' => 0,
              'mapviewdepth' => '/software/pathogen/external/apps/usr/bin/bindepth',
              'stats_ref' => '/path/to/ABC.fa.refstats',
              'exit_on_errors' => 0,
              'bwa_exec' => '/software/pathogen/external/apps/usr/local/bwa-0.6.1/bwa',
              'adapters' => '/lustre/scratch108/pathogen/pathpipe/usr/share/solexa-adapters.fasta',
              'samtools' => '/software/pathogen/external/apps/usr/bin/samtools',
              'fa_ref' => '/path/to/ABC.fa',
              'gcdepth_R'         => '/software/pathogen/external/apps/usr/local/gcdepth/gcdepth.R',
              'snps' => '/lustre/scratch108/pathogen/pathpipe/usr/share/mousehapmap.snps.bin'
            },
  'limits' => {
                'project' => [
                               'ABC\ study\(\ EFG\ \)'
                             ]
              },
  'log' => '/nfs/pathnfs05/log/my_database/qc_ABC_study_EFG.log',
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'prefix' => '_',
  'module' => 'VertRes::Pipelines::TrackQC_Fastq'
},'Config file as expected');

# Check assembly file
ok( -e $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_velvet.conf', 'assembly toplevel file' );
$text = read_file( $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_velvet.conf' );
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
              'remove_primers' => 0,
              'genome_size' => 10000000,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'error_correct' => 0,
              'assembler_exec' => '/software/pathogen/external/apps/usr/bin/velvet',
              'dont_wait' => 0,
              'primers_file' => '/nfs/pathnfs05/conf/primers/virus_primers',
              'assembler' => 'velvet',
              'seq_pipeline_root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
              'normalise' => 0,
              'sga_exec' => '/software/pathogen/external/apps/usr/bin/sga',
              'tmp_directory' => '/lustre/scratch108/pathogen/pathpipe/tmp',
              'pipeline_version' => 2.1,
              'post_contig_filtering' => 300,
              'max_threads' => 2,
              'optimiser_exec' => '/software/pathogen/external/apps/usr/bin/VelvetOptimiser.pl'
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
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'log' => '/nfs/pathnfs05/log/my_database/assembly_ABC_study_EFG_velvet.log',
  'limit' => 100,
  'module' => 'VertRes::Pipelines::Assembly',
  'prefix' => '_assembly_'
},'Config file as expected');

# Check annotation file
ok( -e $destination_directory . '/my_database/annotate_assembly/annotate_assembly_ABC_study_EFG_velvet.conf', 'annotate assembly toplevel file' );
$text = read_file( $destination_directory . '/my_database/annotate_assembly/annotate_assembly_ABC_study_EFG_velvet.conf' );
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
              'assembler' => 'velvet',
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
  'log' => '/nfs/pathnfs05/log/my_database/annotate_assembly_ABC_study_EFG_velvet.log',
  'limit' => 100,
  'module' => 'VertRes::Pipelines::AnnotateAssembly',
  'prefix' => '_annotate_'
},'Config file as expected');



ok(
    (
        $obj = Bio::VertRes::Config::Recipes::BacteriaRegisterAndQCStudy->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'], species => ['Cat', 'Dog'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
        )
    ),
    'initalise creating files with species'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files with species' );

ok( -e $destination_directory . '/my_database/qc/qc_ABC_study_EFG_Cat_Dog.conf', 'QC toplevel file with species' );
$text = read_file( $destination_directory . '/my_database/qc/qc_ABC_study_EFG_Cat_Dog.conf' );
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
              'chr_regex' => '.*',
              'mapper' => 'bwa',
              'glf' => '/software/pathogen/external/apps/usr/bin/glf',
              'do_samtools_rmdup' => 1,
              'fai_ref' => '/path/to/ABC.fa.fai',
              'gtype_confidence' => '1.2',
              'bwa_ref' => '/path/to/ABC.fa',
              'assembly' => 'ABC',
              'skip_genotype' => 1,
              'dont_wait' => 0,
              'mapviewdepth' => '/software/pathogen/external/apps/usr/bin/bindepth',
              'stats_ref' => '/path/to/ABC.fa.refstats',
              'exit_on_errors' => 0,
              'bwa_exec' => '/software/pathogen/external/apps/usr/local/bwa-0.6.1/bwa',
              'adapters' => '/lustre/scratch108/pathogen/pathpipe/usr/share/solexa-adapters.fasta',
              'samtools' => '/software/pathogen/external/apps/usr/bin/samtools',
              'fa_ref' => '/path/to/ABC.fa',
              'gcdepth_R'         => '/software/pathogen/external/apps/usr/local/gcdepth/gcdepth.R',
              'snps' => '/lustre/scratch108/pathogen/pathpipe/usr/share/mousehapmap.snps.bin'
            },
  'limits' => {
                'project' => [
                               'ABC\ study\(\ EFG\ \)'
                             ],
                'species' => [
                               'Cat',
                               'Dog'
                             ]
              },
  'log' => '/nfs/pathnfs05/log/my_database/qc_ABC_study_EFG_Cat_Dog.log',
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'prefix' => '_',
  'module' => 'VertRes::Pipelines::TrackQC_Fastq'
},'Config file as expected with species limit');


ok(
    (
        $obj = Bio::VertRes::Config::Recipes::BacteriaRegisterAndQCStudy->new(
            database    => 'my_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['ABC study( EFG )'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
            assembler             => 'spades'
        )
    ),
    'initalise creating spades assembly file'
);
ok( ( $obj->create ), 'Create all the config files and toplevel files with spades' );

ok( -e $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_spades.conf', 'created toplevel spades' );
$text = read_file( $destination_directory . '/my_database/assembly/assembly_ABC_study_EFG_spades.conf' );
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
              'remove_primers' => 0,
              'genome_size' => 10000000,
              'db' => {
                        'database' => 'my_database',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'error_correct' => 0,
              'assembler_exec' => '/software/pathogen/external/apps/usr/bin/spades.py',
              'dont_wait' => 0,
              'primers_file' => '/nfs/pathnfs05/conf/primers/virus_primers',
              'assembler' => 'spades',
              'seq_pipeline_root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
              'normalise' => 0,
              'sga_exec' => '/software/pathogen/external/apps/usr/bin/sga',
              'tmp_directory' => '/lustre/scratch108/pathogen/pathpipe/tmp',
              'pipeline_version' => 2.1,
              'post_contig_filtering' => 300,
              'max_threads' => 2,
              'single_cell' => 0,
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
  'root' => '/lustre/scratch108/pathogen/pathpipe/my_database/seq-pipelines',
  'log' => '/nfs/pathnfs05/log/my_database/assembly_ABC_study_EFG_spades.log',
  'limit' => 100,
  'module' => 'VertRes::Pipelines::Assembly',
  'prefix' => '_assembly_'
},'Config file as expected with spades assembler');

# Populate a new study
Bio::VertRes::Config::RegisterStudy->new(database => 'pathogen_prok_track', study_name => 'DDD',config_base => $destination_directory)->register_study_name();

ok(
    (
        $obj = Bio::VertRes::Config::Recipes::BacteriaRegisterAndQCStudy->new(
            database    => 'my_other_database',
            config_base => $destination_directory,
            database_connect_file => 't/data/database_connection_details',
            limits      => { project => ['DDD'] },
            reference_lookup_file => 't/data/refs.index',
            reference             => 'ABC',
        )
    ),
    'Initialise with the study pointing at the wrong database'
);
ok( ( $obj->create ), 'the database name should have been updated to prevent the same study being registered in 2 different places' );

ok( -e $destination_directory . '/prokaryotes/qc/qc_DDD.conf', 'QC toplevel file with modified database' );
$text = read_file( $destination_directory . '/prokaryotes/qc/qc_DDD.conf' );
$input_config_file = eval($text);
is_deeply($input_config_file,{
  'max_failures' => 3,
  'db' => {
            'database' => 'pathogen_prok_track',
            'password' => 'some_password',
            'user' => 'some_user',
            'port' => 1234,
            'host' => 'some_hostname'
          },
  'data' => {
              'db' => {
                        'database' => 'pathogen_prok_track',
                        'password' => 'some_password',
                        'user' => 'some_user',
                        'port' => 1234,
                        'host' => 'some_hostname'
                      },
              'chr_regex' => '.*',
              'mapper' => 'bwa',
              'glf' => '/software/pathogen/external/apps/usr/bin/glf',
              'do_samtools_rmdup' => 1,
              'fai_ref' => '/path/to/ABC.fa.fai',
              'gtype_confidence' => '1.2',
              'bwa_ref' => '/path/to/ABC.fa',
              'assembly' => 'ABC',
              'skip_genotype' => 1,
              'dont_wait' => 0,
              'mapviewdepth' => '/software/pathogen/external/apps/usr/bin/bindepth',
              'stats_ref' => '/path/to/ABC.fa.refstats',
              'exit_on_errors' => 0,
              'bwa_exec' => '/software/pathogen/external/apps/usr/local/bwa-0.6.1/bwa',
              'adapters' => '/lustre/scratch108/pathogen/pathpipe/usr/share/solexa-adapters.fasta',
              'samtools' => '/software/pathogen/external/apps/usr/bin/samtools',
              'fa_ref' => '/path/to/ABC.fa',
              'gcdepth_R'         => '/software/pathogen/external/apps/usr/local/gcdepth/gcdepth.R',
              'snps' => '/lustre/scratch108/pathogen/pathpipe/usr/share/mousehapmap.snps.bin'
            },
  'limits' => {
                'project' => [
                               'DDD'
                             ],

              },
  'log' => '/nfs/pathnfs05/log/prokaryotes/qc_DDD.log',
  'root' => '/lustre/scratch108/pathogen/pathpipe/prokaryotes/seq-pipelines',
  'prefix' => '_',
  'module' => 'VertRes::Pipelines::TrackQC_Fastq'
},'Config file has modified database names');


done_testing();
