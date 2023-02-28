package App::SeismicUnixGui::big_streams::iApply_top_mute;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iApply_top_mute
 AUTHOR: Juan Lorenzo

 DESCRIPTION:
 Purpose: Linear Top Mute of Data 
         Sept. 23, 2015: added oop functinality

 	Modification: plotting functionality added with suxwigb 
 	Modifier: Nathan Benton 
 	Date: 07/09/2017
 	Purpose: viewing both image and wiggle plots for muting purposes 
 	helps facilitate better muting of the surface wave - note that 
 	the wiggle plotting was added for this very reason - viewing the 
 	wiggle plot of each shotgather (or cmp) can sometimes be better than
 	just viewing the image plot, especially when a good or bad gain has 
 	been applied 

=head2 USE

=head2 NOTES

  TODO replace iApply_top_mute with iApply_mute with an adidtional method='purpse'

=cut

=head2 

 needed packages

=cut

use Moose;
our $VERSION = '1.0.3';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sumute';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::messages::SuMessages';

use App::SeismicUnixGui::misc::SeismicUnix
  qw($go $in $on $off $itop_mute $itemp_top_mute_picks_ $itemp_top_mute_num_points $itemp_top_mute_picks_sorted_par_ $itop_mute_par_ $suffix_su $suffix_hyphen $to);

=head2

 inherit other packages
   1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish
     Use the following classes:

=cut

my $log        = message->new();
my $run        = flow->new();
my $sufilter   = sufilter->new();
my $sugain     = sugain->new();
my $sumute     = sumute->new();
my $suwind     = suwind->new();
my $suxwigb    = suxwigb->new();
my $suximage   = suximage->new();
my $Project    = Project_config->new();
my $SuMessages = SuMessages->new();

=head2

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix
  qw($itemp_top_mute_picks_sorted_par_);

my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=head2
 
 establish just the locally scoped variables

=cut

my ( @items,    @flow,    @sugain, @sufilter, @suwind );
my ( @suximage, @suxwigb, @sumute ); #suxwigb added here by Nate B. (07/09/2017)
my ( $windowtitle, $base_caption );

=head2

  hash array of important variables used within
  this package
  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
     $itemp_top_mute_picks_sorted_par_.$iApply_top_mute->{_file_in}

=cut

my $iApply_top_mute = {
	_gather_num      => '',
	_gather_header   => '',
	_offset_type     => '',
	_file_in         => '',
	_freq            => '',
	_inbound         => '',
	_message_type    => '',
	_ntaper          => '',
	_number_of_tries => '',
	_textfile_in     => '',
	_parfile_in      => '',
};

=head2

 subroutine clear
         to blank out hash array values

=cut

sub clear {
	$iApply_top_mute->{_gather_num}      = '';
	$iApply_top_mute->{_file_in}         = '';
	$iApply_top_mute->{_freq}            = '';
	$iApply_top_mute->{_inbound}         = '';
	$iApply_top_mute->{_message_type}    = '';
	$iApply_top_mute->{_gather_header}   = '';
	$iApply_top_mute->{_offset_type}     = '';
	$iApply_top_mute->{_ntaper}          = '';
	$iApply_top_mute->{_number_of_tries} = '';
	$iApply_top_mute->{_file_in}         = '';
	$iApply_top_mute->{_parfile_in}      = '';
	$iApply_top_mute->{_textfile_in}     = '';
}

=head2 subroutine gather_header

  define the header for the xmute values
  binheader type value helps define the xmute values
  e.g. if gather_header = 'gather'
             the the xmute values are 'offset'

=cut

sub gather_header {
	my ( $variable, $gather_header ) = @_;
	$iApply_top_mute->{_gather_header} = $gather_header
	  if defined($gather_header);

	#print(" header type is $iApply_top_mute->{_gather_header}\n\n");
}

=head2 subroutine offset_type

  define the header for the xmute values
  offset type value helps define the xmute values
  e.g. if offset_type = 'gather'
             the the xmute values are 'offset'

=cut

sub offset_type {
	my ( $variable, $offset_type ) = @_;
	$iApply_top_mute->{_offset_type} = $offset_type if defined($offset_type);

	print(" header type is $iApply_top_mute->{_offset_type}\n\n");
}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
	my ( $variable, $gather_num ) = @_;
	$iApply_top_mute->{_gather_num} = $gather_num if defined($gather_num);
}

=head2

 subroutine freq
  creates the bandpass frequencies to filter data
   e.g., "3,6,40,50"
 
=cut

sub freq {
	my ( $variable, $freq ) = @_;
	$iApply_top_mute->{_freq} = $freq if defined($freq);

	#print("freq is $iApply_top_mute->{_freq}\n\n");
}

=head2

 subroutine file_in
 Required file name
 on which to apply top mute values

=cut

sub file_in {
	my ( $variable, $file_in ) = @_;
	$iApply_top_mute->{_file_in} = $file_in if defined($file_in);
	$iApply_top_mute->{_inbound} =
	  $DATA_SEISMIC_SU . '/' . $iApply_top_mute->{_file_in} . $suffix_su;
}

=head2

 subroutine minumum amplitude to plot 

=cut

sub min_amplitude {
	my ( $variable, $min_amplitude ) = @_;
	$iApply_top_mute->{_min_amplitude} = $min_amplitude
	  if defined($min_amplitude);

	#print("min_amplitude is $iApply_top_mute->{_min_amplitude}\n\n");
}

=head2

 subroutine maximum amplitude to plot 

=cut

sub max_amplitude {
	my ( $variable, $max_amplitude ) = @_;
	$iApply_top_mute->{_max_amplitude} = $max_amplitude
	  if defined($max_amplitude);

	#print("max_amplitude is $iApply_top_mute->{_max_amplitude}\n\n");
}

