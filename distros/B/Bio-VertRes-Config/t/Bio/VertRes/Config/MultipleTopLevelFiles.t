#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }

use Bio::VertRes::Config::Pipelines::BwaMapping;
use Bio::VertRes::Config::Pipelines::Import;
use Bio::VertRes::Config::Pipelines::Store;
use Bio::VertRes::Config::Pipelines::SnpCalling;
use Bio::VertRes::Config::Pipelines::SmaltMapping;



BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::MultipleTopLevelFiles');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

# Create a few config objects for testing
my @pipeline_configs;
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::Import->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base           => $destination_directory
));
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::Store->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base => $destination_directory));
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
push(@pipeline_configs, Bio::VertRes::Config::Pipelines::SnpCalling->new(
    database              => 'my_database',
    database_connect_file => 't/data/database_connection_details',
    reference_lookup_file => 't/data/refs.index',
    reference             => 'ABC',
    limits                => { project => ['XYZ study( EFG )'] },
    root_base             => '/path/to/root',
    log_base              => '/path/to/log',
    config_base           => $destination_directory
));

ok((my $obj = Bio::VertRes::Config::MultipleTopLevelFiles->new(
  database => 'my_database', 
  pipeline_configs => \@pipeline_configs,
  config_base => $destination_directory
)), 'initialise object');

ok(($obj->update_or_create()), 'Create all the toplevel files');

ok(-e $destination_directory.'/my_database/my_database_mapping_pipeline.conf', 'mapping toplevel file');
ok(-e $destination_directory.'/my_database/my_database_stored_pipeline.conf', 'stored toplevel file');
ok(-e $destination_directory.'/my_database/my_database_import_pipeline.conf', 'import toplevel file');
ok(-e $destination_directory.'/my_database/my_database_snps_pipeline.conf', 'snps toplevel file');

my $text = read_file( $destination_directory.'/my_database/my_database_mapping_pipeline.conf' );
chomp($text);
my @mapping_rows = sort(split("\n",$text));
is_deeply(\@mapping_rows , ["__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_bwa.conf",
"__VRTrack_Mapping__ $destination_directory/my_database/mapping/mapping_ABC_study_EFG_ABC_smalt.conf"], 'content of mapping toplevel file as expected');

$text = read_file( $destination_directory.'/my_database/my_database_stored_pipeline.conf' );
chomp($text);
is($text, "__VRTrack_Storing__ $destination_directory/my_database/stored/stored_global.conf", 'content of stored toplevel file as expected');

$text = read_file( $destination_directory.'/my_database/my_database_import_pipeline.conf' );
chomp($text);
is($text, "__VRTrack_Import__ $destination_directory/my_database/import/import_global.conf", 'content of import toplevel file as expected');

$text = read_file( $destination_directory.'/my_database/my_database_snps_pipeline.conf' );
chomp($text);
is($text, "__VRTrack_SNPs__ $destination_directory/my_database/snps/snps_XYZ_study_EFG_ABC.conf", 'content of snps toplevel file as expected');

done_testing();

