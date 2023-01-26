package App::SeismicUnixGui::big_streams::iApply_mute;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME: iApply_mute
 AUTHOR: Juan Lorenzo

 DESCRIPTION:
 Purpose: Mute of Data 

=head2 USE

=head2 NOTES 
  Derives from iApply_top_mute.pm V3 Sept. 23, 2015:

=head4 
 Examples

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::manage_files_by';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::readfiles';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sumute';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::messages::SuMessages';

use App::SeismicUnixGui::misc::SeismicUnix
  qw($go $in $out $on $off $itop_mute $itemp_top_mute_picks_ 
  $itemp_top_mute_num_points $itemp_top_mute_picks_sorted_par_ 
  $itop_mute_par_ $suffix_su $suffix_hyphen $to);

=head2

 inherit other packages
   1. Instantiate classes 
       Create a new version of the package
       Personalize to give it a new name if you wish
     Use the following classes:

=cut

my $log        = message->new();
my $read       = readfiles->new();
my $run        = flow->new();
my $sufilter   = sufilter->new();
my $sugain     = sugain->new();
my $sumute     = sumute->new();
my $suwind     = suwind->new();
my $suxwigb    = suxwigb->new();
my $suximage   = suximage->new();
my $SuMessages = SuMessages->new();
my $Project    = Project_config->new();

=head2

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($itemp_top_mute_picks_sorted_par_);
my ($PL_SEISMIC)      = $Project->PL_SEISMIC();
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=head2
 
 establish just the locally scoped variables

=cut

my ( @items, @flow, @sugain, @sufilter, @suwind );
my ( @suximage, @suxwigb, @sumute );
my ( $windowtitle, $base_caption );

=head2

  hash array of important variables used within
  this package
  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
     $itemp_top_mute_picks_sorted_par_.$iApply_mute->{_file_in}

=cut

my $iApply_mute = {
    _gather_num      => '',
    _gather_header   => '',
    _offset_type     => '',
    _file_in         => '',
    _freq            => '',
    _inbound         => '',
    _message_type    => '',
    _purpose         => '',
    _number_of_tries => '',
    _outbound        => '',
    _textfile_in     => '',
    _parfile_in      => ''
};

=head2

 subroutine clear
         to blank out hash array values

=cut

sub clear {
    $iApply_mute->{_gather_num}      = '';
    $iApply_mute->{_file_in}         = '';
    $iApply_mute->{_freq}            = '';
    $iApply_mute->{_inbound}         = '';
    $iApply_mute->{_message_type}    = '';
    $iApply_mute->{_gather_header}   = '';
    $iApply_mute->{_offset_type}     = '';
    $iApply_mute->{_number_of_tries} = '';
    $iApply_mute->{_outbound}        = '';
    $iApply_mute->{_purpose}         = '';
    $iApply_mute->{_parfile_in}      = '';
    $iApply_mute->{_textfile_in}     = '';
}

=head2 subroutine gather_header

  define the header for the xmute values
  binheader type value helps define the xmute values
  e.g. if gather_header = 'gather'
  the the xmute values are 'offset'

=cut

sub gather_header {
    my ( $variable, $gather_header ) = @_;
    $iApply_mute->{_gather_header} = $gather_header
      if defined($gather_header);

    #print(" header type is $iApply_mute->{_gather_header}\n\n");
}

=head2 subroutine offset_type

  define the header for the xmute values
  offset type value helps define the xmute values
  e.g. if offset_type = 'gather'
  the the xmute values are 'offset'

=cut

sub offset_type {
    my ( $variable, $offset_type ) = @_;
    $iApply_mute->{_offset_type} = $offset_type if defined($offset_type);

    #print(" header type is $iApply_mute->{_offset_type}\n\n");
}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
    my ( $variable, $gather_num ) = @_;
    $iApply_mute->{_gather_num} = $gather_num if defined($gather_num);
}

=head2

 subroutine freq
 creates the bandpass frequencies to filter data
 e.g., "3,6,40,50"
 
=cut

sub freq {
    my ( $variable, $freq ) = @_;
    $iApply_mute->{_freq} = $freq if defined($freq);

    #print("freq is $iApply_mute->{_freq}\n\n");
}

=head2

 subroutine file_in
 Required file name
 on which to apply top mute values
 print(" iApply inbound is $iApply_mute->{_inbound}\n\n");

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    if ( defined($file_in) ) {
        $iApply_mute->{_file_in} = $file_in;
        print(" file in is $iApply_mute->{_file_in} in iApply_Mute\n\n");
        $iApply_mute->{_inbound} =
            $DATA_SEISMIC_SU . '/'
          . $iApply_mute->{_file_in} . '_'
          . $iApply_mute->{_gather_type}
          . $iApply_mute->{_gather_num}
          . $suffix_su;

        $iApply_mute->{_outbound} =
            $DATA_SEISMIC_SU . '/'
          . $iApply_mute->{_file_in} . '_'
          . $iApply_mute->{_gather_type}
          . $iApply_mute->{_gather_num} . '_mute'
          . $suffix_su;
        print(" iApply outbound is $iApply_mute->{_outbound}\n\n");
    }
}

