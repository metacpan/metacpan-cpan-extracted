package App::SeismicUnixGui::big_streams::iTopMute;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iTopMute.pm 
 AUTHOR: Juan Lorenzo
 DATE:  Sept. 14 2015 
         

 DESCRIPTION: 
 Version: 1.1
 Package used for interactive top mute 

=head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES


=cut

=head2 STEPS

 1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

set defaults

VELAN DATA 
 m/s

=cut

=head2 Import 

  packages
  directory definitions

=cut 

use Moose;
our $VERSION = '1.0.3';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::shell::cp';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::big_streams::iApply_top_mute';
use aliased 'App::SeismicUnixGui::big_streams::iSelect_tr_Sumute_top';
use aliased 'App::SeismicUnixGui::big_streams::iTopMutePicks2par';
use aliased 'App::SeismicUnixGui::misc::old_data';
use aliased 'App::SeismicUnixGui::big_streams::iSave_top_mute_picks';
use aliased 'App::SeismicUnixGui::messages::SuMessages';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($on $off $in $to $go $itop_mute_par_ $itop_mute_check_pickfile_ $false $true );
  
my $Project           = Project_config->new();
my ($DATA_SEISMIC_TXT)= $Project->DATA_SEISMIC_TXT();
my ($DATA_SEISMIC_SU) = $Project->DATA_SEISMIC_SU();
my ($date)            = $Project->date();

=head2 instantiate 

 programs

=cut

my $cp                    = cp->new();
my $log                   = message->new();
my $run                   = flow->new();
my $iApply_top_mute       = iApply_top_mute->new();
my $iSelect_tr_Sumute_top = iSelect_tr_Sumute_top->new();
my $iPicks2par            = iTopMutePicks2par->new();
my $check4old_data        = old_data->new();
my $iSave_top_mute_picks  = iSave_top_mute_picks->new();
my $SuMessages            = SuMessages->new();

=head2 private hash
 
=cut

my $iTopMute = {
    _gather_header     => '',
    _offset_type       => '',
    _gather_num        => '',
    _gather_num_suffix => '',
    _exists            => '',
    _file_in           => '',
    _freq              => '',
    _gather_type       => '',
    _min_amplitude     => '',
    _max_amplitude     => '',
    _next_step         => '',
    _number_of_tries   => '',
    _TX_inbound        => '',
    _TX_outbound       => '',
    _textfile_in       => '',
    _textfile_out      => ''
};

=head2
 
 declare variables types
 establish just the locally scoped variables

=cut

my ( @flow, @cp, @items );

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $iTopMute->{_gather_num}        = '';
    $iTopMute->{_gather_type}       = '';
    $iTopMute->{_gather_header}     = '';
    $iTopMute->{_offset_type}       = '';
    $iTopMute->{_gather_num_suffix} = '';
    $iTopMute->{_exists}            = '';
    $iTopMute->{_file_in}           = '';
    $iTopMute->{_freq}              = '';
    $iTopMute->{_min_amplitude}     = '';
    $iTopMute->{_max_amplitude}     = '';
    $iTopMute->{_next_step}         = '';
    $iTopMute->{_number_of_tries}   = '';
    $iTopMute->{_textfile_in}       = '';
    $iTopMute->{_textfile_out}      = '';
    $iTopMute->{_TX_inbound}        = '';
    $iTopMute->{_TX_outbound}       = '';
}

=head2 subroutine gather_header

  define which values  to use in the xaxis 

=cut

sub gather_header {
    my ( $variable, $gather_header ) = @_;
    $iTopMute->{_gather_header} = $gather_header if defined($gather_header);
}

=head2 sub offset_type

  define which values  to use in the xaxis 

=cut

sub offset_type {
    my ( $variable, $offset_type ) = @_;
    $iTopMute->{_offset_type} = $offset_type if defined($offset_type);

    #print("offset type -2 $offset_type\n\n");
}

=head2 sub gather_type

  define which family of messages to use

=cut

sub gather_type {
    my ( $variable, $gather_type ) = @_;
    $iTopMute->{_gather_type} = $gather_type if defined($gather_type);
}

