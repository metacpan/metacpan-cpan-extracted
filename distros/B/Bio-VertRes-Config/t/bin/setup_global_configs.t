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

my $script_name = 'setup_global_configs';

my %scripts_and_expected_files = (
    '-d pathogen_euk_track' => [
        'command_line.log',
        'eukaryotes/eukaryotes_import_pipeline.conf',
        'eukaryotes/eukaryotes_stored_pipeline.conf',   'eukaryotes/import/import_global.conf',
        'eukaryotes/stored/stored_global.conf',
    ],
    '-d some_other_db_name' => [
        'command_line.log',
        'some_other_db_name/import/import_global.conf',
        'some_other_db_name/some_other_db_name_import_pipeline.conf',
        'some_other_db_name/some_other_db_name_stored_pipeline.conf',
        'some_other_db_name/stored/stored_global.conf',
    ],

);

execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

done_testing();
