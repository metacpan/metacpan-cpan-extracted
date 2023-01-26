package App::SeismicUnixGui::big_streams::iSuvelan;

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PCKAGE NAME: iSuvelan

  Purpose:  interactive suvelan
  AUTHOR:  Juan M. Lorenzo
  DEPENDS: Seismic Unix modules from CSM 
  DATE:    April 1 2009
  DESCRIPTION:  Generate Velocity Analysis  
  MODIFIED  Nov. 11, 2013
            July 24 2015   uses oop


=head2 NOTES 

We recommend that you prepare the balance the
amplitudes in the data before you hand them
over to iSuvelan, which DOES not GAIN 
its data. The resulting semblances may
suffer if you do not pay attention
  
=head2 USES
   
=head2 STEPS IN THE PROGRAM 

=cut

=head2 inherit and Instantiate

   classes 
    Create a new version of the package
    Personalize to give it a new name if you wish
    Use classes:
                  suvelan

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::manage_files_by';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::susort';
use aliased 'App::SeismicUnixGui::sunix::NMO_Vel_Stk::suvelan';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::header::header_values';
use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $in $to $go);
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $log               = message->new();
my $manage_files_by   = manage_files_by->new();
my $run               = flow->new();
my $sufilter          = sufilter->new();
my $sugain            = sugain->new();
my $susort            = susort->new();
my $suvelan           = suvelan->new();
my $suwind            = suwind->new();
my $suximage          = suximage->new();
my $suxwigb           = suxwigb->new();
my $Project           = Project_config->new();
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
my $get               = L_SU_global_constants->new();

=head2 Import Special Variables

=cut

my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $us2s         = $var->{_us2s};

=head2
 
 establish just the locally scoped variables

=cut

my ( @suwind_min, @suwind_max );
my ( @sufilter,   @suvelan, @suximage, @suxwigb );
my ( @susort,     @sugain,  @suwind,   @wgagc, @bandpass );
my (@cp);
my ( @suximage_col_bar_max, @suximage_col_bar_min );
my (@windowtitle);
my ($N);
my ( @suximage_first_vel,  @suximage_vel_inc );
my ( @first_velocity_tick, @suximage_vel_tick_inc );
my ( @base_caption,        @tlabel, @xlabel, @X0, @Y0, @max_abs );
my ( @flow,                @items );

=head2  hash array of important variables

 used within
  this package

=cut 

my $iSuvelan = {
	_anis1                => '',
	_anis2                => '',
	_cdp_num              => '',
	_cdp_num_suffix       => '',
	_dtratio              => '',
	_data_scale           => 1,
	_dt_s                 => '',
	_file_in              => '',
	_first_velocity       => '',
	_freq                 => '',
	_inbound              => '',
	_max_semblance        => '',
	_min_semblance        => '',
	_nsmooth              => '',
	_number_of_tries      => '',
	_number_of_velocities => '',
	_pwr                  => '',
	_smute                => '',
	_sufile_in            => '',
	_tmax_s               => '',
	_textfile_in          => '',
	_textfile_out         => '',
	_Tvel_inbound         => '',
	_Tvel_outbound        => '',
	_velocity_increment   => '',

	#	_verbose			  => '',
};

=head2 subroutine clear

         to blank out hash array values

=cut

sub clear {
	$iSuvelan->{_anis1}                = '';
	$iSuvelan->{_anis2}                = '';
	$iSuvelan->{_cdp_num}              = '';
	$iSuvelan->{_cdp_num_suffix}       = '';
	$iSuvelan->{_data_scale}           = '';
	$iSuvelan->{_dtratio}              = '';
	$iSuvelan->{_dt_s}                 = '';
	$iSuvelan->{_file_in}              = '';
	$iSuvelan->{_first_velocity}       = '';
	$iSuvelan->{_freq}                 = '';
	$iSuvelan->{_inbound}              = '';
	$iSuvelan->{_max_semblance}        = '';
	$iSuvelan->{_min_semblance}        = '';
	$iSuvelan->{_nsmooth}              = '';
	$iSuvelan->{_number_of_tries}      = '';
	$iSuvelan->{_number_of_velocities} = '';
	$iSuvelan->{_velocity_increment}   = '';
	$iSuvelan->{_smute}                = '';
	$iSuvelan->{_pwr}                  = '';
	$iSuvelan->{_sufile_in}            = '';
	$iSuvelan->{_textfile_in}          = '';
	$iSuvelan->{_textfile_out}         = '';
	$iSuvelan->{_Tvel_inbound}         = '';
	$iSuvelan->{_Tvel_outbound}        = '';
	$iSuvelan->{_tmax_s}               = '';

	#	$iSuvelan->{_verbose}              = '';
}

