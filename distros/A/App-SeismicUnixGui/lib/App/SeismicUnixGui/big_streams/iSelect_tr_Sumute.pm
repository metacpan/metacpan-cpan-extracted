package App::SeismicUnixGui::big_streams::iSelect_tr_Sumute;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iSelect_tr_Sumute.pm
 AUTHOR: Juan Lorenzo
 DATE:   January 29, 2017 
       
	 Based on iSelect_tr_Sumute_top3.pm
         from  August 2016, V 3.1 

 DESCRIPTION:
 plot data to select mute values
 top or bottom

=head2 USE

=head3 NOTES 

=head4 

 Examples

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::filter::sufilter';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::suwind';
use aliased 'App::SeismicUnixGui::sunix::plot::suxwigb';
use aliased 'App::SeismicUnixGui::sunix::plot::suximage';
use aliased 'App::SeismicUnixGui::sunix::shapeNcut::sugain';
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

use App::SeismicUnixGui::misc::SeismicUnix qw($on $off $go $in $true
  $false $itemp_top_mute_picks_
  $itemp_top_mute_picks_sorted_par_
  $itop_mute_par_ $itop_mute_check_pickfile_
  $suffix_su $to);

=head2 Instantiate 

 other packages
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
my $SuMessages = SuMessages->new();
my $Project    = Project_config->new();

my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();

=head2 Establish
 
 just the localally scoped variables

=cut

my ( @parfile_in, @file_in, @suffix, @inbound );
my ( @suwind_min, @suwind_max );
my ( @items, @flow, @sugain, @sufilter, @suwind );
my ( @suximage,    @suxwigb );
my ( @windowtitle, @base_caption );

=head2  hash array 

 of important variables used within
  this package

=cut 

my $iSelect_tr_Sumute = {
    _TX_outbound     => '',
    _bottom          => '',
    _gather_num      => '',
    _file_in         => '',
    _freq            => '',
    _inbound         => '',
    _message_type    => '',
    _purpose         => '',
    _gather_header   => '',
    _offset_type     => '',
    _gather_type     => '',
    _number_of_tries => '',
    _textfile_in     => ''
};

=head2 sub clear

         to blank out hash array values

=cut

sub clear {
    $iSelect_tr_Sumute->{_TX_outbound}     = '';
    $iSelect_tr_Sumute->{_bottom}          = '';
    $iSelect_tr_Sumute->{_gather_num}      = '';
    $iSelect_tr_Sumute->{_file_in}         = '';
    $iSelect_tr_Sumute->{_freq}            = '';
    $iSelect_tr_Sumute->{_inbound}         = '';
    $iSelect_tr_Sumute->{_message_type}    = '';
    $iSelect_tr_Sumute->{_purpose}         = '';
    $iSelect_tr_Sumute->{_gather_type}     = '';
    $iSelect_tr_Sumute->{_offset_type}     = '';
    $iSelect_tr_Sumute->{_gather_header}   = '';
    $iSelect_tr_Sumute->{_number_of_tries} = '';
    $iSelect_tr_Sumute->{_file_in}         = '';
    $iSelect_tr_Sumute->{_textfile_in}     = '';
}

=head2 sub file_in

 Required file name
 on which to pick  mute values
 print("$iSelect_tr_Sumute->{_inbound}\n\n");
 

=cut

sub file_in {

    my ( $variable, $file_in ) = @_;
    if (   defined($file_in)
        && $iSelect_tr_Sumute->{_gather_type}
        && $iSelect_tr_Sumute->{_gather_num} )
    {
        $iSelect_tr_Sumute->{_file_in} = $file_in if defined($file_in);
        $iSelect_tr_Sumute->{_inbound} =
            $DATA_SEISMIC_SU . '/'
          . $iSelect_tr_Sumute->{_file_in} . '_'
          . $iSelect_tr_Sumute->{_gather_type}
          . $iSelect_tr_Sumute->{_gather_num}
          . $suffix_su;
    }
    else {

        print("Error: add gather_type, and gather_num before file_in\n\n");

    }
}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
    my ( $variable, $gather_num ) = @_;
    $iSelect_tr_Sumute->{_gather_num} = $gather_num if defined($gather_num);
}

=head2 sub gather_header

  define the message family to use

=cut

sub gather_header {
    my ( $variable, $type ) = @_;
    if ( defined($type) ) {
        $iSelect_tr_Sumute->{_gather_header} = $type;
    }
}

=head2 sub purpose 

  define the type of mute to use 
=cut

sub purpose {
    my ( $variable, $type ) = @_;
    if ( defined($type) ) {
        $iSelect_tr_Sumute->{_purpose} = $type;
    }
}

=head2 sub gather_type

  define the message family to use

