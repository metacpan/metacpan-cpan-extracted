package App::SeismicUnixGui::big_streams::iSelect_xt;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iSelect_xt.pm
 AUTHOR: Juan Lorenzo
 DATE:   June 16 2019

 DESCRIPTION:
 plot data to select X-T values
 
 Based on iSelect_xt_top3.pm
 from  August 2016, V 3.1 

=head2 USE

=head3 NOTES 

=head4 

 Examples

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::specs::big_streams::iPick_specD';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $go $in $true
  $false $itemp_picks_
  $suffix_su $to);

=head2 Instantiate 

 other packages
   1. Instantiate classes 
   Create a new version of the package
   Personalize to give it a new name if you wish
   Use the following classes:

=cut

my $control    = control->new();
my $log        = message->new();
my $run        = flow->new();
my $sufilter   = sufilter->new();
my $sugain     = sugain->new();
my $suwind     = suwind->new();
my $suxwigb    = suxwigb->new();
my $suximage   = suximage->new();
my $SuMessages = SuMessages->new();
my $Project    = Project_config->new();

my $get        = L_SU_global_constants->new();
my $iPick_specD = iPick_specD->new();

my $variables      = $iPick_specD->variables();
my $DATA_DIR_IN    = $variables->{_DATA_DIR_IN};
my $DATA_DIR_OUT   = $variables->{_DATA_DIR_OUT};
my $data_suffix_in = $variables->{_data_suffix_in};

my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
my $var               = $get->var();
my $empty_string      = $var->{_empty_string};
my $purpose           = $get->purpose();

=head2 Establish
 
 just the locally scoped variables

=cut

my ( @parfile_in,  @file_in, @suffix, @inbound );
my ( @suwind_min,  @suwind_max );
my ( @items,       @flow, @sugain, @sufilter, @suwind );
my ( @suximage,    @suxwigb );
my ( @windowtitle, @base_caption );

=head2  hash array 

 of important variables used within
  this package

=cut 

my $iSelect_xt = {
	_TX_outbound     => '',
	_gather_header   => '',
	_error_freq      => $false,
	_gather_num      => '',
	_gather_type     => '',
	_file_in         => '',
	_freq            => '',
	_inbound         => '',
	_max_amplitude   => '',
	_max_x1          => '',
	_min_amplitude   => '',
	_min_x1          => '',
	_message_type    => '',
	_number_of_tries => '',
	_offset_type     => '',
	_purpose         => '',
	_textfile_in     => ''
};

=head2  sub clear

   to blank out hash array values      
   _number_of_tries		=> '',

=cut

sub clear {

	$iSelect_xt->{_TX_outbound}     = '';
	$iSelect_xt->{_gather_header}   = '';
	$iSelect_xt->{_error_freq}      = $false;
	$iSelect_xt->{_file_in}         = '';
	$iSelect_xt->{_gather_type}     = '';
	$iSelect_xt->{_freq}            = '';
	$iSelect_xt->{_gather_num}      = '';
	$iSelect_xt->{_inbound}         = '';
	$iSelect_xt->{_max_amplitude}   = '';
	$iSelect_xt->{_max_x1}          = '';
	$iSelect_xt->{_min_amplitude}   = '';
	$iSelect_xt->{_min_x1}          = '';
	$iSelect_xt->{_message_type}    = '';
	$iSelect_xt->{_number_of_tries} = '';
	$iSelect_xt->{_offset_type}     = '';
	$iSelect_xt->{_purpose}         = '';
	$iSelect_xt->{_textfile_in}     = '';

}

=head2 subroutine calcNdisplay 

 main processing flow
  calculate mute and display results 

=cut

