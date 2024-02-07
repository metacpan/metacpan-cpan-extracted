
=head2 SYNOPSIS

 FILE/PERL PROGRAM NAME: Synseis.pl

 AUTHOR:  Juan M. Lorenzo (sm), gllore@lsu.edu

 DATE:10/02/2017 05:33:04 PM

 DESCRIPTION:

 Version: 2.0

=head2 USE


=head3 NOTES for old V 1.0
 This script creates the synthetic seismogram in an ascii file
 usage Synseis.sh Site number

 ***** SETTING SITE WATER DEPTHS******* NOTE 1 ***************************
water_depth=1123. # water depth at site 904 delay = 370 ms
water_depth=1; #1123.  #wqter depth incurrent zrhov model


 ********SETTING PATHS ******* NOTE 2 ***************************
 
 zrhov is the only file that Synseis reads on input 
 zrhov contains depth versus density and velosity in three columns
 values versus depth DO NOT HAVE  to be at regular intervals but
 commonly are.

----

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
 The program has various options, e.g.
	1) variable sampling rate
	2) synthetic Ricker source
	3A) real MCS source ready to roll!
	3B) sources that need to be resampled at a finer sampling rate

 For each option several parameters must be turned off and others turned
 on.  At present this program works using an MCS source wavelet with
 a 2ms sampling interval taken from EW Line 1027 at CDP 1377 1.106-1.166ms
 (1027.source) found in /projects/projects5/Geol4068/Synseis_class/sources
 Be careful with the units as SUnix uses microseconds and you may
 like to think in terms of milliseconds or just seconds!

 ---------------- uncomment before next line if using resampled source
  OTHER OPTIONAL SOURCES with DIFFERENT (!!!) sampling intervals

 1ms SI; first source used, fromCDP 1400, line2, SCS
 input_source_filename=$path/sources/CDP1400.source
 time_sampling_interval=0.001  in seconds

 1ms SI;  CDP 1210 1086-1173ms 
 input_source_filename=$path/sources/line2.source 
 time_sampling_interval=0.001  in seconds

 ******************************************************
 WE USE THE FOLLOWING SOURCE IN THIS EXAMPLE
 *******************************************************
 2ms SI CDP 1377 1.106-1.166ms
 input_source_filename=./1027.source 
 time_sampling_interval=0.002  in seconds

depth_sampling_interval=0.4    in meters

 Remember that you can't use an MCS source AND a Ricker wavelet
 and a seismic source wavelet you would like to change within Synseis
 SIMLUTANEOUSLY.  Therefore, if you want to use on eof these options
 other options MUST be set off.  I advise you to not use the following
 options for the time being without help.

 If you want to use the following options
 ----------------- uncomment before next line for source for sampling
  source_resampling_interval=0.004
##  tmin_resampled_source=0.004 
  xstart4resampling_source=0.0
 -X0$xstart4resampling_source \
-S$input_source_filename

 --------------- uncomment below this line if using Ricker --------
 Ricker_endtime=0.15     s
 Ricker_file=$path2/Geol4068/users/$1/modeling/output/ricker.out
 Ricker_frequency=40.    Hz
 -AF$Ricker_frequency \
 -AE$Ricker_endtime \
 -Ao$Ricker_file 
 -----------------------------------------------------------------  
 ************* Running the program *********** NOTE   ***************
 -V allows output of all values during run time : not recommended
 unless you desire to inspect the gizzards of the beast

 -X0$xstart4resampling_source \
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
 -V
 
=head2 NOTEs V 2.0

=head4 Examples


=head3 SEISMIC UNIX NOTES


=head2 CHANGES and their DATES

   upgrade ss plot to use suxwigb

=cut 

use Moose;
our $VERSION = '0.0.2';

use aliased 'App::SeismicUnixGui::sunix::par::a2b';
use aliased 'App::SeismicUnixGui::misc::a2su';
use aliased 'App::SeismicUnixGui::sunix::data::data_in';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::big_streams::Synseis';
use aliased 'App::SeismicUnixGui::configs::big_streams::Synseis_config';
use App::SeismicUnixGui::misc::SeismicUnix
     qw($in $out $on $go $to $suffix_ascii $suffix_bin $off $suffix_su);
use aliased 'App::SeismicUnixGui::sunix::plot::xgraph';
use aliased 'App::SeismicUnixGui::sunix::header::suaddhead';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 Instantiate classes 

       Create a new version of the package
       Personalize to give it a new name if you wish

