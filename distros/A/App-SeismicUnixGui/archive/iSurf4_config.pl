#!/usr/bin/perl  -w

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iSurf_config.pl 
 AUTHOR: Juan Lorenzo
 DATE:  January 24 2017 
 DESCRIPTION  Incorporate upper-level variable
      definitions for iSurf4 
      
 Package name is the same as the file name

=cut

=head2 Notes 

=cut 

=head2 Requires 

 iSurf4.config in the local user's directory

=cut 

=head2 EXPORT 
   
 GLOBAL VARIABLES to iSurf4
 read program pvariables from iSurf4.config 

=cut 

use Moose;
use Config::Simple;

use lib '/usr/local/pl/libAll';
my $cfg = new Config::Simple('iSurf4.config');
use App::SeismicUnixGui::configs::big_streams::Project_config;
my $Project = Project_config->new();
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=head2 anonymous array reference is CFG

 contains all the configuration variables in
 perl script

=cut

=head2 LOCAL VARIABLES 

 taken from the local user file called:

  iSurf4.config
 print("data_name is $data_name\n\n");
 print(" transform_type is $sutaup_1_transform\n\n");
 print(" current_trace_separation is $suinterp_1_current_trace_separation\n\n");

=cut

my $data_name = $cfg->param("data_name");

=head2 SUTAUP TRANSFORMATION 

  includes sugain variables

=cut

my $sutaup_1_pmin        = $cfg->param("sutaup_1_pmin");
my $sutaup_1_pmax        = $cfg->param("sutaup_1_pmax");
my $sutaup_1_min_freq_Hz = $cfg->param("sutaup_1_min_freq_Hz");
my $sutaup_1_transform   = $cfg->param("sutaup_1_transform_type");

if ( $sutaup_1_transform eq 'inverse_via_tx' ) { $sutaup_1_transform = 3 }
if ( $sutaup_1_transform eq 'inverse_via_fk' ) { $sutaup_1_transform = 4 }
if ( $sutaup_1_transform eq 'forward_via_tx' ) { $sutaup_1_transform = 1 }
if ( $sutaup_1_transform eq 'forward_via_fk' ) { $sutaup_1_transform = 2 }

=head2 MUTING SUTAUP DATA 

  includes sumute variables

=cut

my $sumute_1_offset_type   = $cfg->param("sumute_1_offset_type");
my $sumute_1_gather_header = $cfg->param("sumute_1_gather_header");

=head2 SUTAUP INVERSE TRANSFORMATION 

  includes sutaup variables
  convert the transformation option from
  words into numbers

=cut

my $sutaup_2_pmin        = $cfg->param("sutaup_2_pmin");
my $sutaup_2_pmax        = $cfg->param("sutaup_2_pmax");
my $sutaup_2_min_freq_Hz = $cfg->param("sutaup_2_min_freq_Hz");
my $sutaup_2_transform   = $cfg->param("sutaup_2_transform_type");

if ( $sutaup_2_transform eq 'inverse_via_tx' ) { $sutaup_2_transform = 3 }
if ( $sutaup_2_transform eq 'inverse_via_fk' ) { $sutaup_2_transform = 4 }
if ( $sutaup_2_transform eq 'forward_via_tx' ) { $sutaup_2_transform = 1 }
if ( $sutaup_2_transform eq 'forward_via_fk' ) { $sutaup_2_transform = 2 }

=head2 TRACE INTERPOLATION 

  includes suinterp variables

=cut

my $suinterp_1_number_of_traces_to_smooth =
  $cfg->param("suinterp_1_number_of_traces_to_smooth");
my $suinterp_1_number_of_samples_to_smooth =
  $cfg->param("suinterp_1_number_of_samples_to_smooth");
my $suinterp_1_min_freq_Hz = $cfg->param("suinterp_1_min_freq_Hz");
my $suinterp_1_number_new_traces2interpolate =
  $cfg->param("suinterp_1_number_new_traces2interpolate");
my $suinterp_1_current_trace_separation =
  $cfg->param("suinterp_1_current_trace_separation");
my $suinterp_1_traces_per_gather = $cfg->param("suinterp_1_traces_per_gather");

=head2  FREQUENCY FILTERING 

  set sufilter parameters 

=cut

my $sufilter_1_freq      = $cfg->param("sufilter_1_freq");
my $sufilter_1_amplitude = $cfg->param("sufilter_1_amplitude");
my $sumute_1_transform   = $cfg->param("transform_type");

=head2   AMPLITUDE MODIFICAION 

  set sugain parameters 

=cut

my $sugain_1_agc_switch = $cfg->param("sugain_1_agc_switch");
my $sugain_1_wagc       = $cfg->param("sugain_1_wagc");

