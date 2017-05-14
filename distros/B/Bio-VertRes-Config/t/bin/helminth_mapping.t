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

my $script_name = 'Bio::VertRes::Config::CommandLine::HelminthMapping';

my %scripts_and_expected_files = (
    '-a ABC '                  => ['command_line.log'],
    '-t study -i ZZZ -r ABC' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_smalt.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t lane -i 1234_5#6 -r ABC' => [
        'command_line.log',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_1234_5_6_ABC_smalt.conf',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',   'helminths/qc/qc_1234_5_6.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t library -i libname -r ABC' => [
        'command_line.log',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_libname_ABC_smalt.conf',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',   'helminths/qc/qc_libname.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t sample -i sample -r ABC' => [
        'command_line.log',
        'helminths/import/import_global.conf',        'helminths/mapping/mapping_sample_ABC_smalt.conf',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',  'helminths/helminths_qc_pipeline.conf',
        'helminths/helminths_stored_pipeline.conf',   'helminths/qc/qc_sample.conf',
        'helminths/stored/stored_global.conf',
    ],
    '-t file -i t/data/lanes_file -r ABC' => [
        'command_line.log',
        'helminths/import/import_global.conf',
        'helminths/mapping/mapping_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_ABC_smalt.conf',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',

        'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name.conf',

        'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -p "StandardProtocol"' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_smalt.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -s Staphylococcus_aureus' => [
        'command_line.log',
        'helminths/import/import_global.conf',
        'helminths/mapping/mapping_ZZZ_Staphylococcus_aureus_ABC_smalt.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf',
        'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',

        'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ_Staphylococcus_aureus.conf',

        'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m bwa' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_bwa.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m stampy' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_stampy.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m ssaha2' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_ssaha.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m tophat' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_tophat.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m bowtie2' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_bowtie2.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -m smalt --smalt_index_k 15 --smalt_index_s 4 --smalt_mapper_r 1 --smalt_mapper_y 0.9 --smalt_mapper_x' => [
        'command_line.log',
        'helminths/import/import_global.conf',      'helminths/mapping/mapping_ZZZ_ABC_smalt.conf',
        'helminths/helminths.ilm.studies',
        'helminths/helminths_import_pipeline.conf', 'helminths/helminths_mapping_pipeline.conf',
        'helminths/helminths_qc_pipeline.conf',     'helminths/helminths_stored_pipeline.conf',
        'helminths/qc/qc_ZZZ.conf',                'helminths/stored/stored_global.conf',
    ],

);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();