=head2 subroutine gather_type

  sets gather type to consider 
  e.g., 'ep', 'cdp', etc. 

=cut

sub gather_type {
    my ( $variable, $gather_type ) = @_;
    $iApply_mute->{_gather_type} = $gather_type if defined($gather_type);
}

=head2

 subroutine minumum amplitude to plot 

=cut

sub min_amplitude {
    my ( $variable, $min_amplitude ) = @_;
    $iApply_mute->{_min_amplitude} = $min_amplitude
      if defined($min_amplitude);

    #print("min_amplitude is $iApply_mute->{_min_amplitude}\n\n");
}

=head2

 subroutine maximum amplitude to plot 

=cut

sub max_amplitude {
    my ( $variable, $max_amplitude ) = @_;
    $iApply_mute->{_max_amplitude} = $max_amplitude
      if defined($max_amplitude);

    #print("max_amplitude is $iApply_mute->{_max_amplitude}\n\n");
}

=head2 subroutine purpose

 are the picks for a future top mute
 or a future bottom mute ? 
 e.g.= _bottom_mute
 
=cut

sub purpose {

    my ( $variable, $purpose ) = @_;

    if ( defined($purpose) ) {
        $iApply_mute->{_purpose} = $purpose;
    }
}

=head2 subroutine calcNdisplay

  main processing flow
  calculate mute and display results 

=cut

sub calcNdisplay {

=head2

  Assume that the parameter file already exists
  Assume that the name of this parameter file is:
     $itemp_top_mute_picks_sorted_par_.$iApply_mute->{_file_in}

=cut 

    $iApply_mute->{_parfile_in} =
        $PL_SEISMIC . '/'
      . 'itemp_'
      . $iApply_mute->{_purpose}
      . '_picks_sorted_par_'
      . $iApply_mute->{_file_in} . '_'
      . $iApply_mute->{_gather_type}
      . $iApply_mute->{_gather_num};

    print("mute pick file is $iApply_mute->{_parfile_in}\n\n");
    print("/lib/iApply_mute : mute type is $iApply_mute->{_purpose}\n\n");

=head2

 MUTE  DATA by  

=cut

    $sumute->clear();
    $sumute->par_file( $iApply_mute->{_parfile_in} );
    $sumute->offset_word( $iApply_mute->{_offset_type} );
    $sumute->type( $iApply_mute->{_purpose} );
    $sumute[1] = $sumute->Step();

=head2

  set filtering parameters 

=cut

    $sufilter->clear();
    $sufilter->freq( $iApply_mute->{_freq} );
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

    $sugain->clear();
    $sugain->tpower(3);
    $sugain[3] = $sugain->Step();

=head2

 DISPLAY DATA

=cut

# $base_caption	  = $iApply_mute->{_file_in}.quotemeta(' f=').$iApply_mute->{_freq};
# $windowtitle	  = '';

    # $suximage -> clear();
    # $suximage -> box_width(300);
    # $suximage -> box_height(700);
    # $suximage -> box_X0(70);
    # $suximage -> box_Y0(120);
    # $suximage -> title($base_caption);
    # $suximage -> windowtitle($windowtitle);
    # $suximage -> ylabel(quotemeta('TWTTs'));
    # $suximage -> xlabel($iApply_mute->{_offset_type});
    # $suximage -> legend($on);
    # $suximage -> cmap('rgb0');
    # #$suximage -> loclip($iApply_mute->{_min_amplitude});
    # #$suximage -> hiclip($iApply_mute->{_max_amplitude});
    # $suximage -> verbose($off);
    # $suximage[1]  = $suximage -> Step();
    #

=head2 Set wiggle plot 
	
	for tau-p data

=cut

    $suxwigb->clear();
    $suxwigb->defaults( 'iSurf4', 'top_middle' );
    $suxwigb->key('tracl');
    $suxwigb->title( $iApply_mute->{_file_in} );

    #$suxwigb-> pmin($CFG->{sutaup}{1}{pmin});
    #$suxwigb-> dp($dp);
    $suxwigb->box_width(400);
    $suxwigb->box_height(500);

    #$suxwigb-> percent(99.9);
    $suxwigb->clip(1);
    $suxwigb->windowtitle( quotemeta('Muted Taup Data') );
    $suxwigb[1] = $suxwigb->Step();

=head2
 
  DEFINE FLOW(S)

=cut

    @items =
      ( $sumute[1], $in, $iApply_mute->{_inbound}, $to, $suxwigb[1], $go );
    $flow[1] = $run->modules( \@items );

    @items = (
        $sumute[1], $in, $iApply_mute->{_inbound},
        $out, $iApply_mute->{_outbound}, $go
    );
    $flow[2] = $run->modules( \@items );

=head2

  RUN FLOW(S)
  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

    $run->flow( \$flow[1] );
    $run->flow( \$flow[2] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    #print  "$flow[1]\n";
    #$log->file($flow[1]);
    print "$flow[2]\n";

    #$log->file($flow[2]);

}    # end calcNdisplay subroutine

1;
