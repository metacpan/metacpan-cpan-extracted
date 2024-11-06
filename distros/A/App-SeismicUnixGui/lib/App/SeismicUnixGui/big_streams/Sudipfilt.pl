
=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: Sudipfilt.pl
  Purpose: f-k spectral analysis 
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    Feb 15 2008 V0.1
           V0.2 June 30 2016 make oop
  DESCRIPTION:  based upon non-oop Xamine.pl  

=head2 USES

 (for subroutines) 
     manage_files_by 

     (for variable definitions)
     SeismicUnix (Seismic Unix modules)

 use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su) ;

=head2 USAGE
 
 Sucat 

=head2 NEEDS 
 
=head2 EXAMPLES 
 
=head2 NOTES 

 We are using Moose 
 moose already declares that you need debuggers turned on
 so you don't need a line like the following:

 use warnings;


  sample rate = 125 us
  d1 = sample rate in ms = .000125

=cut

use Moose;
our $VERSION = '1.0.2';

use aliased 'App::SeismicUnixGui::configs::big_streams::Sudipfilt_config';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::filter::sudipfilt';
use aliased 'App::SeismicUnixGui::sunix::statsMath::suinterp';
use aliased 'App::SeismicUnixGui::sunix::transform::suspecfk';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

=head2 Instantiate classes

     Create a new version of the package
     Personalize to give it a new name if you wish

     Use classes:
     flow
     log
     message
     sufilter
     sugain
     sureduce
     suspecfk
     suxwigb
     suximage
     sudipfilt

=cut

my $get              = L_SU_global_constants->new();
my $log              = message->new();
my $run              = flow->new();
my $sudipfilter      = sudipfilt->new();
my $Sudipfilt_config = Sudipfilt_config->new();
my $suspecfk         = suspecfk->new();
my $suxwigb          = suxwigb->new();
my $suximage         = suximage->new();
my $sufilter         = sufilter->new();
my $suinterp         = suinterp->new();
my $sugain           = sugain->new();
my $suwind           = suwind->new();
my $read             = readfiles->new();

=head2 notes

=cut

my ( @flow,        @sufile_out, @inbound,  @outbound );
my ( @suxwigb,     @sufilter,   @suximage, @sugain, @suinterp, @items, @suspecfk );
my ( @sudipfilter, @suwind );
my ($sufile_in);

my $yes           = $get->var->{_yes};
my $no            = $get->var->{_no};
my $skip_suinterp = $yes;

=head2 Get configuration information

=cut

my ( $CFG_h, $CFG_aref ) = $Sudipfilt_config->get_values();

=head2 TOP LEFT PLOT

  includes sugain variables

=cut

# print("Sudipfilt.pl,HOME=$CFG_h->{Project_Variables}{1}{HOME}\n");

my $TOP_LEFT_sugain_pbal_switch = $CFG_h->{TOP_LEFT}{sugain}{pbal_switch};
my $TOP_LEFT_sugain_agc_switch  = $CFG_h->{TOP_LEFT}{sugain}{agc_switch};
my $TOP_LEFT_sugain_agc_width   = $CFG_h->{TOP_LEFT}{sugain}{agc_width};

my $BOTTOM_RIGHT_suximage_absclip = $CFG_h->{BOTTOM_RIGHT}{suximage}{absclip};

my $sudipfilter_1_dt     = $CFG_h->{sudipfilter}{1}{dt};
my $sudipfilter_1_dx     = $CFG_h->{sudipfilter}{1}{dx};
my $sudipfilter_1_slopes = $CFG_h->{sudipfilter}{1}{slopes};
my $sudipfilter_1_bias   = $CFG_h->{sudipfilter}{1}{bias};
my $sudipfilter_1_amps   = $CFG_h->{sudipfilter}{1}{amps};

