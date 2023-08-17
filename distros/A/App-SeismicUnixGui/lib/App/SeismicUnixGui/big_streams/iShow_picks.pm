package App::SeismicUnixGui::big_streams::iShow_picks;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iShow_picks.pm
 AUTHOR: Juan Lorenzo

 DESCRIPTION:
 Purpose: display seelcted picks ontop of data	
 June 16 2019

=head2 USE

=head2 NOTES


=cut

=head2 

 needed packages

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::specs::big_streams::iPick_spec';
use aliased 'App::SeismicUnixGui::misc::manage_files_by';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::messages::SuMessages';

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $on $off $ipicks 
$itemp_picks_ $itemp_num_points
  $itemp_picks_sorted_par_ $ipicks_par_ $suffix_su $suffix_hyphen $to
  $itemp_picks_sorted_par_);

my $iPick_spec = iPick_spec->new();

my $get             = L_SU_global_constants->new();
my $control         = control->new();
my $manage_files_by = manage_files_by->new();
my $variables       = $iPick_spec->variables();
my $DATA_DIR_IN     = $variables->{_DATA_DIR_IN};
my $DATA_DIR_OUT    = $variables->{_DATA_DIR_OUT};
my $data_suffix_in  = $variables->{_data_suffix_in};
my $data_suffix_out = $variables->{_data_suffix_out};
my $var             = $get->var();
my $empty_string    = $var->{_empty_string};

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
my $suwind     = suwind->new();
my $suxwigb    = suxwigb->new();
my $suximage   = suximage->new();
my $Project    = Project_config->new();
my $SuMessages = SuMessages->new();

=head2

 Import file-name and directory definitions

=cut 

my ($PL_SEISMIC)       = $Project->PL_SEISMIC();
my ($DATA_SEISMIC_SU)  = $Project->DATA_SEISMIC_SU();
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

=head2
 
 establish just the locally scoped variables

=cut

my ( @items, @flow, @sugain, @sufilter, @suwind );
my ( @suximage, @suxwigb );
my @windowtitle;
my @base_caption;

=head2

  hash array of important variables used within
  this package
  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
  $itemp__picks_sorted_par_.$iShow_picks->{_file_in}

=cut

my $iShow_picks = {
    _gather_header      => '',
    _offset_type        => '',
    _file_in            => '',
    _freq               => '',
    _gather_num         => '',
    _inbound            => '',
    _inbound_curve_file => '',
    _message_type       => '',
    _max_amplitude      => '',
    _max_x1         => '',
    _min_amplitude      => '',
    _min_x1         => '',
    _ntaper             => '',
    _number_of_tries    => '',
    _offset_type        => '',
    _parfile_in         => '',
    _textfile_in        => '',
};

=head2

 subroutine clear
         to blank out hash array values

=cut

sub clear {
    $iShow_picks->{_gather_header}      = '';
    $iShow_picks->{_file_in}            = '';
    $iShow_picks->{_file_in}            = '';
    $iShow_picks->{_freq}               = '';
    $iShow_picks->{_gather_num}         = '';
    $iShow_picks->{_inbound}            = '';
    $iShow_picks->{_inbound_curve_file} = '',
      $iShow_picks->{_message_type}     = '';
    $iShow_picks->{_max_amplitude}   = '';
    $iShow_picks->{_max_x1}      = '';
    $iShow_picks->{_min_amplitude}   = '';
    $iShow_picks->{_min_x1}      = '';
    $iShow_picks->{_ntaper}          = '';
    $iShow_picks->{_number_of_tries} = '';
    $iShow_picks->{_offset_type}     = '';
    $iShow_picks->{_parfile_in}      = '';
    $iShow_picks->{_textfile_in}     = '';
}

=head2  sub _inbound_curve_file

 Required text file with x,t pairs
 
=cut

sub _inbound_curve_file {

    my ($self) = @_;

    if ( defined $iShow_picks->{_file_in} ) {

        my $file_in = $iShow_picks->{_file_in};

        $iShow_picks->{_inbound_curve_file} =
          $DATA_DIR_OUT . '/' . $itemp_picks_ . $file_in;

        # print("iShow_picks, file_in: $iShow_picks->{_file_in} \n\n");
    }
    else {
        print("iShow_picks, file_in: unexpected file_in \n\n");
    }
}