=head2 subroutine calcNdisplay

  main processing flow
  calculate mute and display results 

=cut

sub calcNdisplay {

	# print("iApply_top_mute, made it \n\n");

=head2

  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
     $itemp_top_mute_picks_sorted_par_.$iApply_top_mute->{_file_in}

=cut 

	$iApply_top_mute->{_parfile_in} =
	  $itemp_top_mute_picks_sorted_par_ . $iApply_top_mute->{_file_in};

#	print(
#		"iApply_top_mute, mute pick file is $iApply_top_mute->{_parfile_in}\n\n"
#	);

=head2

 MUTE  DATA by  

=cut

	$sumute->clear();
	$sumute->par_directory('PL_SEISMIC');
	$sumute->par_file( $iApply_top_mute->{_parfile_in} );
	$sumute->offset_word( $iApply_top_mute->{_offset_type} );

	# not taper applied
	# $sumute ->ntaper($iApply_top_mute->{_ntaper});
	$sumute->type('top');
	$sumute[1] = $sumute->Step();

=head2

 WINDOW  DATA   

=cut

	$suwind->clear();
	$suwind->setheaderword( $iApply_top_mute->{_gather_header} );
	$suwind->min( $iApply_top_mute->{_gather_num} );
	$suwind->max( $iApply_top_mute->{_gather_num} );

	# print("gather num is $iApply_top_mute->{_gather_num}\n\n");
	$suwind[1] = $suwind->Step();

	$suwind->clear();

	#$suwind   		-> setheaderword('time');
	$suwind->tmin(0);
	$suwind->tmax(1);
	$suwind[2] = $suwind->Step();

=head2

  set filtering parameters 

=cut

	$sufilter->clear();
	$sufilter->freq( $iApply_top_mute->{_freq} );
	$sufilter[1] = $sufilter->Step();

=head2

 GAIN DATA

=cut

	$sugain->clear();
	$sugain->pbal($on);
	$sugain[1] = $sugain->Step();

	$sugain->clear();
	$sugain->agc($on);
	$sugain->width(0.1);

	# $sugain     -> setdt(1000);
	$sugain[2] = $sugain->Step();

#	$sugain->clear();
#	$sugain->tpower(1.8);
#	$sugain[3] = $sugain->Step();

=head2

 DISPLAY DATA (SUXIMAGE)

=cut

	$base_caption =
		$iApply_top_mute->{_file_in}
	  . quotemeta(' f=')
	  . $iApply_top_mute->{_freq};
	$windowtitle =
		$iApply_top_mute->{_gather_header}
	  . quotemeta(' = ')
	  . $iApply_top_mute->{_gather_num};

	$suximage->clear();
	$suximage->box_width(500);
	$suximage->box_height(700);
	$suximage->box_X0(100);
	$suximage->box_Y0(200);
	$suximage->title($base_caption);
	$suximage->windowtitle($windowtitle);
	$suximage->ylabel( quotemeta('TWTTs') );
	$suximage->xlabel( $iApply_top_mute->{_offset_type} );
	$suximage->legend($on);
	$suximage->cmap('rgb0');
	$suximage->loclip( $iApply_top_mute->{_min_amplitude} );
	$suximage->hiclip( $iApply_top_mute->{_max_amplitude} );
	$suximage->verbose($off);
	$suximage[1] = $suximage->Step();

=head2

 DISPLAY DATA (SUXWIGB) 

=cut

	$base_caption =
		$iApply_top_mute->{_file_in}
	  . quotemeta(' f=')
	  . $iApply_top_mute->{_freq};
	$windowtitle =
		$iApply_top_mute->{_gather_header}
	  . quotemeta(' = ')
	  . $iApply_top_mute->{_gather_num};

	$suxwigb->clear();
	$suxwigb->box_width(500);
	$suxwigb->box_height(700);
	$suxwigb->box_X0(700);
	$suxwigb->box_Y0(200);
	$suxwigb->title($base_caption);
	$suxwigb->windowtitle($windowtitle);
	$suxwigb->ylabel( quotemeta('TWTTs') );
	$suxwigb->xlabel( $iApply_top_mute->{_offset_type} );
	$suxwigb->clip('1.5');    #clip/perc set manually
	$suxwigb->verbose($off);
	$suxwigb[1] = $suxwigb->Step();

=head2
 
  DEFINE FLOW(S) - for both suximage AND suxwigb 

=cut

#save copy for below
#@items   = ($suwind[1],$in,$iApply_top_mute->{_inbound},$to,$suwind[2],$to,$sumute[1],$to,$sufilter[1],$to,$suximage[1],$go);

	#for suximage
	@items = (
		$suwind[1],
		$in, $iApply_top_mute->{_inbound},
		$to, $suwind[2],
		$to, $sumute[1],
		$to, $sugain[2],
		$to, $suximage[1],
		$go
	);

	$flow[1] = $run->modules( \@items );

	#for suxwigb
	@items = (
		$suwind[1], 
		$in, $iApply_top_mute->{_inbound},
		$to, $suwind[2], 
		$to, $sumute[1], 
		$to, $sugain[2], 
		$to, $suxwigb[1],
		$go
	);
	$flow[2] = $run->modules( \@items );

=head2

  RUN FLOW(S)
  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

	#for suximage
	$run->flow( \$flow[1] );

	#for suxwigb
	$run->flow( \$flow[2] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

	#for suximage
	#print("iApply_top_mute:$flow[1]\n");
	$log->file( $flow[1] );

	#for suxwigb
#	print "iApply_top_mute: $flow[2]\n";

}    # end calcNdisplay subroutine

1;
