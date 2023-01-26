#! /usr/local/bin/perl

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PACKAGE NAME: Sudipfilt 
 AUTHOR: Juan Lorenzo
 DATE: July 1 2016 
 DESCRIPTION Upper-level variable
      definitions for Sudipfilt 
 Package name is the same as the file name

 Package control corrects some values read
 in by Config::Simple

=cut

=head2 Notes 

 
=cut 

=head2 EXPORT GLOBAL VARIABLES
   
  to Sudipfilt 
  print("1.file    $file  \n");


=head2 Values exported

=cut 

use Moose;
use Config::Simple;
use control 0.0.3;
use System_Variables;
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
use App::SeismicUnixGui::misc::L_SU_global_constants;
my $get                         = L_SU_global_constants->new();
my $alias_superflow_config_name = $get->alias_superflow_config_names_aref();

#WARNING---- watch out for missing underscore!!
# print("1. Sudipfilt2_config,fk alias_superflow_config_name : $$alias_superflow_config_name[0]\n");

my ( $file_name, $cfg, $control, $DATA_SEISMIC_SU );

#$cfg 					= new Config::Simple($$alias_superflow_config_name[0].'.config');Sudipfilt.config

$cfg = new Config::Simple('Sudipfilt.config');

#$cfg 					= new Config::Simple('iSpectralAnalysis.config');
$file_name = $cfg->param("file_name");

# print("1. Sudipfilter2_config.pl,file_name: $file_name\n");
$control         = control->new();
$DATA_SEISMIC_SU = System_Variables::DATA_SEISMIC_SU();

=head2 anonymous array reference is CFG

 contains all the configuration variables in
 perl script

=cut

=head2 LOCAL VARIABLES 


  include 2 if statements
  for backwards comaptibility of
  self-standing program (i.e.
  not run from the GUI)

 print("2. file_name  $file_name \n");

=cut

$file_name = $cfg->param("file_name");

=head2 TOP LEFT 

  includes sugain variables
 print("sudipfilter dx is $sudipfilter_1_dx \n\n");

=cut

my $sudipfilter_1_dt     = $cfg->param("sudipfilter_1_dt");
my $sudipfilter_1_dx     = $cfg->param("sudipfilter_1_dx");
my $sudipfilter_1_slopes = $cfg->param("sudipfilter_1_slopes");
my $sudipfilter_1_bias   = $cfg->param("sudipfilter_1_bias");
my $sudipfilter_1_amps   = $cfg->param("sudipfilter_1_amps");

my $sudipfilter_2_dt     = $cfg->param("sudipfilter_2_dt");
my $sudipfilter_2_dx     = $cfg->param("sudipfilter_2_dx");
my $sudipfilter_2_slopes = $cfg->param("sudipfilter_2_slopes");
my $sudipfilter_2_bias   = $cfg->param("sudipfilter_2_bias");
my $sudipfilter_2_amps   = $cfg->param("sudipfilter_2_amps");
my $sufilter_1_freq      = $cfg->param("sufilter_1_freq");
my $sufilter_1_amplitude = $cfg->param("sufilter_1_amplitude");

my $suspecfk_1_dt = $cfg->param("suspecfk_1_dt");
my $suspecfk_1_dx = $cfg->param("suspecfk_1_dx");

my $suwind_1_tmin = $cfg->param("suwind_1_tmin");
my $suwind_1_tmax = $cfg->param("suwind_1_tmax");

my $suwind_2_key = $cfg->param("suwind_2_key");
my $suwind_2_min = $cfg->param("suwind_2_min");
my $suwind_2_max = $cfg->param("suwind_2_max");

my $TOP_LEFT_sugain_pbal_switch = $cfg->param("TOP_LEFT_sugain_pbal_switch");

# print ("Sudipfilt_config.pl, pbal is $TOP_LEFT_sugain_pbal_switch\n\n");
# print ("Sudipfilt_config.pl,suwind_1_tmin  is $suwind_1_tmin\n\n");
my $TOP_LEFT_sugain_agc_switch = $cfg->param("TOP_LEFT_sugain_agc_switch");
my $TOP_LEFT_sugain_agc_width  = $cfg->param("TOP_LEFT_sugain_agc_width");
my $BOTTOM_RIGHT_suximage_absclip =
  $cfg->param("BOTTOM_RIGHT_suximage_absclip");

=pod Package control 

 filename is file, without a suffix!
 In some cases, some numbers must be
 separated by commas

=cut

# print ("Sudipfilt_config.pl,file_name was $file_name\n\n");
$file_name = $control->su_file_name($file_name);

# print ("3. Sudipfilt2_config.pl,file_name  is $file_name\n\n");
#$CFG[7] 			= $control->commas(\$CFG[7]);
#$CFG[11] 			= $control->commas(\$CFG[11]);
#$CFG[17] 			= $control->commas(\$CFG[17]);
#$CFG[21] 			= $control->commas(\$CFG[21]);
#$CFG[23]      		= $control->commas(\$CFG[23]);
#$CFG[25]      		= $control->commas(\$CFG[25]);

=head2 Example LOCAL VARIABLES FOR THIS PROJECT


=cut

our $CFG = {
    TOP_LEFT => {
        sugain => {
            agc_switch  => $TOP_LEFT_sugain_agc_switch,
            pbal_switch => $TOP_LEFT_sugain_pbal_switch,
            agc_width   => $TOP_LEFT_sugain_agc_width
        }
    },
    BOTTOM_RIGHT =>
      { suximage => { absclip => $BOTTOM_RIGHT_suximage_absclip } },
    sudipfilter => {
        1 => {
            dt     => $sudipfilter_1_dt,
            dx     => $sudipfilter_1_dx,
            slopes => $sudipfilter_1_slopes,
            bias   => $sudipfilter_1_bias,
            amps   => $sudipfilter_1_amps
        },
        2 => {
            dt     => $sudipfilter_2_dt,
            dx     => $sudipfilter_2_dx,
            slopes => $sudipfilter_2_slopes,
            bias   => $sudipfilter_2_bias,
            amps   => $sudipfilter_2_amps
        }
    },
    suwind => {
        1 => {
            tmin => $suwind_1_tmin,
            tmax => $suwind_1_tmax
        },
        2 => {
            key => $suwind_2_key,
            min => $suwind_2_min,
            max => $suwind_2_max
        }
    },
    sufilter => {
        1 => {
            freq      => $sufilter_1_freq,
            amplitude => $sufilter_1_amplitude
        }
    },
    suspecfk => {
        1 => {
            dt => $suspecfk_1_dt,
            dx => $suspecfk_1_dx
        }
    },

    file_name         => $file_name,
    inbound_directory => $DATA_SEISMIC_SU,

};
