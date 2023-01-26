#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: Sseg2su_config.pl 
 AUTHOR: Juan Lorenzo
 DATE: July 29 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR 
      Upper-level variable
      definitions in iTop_Mute3 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
 Version 1  Based on linux command "cat"
 Version 2 based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)
     
   
 Needs: Simple (ASCII) local configuration 
      file is Sseg2su.config

=cut

=head2 Notes from bash

 
=cut 

use Moose;
use Config::Simple;
my $cfg = new Config::Simple('Sseg2su.config');

=head2 anonymous array reference $CFG

 contains all the configuration variables in
 perl script
  $number_of_files	= 38;
  $first_file_number  	= 1000;
 print("number of files is $number_of_files\n");
  
=cut 

my $number_of_files   = $cfg->param("number_of_files");
my $first_file_number = $cfg->param("first_file_number");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

our $CFG = {
    seg2su => {
        1 => {
            number_of_files   => $number_of_files,
            first_file_number => $first_file_number
        }
    }
};
