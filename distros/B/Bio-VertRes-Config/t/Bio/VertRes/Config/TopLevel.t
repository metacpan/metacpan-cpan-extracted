#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

use Bio::VertRes::Config::Pipelines::BwaMapping;
use Bio::VertRes::Config::Pipelines::Assembly;
use Bio::VertRes::Config::Pipelines::Import;
use Bio::VertRes::Config::Pipelines::Store;
use Bio::VertRes::Config::Pipelines::SnpCalling;
use Bio::VertRes::Config::Pipelines::SmaltMapping;
use Bio::VertRes::Config::Pipelines::StampyMapping;



BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::MultipleTopLevelFiles');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

# Create a few config objects for testing
my @pipeline_configs;
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::BwaMapping->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    reference_lookup_file => 't/data/refs.index',
    reference             => 'ABC',
    limits                => { project => ['ABC study( EFG )'] },
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base           => $destination_directory
));
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::SmaltMapping->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    reference_lookup_file => 't/data/refs.index',
    reference             => 'ABC',
    limits                => { project => ['ABC study( EFG )'] },
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base           => $destination_directory
));

ok((my $obj = Bio::VertRes::Config::TopLevel->new(
  database => 'my_database', 
  pipeline_configs => \@pipeline_configs,
  config_base => $destination_directory,
  pipeline_short_name => 'mapping'
)), 'initialise object');

ok(($obj->update_or_create()), 'Create the toplevel file');

ok(-e $destination_directory.'/my_database/my_database_mapping_pipeline.conf', 'mapping toplevel file');

my $text = read_file( $destination_directory.'/my_database/my_database_mapping_pipeline.conf' );
chomp($text);
my @mapping_rows = sort(split("\n",$text));
is_deeply(\@mapping_rows , ["__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_bwa.conf",
"__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf"], 'content of mapping toplevel file as expected');


# Running it again should produce the same output
ok((my $obj_rerun = Bio::VertRes::Config::TopLevel->new(
  database => 'my_database', 
  pipeline_configs => \@pipeline_configs,
  config_base => $destination_directory,
  pipeline_short_name => 'mapping'
)), 'initialise object to run it again');
ok(($obj_rerun->update_or_create()), 'Create the toplevel file thats been rerun');
$text = read_file( $destination_directory.'/my_database/my_database_mapping_pipeline.conf' );
chomp($text);
@mapping_rows = sort(split("\n",$text));
is_deeply(\@mapping_rows , ["__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_bwa.conf",
"__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf"], 'content of mapping toplevel file as expected, so no duplicates');


# Append a new mapping
@pipeline_configs = ();
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::StampyMapping->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    reference_lookup_file => 't/data/refs.index',
    reference             => 'ABC',
    limits                => { project => ['Another study'] },
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base           => $destination_directory
));
ok((my $obj_append = Bio::VertRes::Config::TopLevel->new(
  database => 'my_database', 
  pipeline_configs => \@pipeline_configs,
  config_base => $destination_directory,
  pipeline_short_name => 'mapping'
)), 'initialise object to append a new mapping');
ok(($obj_append->update_or_create()), 'Create the toplevel file to append a new mapping');
$text = read_file( $destination_directory.'/my_database/my_database_mapping_pipeline.conf' );
chomp($text);
@mapping_rows = sort(split("\n",$text));
is_deeply(\@mapping_rows , [
  "__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_bwa.conf",
  "__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf",
  "__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_Another_study_ABC_stampy.conf"
], 'content of mapping toplevel file has the appended row');


done_testing();

