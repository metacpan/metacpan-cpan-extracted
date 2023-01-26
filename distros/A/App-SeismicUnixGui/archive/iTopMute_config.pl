#!/usr/local/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iTop_Mute2_config.pl 
 AUTHOR: Juan Lorenzo
 DATE: July 27 2016 
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
      file is iTop_Mute3.config

  Package control:
     filename is file, without a suffix!
     In some cases, numbers must be
     separated by commasi-- needed by 
     Seismic Unix

=cut

=head2 Notes from bash

 
=cut 

use Moose;
use Config::Simple;
use control 0.0.3;
use System_Variables;
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

my $cfg             = new Config::Simple('iTop_Mute3.config');
my $DATA_SEISMIC_SU = System_Variables::DATA_SEISMIC_SU();
my $control         = control->new();

=head2 anonymous array reference $CFG

 contains all the configuration variables in
 perl script

     file_name  		= '30Hz_All_geom_geom';
     gather_header  	= 'fldr';
     offset_type  		= 'tracl';
     first_gather   	= 1;
     gather_inc    		= 1;
     last_gather    	= 100;
     freq    		    = '0,3,100,200';
     gather_type    	= 'fldr';
     min_amplitude    	= .0;
     max_amplitude    	= .75;

 DB

 print("offset_type -4$offset_type\n\n");
       
=cut 

my $file_name     = $cfg->param("file_name");
my $gather_header = $cfg->param("gather_header");
my $offset_type   = $cfg->param("offset_type");
my $first_gather  = $cfg->param("first_gather");
my $gather_inc    = $cfg->param("gather_inc");
my $last_gather   = $cfg->param("last_gather");
my $freq          = $cfg->param("freq");
my $gather_type   = $cfg->param("gather_type");
my $min_amplitude = $cfg->param("min_amplitude");
my $max_amplitude = $cfg->param("max_amplitude");

$file_name = $control->su_file_name( \$file_name );

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

our $Variable1 = $file_name;

our $CFG = {
    sumute => {
        1 => {
            gather_header => $gather_header,
            offset_type   => $offset_type,
            first_gather  => $first_gather,
            gather_inc    => $gather_inc,
            last_gather   => $last_gather,
            freq          => $freq,
            gather_type   => $gather_type,
            min_amplitude => $min_amplitude,
            max_amplitude => $max_amplitude
        }
    },
    sugain => {
        1 => { freq => $freq }

    },

    file_name => $file_name
};