if ( $sugain_1_agc_switch eq 'on' )  { $sugain_1_agc_switch = 1 }
if ( $sugain_1_agc_switch eq 'off' ) { $sugain_1_agc_switch = 0 }

=head2  SELECTION DATA SUBSETS 

  set suwind parameters 

=cut

my $suwind_1_key = $cfg->param("suwind_1_key");
my $suwind_1_min = $cfg->param("suwind_1_min");
my $suwind_1_max = $cfg->param("suwind_1_max");
my $suwind_1_inc = $cfg->param("suwind_1_inc");

my $suwind_2_key = $cfg->param("suwind_2_key");
my $suwind_2_min = $cfg->param("suwind_2_min");
my $suwind_2_max = $cfg->param("suwind_2_max");

my $suwind_3_tmin = $cfg->param("suwind_3_tmin");
my $suwind_3_tmax = $cfg->param("suwind_3_tmax");

=head2 TOP LEFT IMAGE (F-P) 

  set plotting parmaters 

=cut

my $suximage_2_hiclip = $cfg->param("suximage_2_hiclip");
my $suximage_2_loclip = $cfg->param("suximage_2_loclip");

=head2  TOP MIDDLE WIGGLE PLOT (TAU-P)

  set plotting parmaters 

=cut

my $suxwigb_2_absclip = $cfg->param("suxwigb_2_absclip");

=head2   TOP RIGHT WIGGLE PLOT (X-T original)


  set plotting parmaters 

=cut

my $suxwigb_1_absclip = $cfg->param("suxwigb_1_absclip");

=head2   TOP RIGHT IMAGE PLOT (X-T original)


  set plotting parmaters 

=cut

my $suximage_1_absclip = $cfg->param("suximage_1_absclip");

=head2  BOTTOM RIGHT  PLOT (X-T inverted) 

  set plotting parmaters 

=cut

my $suxwigb_3_absclip = $cfg->param("suxwigb_3_absclip");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

 filename is file,without a suffix!

=cut

our $CFG = {
    TOP_LEFT_IMAGE => {
        suximage => {
            hiclip => $suximage_2_hiclip,
            loclip => $suximage_2_loclip
        }
    },
    TOP_MIDDLE_WIGGLE_PLOT => { suxwigb => { absclip => $suxwigb_2_absclip } },
    TOP_RIGHT_WIGGLE_PLOT  => { suxwigb => { absclip => $suxwigb_1_absclip } },

    TOP_RIGHT_IMAGE => { suximage => { absclip => $suximage_1_absclip } },
    BOTTOM_RIGHT_WIGGLE_PLOT =>
      { suxwigb => { absclip => $suxwigb_3_absclip } },

    sutaup => {
        1 => {
            pmin           => $sutaup_1_pmin,
            pmax           => $sutaup_1_pmax,
            min_freq_Hz    => $sutaup_1_min_freq_Hz,
            transform_type => $sutaup_1_transform
        },
        2 => {
            pmin           => $sutaup_2_pmin,
            pmax           => $sutaup_2_pmax,
            min_freq_Hz    => $sutaup_2_min_freq_Hz,
            transform_type => $sutaup_2_transform
        }
    },
    sumute => {
        1 => {
            offset_type   => $sumute_1_offset_type,
            gather_header => $sumute_1_gather_header
        }
    },
    suinterp => {
        1 => {
            number_of_traces_to_smooth =>
              $suinterp_1_number_of_traces_to_smooth,
            number_of_samples_to_smooth =>
              $suinterp_1_number_of_samples_to_smooth,
            min_freq_Hz => $suinterp_1_min_freq_Hz,
            number_new_traces2interpolate =>
              $suinterp_1_number_new_traces2interpolate,
            current_trace_separation => $suinterp_1_current_trace_separation,
            traces_per_gather        => $suinterp_1_traces_per_gather
        }
    },
    sufilter => {
        1 => {
            freq      => $sufilter_1_freq,
            amplitude => $sufilter_1_amplitude
        }
    },
    sugain => {
        1 => {
            agc_switch => $sugain_1_agc_switch,
            wagc       => $sugain_1_wagc
        }
    },
    suwind => {
        1 => {
            key => $suwind_1_key,
            min => $suwind_1_min,
            max => $suwind_1_max,
            inc => $suwind_1_inc
        },
        2 => {
            key => $suwind_2_key,
            min => $suwind_2_min,
            max => $suwind_2_max
        },
        3 => {
            tmin => $suwind_3_tmin,
            tmax => $suwind_3_tmax
        }
    },
    data_name => $data_name
};