my $sudipfilter_2_dt     = $CFG_h->{sudipfilter}{2}{dt};
my $sudipfilter_2_dx     = $CFG_h->{sudipfilter}{2}{dx};
my $sudipfilter_2_slopes = $CFG_h->{sudipfilter}{2}{slopes};
my $sudipfilter_2_bias   = $CFG_h->{sudipfilter}{2}{bias};
my $sudipfilter_2_amps   = $CFG_h->{sudipfilter}{2}{amps};

my $suinterp_1_ninterp = $CFG_h->{suinterp}{1}{ninterp};

my $suwind_1_tmin = $CFG_h->{suwind}{1}{tmin};
my $suwind_1_tmax = $CFG_h->{suwind}{1}{tmax};

my $suwind_2_min = $CFG_h->{suwind}{2}{min};
my $suwind_2_max = $CFG_h->{suwind}{2}{max};
my $suwind_2_key = $CFG_h->{suwind}{2}{key};

my $sufilter_1_freq      = $CFG_h->{sufilter}{1}{freq};
my $sufilter_1_amplitude = $CFG_h->{sufilter}{1}{amplitude};

my $suspecfk_1_dt = $CFG_h->{suspecfk}{1}{dt};
my $suspecfk_1_dx = $CFG_h->{suspecfk}{1}{dx};

my $file_in           = $CFG_h->{base_file_name};
my $inbound_directory = $CFG_h->{inbound_directory};

# print("2. Sudipfilt,inbound_directory : $inbound_directory\n\n");

=head2 Declare file names 

=cut

$sufile_in     = $file_in . $suffix_su;
$sufile_out[1] = $file_in . '_fk' . $suffix_su;
$inbound[1]    = $inbound_directory . '/' . $sufile_in;
$outbound[1]   = $inbound_directory . '/' . $sufile_out[1];

=head2 sugain
  
 Set gain variables for TOP LEFT PLOT

=cut

if ( $TOP_LEFT_sugain_pbal_switch eq $on ) {

	$sugain->clear();
	$sugain->pbal( quotemeta($TOP_LEFT_sugain_pbal_switch) );
	$sugain[1] = $sugain->Step();

} else {

	$sugain->clear();
	$sugain->agc( quotemeta($TOP_LEFT_sugain_agc_switch) );
	$sugain->width( quotemeta($TOP_LEFT_sugain_agc_width) );

	# $sugain     	-> setdt(quotemeta(1000));
	$sugain[1] = $sugain->Step();
}

=head2 suinterp
  
 Set interpolation to reduce aliasing

=cut

if ( length $suinterp_1_ninterp and $suinterp_1_ninterp > 0 ) {

	$suinterp->clear();
	$suinterp->ninterp( quotemeta($suinterp_1_ninterp) );
	$suinterp[1] = $suinterp->Step();

	# print("Sudipfilt.pl, do not skip suninterp \n");
	# print $suinterp[1]."\n";
	$skip_suinterp = $no;
	# print("Sudipfilt.pl, skip suninterp= $skip_suinterp\n");

} else {

	$suinterp->clear();
	print("Sudipfilt.pl, skip suninterp--bad ninterp \n");
	$skip_suinterp = $yes;
	# print("Sudipfilt.pl, skip suninterp= $skip_suinterp\n");

}

=head2 sufilter
  
 Set frequency filter ing parameters

=cut

$sufilter->clear();
$sufilter->freq( quotemeta($sufilter_1_freq) );
$sufilter->amplitude( quotemeta($sufilter_1_amplitude) );
$sufilter[1] = $sufilter->Step();

=head2 suwind
  
 Set windowing parameters

=cut

=head2 Window 
   
   by time

=cut

$suwind->clear();
$suwind->tmin( quotemeta($suwind_1_tmin) );
$suwind->tmax( quotemeta($suwind_1_tmax) );
$suwind[1] = $suwind->Step();

=head2  Window 
   
   by field record 

=cut

$suwind->clear();
$suwind->key( quotemeta($suwind_2_key) );
$suwind->min( quotemeta($suwind_2_min) );
$suwind->max( quotemeta($suwind_2_max) );
$suwind[2] = $suwind->Step();

=head2 f-k analysis 

  make non-dimensional 

=cut

