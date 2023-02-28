package App::SeismicUnixGui::big_streams::Synseis;

=pod

 This script creates the synthetic seismogram in an ascii file
 usage synseis.sh Site number
#
 ***** SETTING SITE WATER DEPTHS******* NOTE 1 ***************************
#water_depth=1123. # water depth at site 904 delay = 370 ms
water_depth=1; #1123.  #wqter depth incurrent zrhov model
#

 ********SETTING PATHS ******* NOTE 2 ***************************
 
 zrhov is the only file that Synseis reads on input 
 zrhov contains depth versus density and velosity in three columns
 values versus depth DO NOT HAVE  to be at regular intervals but
 commonly are.

----
#
# Setting paths
path=./
zrhov_filename=./zrhov.904 # input filename 
zrhov_filename=./zrhov # input filename 
output_source=./source.out
reflec_coef_time=./rc_t
reflec_coef_depth=./rc_z
reg_density_file=./zrho.reg
reg_velocity_file=./zv.reg
#
# *********** OPTIONS ************* NOTE 3 *************************
# The program has various options, e.g.
#	1) variable sampling rate
#	2) synthetic Ricker source
#	3A) real MCS source ready to roll!
#	3B) sources that need to be resampled at a finer sampling rate
#
# For each option several parameters must be turned off and others turned
# on.  At present this program works using an MCS source wavelet with
# a 2ms sampling interval taken from EW Line 1027 at CDP 1377 1.106-1.166ms
# (1027.source) found in /projects/projects5/Geol4068/Synseis_class/sources
# Be careful with the units as SUnix uses microseconds and you may
# like to think in terms of milliseconds or just seconds!
#
# ---------------- uncomment before next line if using resampled source
#  OTHER OPTIONAL SOURCES with DIFFERENT (!!!) sampling intervals
#
# 1ms SI; first source used, fromCDP 1400, line2, SCS
# input_source_filename=$path/sources/CDP1400.source
# time_sampling_interval=0.001 # in seconds
#
# 1ms SI;  CDP 1210 1086-1173ms 
# input_source_filename=$path/sources/line2.source 
# time_sampling_interval=0.001 # in seconds
#
# ******************************************************
# WE USE THE FOLLOWING SOURCE IN THIS EXAMPLE
# *******************************************************
# 2ms SI CDP 1377 1.106-1.166ms
input_source_filename=./1027.source 
time_sampling_interval=0.002 # in seconds
#
depth_sampling_interval=0.4   # in meters
#
# Remember that you can't use an MCS source AND a Ricker wavelet
# and a seismic source wavelet you would like to change within Synseis
# SIMLUTANEOUSLY.  Therefore, if you want to use on eof these options
# other options MUST be set off.  I advise you to not use the following
# options for the time being without help.

# If you want to use the following options
# ----------------- uncomment before next line for source for sampling
#  source_resampling_interval=0.004
##  tmin_resampled_source=0.004 
#  xstart4resampling_source=0.0
# -X0$xstart4resampling_source \
#-S$input_source_filename
#
# --------------- uncomment below this line if using Ricker --------
# Ricker_endtime=0.15    # s
# Ricker_file=$path2/Geol4068/users/$1/modeling/output/ricker.out
# Ricker_frequency=40.   # Hz
# -AF$Ricker_frequency \
# -AE$Ricker_endtime \
# -Ao$Ricker_file 
# -----------------------------------------------------------------  
# ************* Running the program *********** NOTE   ***************
# -V allows output of all values during run time : not recommended
# unless you desire to inspect the gizzards of the beast
#
# -X0$xstart4resampling_source \
Synseis \
-S$input_source_filename \
-CZ$reflec_coef_depth \
-CT$reflec_coef_time \
-I$time_sampling_interval \
-IZ$depth_sampling_interval \
-LD$reg_density_file \
-LV$reg_velocity_file \
-Ro$output_source \
-Z$zrhov_filename \
-W$water_depth
# -V

=head4 Examples


=head3 SEISMIC UNIX NOTES


=head2 CHANGES and their DATES
   

=cut 

use Moose;
our $VERSION = '0.0.1';

my $Synseis = {
    _input_source_filename   => '',
    _reflec_coef_depth       => '',
    _reflec_coef_time        => '',
    _time_sampling_interval  => '',
    _depth_sampling_interval => '',
    _reg_density_file        => '',
    _reg_velocity_file       => '',
    _output_source           => '',
    _zrhov_filename          => '',
    _water_depth             => '',
    _Ricker_frequency        => '',
    _Ricker_endtime          => '',
    _Ricker_file             => '',
    _verbose                 => '',
    _Step                    => '',
    _note                    => ''
};

# define a value
my $on = 1;

=head2 sub clear

     clear global variables from the memory

=cut

sub clear {
    $Synseis->{_input_source_filename}   = '';
    $Synseis->{_reflec_coef_depth}       = '';
    $Synseis->{_reflec_coef_time}        = '';
    $Synseis->{_time_sampling_interval}  = '';
    $Synseis->{_depth_sampling_interval} = '';
    $Synseis->{_reg_density_file}        = '';
    $Synseis->{_reg_velocity_file}       = '';
    $Synseis->{_output_source}           = '';
    $Synseis->{_zrhov_filename}          = '';
    $Synseis->{_water_depth}             = '';
    $Synseis->{_verbose}                 = '';
    $Synseis->{_Step}                    = '';
    $Synseis->{_note}                    = '';
}