=head2 sub iTM_Select_tr_Sumute_top

 Select mute points in traces
 provide file name
 
=cut

sub iTM_Select_tr_Sumute_top {
	
	my ($self) = @_;
	
    $iSelect_tr_Sumute_top->gather_type( $iTopMute->{_gather_type} );
    $iSelect_tr_Sumute_top->offset_type( $iTopMute->{_offset_type} );
    $iSelect_tr_Sumute_top->gather_header( $iTopMute->{_gather_header} );
    $iSelect_tr_Sumute_top->file_in( $iTopMute->{_file_in} );
    $iSelect_tr_Sumute_top->freq( $iTopMute->{_freq} );
    $iSelect_tr_Sumute_top->gather_num( $iTopMute->{_gather_num} );
    $iSelect_tr_Sumute_top->min_amplitude( $iTopMute->{_min_amplitude} );
    $iSelect_tr_Sumute_top->max_amplitude( $iTopMute->{_max_amplitude} );
    $iSelect_tr_Sumute_top->number_of_tries( $iTopMute->{_number_of_tries} );
    $iSelect_tr_Sumute_top->calcNdisplay();
    
}

=head2 sub iTM_Apply_top_mute

  Mute the data using selected parameters 
 
=cut

sub iTM_Apply_top_mute {
    $iApply_top_mute->file_in( $iTopMute->{_file_in} );
    $iApply_top_mute->gather_header( $iTopMute->{_gather_header} );
    $iApply_top_mute->offset_type( $iTopMute->{_offset_type} );
    $iApply_top_mute->freq( $iTopMute->{_freq} );
    $iApply_top_mute->gather_num( $iTopMute->{_gather_num} );
    $iApply_top_mute->min_amplitude( $iTopMute->{_min_amplitude} );
    $iApply_top_mute->max_amplitude( $iTopMute->{_max_amplitude} );
    $iApply_top_mute->calcNdisplay();
}

=head2 subroutine iPicks2par

 convert format of pick files for use later
 into "par" format 
 
=cut

sub iPicks2par {
    $iPicks2par->file_in( $iTopMute->{_file_in} );
    $iPicks2par->calc();
}

=head2 subroutine iTM_Save_top_mute_picks

 save pick files for later use
 
=cut

sub iTM_Save_top_mute_picks {
    $iSave_top_mute_picks->gather_num( $iTopMute->{_gather_num} );
    $iSave_top_mute_picks->gather_header( $iTopMute->{_gather_header} );
    $iSave_top_mute_picks->gather_type( $iTopMute->{_gather_type} );
    $iSave_top_mute_picks->file_in( $iTopMute->{_file_in} );
    $iSave_top_mute_picks->calc();
}

=head2 sub set_message

  define the message family (type) to use
  also set the gather nuimber (TODO: move option elsewhere)

=cut

sub set_message {
    my ( $variable, $type ) = @_;
    $iTopMute->{_message_type} = $type if defined($type);
    $SuMessages->set( $iTopMute->{_message_type} );

=head2

    update gather number for messages

=cut

    $SuMessages->gather_num( $iTopMute->{_gather_num} );
    $SuMessages->gather_header( $iTopMute->{_gather_header} );
    $SuMessages->gather_type( $iTopMute->{_gather_type} );
}

=head2 sub iTM_message

  instructions 

=cut

sub iTM_message {
    my ( $variable, $instructions ) = @_;
    $iTopMute->{_instructions} = $instructions if defined($instructions);

=head2
    update gather number for messages
=cut

    $SuMessages->gather_num( $iTopMute->{_gather_num} );
    $SuMessages->instructions( $iTopMute->{_instructions} );
    $SuMessages->gather_header( $iTopMute->{_gather_header} );
    $SuMessages->gather_type( $iTopMute->{_gather_type} );
}

=head2 sub type

look for old data

  Are there old picks to read?
  These old picks are of a type e.g. velan or gather
  

=cut

sub type {

    my ( $variable, $type ) = @_;
    $iTopMute->{_type} = $type if defined($type);
    $check4old_data->gather_num( $iTopMute->{_gather_num} );
    $check4old_data->file_in( $iTopMute->{_file_in} );
    $iTopMute->{_exists} = $check4old_data->type( $iTopMute->{_type} );

    return $iTopMute->{_exists};
}