=cut

my $Project         = Project_config->new();
my $manage_files_by2 = manage_files_by2->new();
my $log            = message->new();
my $a2b            = a2b->new();
my $a2su           = a2su->new();
my $run            = flow->new();
my $suxwigb        = suxwigb->new();
my $Synseis        = Synseis->new();
my $Synseis_config = Synseis_config->new();
my $xgraph         = xgraph->new();
my $data_in	       = data_in->new();


my $DATA_SEISMIC_BIN            = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_SEGD           = $Project->DATA_SEISMIC_SEGD();
my $DATA_SEISMIC_SEGY           = $Project->DATA_SEISMIC_SEGY();
my $DATA_SEISMIC_SU             = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_TXT            = $Project->DATA_SEISMIC_TXT();
my ($PL_SEISMIC)                = $Project->PL_SEISMIC();
my ($DATA_SEISMIC_WELL_SYNSEIS) = $Project->DATA_SEISMIC_WELL_SYNSEIS();
my ($DATA_RESISTIVITY_WELL_TXT) =
     $Project->DATA_RESISTIVITY_WELL_TXT();     # from False River

=head2 Declare

  local variables 

=cut

my ( @Synseis, @SynseisNote, @flow );
my ( @items, @plot, @a2b, @xgraph );
my ( @a2b_outbound, @a2b_inbound );
my @xgraph_inbound;
my $xgraph_file_name;
my ( @geometry, @a2b_file_name );
my ( $wbox, $hbox, $xbox, $ybox );
my (@data_in);
my (@suxwigb);

=head2 default values for
geomtery of boxes
 
=cut

$wbox = 230;
$hbox = 600;
$ybox = 500;

=head2 Get configuration information
input hash and an array reference

=cut

my ( $CFG_h, $CFG_aref ) = $Synseis_config->get_values();


=head2 set the different parameters
includes sugain variables

=cut

my $base_file_name           = $CFG_h->{Synseis}{1}{base_file_name};
my $time_sampling_interval_s = $CFG_h->{Synseis}{1}{time_sampling_interval_s};

my $depth_sampling_interval_m =
     $CFG_h->{Synseis}{1}{depth_sampling_interval_m};
my $Ricker_endtime    = $CFG_h->{Synseis}{1}{Ricker_endtime};
my $Ricker_frequency  = $CFG_h->{Synseis}{1}{Ricker_frequency};
my $plot_density_min  = $CFG_h->{Synseis}{1}{plot_density_min};
my $plot_density_max  = $CFG_h->{Synseis}{1}{plot_density_max};
my $plot_depth_min_m  = $CFG_h->{Synseis}{1}{plot_depth_min_m};
my $plot_depth_max_m  = $CFG_h->{Synseis}{1}{plot_depth_max_m};
my $plot_time_min_s   = $CFG_h->{Synseis}{1}{plot_time_min_s};
my $plot_time_max_s   = $CFG_h->{Synseis}{1}{plot_time_max_s};
my $plot_velocity_min = $CFG_h->{Synseis}{1}{plot_velocity_min};
my $plot_velocity_max = $CFG_h->{Synseis}{1}{plot_velocity_max};
my $plot_reflection_coefficient_min =
     $CFG_h->{Synseis}{1}{plot_reflection_coefficient_min};
my $plot_reflection_coefficient_max =
     $CFG_h->{Synseis}{1}{plot_reflection_coefficient_max};
my $water_depth_m         = $CFG_h->{Synseis}{1}{water_depth_m};
my $plot_ss_amplitude_min = $CFG_h->{Synseis}{1}{plot_ss_amplitude_min};
my $plot_ss_amplitude_max = $CFG_h->{Synseis}{1}{plot_ss_amplitude_max};

my $output_synthetic_seismogram = $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'ss';

# file names and their full paths
my $reflection_coef_time  = $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'rc_t';
my $reflection_coef_depth = $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'rc_z';
my $zrho_reg              = $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'zrho_reg';
my $zv_reg                = $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'zv_reg';
my $zrhov                 = $DATA_SEISMIC_WELL_SYNSEIS . '/' . $base_file_name;

# my $zrhov							= $DATA_RESISTIVITY_WELL_TXT.'/'.'zrhov_W8';

# default calculations
my $water_velocity_mps = 1500.;
my $water_depth_s = $water_depth_m / $water_velocity_mps/ 2;