=head2 subroutine cdp_num


  establishes the CDP number being worked
  Also establishes'cdp'# as a recognizable suffix
  for file names

=cut

sub cdp_num {
	my ( $variable, $cdp_num ) = @_;
	if ($cdp_num) {
		$iSuvelan->{_cdp_num} = $cdp_num;

		#print("cdp_num in iSuvelan is $iSuvelan->{_cdp_num}\n\n");
	}
}

=head2 subroutine cdp_num_suffix


  establishes the CDP number suffix 
  that is being worked

=cut

sub cdp_num_suffix {
	my ( $variable, $cdp_num ) = @_;
	if ($cdp_num) {
		$iSuvelan->{_cdp_num_suffix} = '_cdp' . $cdp_num;

		#print("suffix in iSuvelan is $iSuvelan->{_cdp_num_suffix}\n\n");
	}
}

=head2 subroutine dt_s


=cut

sub dt_s {
	my ( $variable, $dt_s ) = @_;

	if ($dt_s) {

		$iSuvelan->{_dt_s} = $dt_s;

	}
}

=head2 subroutine file_in

   gets the file name
   creates the sufile name to read
   creates the full path for reading the sufile

   print("iSuvelan_inbound is $iSuvelan->{_inbound}\n\n");

=cut

sub file_in {
	my ( $variable, $file_in ) = @_;
	if ($file_in) {
		$iSuvelan->{_file_in}   = $file_in;
		$iSuvelan->{_sufile_in} = $file_in . '.su';
	}
	$iSuvelan->{_inbound} = $DATA_SEISMIC_SU . '/' . $iSuvelan->{_sufile_in};
}

=head2  subroutine first_velocity

    print("first velocity is $iSuvelan->{_first_velocity} \n\n");

=cut

sub first_velocity {
	my ( $variable, $first_velocity ) = @_;
	if ($first_velocity) {
		$iSuvelan->{_first_velocity} = $first_velocity;
	}
}

=head2 subroutine freq

  creates the bandpass frequencies to filter data before
  conducting semblance analysis
  e.g., "3,6,40,50"
 
=cut

sub freq {
	my ( $variable, $freq ) = @_;
	$iSuvelan->{_freq} = $freq if defined($freq);

	# print("iSuvelan,freq= $iSuvelan->{_freq}\n");
}

=head2  subroutine  number_of_tries

    keep track of the number of attempts
    at picking velocities

=cut

sub number_of_tries {
	my ( $variable, $number_of_tries ) = @_;
	$iSuvelan->{_number_of_tries} = $number_of_tries
	  if defined($number_of_tries);

#print("num of tries is $iSuvelan->{_number_of_tries}\n\n");
#print("\nReading: $Tvel_iSuvelan->{_inbound} \nTime=$$ref_T_nmo[1],Vel=$$ref_Vnmo[1],npairs=$num_tvel_pairs \n");

}

=head2 subroutine set_anis1


=cut

sub set_anis1 {
	my ( $variable, $anis1 ) = @_;

	if ( defined $anis1 && $anis1 ne $empty_string ) {
		$iSuvelan->{_anis1} = $anis1;
	}
	else {
		print("iSuvelan, unexpected anis1\n");
	}

}

=head2 subroutine set_anis2


=cut

sub set_anis2 {
	my ( $variable, $anis2 ) = @_;

	if ( defined $anis2 && $anis2 ne $empty_string ) {
		$iSuvelan->{_anis2} = $anis2;
	}
	else {
		print("iSuvelan, unexpected anis2\n");
	}

}

