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

my $script_name = 'Bio::VertRes::Config::CommandLine::BacteriaAssemblySingleCell';

my %scripts_and_expected_files = (
    '-t study -i ZZZ' => [
        'command_line.log',                               'prokaryotes/annotate_assembly/annotate_assembly_ZZZ_spades.conf',
        'prokaryotes/assembly/assembly_ZZZ_spades.conf',  'prokaryotes/prokaryotes_annotate_assembly_pipeline.conf',
        'prokaryotes/prokaryotes_assembly_pipeline.conf', 'prokaryotes/prokaryotes.ilm.studies',
    ],
    '-t lane -i 1234_5#6 ' => [
        'command_line.log',
        'prokaryotes/annotate_assembly/annotate_assembly_1234_5_6_spades.conf',
        'prokaryotes/assembly/assembly_1234_5_6_spades.conf',
        'prokaryotes/prokaryotes_annotate_assembly_pipeline.conf',
        'prokaryotes/prokaryotes_assembly_pipeline.conf',

    ],
    '-t library -i libname ' => [
        'command_line.log',
        'prokaryotes/annotate_assembly/annotate_assembly_libname_spades.conf',
        'prokaryotes/assembly/assembly_libname_spades.conf',
        'prokaryotes/prokaryotes_annotate_assembly_pipeline.conf',
        'prokaryotes/prokaryotes_assembly_pipeline.conf',

    ],
    '-t sample -i sample ' => [
        'command_line.log',
        'prokaryotes/annotate_assembly/annotate_assembly_sample_spades.conf',
        'prokaryotes/assembly/assembly_sample_spades.conf',
        'prokaryotes/prokaryotes_annotate_assembly_pipeline.conf',
        'prokaryotes/prokaryotes_assembly_pipeline.conf',

    ],
    '-t file -i t/data/lanes_file ' => [
        'command_line.log',
        'prokaryotes/annotate_assembly/annotate_assembly_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_spades.conf',
        'prokaryotes/assembly/assembly_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_spades.conf',
        'prokaryotes/prokaryotes_annotate_assembly_pipeline.conf',
        'prokaryotes/prokaryotes_assembly_pipeline.conf',
    ],
    '-d some_other_db_name -t study -i ZZZ ' => [
        'command_line.log',
        'some_other_db_name/annotate_assembly/annotate_assembly_ZZZ_spades.conf',
        'some_other_db_name/assembly/assembly_ZZZ_spades.conf',
        'some_other_db_name/some_other_db_name_annotate_assembly_pipeline.conf',
        'some_other_db_name/some_other_db_name_assembly_pipeline.conf',
        'some_other_db_name/some_other_db_name.ilm.studies',
    ],

);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();