# print("Synseis.pl, DATA In is $base_file_name\n");
# print("Synseis.pl, plot_time_min_s is $plot_time_min_s\n");
# print("Synseis.pl, plot_time_min_s is $plot_time_max_s\n");
# print(" 1. Synseis.pl, plot_depth_min_m:$plot_depth_min_m\n\n");
# print(" 1. Synseis.pl, plot_density_min:$plot_density_min\n\n");
# print(" 1. Synseis.pl, plot_depth_min_m:$plot_time_min_s\n\n");
# print(" 1. Synseis.pl, plot_velocity_min:$plot_velocity_min\n\n");
#print(" 1. Synseis.pl, plot_ss_amplitude_min:$plot_ss_amplitude_min\n\n");
#print(" 1. Synseis.pl, plot_reflection_coefficient_min:$plot_reflection_coefficient_min\n\n");


=head2 Set a2b 

=cut

$a2b_file_name[1] = $zrho_reg;
$a2b_outbound[1]  = $a2b_file_name[1] . $suffix_bin;
$a2b_inbound[1]   = $a2b_file_name[1];

$a2b->clear();
$a2b->floats_per_line( quotemeta(2) );
$a2b->outpar(
    quotemeta( $DATA_SEISMIC_WELL_SYNSEIS . '/' . '.temp_zrho_reg' ) );
$a2b[1] = $a2b->Step();


=head2 Set up

	data_in parameter values

=cut

$data_in->clear();
$data_in->base_file_name( quotemeta('ss_amp_only') );
$data_in->suffix_type( quotemeta('su') );
$data_in[1] = $data_in->Step();


=head2 Set  a2b 

=cut

$a2b_file_name[2] = $zv_reg;
$a2b_outbound[2]  = $a2b_file_name[2] . $suffix_bin;
$a2b_inbound[2]   = $a2b_file_name[2];

$a2b->clear();
$a2b->floats_per_line( quotemeta(2) );
$a2b->outpar(
    quotemeta( $DATA_SEISMIC_WELL_SYNSEIS . '/' . '.temp_zv_reg' ) );
$a2b[2] = $a2b->Step();


=head2 Set a2b 

=cut

$a2b_file_name[3] = $reflection_coef_depth;
$a2b_outbound[3]  = $a2b_file_name[3] . $suffix_bin;
$a2b_inbound[3]   = $a2b_file_name[3];

$a2b->clear();
$a2b->floats_per_line( quotemeta(2) );
$a2b->outpar(
    quotemeta(
        $DATA_SEISMIC_WELL_SYNSEIS . '/' . '.temp_reflection_coef_depth'
    )
);
$a2b[3] = $a2b->Step();


=head2 Set a2b 

=cut

$a2b_file_name[4] = $reflection_coef_time;
$a2b_outbound[4]  = $a2b_file_name[4] . $suffix_bin;
$a2b_inbound[4]   = $a2b_file_name[4];

$a2b->clear();
$a2b->floats_per_line( quotemeta(2) );
$a2b->outpar(
    quotemeta(
        $DATA_SEISMIC_WELL_SYNSEIS . '/' . '.temp_reflection_coef_time'
    )
);
$a2b[4] = $a2b->Step();


=head2 Set a2b 

=cut

$a2b_file_name[5] = $output_synthetic_seismogram;
$a2b_outbound[5]  = $a2b_file_name[5] . $suffix_bin;
$a2b_inbound[5]   = $a2b_file_name[5];

$a2b->clear();
$a2b->floats_per_line( quotemeta(2) );
$a2b->outpar(
    quotemeta(
        $DATA_SEISMIC_WELL_SYNSEIS . '/'
             . '.temp_output_synthetic_seismogram'
    )
);
$a2b[5] = $a2b->Step();


=head2 Set sed 

=cut

my $sed_num_points;


=head2 Set Synseis

=cut

my $s2us = 1000000;
my $time_sampling_interval_us = $time_sampling_interval_s * $s2us;

$Synseis->clear();
$Synseis->reflec_coef_depth( quotemeta($reflection_coef_depth) );
$Synseis->reflec_coef_time( quotemeta($reflection_coef_time) );
$Synseis->time_sampling_interval( quotemeta($time_sampling_interval_s) )
     ;     # seconds
$Synseis->depth_sampling_interval( quotemeta($depth_sampling_interval_m) )
     ;     # meters
