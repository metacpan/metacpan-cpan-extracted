package App::SeismicUnixGui::big_streams::iSave_mute_picks;

use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME:iSave_mute_picks.pm
 AUTHOR:  Juan Lorenzo
 DATE:    iSave_mute_picks 
 Version: 1.0 

 DESCRIPTION: Save final version of
  muted picks for any type of muting

=head2 USE

=head4 

 Examples

=head2 SEISMIC UNIX NOTES

=head4 CHANGES and their DATES

 Base on iTop_mute_picks3.pm V 3.0 
  Sept. 2015
 Originally to Save final Top Mute of Data

=head2 STEPS

  use the local library of the user
  bring is user variables from a local file
  create instances of the needed subroutines

=cut

=head2

 instantiate classes

=cut

use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::shell::cp';
use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $on $to);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

my $log     = message->new();
my $run     = flow->new();
my $cp      = cp->new();
my $Project = Project_config->new();

=head2
 
 declare variables types
 establish just the locally scoped variables

=cut

my ( @flow, @cp, @items );

=head2

 create hash with important variables

=cut

my $iSave_mute_picks = {
    _gather_num    => '',
    _gather_type   => '',
    _gather_header => '',
    _file_in       => '',
    _inbound       => '',
    _outbound      => '',
    _purpose       => ''
};

=head2

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($itemp_top_mute_picks_sorted_par_ $itop_mute_par_);
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

=head2 subroutine clear

  sets all variable strings to '' 

=cut 

sub clear {
    $iSave_mute_picks->{_gather_num}    = '';
    $iSave_mute_picks->{_gather_type}   = '';
    $iSave_mute_picks->{_gather_header} = '';
    $iSave_mute_picks->{_purpose}       = '';
    $iSave_mute_picks->{_inbound}       = '';
    $iSave_mute_picks->{_outbound}      = '';
}

=head2 subroutine file_in

 Required file name
 on which to pick top mute values

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iSave_mute_picks->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iSave_mute_picks->{_file_in} \n\n");

}

=head2 subroutine gather

  sets gather number to consider  

=cut

sub gather_num {
    my ( $variable, $gather_num ) = @_;
    $iSave_mute_picks->{_gather_num} = $gather_num if defined($gather_num);
}

=head2 subroutine gather_type

  sets gather_type number to consider  

=cut

sub gather_type {
    my ( $variable, $gather_type ) = @_;
    $iSave_mute_picks->{_gather_type} = $gather_type if defined($gather_type);
}

=head2 subroutine gather_header

  sets gather_header number to consider  

=cut

sub gather_header {
    my ( $variable, $gather_header ) = @_;
    $iSave_mute_picks->{_gather_header} = $gather_header
      if defined($gather_header);
}

=head2 subroutine purpose

 are the picks for a future top mute
 or a future bottom mute ? 
 e.g.= _bottom_mute
 
=cut

sub purpose {

    my ( $variable, $purpose ) = @_;

    if ( defined($purpose) ) {
        $iSave_mute_picks->{_purpose} = $purpose;
    }
}

=head2 sub calc

 rewrite sorted picks into a permanent file

=cut

sub calc {

    my $suffix = '_'
      . $iSave_mute_picks->{_gather_header}
      . $iSave_mute_picks->{_gather_num};

    $iSave_mute_picks->{_inbound} =
        $DATA_SEISMIC_TXT . '/'
      . 'itemp_'
      . $iSave_mute_picks->{_purpose}
      . '_picks_sorted_par_'
      . $iSave_mute_picks->{_file_in} . '_'
      . $iSave_mute_picks->{_gather_type}
      . $iSave_mute_picks->{_gather_num};

    $iSave_mute_picks->{_outbound} =
        $DATA_SEISMIC_TXT . '/'
      . 'mute_par_'
      . $iSave_mute_picks->{_purpose} . '_'
      . $iSave_mute_picks->{_file_in} . '_'
      . $iSave_mute_picks->{_gather_type}
      . $iSave_mute_picks->{_gather_num};

    $cp->from( $iSave_mute_picks->{_inbound} );
    $cp->to( $iSave_mute_picks->{_outbound} );
    $cp[1] = $cp->Step();

=head2

  DEFINE FLOW(S)

=cut 

    @items = ( $cp[1], $go );
    $flow[1] = $run->modules( \@items );

=head2

  RUN FLOW(S)

=cut 

    $run->flow( \$flow[1] );

=head2

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    print "$flow[1]\n";

    #$log->file($flow[1]);

}    # end calc subroutine
1;