=head2 subroutine set_data_scale

suvelan does not consider scalco or scalel header values
automatically

=cut

sub set_data_scale {
	my ( $variable, $data_scale ) = @_;

	if ( defined $data_scale && $data_scale ne $empty_string ) {
		$iSuvelan->{_data_scale} = $data_scale;
	}
	else {
		print("iSuvelan, unexpected data_scale\n");
	}

}

=head2 subroutine set_dtratio


=cut

sub set_dtratio {
	my ( $variable, $dtratio ) = @_;

	if ( defined $dtratio && $dtratio ne $empty_string ) {

		$iSuvelan->{_dtratio} = $dtratio;

	}
	else {
		print("iSuvelan, unexpected dtratio\n");
	}

}

=head2 subroutine set_nsmooth


=cut

sub set_nsmooth {
	my ( $variable, $nsmooth ) = @_;

	if (    length $nsmooth
		and length $iSuvelan->{_dtratio} )
	{

		$iSuvelan->{_nsmooth} = $nsmooth;

	}
	elsif ( length $iSuvelan->{_dtratio} ) {

		$iSuvelan->{_nsmooth} = $iSuvelan->{_dtratio} * 2 + 1;    # from suvelan

	}
	else {
		print("iSuvelan, a value for dtratio may be missing\n");
	}

}

=head2 subroutine set_pwr


=cut

sub set_pwr {
	my ( $variable, $pwr ) = @_;

	if ( defined $pwr && $pwr ne $empty_string ) {
		$iSuvelan->{_pwr} = $pwr;
	}
	else {
		print("iSuvelan, unexpected pwr\n");
	}

}

=head2 subroutine set_smute


=cut

sub set_smute {
	my ( $variable, $smute ) = @_;

	if ( defined $smute && $smute ne $empty_string ) {
		$iSuvelan->{_smute} = $smute;
	}
	else {
		print("iSuvelan, unexpected smute\n");
	}

}

#=head2 subroutine set_verbose
#
#
#=cut
#
#sub set_verbose {
#	my ( $variable, $verbose ) = @_;
#
#	if ( defined $verbose && $verbose ne $empty_string ) {
#		$iSuvelan->{_verbose} = $verbose;
#	}
#	else {
#		print("iSuvelan, unexpected verbose\n");
#	}
#
#}

=head2 subroutine tmax_s


=cut

sub tmax_s {
	my ( $self, $tmax_s ) = @_;
	if ($tmax_s) {
		$iSuvelan->{_tmax_s} = $tmax_s;
	}
}

=head2  subroutine velocity increment 


=cut

sub velocity_increment {
	my ( $variable, $velocity_increment ) = @_;
	$iSuvelan->{_velocity_increment} = $velocity_increment
	  if defined($velocity_increment);

	#print("velocity_increment is $iSuvelan->{_velocity_increment} \n\n");
}

=head2 

 subroutine number_of_velocities 

=cut

sub number_of_velocities {
	my ( $variable, $number_of_velocities ) = @_;

	$iSuvelan->{_number_of_velocities} = $number_of_velocities
	  if defined $number_of_velocities;

#	print(" iSuvelan,number_of_velocities:$iSuvelan->{_number_of_velocities} \n\n");
}

=head2 subroutine calcNdisplay

  calculate semblance and display results 

=cut

