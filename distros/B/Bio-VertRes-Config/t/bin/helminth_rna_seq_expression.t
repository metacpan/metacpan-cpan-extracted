#!/usr/bin/env perl
package Bio::VertRes::Config::Tests;
use Moose;
use Data::Dumper;
use File::Temp;
use File::Slurp;
use File::Find;
use Test::Most;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';

my $script_name = 'Bio::VertRes::Config::CommandLine::HelminthRnaSeqExpression';

my %scripts_and_expected_files = (
    '-t file -i t/data/lanes_file -r ABC' => [
        'command_line.log',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_rna_seq_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',
        'helminths/import/import_global.conf',
        'helminths/mapping/mapping_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_ABC_tophat.conf',
        'helminths/qc/qc_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name.conf',
        'helminths/rna_seq/rna_seq_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_ABC.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t lane -i 1234_5#6 -r ABC' => [
        'command_line.log',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_rna_seq_pipeline.conf',  'helminths/helminths_stored_pipeline.conf',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_1234_5_6_ABC_tophat.conf',
        'helminths/qc/qc_1234_5_6.conf',             'helminths/rna_seq/rna_seq_1234_5_6_ABC.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t library -i libname -r ABC' => [
        'command_line.log',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_rna_seq_pipeline.conf',  'helminths/helminths_stored_pipeline.conf',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_libname_ABC_tophat.conf',
        'helminths/qc/qc_libname.conf',              'helminths/rna_seq/rna_seq_libname_ABC.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t sample -i sample -r ABC' => [
        'command_line.log',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_rna_seq_pipeline.conf',  'helminths/helminths_stored_pipeline.conf',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_sample_ABC_tophat.conf',
        'helminths/qc/qc_sample.conf',               'helminths/rna_seq/rna_seq_sample_ABC.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -p "StrandSpecificProtocol"' => [
        'command_line.log',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
        'helminths/mapping/mapping_ZZZ_ABC_tophat.conf', 'helminths/qc/qc_ZZZ.conf',
        'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -s Staphylococcus_aureus' => [
        'command_line.log',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_rna_seq_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',
        'helminths/import/import_global.conf',
        'helminths/mapping/mapping_ZZZ_Staphylococcus_aureus_ABC_tophat.conf',
        'helminths/qc/qc_ZZZ_Staphylococcus_aureus.conf',
        'helminths/rna_seq/rna_seq_ZZZ_Staphylococcus_aureus_ABC.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC' => [
        'command_line.log',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
        'helminths/mapping/mapping_ZZZ_ABC_tophat.conf', 'helminths/qc/qc_ZZZ.conf',
        'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
    ],
     '-t study -i ZZZ -r ABC -m smalt' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_smalt.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     '-t study -i ZZZ -r ABC -m bwa' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_bwa.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     '-t study -i ZZZ -r ABC -m bowtie2' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_bowtie2.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     '-t study -i ZZZ -r ABC -m stampy' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_stampy.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     '-t study -i ZZZ -r ABC -m smalt --smalt_index_k 15 --smalt_index_s 4 --smalt_mapper_r 1 --smalt_mapper_y 0.9 --smalt_mapper_x' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_smalt.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     '-t study -i ZZZ -r ABC --tophat_mapper_max_intron 10000 --tophat_mapper_min_intron 70 --tophat_mapper_max_multihit 1' =>   [
         'command_line.log',
         'helminths/helminths.ilm.studies',
         'helminths/helminths_import_pipeline.conf',      'helminths/helminths_mapping_pipeline.conf',
         'helminths/helminths_qc_pipeline.conf',          'helminths/helminths_rna_seq_pipeline.conf',
         'helminths/helminths_stored_pipeline.conf',      'helminths/import/import_global.conf',
         'helminths/mapping/mapping_ZZZ_ABC_tophat.conf', 'helminths/qc/qc_ZZZ.conf',
         'helminths/rna_seq/rna_seq_ZZZ_ABC.conf',        'helminths/stored/stored_global.conf',
     ],
     
     
    '-a ABC ' => ['command_line.log'],

);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();