sub calcNdisplay {

	my ($self) = @_;

	# SORT a TEXT FILE
	my @sort;
	$sort[1] = (
		" sort 			\\
		-n								\\
		"
	);

=head2 GAIN 
     
 DATA

=cut

	$sugain->clear();
	$sugain->pbal($on);
	$sugain[1] = $sugain->Step();

	$sugain->clear();
	$sugain->agc($on);
	$sugain->width(0.1);
	$sugain[2] = $sugain->Step();

	$sugain->clear();
	$sugain->tpower(3);
	$sugain[3] = $sugain->Step();

=head2 FILTER DATA
  
=cut

	if ( defined $iSelect_xt->{_freq}
		&& $iSelect_xt->{_freq} ne $empty_string )
	{

		# print("iSelect_xt, sufilter frequencies:  $iSelect_xt->{_freq}\n");
		$sufilter->clear();
		$sufilter->freq( $iSelect_xt->{_freq} );
		$sufilter[1] = $sufilter->Step();

	}
	elsif ( not defined $iSelect_xt->{_freq}
		or $iSelect_xt->{_freq} eq $empty_string )
	{

		$iSelect_xt->{_error_freq} = $true;
#		print("iSelect_xt, missing frequencies -- warning\n");

	}
	else {
		print("iSelect_xt, missing frequencies -- warning \n");
	}

=head2 WINDOW  DATA 

 by  

=cut

	$suwind->clear();
	$suwind->setheaderword( $iSelect_xt->{_gather_header} );
	$suwind->min( $iSelect_xt->{_gather_num} );
	$suwind->max( $iSelect_xt->{_gather_num} );

	# print("gather num is $iSelect_xt->{_gather_num}\n\n");
	$suwind[1] = $suwind->Step();

	$suwind->clear();
	$suwind->tmin( $iSelect_xt->{_min_x1} );
	$suwind->tmax( $iSelect_xt->{_max_x1} );
	$suwind[2] = $suwind->Step();

=head2 DISPLAY Suximage

 DATA

=cut

	$base_caption[1] =
		$iSelect_xt->{_file_in}
	  . quotemeta(' ')
	  . quotemeta('f=')
	  . $iSelect_xt->{_freq};
	$windowtitle[1] = quotemeta('GATHER = ') . $iSelect_xt->{_gather_num};

	$suximage->clear();
	$suximage->box_width(400);
	$suximage->box_height(600);
	$suximage->box_X0(200);
	$suximage->box_Y0(150);
	$suximage->title( $base_caption[1] );
	$suximage->windowtitle( $windowtitle[1] );
	$suximage->ylabel( quotemeta('TWTT s') );
	$suximage->xlabel( $iSelect_xt->{_offset_type} );
	$suximage->legend($on);
	$suximage->cmap('hsv2');
	$suximage->loclip( $iSelect_xt->{_min_amplitude} );
	$suximage->hiclip( $iSelect_xt->{_max_amplitude} );

	# purposes can refine the style of plots
	# geopsy plot preference for JML
	if (    length $iSelect_xt->{_purpose}
		and $iSelect_xt->{_purpose} eq 'geopsy'
		and $iSelect_xt->{_max_x1} > $iSelect_xt->{_min_x1} )
	{

		$suximage->x1beg( $iSelect_xt->{_max_x1} );
		$suximage->x1end( $iSelect_xt->{_min_x1} );

		#		print("iSelect_xt, \n");

	}
	else {
		$suximage->x1beg( $iSelect_xt->{_min_x1} );
		$suximage->x1end( $iSelect_xt->{_max_x1} );
	}

	$suximage->verbose($off);

=item
 
	choose to save picks
 
=cut

	if ( $iSelect_xt->{_number_of_tries} > 0 ) {

		$iSelect_xt->{_TX_outbound} = $itemp_picks_ . $iSelect_xt->{_file_in};
		$suximage->picks( $DATA_DIR_OUT . '/' . $iSelect_xt->{_TX_outbound} );

# print("iSelect_xt, suximage, writing picks to $itemp_picks_$iSelect_xt->{_file_in} \n");
# print("iSelect_xt, suximage, PATH: $DATA_DIR_OUT \n\n");
# print("number of tries is $iSelect_xt->{_number_of_tries} \n\n");
	}
	$suximage[1] = $suximage->Step();

=head2 DISPLAY suxwigb

 DATA

=cut

	$base_caption[2] =
		$iSelect_xt->{_file_in}
	  . quotemeta('  ')
	  . quotemeta('f=')
	  . $iSelect_xt->{_freq};
	$windowtitle[2] = quotemeta('GATHER = ') . $iSelect_xt->{_gather_num};

	$suxwigb->clear();
	$suxwigb->box_width( quotemeta(400) );
	$suxwigb->box_height( quotemeta(600) );
	$suxwigb->box_X0( quotemeta(750) );
	$suxwigb->box_Y0( quotemeta(150) );
	$suxwigb->title( $base_caption[2] );
	$suxwigb->windowtitle( $windowtitle[2] );
	$suxwigb->ylabel( quotemeta('TWTT s') );
	$suxwigb->xlabel( $iSelect_xt->{_offset_type} );
	$suxwigb->loclip( $iSelect_xt->{_min_amplitude} );
	$suxwigb->hiclip( $iSelect_xt->{_max_amplitude} );

	# purposes can refine the style of plots
	# geopsy plot preference for JML
	if (    length $iSelect_xt->{_purpose}
		and $iSelect_xt->{_purpose} eq 'geopsy'
		and $iSelect_xt->{_max_x1} > $iSelect_xt->{_min_x1} )
	{

		$suxwigb->x1beg( $iSelect_xt->{_max_x1} );
		$suxwigb->x1end( $iSelect_xt->{_min_x1} );

		#		print("iSelect_xt, suxwigb with \'geopsy\' purpose\n");

	}
	else {
		$suxwigb->x1beg( $iSelect_xt->{_min_x1} );
		$suxwigb->x1end( $iSelect_xt->{_max_x1} );
	}
	$suxwigb->verbose($off);

=item choose to save picks
 
=cut

	if ( $iSelect_xt->{_number_of_tries} > 0 ) {

		$iSelect_xt->{_TX_outbound} = $itemp_picks_ . $iSelect_xt->{_file_in};
		$suxwigb->picks( $DATA_DIR_OUT . '/' . $iSelect_xt->{_TX_outbound} );

# print("iSelect_xt, suxwigb, writing picks to $itemp_picks_$iSelect_xt->{_file_in} \n");
# print("iSelect_xt, suxwigb, PATH: $DATA_DIR_OUT \n\n");
# print("number of tries is $iSelect_xt->{_number_of_tries} \n\n");
	}

	$suxwigb[1] = $suxwigb->Step();

=head2 DEFINE FLOW(S)

In interactive mode:
First time you see the image, number_of_tries =0
For second, third ... times, number_of_tries >0
The pick file can be saved

=cut

	if ( defined $iSelect_xt->{_purpose}
		and $iSelect_xt->{_purpose} ne $empty_string )
	{
		# CASE 1: With GEOPSY purpose

		if (   $iSelect_xt->{_purpose} eq $purpose->{_geopsy}
			&& $iSelect_xt->{_error_freq} eq $true )
		{

			# CASE 1A: With geopsy and no filter
#			$sugain[1],              $to,
			@items = (
				$suwind[1],  $in, $iSelect_xt->{_inbound}, $to,
				$suwind[2],  $to, 
				$suxwigb[1], $go
			);
			$flow[1] = $run->modules( \@items );

#			print("iSelect_xt,  CASE1: \n $flow[1]\n");
#							$sugain[1],              $to,
			@items = (
				$suwind[1],              $in,
				$iSelect_xt->{_inbound}, $to,
				$suwind[2],              $to,
				$suximage[1],
				$go
			);
			$flow[2] = $run->modules( \@items );

		}
		elsif ($iSelect_xt->{_purpose} eq $purpose->{_geopsy}
			&& $iSelect_xt->{_error_freq} eq $false )
		{

			# CASE 2: With geopsy and  filter
			@items = (
				$suwind[1],  $in,
				$iSelect_xt->{_inbound}, $to,
				$suwind[2],  $to, $sufilter[1],$to,
				$suxwigb[1], $go
			);
			$flow[1] = $run->modules( \@items );
#			print("iSelect_xt, CASE2: \n $flow[1]\n");

# 				$sugain[1], $to, 
			@items = (
				$suwind[1], $in, 
				$iSelect_xt->{_inbound},$to,
				$suwind[2], $to, 
				$sufilter[1],$to,
				$suximage[1],
				$go
			);
			$flow[2] = $run->modules( \@items );

		}
		else {
			# CASE 1 Error catch
			#			print("CASE 1 iSelect_xt, purpose:$iSelect_xt->{_purpose}\n");
			my $ans = $iSelect_xt->{_error_freq};

			#	print("CASE 1 iSelect_xt, _error: $ans\n");
			#	print("CASE 1 iSelect_xt, missing purpose and/or error_freq\n");
		}

	}

	# CASE 2A: No purpose, with filter
	elsif (
		(
			not( defined $iSelect_xt->{_purpose} )
			|| $iSelect_xt->{_purpose} eq $empty_string
		)
		&& $iSelect_xt->{_error_freq} eq $false
	  )
	{

		@items = (
			$suwind[1], $in, $iSelect_xt->{_inbound}, $to,
			$suwind[2], $to, $sufilter[1],            $to,
			$sugain[1], $to, $suxwigb[1],             $go
		);
		$flow[1] = $run->modules( \@items );

		# print("iSelect_xt,  CASE 2: $flow[1]\n");
#$sugain[1], $to, 
		@items = (
			$suwind[1], $in, $iSelect_xt->{_inbound}, $to,
			$suwind[2], $to, $sufilter[1],            $to,
			$suximage[1],            $go
		);

		$flow[2] = $run->modules( \@items );

	}
	else {
#  print("2. iSelect_xt, purpose:---$iSelect_xt->{_purpose}---\n");
  # print("2. iSelect_xt, error_freq:---$iSelect_xt->{_error_freq}---\n");
  #		print("2. iSelect_xt, missing purpose and/or error in filter frequencies");
	}

=head2 RUN FLOW(S)

  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

	# for suxwigb
	$run->flow( \$flow[1] );

	# for suximage
	$run->flow( \$flow[2] );

=head2 LOG FLOW(S)

 TO SCREEN AND FILE

=cut

#	print "$flow[1]\n";
	# $log->file($flow[1]);

#	print  "$flow[2]\n";
	# $log->file($flow[2]);

}    # end calcNdisplay subroutine