=head2 subroutine gather_header

  define the header for the x values
  binheader type value helps define the x values
  e.g. if gather_header = 'gather'
  the x values are 'offset'

=cut

sub gather_header {
    my ( $self, $gather_header ) = @_;
    $iShow_picks->{_gather_header} = $gather_header
      if defined($gather_header);

    #print(" header type is $iShow_picks->{_gather_header}\n\n");
}

=head2 subroutine calcNdisplay

  main processing flow
  display picks on top of results 

=cut

sub calcNdisplay {

=head2

  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
  $itemp_picks_sorted_par_.$iShow_picks->{_file_in}

=cut 

    $iShow_picks->{_parfile_in} =
      $itemp_picks_sorted_par_ . $iShow_picks->{_file_in};

    # SORT a TEXT FILE
    #	my @sort;
    #  	$sort[1] 		=  (" sort 			\\
    #		-n								\\
    #		");

    # print("iShow_picks, pick file is $iShow_picks->{_parfile_in}\n\n");

=head2

 WINDOW  DATA   

=cut

    $suwind->clear();
    $suwind->setheaderword( $iShow_picks->{_gather_header} );
    $suwind->min( $iShow_picks->{_gather_num} );
    $suwind->max( $iShow_picks->{_gather_num} );

    # print("gather num is $iShow_picks->{_gather_num}\n\n");
    $suwind[1] = $suwind->Step();

    $suwind->clear();
    $suwind->tmin( $iShow_picks->{_min_x1} );
    $suwind->tmax( $iShow_picks->{_max_x1} );
    $suwind[2] = $suwind->Step();

=head2

  set filtering parameters 

=cut

    $sufilter->clear();
    $sufilter->freq( $iShow_picks->{_freq} );
    $sufilter[1] = $sufilter->Step();

=head2

 GAIN DATA

=cut

    $sugain->clear();
    $sugain->pbal($on);
    $sugain[1] = $sugain->Step();

    $sugain->clear();
    $sugain->agc($on);

    # nominal agc width
    my $wagc =
      ( $iShow_picks->{_max_x1} - $iShow_picks->{_min_x1} ) / 10;

    # print("iShow_picks,calcNdisplay,wagc=$wagc\n");
    $sugain->width($wagc);
    $sugain[2] = $sugain->Step();

    $sugain->clear();
    $sugain->tpower(1.8);
    $sugain[3] = $sugain->Step();

=head2

 DISPLAY DATA (SUXIMAGE)

=cut

    $base_caption[1] =
        $iShow_picks->{_file_in}
      . quotemeta(' ')
      . quotemeta(' f=')
      . $iShow_picks->{_freq};
    $windowtitle[1] =
        $iShow_picks->{_gather_header}
      . quotemeta(' = ')
      . $iShow_picks->{_gather_num};

    $suximage->clear();
    $suximage->box_width(400);
    $suximage->box_height(600);
    $suximage->box_X0(200);
    $suximage->box_Y0(150);
    $suximage->title( $base_caption[1] );
    $suximage->windowtitle( $windowtitle[1] );
    $suximage->ylabel( quotemeta('TWTTs') );
    $suximage->xlabel( $iShow_picks->{_offset_type} );
    $suximage->legend($on);
    $suximage->cmap('rgb0');
    $suximage->loclip( $iShow_picks->{_min_amplitude} );
    $suximage->hiclip( $iShow_picks->{_max_amplitude} );
    
    # geopsy plot preference for JML
	if (    length $iShow_picks->{_purpose}
		and $iShow_picks->{_purpose} eq 'geopsy'
		and $iShow_picks->{_max_x1} > $iShow_picks->{_min_x1} ) {

		$suxwigb->x1beg( $iShow_picks->{_max_x1} );
		$suxwigb->x1end( $iShow_picks->{_min_x1} );
#		print("iShow_picks, suximage with \'geopsy\' purpose\n");
		
	} else {
		$suxwigb->x1beg( $iShow_picks->{_min_x1} );
		$suxwigb->x1end( $iShow_picks->{_max_x1} );
	}
    

    $suximage->verbose($off);

    _inbound_curve_file();

    print("iShow_picks,calc, using a curve file:\n");
    print("\t$iShow_picks->{_inbound_curve_file}\n\n");

    $suximage->curve( quotemeta( $iShow_picks->{_inbound_curve_file} ) );
    my ( $ref_T, $ref_X, $num_tx_pairs ) =
    $manage_files_by->read_2cols( \$iShow_picks->{_inbound_curve_file} );
    $suximage->npair( quotemeta($num_tx_pairs) );
    $suximage->curvecolor( quotemeta(2) );

=item choose to save picks
 
=cut

    if ( $iShow_picks->{_number_of_tries} > 0 ) {

        $iShow_picks->{_TX_outbound} = $itemp_picks_ . $iShow_picks->{_file_in};
        $suximage->picks( $DATA_DIR_OUT . '/' . $iShow_picks->{_TX_outbound} );

        print(
"iShow_picks, suximage, writing picks to $itemp_picks_$iShow_picks->{_file_in} \n"
        );

        # print("iShow_picks, suximage, PATH: $DATA_DIR_OUT \n\n");
        # print("number of tries is $iShow_picks->{_number_of_tries} \n\n");
    }

    $suximage[1] = $suximage->Step();

=head2

 DISPLAY DATA (SUXWIGB) 

=cut

    $base_caption[2] =
      $iShow_picks->{_file_in} . quotemeta(' f=') . $iShow_picks->{_freq};
    $windowtitle[2] =
        $iShow_picks->{_gather_header}
      . quotemeta(' = ')
      . $iShow_picks->{_gather_num};

    $suxwigb->clear();
    $suxwigb->box_width(400);
    $suxwigb->box_height(600);
    $suxwigb->box_X0(750);
    $suxwigb->box_Y0(150);
    $suxwigb->title( $base_caption[2] );
    $suxwigb->windowtitle( $windowtitle[2] );
    $suxwigb->ylabel( quotemeta('TWTTs') );
    $suxwigb->xlabel( $iShow_picks->{_offset_type} );
    $suxwigb->loclip( $iShow_picks->{_min_amplitude} );
    $suxwigb->hiclip( $iShow_picks->{_max_amplitude} );
    
    # geopsy plot preference for JML
	if (    length $iShow_picks->{_purpose}
		and $iShow_picks->{_purpose} eq 'geopsy'
		and $iShow_picks->{_max_x1} > $iShow_picks->{_min_x1} ) {

		$suxwigb->x1beg( $iShow_picks->{_max_x1} );
		$suxwigb->x1end( $iShow_picks->{_min_x1} );
		print("iShow_picks, suxwigb with \'geopsy\' purpose\n");
		
	} else {
		$suxwigb->x1beg( $iShow_picks->{_min_x1} );
		$suxwigb->x1end( $iShow_picks->{_max_x1} );
	}
    
    $suxwigb->verbose($off);

=head2 conditions
 
 when number_of_tries is >=2 
 there should be a pre-exisiting digitized
 overlay curve to plot as well

=cut

    _inbound_curve_file();

    # print("iShow_picks,calc, using a curve file:\n");
    # print("\t$iShow_picks->{_inbound_curve_file}\n\n");

    $suxwigb->curve( quotemeta( $iShow_picks->{_inbound_curve_file} ) );
    ( $ref_T, $ref_X, $num_tx_pairs ) =
    $manage_files_by->read_2cols( \$iShow_picks->{_inbound_curve_file} );
    $suxwigb->npair( quotemeta($num_tx_pairs) );
    $suxwigb->curvecolor( quotemeta(2) );

=item choose to save picks
 
=cut

    if ( $iShow_picks->{_number_of_tries} > 0 ) {

        $iShow_picks->{_TX_outbound} = $itemp_picks_ . $iShow_picks->{_file_in};
        $suxwigb->picks( $DATA_DIR_OUT . '/' . $iShow_picks->{_TX_outbound} );

# print("iShow_picks, suxwigb, writing picks to $itemp_picks_$iShow_picks->{_file_in} \n");
# print("iShow_picks, suxwigb, PATH: $DATA_DIR_OUT \n\n");
# print("number of tries is $iShow_picks->{_number_of_tries} \n\n");
    }

    $suxwigb[1] = $suxwigb->Step();

=head2
 
  DEFINE FLOW(S) - for both suximage AND suxwigb 

=cut

    @items = (
        $suwind[1], $in, $iShow_picks->{_inbound}, $to,
        $suwind[2], $to, $sufilter[1],             $to,
        $sugain[1], $to, $suxwigb[1],              $go
    );
    $flow[1] = $run->modules( \@items );

    @items = (
        $suwind[1], $in, $iShow_picks->{_inbound}, $to,
        $suwind[2], $to, $sufilter[1],             $to,
        $sugain[1], $to, $suximage[1],             $go
    );
    $flow[2] = $run->modules( \@items );

=head2

  RUN FLOW(S)
  
  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

    # for suxwigb
    $run->flow( \$flow[1] );

    # for suximage
    $run->flow( \$flow[2] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    # for suxwigb
    # print  "$flow[1]\n";
    #$log->file($flow[1]);

    #for suximage
    # print  "$flow[2]\n";

}    # end calcNdisplay subroutine

=head2  sub file_in

 Required sunix file name
 on which to pick  mute values
 print("$iShow_picks->{_inbound}\n\n");
 
=cut

sub file_in {

    my ( $self, $file_in ) = @_;

    if ( defined $file_in ) {

        # e.g. 'sp1' becomes sp1
        $control->set_infection($file_in);
        $file_in = control->get_ticksBgone();
        $iShow_picks->{_file_in} = $file_in if defined($file_in);
        $iShow_picks->{_inbound} =
          $DATA_DIR_IN . '/' . $file_in . $data_suffix_in;

        # print("iShow_picks, file_in: $iShow_picks->{_file_in} \n\n");
    }
    else {
        print("iShow_picks, file_in: unexpected file_in \n\n");
    }
}

=head2

 subroutine freq
  creates the bandpass frequencies to filter data
   e.g., "3,6,40,50"
 
=cut

sub freq {
    my ( $self, $freq ) = @_;
    $iShow_picks->{_freq} = $freq if defined($freq);

    # print("freq is $iShow_picks->{_freq}\n\n");
}

=head2 subroutine gather

  sets gather number to consider      

=cut

sub gather_num {
    my ( $self, $gather_num ) = @_;
    $iShow_picks->{_gather_num} = $gather_num if defined($gather_num);
}

=head2

 subroutine maximum amplitude to plot 

=cut

sub max_amplitude {
    my ( $self, $max_amplitude ) = @_;
    $iShow_picks->{_max_amplitude} = $max_amplitude
      if defined($max_amplitude);

    # print("max_amplitude is $iShow_picks->{_max_amplitude}\n\n");
}

=head2

 subroutine minumum amplitude to plot 

=cut

sub min_amplitude {
    my ( $self, $min_amplitude ) = @_;
    $iShow_picks->{_min_amplitude} = $min_amplitude
      if defined($min_amplitude);

    # print("min_amplitude is $iShow_picks->{_min_amplitude}\n\n");

}

=head2  sub max_x1

 maximum time/Hz to plot 

=cut

sub max_x1 {
	my ( $self, $max_x1 ) = @_;

	if ( length $max_x1 ) {

		$iShow_picks->{_max_x1} = $max_x1;

		# print("max_x1 is $iShow_picks->{_max_x1}\n\n");

	} else {
		print("iShow_picks, max_x1, value missing\n");
	}
	return ();
}

=head3  sub min_x1

 minumum time/Hz to plot 

=cut

sub min_x1 {
	my ( $self, $min_x1 ) = @_;

	if ( length $min_x1 ) {

		$iShow_picks->{_min_x1} = $min_x1;

		# print("min_x1 is $iShow_picks->{_min_x1}\n\n");

	} else {
		print("iShow_picks,min_x1, unexpected min time-s\n");
	}
}

=head2  sub number_of_tries

    keep track of the number of attempts
    at picking top mute

=cut

sub number_of_tries {
    my ( $self, $number_of_tries ) = @_;
    $iShow_picks->{_number_of_tries} = $number_of_tries
      if defined($number_of_tries);

    # print("num of tries is $iShow_picks->{_number_of_tries}\n\n");
}

=head2 subroutine offset_type

  define the header for the x values
  offset type value helps define the x values
  e.g. if offset_type = 'gather'
  the x values are 'offset'

=cut

sub offset_type {
    my ( $self, $offset_type ) = @_;
    
    $iShow_picks->{_offset_type} = $offset_type if defined($offset_type);

    print(" header type is $iShow_picks->{_offset_type}\n\n");
}

1;
