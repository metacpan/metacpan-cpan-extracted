#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: SuLoadHeaders_config.pl 
 AUTHOR: Juan Lorenzo
 DATE: November 29 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR 
      Upper-level variable
      definitions in SuLoadHeaders 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
 Version 1 based on SuLoadHeaders Nov 7 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)
     
   
 Needs: Simple (ASCII) local configuration 
      file is SuLoadHeaders.config

=cut

=head2 Notes from bash

 
=cut 

use Moose;
use Config::Simple;
my $cfg = new Config::Simple('SuLoadHeaders.config');

use lib '/usr/local/pl/libAll';
use App::SeismicUnixGui::configs::big_streams::Project_config;
my $Project = Project_config->new();
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
my $DATA_SEISMIC_SU = $Project->DATA_SEISMIC_SU();

=head2 anonymous array reference $CFG

 contains all the configuration variables in
 perl script

 file_in
 su_fil_in
 headers_to_replace

=cut 

my $ascii_file_in          = $cfg->param("ascii_file_in");
my $sufile_in              = $cfg->param("sufile_in");
my $number_of_data_columns = $cfg->param("number_of_data_columns");
my $replace_header_words   = $cfg->param("replace_header_words");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

our $CFG = {
    a2b => {
        1 => {
            ascii_file_in          => $ascii_file_in,
            number_of_data_columns => $number_of_data_columns,
            replace_header_words   => $replace_header_words
        }
    },
    sushw => {
        1 => { sufile_in => $sufile_in }

      }

};

#print("ascii_file_in: $ascii_file_in\n\n");
#print("ascii_file_in: $CFG->{a2b}{1}{ascii_file_in}\n\n");
#print("sufile_in: $CFG->{sushw}{1}{sufile_in}\n\n");
