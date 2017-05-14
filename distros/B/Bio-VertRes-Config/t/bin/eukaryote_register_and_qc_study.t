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

my $script_name = 'Bio::VertRes::Config::CommandLine::EukaryotesRegisterAndQCStudy';

my %scripts_and_expected_files = (
    '-a ABC '                  => ['command_line.log'],
    '-t study -i ZZZ -r ABC' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes.ilm.studies',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_ZZZ.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-t lane -i 1234_5#6 -r ABC' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_1234_5_6.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-t library -i libname -r ABC' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_libname.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-t sample -i sample -r ABC' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_sample.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-t file -i t/data/lanes_file -r ABC' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-t study -i ZZZ -r ABC -s Staphylococcus_aureus' => [
        'command_line.log',
        'eukaryotes/import/import_global.conf',
        'eukaryotes/eukaryotes.ilm.studies',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_qc_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',
        'eukaryotes/qc/qc_ZZZ_Staphylococcus_aureus.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-d some_other_db_name -t study -i ZZZ -r ABC' => [
        'command_line.log',
        'some_other_db_name/import/import_global.conf',
        'some_other_db_name/some_other_db_name.ilm.studies',
        'some_other_db_name/some_other_db_name_import_pipeline.conf',
        'some_other_db_name/some_other_db_name_qc_pipeline.conf',
        'some_other_db_name/some_other_db_name_stored_pipeline.conf',
        'some_other_db_name/qc/qc_ZZZ.conf',
        'some_other_db_name/stored/stored_global.conf',
    ],

);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();
