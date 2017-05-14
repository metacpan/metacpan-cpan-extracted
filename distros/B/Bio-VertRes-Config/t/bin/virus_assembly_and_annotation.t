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

my $script_name = 'Bio::VertRes::Config::CommandLine::VirusAssemblyAndAnnotation';

my %scripts_and_expected_files = (
    '-t study -i ZZZ' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_ZZZ_spades.conf',
        'viruses/assembly/assembly_ZZZ_spades.conf',
        'viruses/viruses.ilm.studies',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
        '-t study -i ZZZ -assembler velvet' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_ZZZ_velvet.conf',
        'viruses/assembly/assembly_ZZZ_velvet.conf',
        'viruses/viruses.ilm.studies',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
    '-t lane -i 1234_5#6' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_1234_5_6_spades.conf',
        'viruses/assembly/assembly_1234_5_6_spades.conf',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
    '-t library -i libname' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_libname_spades.conf',
        'viruses/assembly/assembly_libname_spades.conf',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
    '-t sample -i sample' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_sample_spades.conf',
        'viruses/assembly/assembly_sample_spades.conf',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
    '-t file -i t/data/lanes_file' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_spades.conf',
        'viruses/assembly/assembly_1111_2222_3333_lane_name_another_lane_name_a_very_big_lane_name_spades.conf',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',
    ],
    '-t study -i ZZZ -s Staphylococcus_aureus' => [
        'command_line.log',
        'viruses/annotate_assembly/annotate_assembly_ZZZ_Staphylococcus_aureus_spades.conf',
        'viruses/assembly/assembly_ZZZ_Staphylococcus_aureus_spades.conf',
        'viruses/viruses.ilm.studies',
        'viruses/viruses_annotate_assembly_pipeline.conf',
        'viruses/viruses_assembly_pipeline.conf',

    ],
    '-d some_other_db_name -t study -i ZZZ' => [
        'command_line.log',
        'some_other_db_name/annotate_assembly/annotate_assembly_ZZZ_spades.conf',
        'some_other_db_name/assembly/assembly_ZZZ_spades.conf',        
        'some_other_db_name/some_other_db_name.ilm.studies',
        'some_other_db_name/some_other_db_name_annotate_assembly_pipeline.conf',
        'some_other_db_name/some_other_db_name_assembly_pipeline.conf',       
    ],

);

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();