=head2  sub gather_header

  define the message family to use

=cut

sub gather_header {
	my ( $self, $type ) = @_;

	if ( defined $type && $type ne $empty_string ) {

		# e.g. 'sp1' becomes sp1
		# print("1. iSelect_xt, gather_header: $type \n");

		control->set_infection($type);
		$type = control->get_ticksBgone();
		$iSelect_xt->{_gather_header} = $type;

	  # print("2. iSelect_xt, gather_header: $iSelect_xt->{_gather_header} \n");

	}
	else {
		print("iSelect_xt, gather_header: unexpected value \n\n");
	}
}

=head2  sub file_in

 Required file name
 on which to pick  mute values
 print("$iSelect_xt->{_inbound}\n\n");
 
=cut

sub file_in {

	my ( $self, $file_in ) = @_;

	if ( defined $file_in
		&& $file_in ne $empty_string )
	{

		# e.g. 'sp1' becomes sp1
		$control->set_infection($file_in);
		$file_in = control->get_ticksBgone();
		$iSelect_xt->{_file_in} = $file_in;
		$iSelect_xt->{_inbound} =
		  $DATA_DIR_IN . '/' . $iSelect_xt->{_file_in} . $data_suffix_in;

		# print("iSelect_xt, file_in: $iSelect_xt->{_file_in} \n");

	}
	else {
		print("iSelect_xt, file_in: unexpected file_in \n");
	}
}