=head2 sub input_source_filename


=cut

sub input_source_filename {
    my ( $variable, $input_source_filename ) = @_;
    if ($input_source_filename) {
        $Synseis->{_input_source_filename} = $input_source_filename;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -S' . $Synseis->{_input_source_filename};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -S' . $Synseis->{_input_source_filename};
    }
}

=head2 sub reflec_coef_depth 


=cut

sub reflec_coef_depth {
    my ( $variable, $reflec_coef_depth ) = @_;
    if ($reflec_coef_depth) {
        $Synseis->{_reflec_coef_depth} = $reflec_coef_depth;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -CZ' . $Synseis->{_reflec_coef_depth};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -CZ' . $Synseis->{_reflec_coef_depth};
    }
}

=head2 sub reflec_coef_time 

=cut

sub reflec_coef_time {
    my ( $variable, $reflec_coef_time ) = @_;
    if ($reflec_coef_time) {
        $Synseis->{_reflec_coef_time} = $reflec_coef_time;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -CT' . $Synseis->{_reflec_coef_time};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -CT' . $Synseis->{_reflec_coef_time};
    }
}

=head2 sub time_sampling_interval 


=cut

sub time_sampling_interval {
    my ( $variable, $time_sampling_interval ) = @_;
    if ($time_sampling_interval) {
        $Synseis->{_time_sampling_interval} = $time_sampling_interval;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -I' . $Synseis->{_time_sampling_interval};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -I' . $Synseis->{_time_sampling_interval};
    }
}

=head2 sub depth_sampling_interval 


=cut

sub depth_sampling_interval {
    my ( $variable, $depth_sampling_interval ) = @_;
    if ($depth_sampling_interval) {
        $Synseis->{_depth_sampling_interval} = $depth_sampling_interval;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -IZ' . $Synseis->{_depth_sampling_interval};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -IZ' . $Synseis->{_depth_sampling_interval};
    }
}

=head2 sub reg_density_file 


=cut

sub reg_density_file {
    my ( $variable, $reg_density_file ) = @_;
    if ($reg_density_file) {
        $Synseis->{_reg_density_file} = $reg_density_file;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -LD' . $Synseis->{_reg_density_file};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -LD' . $Synseis->{_reg_density_file};
    }
}

=head2 sub reg_velocity_file 


=cut

sub reg_velocity_file {
    my ( $variable, $reg_velocity_file ) = @_;
    if ($reg_velocity_file) {
        $Synseis->{_reg_velocity_file} = $reg_velocity_file;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -LV' . $Synseis->{_reg_velocity_file};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -LV' . $Synseis->{_reg_velocity_file};
    }
}

=head2 sub output_source 


=cut

sub output_source {
    my ( $variable, $output_source ) = @_;
    if ($output_source) {
        $Synseis->{_output_source} = $output_source;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -Ro' . $Synseis->{_output_source};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -Ro' . $Synseis->{_output_source};
    }
}

=head2 sub zrhov_filename 


=cut

sub zrhov_filename {
    my ( $variable, $zrhov_filename ) = @_;
    if ($zrhov_filename) {
        $Synseis->{_zrhov_filename} = $zrhov_filename;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -Z' . $Synseis->{_zrhov_filename};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -Z' . $Synseis->{_zrhov_filename};
    }
}

=head2 sub water_depth 


=cut

sub water_depth {
    my ( $variable, $water_depth ) = @_;
    if ($water_depth) {
        $Synseis->{_water_depth} = $water_depth;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -W' . $Synseis->{_water_depth};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -W' . $Synseis->{_water_depth};
    }
}

=head2 sub Ricker_file 


=cut

sub Ricker_file {
    my ( $variable, $Ricker_file ) = @_;
    if ($Ricker_file) {
        $Synseis->{_Ricker_file} = $Ricker_file;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -Ao' . $Synseis->{_Ricker_file};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -Ao' . $Synseis->{_Ricker_file};
    }
}

=head2 sub Ricker_endtime 


=cut

sub Ricker_endtime {
    my ( $variable, $Ricker_endtime ) = @_;
    if ($Ricker_endtime) {
        $Synseis->{_Ricker_endtime} = $Ricker_endtime;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -AE' . $Synseis->{_Ricker_endtime};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -AE' . $Synseis->{_Ricker_endtime};
    }
}

=head2 sub Ricker_frequency 


=cut

sub Ricker_frequency {
    my ( $variable, $Ricker_frequency ) = @_;
    if ($Ricker_frequency) {
        $Synseis->{_Ricker_frequency} = $Ricker_frequency;
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -AF' . $Synseis->{_Ricker_frequency};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -AF' . $Synseis->{_Ricker_frequency};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ($verbose) {
        $Synseis->{_verbose} = '';
        $Synseis->{_Step} =
          $Synseis->{_Step} . ' -V' . $Synseis->{_verbose};
        $Synseis->{_note} =
          $Synseis->{_note} . ' -V' . $Synseis->{_verbose};
    }
}

=head2 sub note

=cut

sub note {
    my ( $variable, $note ) = @_;
    $Synseis->{_note} = $Synseis->{_note};
    return $Synseis->{_note};
}

=head2 sub Step 

=cut

sub Step {
    my ( $variable, $Step ) = @_;
    $Synseis->{_Step} = 'synseis ' . $Synseis->{_Step};
    $Synseis->{_note} = 'synseis ' . $Synseis->{_note};
    return $Synseis->{_Step};
}

1;