$suspecfk->clear();
$suspecfk->dt( quotemeta($suspecfk_1_dt) );
$suspecfk->dx( quotemeta($suspecfk_1_dx) );
$suspecfk[1] = $suspecfk->Step();

=head2 TODO linear moveout 

# LINEAR MOVEOUT 
	@sureduce[1] =  (" sureduce 	            		\\
			rv=1.5					\\
               ");

# LINEAR MOVEOUT 
	@sureduce[2] =  (" sureduce 	            		\\
			rv=-1.5					\\
               ");

=cut

=head2 Dip filter 

  set parameters 

=cut

$sudipfilter->clear();
$sudipfilter->dt( quotemeta($sudipfilter_1_dt) );
$sudipfilter->dx( quotemeta($sudipfilter_1_dx) );
$sudipfilter->slopes( quotemeta($sudipfilter_1_slopes) );
$sudipfilter->bias( quotemeta($sudipfilter_1_bias) );
$sudipfilter->amps( quotemeta($sudipfilter_1_amps) );
$sudipfilter[1] = $sudipfilter->Step();

=head2 Dip filter 

  set parameters 

=cut

$sudipfilter->clear();
$sudipfilter->dt( quotemeta($sudipfilter_2_dt) );
$sudipfilter->dx( quotemeta($sudipfilter_2_dx) );
$sudipfilter->slopes( quotemeta($sudipfilter_2_slopes) );
$sudipfilter->bias( quotemeta($sudipfilter_2_bias) );
$sudipfilter->amps( quotemeta($sudipfilter_2_amps) );
$sudipfilter[2] = $sudipfilter->Step();

=head2 DISPLAY DATA as wiggles

  Set parameters
  Top middle image

=cut

$suxwigb->clear();
$suxwigb->title( quotemeta($sufile_in) );
$suxwigb->windowtitle( quotemeta('unfiltered data') );
$suxwigb->xlabel( quotemeta('trace No.') );
$suxwigb->ylabel( quotemeta('# samples') );
$suxwigb->box_width( quotemeta(300) );
$suxwigb->box_height( quotemeta(370) );
$suxwigb->dt( quotemeta(1) );
$suxwigb->dx( quotemeta(1) );
$suxwigb->x_tick_increment( quotemeta(20) );
$suxwigb->first_time_sample_value( quotemeta(1) );

#$suxwigb-> first_distance_sample_value(quotemeta(0));
$suxwigb->box_X0( quotemeta(370) );
$suxwigb->box_Y0( quotemeta(0) );
$suxwigb->absclip( quotemeta(25) );
$suxwigb->xcur( quotemeta(3) );
$suxwigb->va( quotemeta(1) );
$suxwigb->num_minor_ticks_betw_distance_ticks( quotemeta(2) );
$suxwigb->num_minor_ticks_betw_time_ticks( quotemeta(3) );
$suxwigb[1] = $suxwigb->Step();

#$suxwigb-> wigclip(quotemeta(1));

=head2 DISPLAY DATA as wiggles

  Set parameters
  

=cut

$suxwigb->clear();
$suxwigb->title( quotemeta($sufile_in) );
$suxwigb->windowtitle( quotemeta('dip-filtered') );
$suxwigb->xlabel( quotemeta('trace No.') );
$suxwigb->ylabel( quotemeta('# samples') );
$suxwigb->box_width( quotemeta(300) );
$suxwigb->box_height( quotemeta(370) );
$suxwigb->box_X0( quotemeta(370) );
$suxwigb->box_Y0( quotemeta(440) );
$suxwigb->dt( quotemeta(1) );
$suxwigb->dx( quotemeta(1) );
$suxwigb->first_time_sample_value( quotemeta(1) );
$suxwigb->first_distance_sample_value( quotemeta(1) );
$suxwigb->absclip( quotemeta(30) );
$suxwigb->xcur( quotemeta(3) );
$suxwigb->va( quotemeta(1) );
$suxwigb->num_minor_ticks_betw_distance_ticks( quotemeta(1) );
$suxwigb->x_tick_increment( quotemeta(20) );
$suxwigb[5] = $suxwigb->Step();

=head2 DISPLAY DATA as IMAGE

  Set parameters
  Top-left image

=cut

$suximage->clear();
$suximage->title( quotemeta($sufile_in) );
$suximage->box_width( quotemeta(300) );
$suximage->box_height( quotemeta(370) );
$suximage->box_X0( quotemeta(0) );
$suximage->box_Y0( quotemeta(0) );
$suximage->tstart_s( quotemeta(.5) );
$suximage->tend_s( quotemeta(-.5) );
$suximage->xstart_m( quotemeta(-.5) );
$suximage->xend_m( quotemeta(.5) );
$suximage->num_minor_ticks_betw_distance_ticks( quotemeta(2) );
$suximage->x_tick_increment( quotemeta(0.2) );
$suximage->first_distance_tick_num( quotemeta(-0.5) );
$suximage->num_minor_ticks_betw_time_ticks( quotemeta(2) );
$suximage->y_tick_increment( quotemeta(0.1) );
$suximage->xlabel( quotemeta('frequency (Hz) dt=1 Nf=0.5') );
$suximage->ylabel( quotemeta('k 1/m dx=1 Nk=0.5') );
$suximage->legend( quotemeta(1) );
$suximage->hiclip( quotemeta(1000) );
$suximage->loclip( quotemeta(0.001) );
$suximage->style( quotemeta('seismic') );
$suximage->cmap( quotemeta('hsv2') );

#$suximage-> wigclip(quotemeta(1));
$suximage->windowtitle( quotemeta('f-k analysis') );
$suximage[1] = $suximage->Step();

=head2 DISPLAY DATA as IMAGE

  Set parameters
  Top-right image

=cut

$suximage->clear();
$suximage->title( quotemeta($sufile_in) );
$suximage->xlabel( quotemeta('trace No.') );
$suximage->ylabel( quotemeta('time s') );
$suximage->box_width( quotemeta(300) );
$suximage->box_height( quotemeta(370) );
$suximage->box_X0( quotemeta(670) );
$suximage->box_Y0( quotemeta(0) );
$suximage->hiclip( quotemeta(1) );
$suximage->loclip( quotemeta(-1) );
$suximage->tstart_s( quotemeta($suwind_1_tmin) );
#$suximage->first_distance_tick_num( quotemeta(1) );
$suximage->tend_s( quotemeta($suwind_1_tmax) );
#$suximage->num_minor_ticks_betw_distance_ticks( quotemeta(1) );
$suximage->x_tick_increment( quotemeta(10) );
#$suximage->num_minor_ticks_betw_time_ticks( quotemeta(2) );
$suximage->y_tick_increment( quotemeta(.1) );
$suximage->windowtitle(quotemeta('unfiltered data'));
$suximage->legend( quotemeta(1) );
$suximage->style( quotemeta('seismic') );
$suximage[2] = $suximage->Step();    #

=head2 DISPLAY DATA as IMAGE

  Set parameters
  Bottom-left image

=cut

$suximage->clear();
$suximage->title( quotemeta($sufile_in) );
$suximage->box_width( quotemeta(300) );
$suximage->box_height( quotemeta(370) );
$suximage->box_X0( quotemeta(0) );
$suximage->box_Y0( quotemeta(440) );
$suximage->legend( quotemeta(1) );
$suximage->tstart_s( quotemeta(0.5) );
$suximage->tend_s( quotemeta(-.5) );
$suximage->xstart_m( quotemeta(-0.5) );
$suximage->xend_m( quotemeta(.5) );
$suximage->num_minor_ticks_betw_time_ticks( quotemeta(2) );
$suximage->num_minor_ticks_betw_distance_ticks( quotemeta(1) );
$suximage->x_tick_increment( quotemeta(0.2) );
$suximage->first_distance_tick_num( quotemeta(-0.5) );
$suximage->y_tick_increment( quotemeta(0.1) );
$suximage->ylabel( quotemeta('frequency (Hz) dt=1 Nf=0.5') );
$suximage->xlabel( quotemeta('k (1/m) dx=1 Nk=0.5') );
$suximage->hiclip( quotemeta(1000) );
$suximage->loclip( quotemeta(0) );
$suximage->cmap( quotemeta('hsv2') );
$suximage->windowtitle( quotemeta('dip-filtered') );
$suximage[4] = $suximage->Step();

=head2 DISPLAY DATA as IMAGE

  Set parameters
  Bottom-right image

=cut

$suximage->clear();
$suximage->title( quotemeta($sufile_in) );
$suximage->xlabel( quotemeta('trace No.') );
$suximage->ylabel( quotemeta('time (s)') );
$suximage->box_width( quotemeta(300) );
$suximage->box_height( quotemeta(370) );
$suximage->box_X0( quotemeta(670) );
$suximage->box_Y0( quotemeta(440) );
$suximage->tstart_s( quotemeta($suwind_1_tmin) );
$suximage->tend_s( quotemeta($suwind_1_tmax) );
$suximage->num_minor_ticks_betw_distance_ticks( quotemeta(1) );
$suximage->x_tick_increment( quotemeta(5) );    #0.2
$suximage->num_minor_ticks_betw_time_ticks( quotemeta(2) );
$suximage->y_tick_increment( quotemeta(.1) );
$suximage->first_time_sample_value( quotemeta(0) );
$suximage->absclip( quotemeta($BOTTOM_RIGHT_suximage_absclip) );
$suximage->windowtitle( quotemeta('dip-filtered') );
$suximage->legend( quotemeta(1) );
$suximage[6] = $suximage->Step();

=head2
 
  Standard:
  1. DEFINE FLOW(S)
  
  top left image
  top middle plot
  top right plot
  bottom-left image
  bottom-middle plot
  bottom-right image
  output filtered data set

=cut

if ( length $skip_suinterp and $skip_suinterp eq $yes ) {

	# top left
	@items = (
		$suwind[1], $in,          $inbound[1], $to,          $suwind[2], $to,          $sugain[1],
		$to,        $sufilter[1], $to,         $suspecfk[1], $to,        $suximage[1], $go
	);
	$flow[1] = $run->modules( \@items );

	# top middle
	@items = (
		$suwind[1], $in, $inbound[1],  $to, $suwind[2],  $to,
		$sugain[1], $to, $sufilter[1], $to, $suxwigb[1], $go
	);
	$flow[2] = $run->modules( \@items );

	# top right plot
	@items = (
		$suwind[1], $in, $inbound[1],  $to, $suwind[2],   $to,
		$sugain[1], $to, $sufilter[1], $to, $suximage[2], $go
	);
	$flow[3] = $run->modules( \@items );

	# bottom-left
	@items = (
		$suwind[1],      $in, $inbound[1],  $to, $suwind[2],      $to,
		$sugain[1],      $to, $sufilter[1], $to, $sudipfilter[1], $to,
		$sudipfilter[2], $to, $suspecfk[1], $to, $suximage[4],    $go
	);
	$flow[4] = $run->modules( \@items );

	# bottom-middle
	@items = (
		$suwind[1],      $in, $inbound[1],  $to, $suwind[2],      $to,
		$sugain[1],      $to, $sufilter[1], $to, $sudipfilter[1], $to,
		$sudipfilter[2], $to, $sugain[1],   $to, $suxwigb[5],     $go
	);
	$flow[5] = $run->modules( \@items );

	# bottom-right image fk filter
	@items = (
		$suwind[1],      $in,
		$inbound[1],     $to,
		$suwind[2],      $to,
		$sufilter[1],    $to,
		$sudipfilter[1], $to,
		$sudipfilter[2], $to,
		$sugain[1],      $to,
		$suximage[6],    $go
	);
	$flow[6] = $run->modules( \@items );

	@items = (
		$suwind[1],   $in,         
		 $inbound[1],  $to, 
		  $suwind[2], $to,
		  $sufilter[1], $to,
		  $sudipfilter[1], $to,
		$sudipfilter[2], $out,
		$outbound[1], $go
	);
	$flow[7] = $run->modules( \@items );
	
} elsif ( length $skip_suinterp and $skip_suinterp eq $no ) {

	# top left
	@items = (
		$suwind[1],   $in,
		$inbound[1],  $to,
		$suwind[2],   $to,
		$suinterp[1], $to,
		$sugain[1],   $to,
		$sufilter[1], $to,
		$suspecfk[1], $to,
		$suximage[1], $go
	);
	$flow[1] = $run->modules( \@items );

	# top middle
	@items = (
		$suwind[1],   $in,
		$inbound[1],  $to,
		$suwind[2],   $to,
		$suinterp[1], $to,
		$sugain[1],   $to,
		$sufilter[1], $to,
		$suxwigb[1],  $go
	);
	$flow[2] = $run->modules( \@items );

	#top right
	@items = (
		$suwind[1],   $in,
		$inbound[1],  $to,
		$suwind[2],   $to,
		$suinterp[1], $to,
		$sugain[1],   $to,
		$sufilter[1], $to,
		$suximage[2], $go
	);
	$flow[3] = $run->modules( \@items );

	# bottom-left
	@items = (
		$suwind[1],      $in,
		$inbound[1],     $to,
		$suwind[2],      $to,
		$suinterp[1],    $to,
		$sufilter[1],    $to,
		$sugain[1],      $to,
		$sudipfilter[1], $to,
		$sudipfilter[2], $to,
		$suspecfk[1],    $to,
		$suximage[4],    $go
	);
	$flow[4] = $run->modules( \@items );

	# bottom-middle
	@items = (
		$suwind[1],      $in,
		$inbound[1],     $to,
		$suwind[2],      $to,
		$suinterp[1],    $to,
		$sufilter[1],    $to,
		$sugain[1],      $to,
		$sudipfilter[1], $to,
		$sudipfilter[2], $to,
		$sugain[1],      $to,
		$suxwigb[5],     $go
	);
	$flow[5] = $run->modules( \@items );

	# bottom-right image fk filter
	@items = (
		$suwind[1],      $in,
		$inbound[1],     $to,
		$suwind[2],      $to,
		$suinterp[1],    $to,
		$sufilter[1],    $to,
		$sudipfilter[1], $to,
		$suwind[1],      $in,
		$inbound[1],     $to,
		$suwind[2],      $to,
		$sufilter[1],    $to,
		$sudipfilter[1], $to,
		$sudipfilter[2], $to,
		$sugain[1],      $to,
		$suximage[6],    $go
	);
	$flow[6] = $run->modules( \@items );

	@items = (
		$suwind[1],   $in,         
		 $inbound[1],  $to, 
		  $suwind[2], $to,
		  $suinterp[1],    $to,
		  $sufilter[1], $to,
		  $sudipfilter[1], $to,
		$sudipfilter[2], $out,
		$outbound[1], $go
	);
	$flow[7] = $run->modules( \@items );

} else {
	print("Sudipfilt.pl, skip_interp is bad\n");
}

=pod

  2. RUN FLOW(S)

=cut

$run->flow( \$flow[1] );
$run->flow( \$flow[2] );
$run->flow( \$flow[3] );
$run->flow( \$flow[4] );
$run->flow( \$flow[5] );
$run->flow( \$flow[6] );
$run->flow( \$flow[7] );

=pod

  3. LOG FLOW(S)TO SCREEN AND FILE

=cut

# print "$flow[1]\n";

#$log->file($flow[1]);

# print "$flow[2]\n";

#$log->file($flow[2]);

# print "$flow[3]\n";

#$log->file($flow[3]);

# print "$flow[4]\n";

#$log->file($flow[4]);

# print "$flow[5]\n";

#$log->file($flow[5]);

#print "$flow[6]\n";

#$log->file($flow[6]);

print "$flow[7]\n";

#$log->file($flow[7]);