=head2  sub freq

  creates the bandpass frequencies to filter data before
  conducting semblance analysis
  e.g., "3,6,40,50"
 
=cut

sub freq {
	my ( $self, $freq ) = @_;
	$iSelect_xt->{_freq} = $freq if defined($freq);

	# print("iSelect_xt, freq is $iSelect_xt->{_freq}\n\n");
}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
	my ( $self, $gather_num ) = @_;
	$iSelect_xt->{_gather_num} = $gather_num if defined($gather_num);
}

=head2  sub gather_type

  define the message family to use

=cut

sub gather_type {

	my ( $self, $type ) = @_;

	if ( $type && $type ne $empty_string ) {

		# e.g. 'sp1' becomes sp1
		$control->set_infection($type);
		$type = control->get_ticksBgone();

		$iSelect_xt->{_gather_type} = $type;

		# print("1. iSelect_xt,gather_type, $iSelect_xt->{_gather_type}\n");

	}
	else {
		print("iSelect_xt,gather_type,missing gather_type\n");
	}
	return ();
}

=head2  sub max_amplitude

 maximum amplitude to plot 

=cut

sub max_amplitude {
	my ( $self, $max_amplitude ) = @_;
	$iSelect_xt->{_max_amplitude} = $max_amplitude if defined($max_amplitude);

	# print("max_amplitude is $iSelect_xt->{_max_amplitude}\n\n");
}