=cut

sub gather_type {
    my ( $variable, $type ) = @_;
    $iSelect_tr_Sumute->{_gather_type} = $type if defined($type);
}

=head2 sub offset_type

  define the message family to use

=cut

sub offset_type {
    my ( $variable, $type ) = @_;
    $iSelect_tr_Sumute->{_offset_type} = $type if defined($type);
    if ( $iSelect_tr_Sumute->{_offset_type} eq 'p' ) {
        $iSelect_tr_Sumute->{_offset_type} = 'tracl';
    }
}

=head2 sub freq

  creates the bandpass frequencies to filter data before
  conducting semblance analysis
  e.g., "3,6,40,50"
 
=cut

sub freq {
    my ( $variable, $freq ) = @_;
    $iSelect_tr_Sumute->{_freq} = $freq if defined($freq);

    #print("freq is $iSelect_tr_Sumute->{_freq}\n\n");
}

=head3 sub min_amplitude

 minumum amplitude to plot 

=cut

sub min_amplitude {
    my ( $variable, $min_amplitude ) = @_;
    $iSelect_tr_Sumute->{_min_amplitude} = $min_amplitude
      if defined($min_amplitude);

    #print("min_amplitude is $iSelect_tr_Sumute->{_min_amplitude}\n\n");
}

=head2 sub max_amplitude

 maximum amplitude to plot 

=cut

sub max_amplitude {
    my ( $variable, $max_amplitude ) = @_;
    $iSelect_tr_Sumute->{_max_amplitude} = $max_amplitude
      if defined($max_amplitude);

    #print("max_amplitude is $iSelect_tr_Sumute->{_max_amplitude}\n\n");
}

=head2 sub number_of_tries

    keep track of the number of attempts
    at picking top mute

=cut

sub number_of_tries {
    my ( $variable, $number_of_tries ) = @_;
    $iSelect_tr_Sumute->{_number_of_tries} = $number_of_tries
      if defined($number_of_tries);

    #print("num of tries is $iSelect_tr_Sumute->{_number_of_tries}\n\n");

}

=head2 sub suxwigb_defaults

 selecting if there are appropriate suxwigb defaults

=cut

sub suxwigb_defaults {
    my ( $variable, $suxwigb_defaults ) = @_;
    $iSelect_tr_Sumute->{_suxwigb_defaults} = $suxwigb_defaults
      if defined($suxwigb_defaults);

    #print("num of tries is $iSelect_tr_Sumute->{_suxwigb_defaults}\n\n");

}

=head2 subroutine calcNdisplay 

 main processing flow
  calculate mute and display results 

=cut

sub calcNdisplay {

=head2 GAIN 

 DATA

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

=head2 DISPLAY 

 DATA

=cut

=head2 Set wiggle plot 
	
	for tau-p data
        if num_tries > 0 then you can save the mute picks
        to a picking file
=cut

    $suxwigb->clear();
    $suxwigb->defaults( 'iSurf4', 'top_middle' );
    $suxwigb->key('tracl');
    $suxwigb->title( $iSelect_tr_Sumute->{_file_in} );

    # $suxwigb-> pmin($CFG->{sutaup}{1}{pmin});
    # $suxwigb-> dp($dp);
    # $suxwigb-> picks($sutaup_outbound_pickfile[1]);
    #$suxwigb-> percent(99.9);
    $suxwigb->clip(1);

    if ( $iSelect_tr_Sumute->{_number_of_tries} > 0 ) {
        $iSelect_tr_Sumute->{_TX_outbound} =
            'itemp_'
          . $iSelect_tr_Sumute->{_purpose}
          . '_picks_'
          . $iSelect_tr_Sumute->{_file_in} . '_'
          . $iSelect_tr_Sumute->{_gather_type}
          . $iSelect_tr_Sumute->{_gather_num};

        $suxwigb->picks( $iSelect_tr_Sumute->{_TX_outbound} );
        print("num tries > 0 $iSelect_tr_Sumute->{_TX_outbound}\n\n");
    }

    $suxwigb[1] = $suxwigb->Step();

=head2 DEFINE FLOW(S)
 
  in interactive mode:
  first time you see the image, number_of_tries =0
  second, third, etc. times number_of_tries >0
  The pick file can be saved

=cut

    @items = ( $suxwigb[1], $in, $iSelect_tr_Sumute->{_inbound}, $go );
    $flow[1] = $run->modules( \@items );

=head2 RUN FLOW(S)

  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

    $run->flow( \$flow[1] );

=head2 LOG FLOW(S)

 TO SCREEN AND FILE

=cut

    #print  "$flow[1]\n";
    #$log->file($flow[1]);

}    # end calcNdisplay subroutine

1;

