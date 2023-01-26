#!/usr/local/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iSpectralAnalysis_config.pl 
 AUTHOR: Juan Lorenzo
 DATE: August 1 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

=head2 PURPOSE 

      Upper-level variable
      definitions in iSpectralAnalysis 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
     
   
 Needs: Simple (ASCII) local configuration 
      file is iSpectralAnalysis.config

=cut

=head2 Notes 

 
=cut 

use Moose;
use Config::Simple;
use System_Variables;
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

my $cfg = new Config::Simple('iSpectralAnalysis.config');

#print("file name is -2\n\n");

=head2 anonymous array reference $CFG

 contains all the configuration variables in
 text script

  file_name     		= '1072_clean';

  sufilter_1_freq	  	= '0,1,20,40'

  sugain_1_agc_gain_width 	= 2.6;

  suxwigb_1_max_amplitude 	= 100000;

  suxwigb_1_min_amplitude_phase	= 100;

  suxwigb_1_max_amplitude_freq	= 100;
       
=cut 

my $file_name = $cfg->param("file_name");

# print("1. iSpectralAnalysis_config.pl,file_name: $file_name\n");
my $sugain_1_agc_gain_width       = $cfg->param("sugain_1_agc_gain_width");
my $sufilter_1_freq               = $cfg->param("sufilter_1_freq");
my $suxwigb_1_max_amplitude_freq  = $cfg->param("suxwigb_1_max_amplitude");
my $suxwigb_1_headerWord          = $cfg->param("suxwigb_1_headerWord");
my $suxwigb_2_min_amplitude_phase = $cfg->param(
    "suxwigb_2_min_amplitude_phase
"
);
my $suxwigb_3_max_amplitude_freq = $cfg->param("suxwigb_3_max_amplitude_freq");

#print("file name is -4$file_name\n\n");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

our $Variable1 = $file_name;

our $CFG = {
    sufilter => { 1 => { freq           => $sufilter_1_freq } },
    sugain   => { 1 => { agc_gain_width => $sugain_1_agc_gain_width } },
    suxwigb  => {
        1 => {
            max_amplitude_freq => $suxwigb_1_max_amplitude_freq,
            headerWord         => $suxwigb_1_headerWord
        },
        2 => { min_amplitude_phase => $suxwigb_2_min_amplitude_phase },
        3 => { max_amplitude_freq  => $suxwigb_3_max_amplitude_freq }
    },
    file_name => $file_name
};