=head2  sub max_x1

 maximum time/Hz to plot 

=cut

sub max_x1 {
	my ( $self, $max_x1 ) = @_;

	if ( length $max_x1 ) {

		$iSelect_xt->{_max_x1} = $max_x1;

		# print("max_x1 is $iSelect_xt->{_max_x1}\n\n");

	}
	else {
		print("iSelect_xt, max_x1, value missing\n");
	}
	return ();
}

=head3  sub min_amplitude

 minumum amplitude to plot 

=cut

sub min_amplitude {

	my ( $self, $min_amplitude ) = @_;
	$iSelect_xt->{_min_amplitude} = $min_amplitude if defined($min_amplitude);

	# print("min_amplitude is $iSelect_xt->{_min_amplitude}\n\n");
}

=head3  sub min_x1

 minumum time/ Hz to plot 

=cut

sub min_x1 {
	my ( $self, $min_x1 ) = @_;

	if ( length $min_x1 ) {

		$iSelect_xt->{_min_x1} = $min_x1;

		# print("min_x1 is $iSelect_xt->{_min_x1}\n\n");

	}
	else {
		print("iSelect_xt,min_x1, unexpected min time-s\n");
	}
}

=head2  sub number_of_tries

    keep track of the number of attempts
    at picking top mute

=cut

sub number_of_tries {
	my ( $self, $number_of_tries ) = @_;
	$iSelect_xt->{_number_of_tries} = $number_of_tries
	  if defined($number_of_tries);

	# print("num of tries is $iSelect_xt->{_number_of_tries}\n\n");
}

=head2  sub offset_type

  define the message family to use

=cut

sub offset_type {
	my ( $self, $type ) = @_;
	$iSelect_xt->{_offset_type} = $type if defined($type);

	if ( $iSelect_xt->{_offset_type} eq 'p' ) {

		$iSelect_xt->{_offset_type} = 'tracl';

	}
}

=head2  sub set_purpose 

  define where the data will need to go
  define the type of behavior
  
=cut

sub set_purpose {

	my ( $self, $type ) = @_;

	if ( defined $type
		&& $type ne $empty_string )
	{

		my $control = control->new();
		$control->set_infection($type);
		$type = control->get_ticksBgone();

		# print("iSelect_xt,set_purpose: $type\n");
		# print("iSelect_xt,set_purpose: $purpose->{_geopsy}\n");

		if ( $type eq $purpose->{_geopsy} ) {

			$iSelect_xt->{_purpose} = $type;

			# print("iSelect_xt,set_purpose: $iSelect_xt->{_purpose}\n");

		}
		else {

			# print("iSelect_xt,set_purpose is unavailable, NADA\n");
		}

	}
	else {

		# print("iSelect_xt,set_purpose value is empty NADA\n");
	}
}

=head2  sub suxwigb_defaults

 selecting if there are appropriate suxwigb defaults

=cut

sub suxwigb_defaults {
	my ( $self, $suxwigb_defaults ) = @_;
	$iSelect_xt->{_suxwigb_defaults} = $suxwigb_defaults
	  if defined($suxwigb_defaults);

	#print("num of tries is $iSelect_xt->{_suxwigb_defaults}\n\n");

}

1;
