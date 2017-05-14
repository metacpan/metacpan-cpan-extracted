#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;
BEGIN { unshift( @INC, './lib' ) }
use Bio::VertRes::Config::RegisterStudy;

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::CommandLine::StudyNameSearch');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

# Populate a few studies
Bio::VertRes::Config::RegisterStudy->new(database => 'pathogen_rnd_track', study_name => 'ABC study',config_base => $destination_directory)->register_study_name();
Bio::VertRes::Config::RegisterStudy->new(database => 'pathogen_rnd_track', study_name => 'EFG study',config_base => $destination_directory)->register_study_name();
Bio::VertRes::Config::RegisterStudy->new(database => 'pathogen_prok_track', study_name => 'CCC',config_base => $destination_directory)->register_study_name();
Bio::VertRes::Config::RegisterStudy->new(database => 'pathogen_euk_track', study_name => 'DDD',config_base => $destination_directory)->register_study_name();


ok(my $obj = Bio::VertRes::Config::CommandLine::StudyNameSearch->new(
  default_database_name => 'pathogen_rnd_track', 
  config_base => $destination_directory,
  study_name => 'Unseen study'
  ), 'Initialise object for unseen study');
is($obj->get_study_database_name_or_default_if_not_found, 'pathogen_rnd_track', 'unseen study returns default database');

ok($obj = Bio::VertRes::Config::CommandLine::StudyNameSearch->new(
  default_database_name => 'pathogen_rnd_track', 
  config_base => $destination_directory,
  study_name => 'ABC study'
  ), 'Initialise object for seen study in default database');
is($obj->get_study_database_name_or_default_if_not_found, 'pathogen_rnd_track', 'seen study in default database should return default');

ok($obj = Bio::VertRes::Config::CommandLine::StudyNameSearch->new(
  default_database_name => 'pathogen_prok_track', 
  config_base => $destination_directory,
  study_name => 'EFG study'
  ), 'Initialise object for seen study in different database');
is($obj->get_study_database_name_or_default_if_not_found, 'pathogen_rnd_track', 'find study in another database');


done_testing();