$Synseis->reg_density_file( quotemeta($zrho_reg) );
$Synseis->reg_velocity_file( quotemeta($zv_reg) );
$Synseis->zrhov_filename($zrhov);     # NOTE: no quotemeta
    #$Synseis     		-> input_source_filename (quotemeta($DATA_SEISMIC_WELL_SYNSEIS.'/'.'1027.source'));
    #$Synseis     		-> output_source(quotemeta($DATA_SEISMIC_WELL_SYNSEIS.'/'.'source.out'));
$Synseis->Ricker_endtime( quotemeta($Ricker_endtime) );     # s
$Synseis->Ricker_file(
    quotemeta( $DATA_SEISMIC_WELL_SYNSEIS . '/' . 'ricker.out' ) );
$Synseis->Ricker_frequency( quotemeta($Ricker_frequency) );     # Hz
$Synseis->water_depth( quotemeta($water_depth_m) );
# only for debugging, will generate
# error in running flow 6
# because the errors are output to stdout which is also ss (text)
#$Synseis     		-> verbose(quotemeta($on));
$Synseis[1]     = $Synseis->Step();
$SynseisNote[1] = $Synseis->note();

=head2 DEFINE FLOW(S)

Reading and plotting data 
and synthetic seismogram
 
=cut

# run main (synseis) and its switches
my $program_ss=$Synseis[1];
@items = ($program_ss, $out, $output_synthetic_seismogram );
# @items = ($program_ss);
$flow[1] = $run->modules( \@items );

# create zrhoreg.bin
@items = ( $a2b[1], $in, $a2b_inbound[1], $out, $a2b_outbound[1] );
# print  "@items\n";
$flow[2] = $run->modules( \@items );

# create zvreg.bin
@items = ( $a2b[2], $in, $a2b_inbound[2], $out, $a2b_outbound[2] );
$flow[3] = $run->modules( \@items );
# print  "zvreg: @items\n";

# create reflection_coef_depth.bin
@items = ( $a2b[3], $in, $a2b_inbound[3], $out, $a2b_outbound[3] );
$flow[4] = $run->modules( \@items );
# print  "synthetic seismograms: @items\n";

# create  reflection_coef_time.bin
@items = ( $a2b[4], $in, $a2b_inbound[4], $out, $a2b_outbound[4] );
 $flow[5] = $run->modules( \@items );
# print  "rc_time: @items\n";

# create ss.bin
@items = ( $a2b[5], $in, $a2b_inbound[5], $out, $a2b_outbound[5] );
# print  "synthetic seismograms: @items\n";
 $flow[6] = $run->modules( \@items );
 
# create a second ss.su with only the amplitude column in preparation
 

=head2 RUN FLOW(S)

flow 1 to create ss and accompanying files
flow 2 create zrhoreg.bin

=cut

# run main
$run->flow( \$flow[1] );
# print  "Synseis.pl,flow1: $flow[1]\n";

# create zrho_reg.bin
$run->flow( \$flow[2] );
#print  "Synseis.pl,flow2: $flow[2]\n";

#get meta-data from zrhoreg
my $num_points_zrho_reg = $manage_files_by2->count_lines( \$zrho_reg );
# print("num_points_zrho_reg  $num_points_zrho_reg \n");

#create zv_reg.bin
$run->flow( \$flow[3] );
#get meta-data from zvreg
my $num_points_zv_reg = $manage_files_by2->count_lines( \$zv_reg );
#print("num_points_zv_reg  $num_points_zv_reg \n");

#create reflection_coef_depth.bin
$run->flow( \$flow[4] );
# get meta-data from reflection_coef_depth
my $num_points_depth = $manage_files_by2->count_lines( \$reflection_coef_depth );
#print("num_points_depth  $num_points_depth \n");

# create reflection_coef_time.bin
$run->flow( \$flow[5] );
#print  "Synseis.pl,flow5: $flow[5]\n";
# get meta-data from reflection_coef_time
my $num_points_time = $manage_files_by2->count_lines( \$reflection_coef_time );
#print("num_points_time $num_points_time \n");

# create ss.bin
$run->flow( \$flow[6] );

#=head2 Set up 
#
#	a2su parameter values
#	and run them
#
#=cut
#
#$a2su->clear();
#$a2su->set_base_file_name_in('ss');
#$a2su->set_path_in($DATA_SEISMIC_TXT);
#$a2su->set_si_us($time_sampling_interval_us);
#$a2su->go();

## get meta-data from ss
my $num_points_synthetic_seismogram =
     $manage_files_by2->count_lines( \$output_synthetic_seismogram );