=head2 subroutine gather_num

  sets gather number to consider  

=cut

sub gather_num {
    my ( $variable, $gather_num ) = @_;
    $iTopMute->{_gather_num} = $gather_num if defined($gather_num);
    $iTopMute->{_gather_num_suffix} = '_gather' . $iTopMute->{_gather_num}

}

=head2  subroutine file_in

 Required file name
 on which to pick top mute values

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iTopMute->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iTopMute->{_file_in} \n\n");
}

=head2 subroutine data_scale

 Required data plotting scale 

=cut

sub data_scale {
    my ( $variable, $data_scale ) = @_;
    $iTopMute->{_data_scale} = $data_scale if defined($data_scale);

    #print("ds=$iTopMute->{_data_scale}\n\n");
}

=head2 subroutine freq

  creates the bandpass frequencies to filter data before
  conducting amplitude analysis
  e.g., "3,6,40,50"
 
=cut

sub freq {
    my ( $variable, $freq ) = @_;
    $iTopMute->{_freq} = $freq if defined($freq);

    #print("freq is $iTopMute->{_freq}\n\n");
}

=head2

 subroutine maximum amplitude to plot 

=cut

sub max_amplitude {
    my ( $variable, $max_amplitude ) = @_;
    $iTopMute->{_max_amplitude} = $max_amplitude if defined($max_amplitude);

    #print("max_amplitude is $iTopMute->{_max_amplitude}\n\n");
}

=head2

 subroutine minumum amplitude to plot 

=cut

sub min_amplitude {
    my ( $variable, $min_amplitude ) = @_;
    $iTopMute->{_min_amplitude} = $min_amplitude if defined($min_amplitude);

    #print("min_amplitude is $iTopMute->{_min_amplitude}\n\n");
}

=head2

 subroutine number_of_tries 
 required count of the number of attempts
 at estimating the velocity

=cut

sub number_of_tries {
    my ( $variable, $number_of_tries ) = @_;
    $iTopMute->{_number_of_tries} = $number_of_tries
      if defined($number_of_tries);

    #print("number_of_tries is $iTopMute->{_number_of_tries} \n\n");
}

=head2 subroutine icp_sorted_2_old_picks

 When user wants to recheck the data 
 this subroutine will allow the user to 
 recheck  using an old sorted file
 Juan M. Lorenzo
 Jan 10 2010

    input file is ivpicks_sorted
    output pick file 
    text file out: ivpicks_old 


=cut 

sub icp_sorted2oldpicks {

    my ( $inbound, $outbound );
    my ($writefile_out);
    my ($flow);
    my ( $suffix, $sortfile_in, $sorted_suffix, $XTpicks_out, $XTpicks_in );

    # suffixes
    $sorted_suffix = '_sorted';
    $suffix        = '_gather' . $iTopMute->{_gather_num};

    #XT file names
    $XTpicks_in  = 'XTpicks_old' . $sorted_suffix;
    $XTpicks_out = 'XTpicks_old';

    # sort file names
    $sortfile_in = $XTpicks_in;
    $inbound =
        $DATA_SEISMIC_TXT . '/'
      . $sortfile_in . '_'
      . $iTopMute->{_file_in} . '_'
      . $iTopMute->{_gather_num_suffix};

    # TX write file names
    $writefile_out = $XTpicks_out;
    $outbound =
        $DATA_SEISMIC_TXT . '/'
      . $writefile_out . '_'
      . $iTopMute->{_file_in} . '_'
      . $iTopMute->{_gather_num_suffix};

    $cp->from($inbound);
    $cp->to($outbound);
    $cp[1] = $cp->Step();

=head2

  DEFINE FLOW(S)

=cut 

    @items = ( $cp[1] );
    $flow[1] = $run->modules( \@items );

=head2

  RUN FLOW(S)

=cut 

    $run->flow( \$flow[1] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    #print  "$flow[1]\n";
    #$log->file($flow[1]);

    #end of copy of XT old picks sorted to iXTpicks_old
}

1;