sub calcNdisplay {

	my ($self) = @_;

	if (
			length $iSuvelan->{_file_in}
		and $iSuvelan->{_dtratio}
		and $iSuvelan->{_cdp_num}
		and $iSuvelan->{_tmax_s}
		and $iSuvelan->{_number_of_velocities}
		and $iSuvelan->{_number_of_velocities}
		and $iSuvelan->{_velocity_increment}
		and $iSuvelan->{_data_scale}
	  )
	{

		print(" iSuvelan, calcNdisplay\n\n");

		my $header = header_values->new();
		
		my $new_dt_s;

		if ( length $iSuvelan->{_file_in} ) {

			$header->set_base_file_name( $iSuvelan->{_file_in} );
			$header->set_header_name('dt');
			my $dt_us   = $header->get_number();
			my $dt_s 	= $dt_us * $us2s;
			$new_dt_s 	= $dt_s * $iSuvelan->{_dtratio};

			  #		print("iSuvelan,calcNdisplay, dt_s = $dt_s \n");

		}
		else {
			print("iSuvelan, calcNdisplay, missing base file name\n");
		}

=head2 WINDOW  DATA

by cdp 

=cut

		$suwind_min[1] = $iSuvelan->{_cdp_num};
		$suwind_max[1] = $iSuvelan->{_cdp_num};

		$suwind->clear();
		$suwind->setheaderword( quotemeta('cdp') );
		$suwind->min( quotemeta( $suwind_min[1] ) );
		$suwind->max( quotemeta( $suwind_max[1] ) );
		$suwind[1] = $suwind->Step();

=head2 WINDOW  DATA 

by time 

=cut

		$suwind->clear();
		$suwind->tmin( quotemeta(0) );
		$suwind->tmax( quotemeta( $iSuvelan->{_tmax_s} ) );
		$suwind[2] = $suwind->Step();

		# SORT data into CDP before calculating semblance
		$susort->clear();
		$susort->headerword( quotemeta('cdp') );
		$susort->headerword( quotemeta('offset') );
		$susort[1] = $susort->Step();

		#=head2 GAIN DATA
		#
		# print("iSuvelan,calculated wagc = $width\n");
		# ROT 10% window length
		# data in velan is not gained
		#
		#=cut
		#
		#	$sugain->clear();
		#	$sugain->pbal( quotemeta($on) );
		#	$sugain[1] = $sugain->Step();
		#
		#	$sugain->clear();
		#	$sugain->agc( quotemeta($on) );
		#	my $width = 0.1 * $iSuvelan->{_tmax_s};
		#	$sugain->width( quotemeta($width) );
		#
		#	$sugain[2] = $sugain->Step();

=head2

  set filtering parameters 

=cut

		$sufilter->clear();
		$sufilter->freq( quotemeta( $iSuvelan->{_freq} ) );
		$sufilter[1] = $sufilter->Step();

=head2 semblance analysis

 a scaling factor is needed to match 
 scalel found in data headers
 suvelan DOES not take scaleco or scalel into consdieration
 automatically

=cut

		$suvelan->clear();

		$suvelan->number_of_velocities(
			quotemeta( $iSuvelan->{_number_of_velocities} ) );

		$suvelan->velocity_increment(
			quotemeta(
				( $iSuvelan->{_velocity_increment} * $iSuvelan->{_data_scale} )
			)
		);
		$suvelan->first_velocity(
			quotemeta(
				( $iSuvelan->{_first_velocity} * $iSuvelan->{_data_scale} )
			)
		);
		$suvelan->anis1( quotemeta( ( $iSuvelan->{_anis1} ) ) );
		$suvelan->anis2( quotemeta( ( $iSuvelan->{_anis2} ) ) );
		$suvelan->smute( quotemeta( ( $iSuvelan->{_smute} ) ) );
		$suvelan->dtratio( quotemeta( ( $iSuvelan->{_dtratio} ) ) );
		$suvelan->nsmooth( quotemeta( ( $iSuvelan->{_nsmooth} ) ) );

		#				$suvelan->verbose(
		#			quotemeta(
		#				( $iSuvelan->{_verbose} )
		#			)
		#		);
		$suvelan->pwr( quotemeta( ( $iSuvelan->{_pwr} ) ) );

		$suvelan[1] = suvelan->Step();

=head2 DISPLAY DATA
 
 new dx_major_divisions 1-14-20

=cut

		my $time_inc_major = $iSuvelan->{_tmax_s} / 10;

		my $number_minor_time_divisions = 5;

		# to make Jorge Reyes' data work
		# my $new_dt_s            = $iSuvelan->{_tmax_s} * $iSuvelan->{_dt_s};

		# to make Daniel Lopez's data work
		#	my $s2ms     = 1000;
		#	my $new_dt_s = $s2ms * $iSuvelan->{_dt_s};

		my $dx_major_divisions = (
			$iSuvelan->{_first_velocity} + (
				$iSuvelan->{_number_of_velocities} *
				  $iSuvelan->{_velocity_increment}
			)
		) / 10;

#	print("iSuvelan,dx_major_divisions:$dx_major_divisions\n");
#	print("iSuvelan,time_inc_major: $time_inc_major\n");
#	print("iSuvelan,number_minor_time_divisions:$number_minor_time_divisions \n");
#	print("iSuvelan,tmax_s $iSuvelan->{_tmax_s}\n");
#	print("iSuvelan,new_dt_s $new_dt_s (ms)\n");

		$N = 2;
		$windowtitle[1] = '\('
		  . $N . '\)\ '
		  . $iSuvelan->{_sufile_in}
		  . '\ CDP=\ '
		  . $iSuvelan->{_cdp_num};

		#units=Semblance					\\
		$suximage->clear();
		$suximage->box_width( quotemeta(300) );
		$suximage->box_height( quotemeta(450) );
		$suximage->box_X0( quotemeta(600) );
		$suximage->box_Y0( quotemeta(0) );
		$suximage->title( quotemeta( $iSuvelan->{_cdp_num_suffix} ) );
		$suximage->windowtitle( quotemeta('Semblance') );
		$suximage->ylabel( quotemeta('TWTT (s)') );
		$suximage->xlabel( quotemeta('Velocity (m/s)') );
		$suximage->legend( quotemeta($on) );
		$suximage->cmap( quotemeta('hsv1') );
		$suximage->first_x( quotemeta( $iSuvelan->{_first_velocity} ) );
		$suximage->dx( quotemeta( $iSuvelan->{_velocity_increment} ) );
		$suximage->dt_s(quotemeta($new_dt_s));
		$suximage->loclip( quotemeta( $iSuvelan->{_min_semblance} ) );
		$suximage->hiclip( quotemeta( $iSuvelan->{_max_semblance} ) );
		$suximage->verbose( quotemeta($off) );

		#print ("d2num is ($iSuvelan->{_velocity_increment})\n\n");
		$suximage->dx_major_divisions( quotemeta($dx_major_divisions) );
		$suximage->dy_minor_divisions(
			quotemeta($number_minor_time_divisions) );
		$suximage->dy_major_divisions( quotemeta($time_inc_major) );

		$suximage->tend_s( quotemeta( $iSuvelan->{_tmax_s} ) );

		#$suximage -> percent4clip(quotemeta(95.0);
		$suximage->first_tick_number_x(
			quotemeta( $iSuvelan->{_first_velocity} ) );
		$suximage->picks( $iSuvelan->{_Tvel_outbound} );

print("iSuvelan, calcNdisplay: Writing picks to $iSuvelan->{_Tvel_outbound}\n\n");

=head2 conditions
 
 when number_of_tries is >=2 
 there should be a pre-exisiting digitized
 overlay curve to plot as well

=cut

		if ( $iSuvelan->{_number_of_tries} >= 2 ) {

			print("using a curve file:\n");
			print("\t$iSuvelan->{_Tvel_inbound}\n\n");
			$suximage->curvefile( quotemeta( $iSuvelan->{_Tvel_inbound} ) )
			  ;
			my ( $ref_T_nmo, $ref_Vnmo, $num_tvel_pairs ) =
			$manage_files_by->read_2cols( \$iSuvelan->{_Tvel_inbound} );
			$suximage->npair( quotemeta($num_tvel_pairs) );
			$suximage->curvecolor( quotemeta(2) );
		}

		$suximage[1] = $suximage->Step();

		# print("$suximage[1]\n\n");

		$N = 1;

=head2  set suxwigb parameters

  In the perl module for suxwigb we should
  have (but we do not yet) an explanation of each of
  these parameters

=cut

		$suxwigb->clear();
		$suxwigb->title( quotemeta( $iSuvelan->{_sufile_in} ) );
		$suxwigb->ylabel( quotemeta('Time s') );
		$suxwigb->xlabel( quotemeta('Offset m') );
		$suxwigb->box_width( quotemeta(300) );
		$suxwigb->box_height( quotemeta(450) );
		$suxwigb->box_X0( quotemeta(875) );
		$suxwigb->box_Y0( quotemeta(0) );
		$suxwigb->absclip( quotemeta(1) );
		$suxwigb->headerword( quotemeta('offset') );
		$suxwigb->xcur( quotemeta(2) );
		$suxwigb->windowtitle( quotemeta( $iSuvelan->{_cdp_num_suffix} ) );

		#	$suxwigb->shading( quotemeta(1) );
		$suxwigb[1] = $suxwigb->Step();

=head2  DEFINE FLOW(S)

  in interactive mode:
  First time you see the image number_of_tries =0
  the suximage is not interactive ( uses '&') 
  Second, third, etc. times (number_of_tries >= 1)
  The image will halt the flow  ('wait'), to allow user to 
  make new picks

  On the other hand suxwigb does not change between the first
  and last attempt
		$sufilter[1], $to, $sugain[2],            $to,
	suwind has currently no gain
=cut

		@items = (
			$susort[1],   $in, $iSuvelan->{_inbound}, $to,
			$suwind[1],   $to, $suwind[2],            $to,
			$sufilter[1], $to, $suxwigb[1],           $go
		);
		$flow[1] = $run->modules( \@items );

=head2  do not halt flow

  print(" suximage NO HALT with num tries $iSuvelan->{_number_of_tries}\n\n");

=cut

		if ( $iSuvelan->{_number_of_tries} == 0 ) {
			@items = (
				$susort[1],   $in, $iSuvelan->{_inbound}, $to,
				$suwind[1],   $to, $suwind[2],            $to,
				$sufilter[1], $to, $suvelan[1],           $to,
				$suximage[1], $go
			);
			$flow[2] = $run->modules( \@items );
		}

=head2  do not halt flow either 

DB

  print("2.suximage WITH HALT \n");
  print("2. number of tries is  $iSuvelan->{_number_of_tries}\n\n");

#,';',' wait'); 
             #$to,$sufilter[1],$to,$suvelan[1],$to,$suximage[1],$go); 
=cut

		if ( $iSuvelan->{_number_of_tries} >= 1 ) {
			@items = (
				$susort[1],   $in, $iSuvelan->{_inbound}, $to,
				$suwind[1],   $to, $suwind[2],            $to,
				$sufilter[1], $to, $suvelan[1],           $to,
				$suximage[1], $go
			);
			$flow[2] = $run->modules( \@items );
		}

=head2
  RUN FLOW(S)
  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

		$run->flow( \$flow[1] );
		$run->flow( \$flow[2] );

=head2  LOG FLOW(S)

 TO SCREEN AND FILE

=cut

		#	print  "iSuvelan, $flow[1]\n";
		#	print  "iSuvelan, $flow[2]\n";
		#  $log->file($flow[1]);
		#  $log->file($flow[2]);
		#

	}
	else {
		print("iSuvelan, calcNdisplay, missing variables\n");
	}

}

# end of calc_display subroutine

=head2  subroutine maximum semblance to plot 


=cut

sub max_semblance {
	my ( $variable, $max_semblance ) = @_;
	$iSuvelan->{_max_semblance} = $max_semblance if defined $max_semblance;
}

=head2  subroutine minimum semblance to plot 


=cut

sub min_semblance {
	my ( $variable, $min_semblance ) = @_;
	$iSuvelan->{_min_semblance} = $min_semblance if defined $min_semblance;
}

=head2  subroutine  TV pick file in


=cut

sub Tvel_inbound {
	my ( $variable, $Tvel_inbound ) = @_;
	$iSuvelan->{_Tvel_inbound} = $Tvel_inbound if defined $Tvel_inbound;
}

=head2 

 subroutine TV pick file out

=cut

sub Tvel_outbound {
	my ( $variable, $Tvel_outbound ) = @_;
	$iSuvelan->{_Tvel_outbound} = $Tvel_outbound if defined $Tvel_outbound;
}

#end of iSuvelan