print("num_points_synthetic_seismogram $num_points_synthetic_seismogram \n");

=head2 plot zrho_reg.bin

 xgraph 

=cut

$xbox = 0;
$geometry[1] = $wbox . 'x' . $hbox . '+' . $xbox . '+' . $ybox;

$xgraph->clear();
$xgraph->axes_style( quotemeta('seismic') );
$xgraph->title( quotemeta('resampled rho in depth, g/cc') );
$xgraph->x2beg( quotemeta($plot_density_min) );
$xgraph->x2end( quotemeta($plot_density_max) );
$xgraph->x1beg( quotemeta($plot_depth_min_m) );
$xgraph->x1end( quotemeta($plot_depth_max_m) );
$xgraph->line_color( quotemeta(2) );
$xgraph->nTic2( quotemeta(2) );
#$xgraph->grid2_type( quotemeta('dash') );
$xgraph->geometry( ( quotemeta( $geometry[1] ) ) );
$xgraph->box_width( quotemeta($wbox) );
$xgraph->num_points( quotemeta($num_points_zrho_reg) );
$xgraph[1]         = $xgraph->Step();
$xgraph_file_name  = $zrho_reg;
$xgraph_inbound[1] = $xgraph_file_name . $suffix_bin;

@items = ( $xgraph[1], $in, $xgraph_inbound[1], $go );

# print  "@items\n";
$flow[7] = $run->modules( \@items );

# print  "$flow[7]\n";

=head2 Set

 xgraph plot zvreg.bin

=cut

$xbox = 230;
$geometry[2] = $wbox . 'x' . $hbox . '+' . $xbox . '+' . $ybox;

$xgraph->clear();
$xgraph->axes_style( quotemeta('seismic') );
$xgraph->title( quotemeta('resampled V in depth') );
$xgraph->x1beg( quotemeta($plot_depth_min_m) );
$xgraph->x1end( quotemeta($plot_depth_max_m) );
$xgraph->x2beg( quotemeta($plot_velocity_min) );
$xgraph->x2end( quotemeta($plot_velocity_max) );
$xgraph->nTic2( quotemeta(2) );
#$xgraph->grid2_type( quotemeta('solid') );
$xgraph->geometry( quotemeta( $geometry[2] ) );
$xgraph->box_width( quotemeta($wbox) );
$xgraph->num_points( quotemeta($num_points_zv_reg) );
$xgraph[2]         = $xgraph->Step();
$xgraph_file_name  = $zv_reg;
$xgraph_inbound[2] = $xgraph_file_name . $suffix_bin;

@items = ( $xgraph[2], $in, $xgraph_inbound[2], $go );
$flow[8] = $run->modules( \@items );

=head2 Set

 xgraph plot reflection_coef_depth.bin

=cut

$xbox = 460;
$geometry[3] = $wbox . 'x' . $hbox . '+' . $xbox . '+' . $ybox;

$xgraph->clear();
$xgraph->axes_style( quotemeta('seismic') );
$xgraph->title( quotemeta('refl. coeffic. in depth') );
$xgraph->x2beg( quotemeta($plot_reflection_coefficient_min) );
$xgraph->x2end( quotemeta($plot_reflection_coefficient_max) );
$xgraph->x1beg( quotemeta($plot_depth_min_m) );
$xgraph->x1end( quotemeta($plot_depth_max_m) );
$xgraph->nTic2( quotemeta(2) );
#$xgraph->grid2_type( quotemeta('solid') );
#$xgraph->grid1_type( quotemeta('solid') );
$xgraph->geometry( quotemeta( $geometry[3] ) );
$xgraph->box_width( quotemeta($wbox) );
$xgraph->num_points( quotemeta($num_points_depth) );
$xgraph[3]         = $xgraph->Step();
$xgraph_file_name  = $reflection_coef_depth;
$xgraph_inbound[3] = $xgraph_file_name . $suffix_bin;

@items = ( $xgraph[3], $in, $xgraph_inbound[3], $go );
$flow[9] = $run->modules( \@items );

=head2 Set

 xgraph plot reflection_coef_time.bin

=cut

$xbox = 690;
$geometry[4] = $wbox . 'x' . $hbox . '+' . $xbox . '+' . $ybox;

$xgraph->clear();
$xgraph->axes_style( quotemeta('seismic') );
$xgraph->title( quotemeta('Refl. coeff. in time') );
$xgraph->x2beg( quotemeta($plot_reflection_coefficient_min) );
$xgraph->x2end( quotemeta($plot_reflection_coefficient_max) );
$xgraph->x1beg( quotemeta($plot_time_min_s) );
$xgraph->x1end( quotemeta($plot_time_max_s) );
$xgraph->nTic2( quotemeta(2) );
#$xgraph->grid2_type( quotemeta('solid') );
$xgraph->geometry( quotemeta( $geometry[4] ) );
$xgraph->box_width( quotemeta($wbox) );
$xgraph->num_points( quotemeta($num_points_time) );
$xgraph[4]         = $xgraph->Step();
$xgraph_file_name  = $reflection_coef_time;
$xgraph_inbound[4] = $xgraph_file_name . $suffix_bin;

@items = ( $xgraph[4], $in, $xgraph_inbound[4], $go );
$flow[10] = $run->modules( \@items );

#=head2 Set up
#
#	suxwigb parameter values
#
#=cut
#
#$suxwigb->clear();
#$suxwigb->x2beg( quotemeta($plot_ss_amplitude_min) );
#$suxwigb->x2end( quotemeta($plot_ss_amplitude_max) );
#$suxwigb->box_width( quotemeta(400) );
#$suxwigb->box_height( quotemeta($hbox) );
#$suxwigb->box_X0( quotemeta($xbox) );
#$suxwigb->box_Y0( quotemeta(920) );
#$suxwigb->orientation( quotemeta('seismic') );
#$suxwigb->windowtitle(quotemeta('Synthetic seismogram'));
#$suxwigb->title(quotemeta('synthetic seismogram in time (s)'));
#$suxwigb[1] = $suxwigb->Step();

=head2 Plot

synthetic seismogram 

=cut

@items = ( $suxwigb[1], $in, $data_in[1], $go );
$flow[11] = $run->modules( \@items );

$xbox = 920;
$geometry[5] = $wbox . 'x' . $hbox . '+' . $xbox . '+' . $ybox;

$xgraph->clear();
$xgraph->axes_style( quotemeta('seismic') );
$xgraph->title( quotemeta('synthetic seismogram') );
$xgraph->x2end( quotemeta($plot_ss_amplitude_max) );
$xgraph->x2beg( quotemeta($plot_ss_amplitude_min) );
$xgraph->x1beg( quotemeta($plot_time_min_s) );
$xgraph->x1end( quotemeta($plot_time_max_s) );
$xgraph->nTic2( quotemeta(2) );
#$xgraph->grid2_type( quotemeta('solid') );
$xgraph->geometry( quotemeta( $geometry[5] ) );
$xgraph->box_width( quotemeta($wbox) );
$xgraph->num_points( quotemeta($num_points_synthetic_seismogram) );
$xgraph[5]         = $xgraph->Step();
$xgraph_file_name  = $output_synthetic_seismogram;
$xgraph_inbound[5] = $xgraph_file_name . $suffix_bin;

@items = ( $xgraph[5], $in, $xgraph_inbound[5], $go );
$flow[11] = $run->modules( \@items );

# plot zrho_reg.bin
$run->flow( \$flow[7] );

## plot zv_reg.bin
$run->flow( \$flow[8] );
#
## plot rc_depth.bin
$run->flow( \$flow[9] );
#
## plot rc_time.bin
$run->flow( \$flow[10] );
#
## plot ss.bin
$run->flow( \$flow[11] );

=head2 LOG FLOW(S)
 TO SCREEN AND FILE

=cut

##          print  "$flow[1]\n";
## $log->file($flow[1]);
##
#
##$log->file($flow[2]);
##
##      print  "$flow[3]\n";
##$log->file($flow[3]);
#
##     print  "$flow[4]\n";
##$log->file($flow[2]);
#
##     print  "$flow[5]\n";
##$log->file($flow[5]);
#
##        print  "$flow[6]\n";
##$log->file($flow[6]);
#
## plot zrho_reg.bin
## print  "$flow[7]\n";
##$log->file($flow[7]);
#
## print  "$flow[8]\n";
##$log->file($flow[8]);
#
#    print  "$flow[9]\n";
#$log->file($flow[9]);
#
##    print  "$flow[10]\n";
##$log->file($flow[10]);
#
     print  "$flow[11]\n";
##$log->file($flow[11]);
#
#system("sh /usr/local/pl/L_SU/c/synseis/run_me_only.sh");
