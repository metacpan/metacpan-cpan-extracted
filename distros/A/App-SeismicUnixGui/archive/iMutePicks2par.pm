package App::SeismicUnixGui::big_streams::iMutePicks2par;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PACKAGE NAME:iMutePicks2par.pm
 AUTHOR: Juan Lorenzo
 DATE:   Jan. 30 2017 

 DESCRIPTION: V 1. Convert isave picks from 
              suxwigb or suximage into par format 
              Write data pairs to par format 
              for input to sumute
 BASED on iTopMutePicks2par3.pm 
           May 5 2009

=head2 USE

=head3 NOTES 

=head4 

Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES
	V1. BASED on iTopMutePicks2par3.pm 
        May 5 2009


=head3 STEPS

1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

=cut

use Moose;
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::mkparfile';

=head2

 instantiate classes

=cut

my $log       = message->new();
my $run       = flow->new();
my $mkparfile = mkparfile->new();

=head2
 
 declare variables types
 establish just the locally scoped variables

=cut

my @mkparfile;
my ( $mkparfile_in,  $mkparfile_inbound );
my ( $mkparfile_out, $mkparfile_outbound );
my ( @items,         @flow );

=head2

 create hash with important variables

=cut

my $iMutePicks2par = {
    _TX_inbound    => '',
    _TX_outbound   => '',
    _exists        => '',
    _gather_num    => '',
    _gather_type   => '',
    _purpose       => '',
    _taup_inbound  => '',
    _taup_outbound => '',
    _textfile_in   => '',
    _textfile_out  => ''
};

=head3

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix qw($true $false $in $out $to;
  $itop_mute_par_ $itemp_top_mute_picks_
  $itemp_top_mute_picks_sorted_par_
  $out $suffix_su);
my $Project = Project_config->new();
my ($PL_SEISMIC) = $Project->PL_SEISMIC();

=head2 subroutine clear

  sets all variable stringsto '' 

=cut

sub clear {
    $iMutePicks2par->{_TX_inbound}    = '';
    $iMutePicks2par->{_TX_outbound}   = '';
    $iMutePicks2par->{_exists}        = '';
    $iMutePicks2par->{_gather_num}    = '';
    $iMutePicks2par->{_gather_type}   = '';
    $iMutePicks2par->{_purpose}       = '';
    $iMutePicks2par->{_taup_inbound}  = '';
    $iMutePicks2par->{_taup_outbound} = '';
    $iMutePicks2par->{_textfile_in}   = '';
    $iMutePicks2par->{_textfile_out}  = '';
}

=head3 subroutine file_in

 Required file name
 on which to pick top mute values

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iMutePicks2par->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iMutePicks2par->{_file_in} \n\n");
}

=head2 subroutine gather_type

  sets gather type to consider 
  e.g., 'ep', 'cdp', etc. 

=cut

sub gather_type {
    my ( $variable, $gather_type ) = @_;
    $iMutePicks2par->{_gather_type} = $gather_type if defined($gather_type);
}

=head2 subroutine gather_num

  sets gather number to consider  
  print("1. first_gather is $iMutePicks2par->{_gather_num} \n\n");

=cut

sub gather_num {

    my ( $variable, $gather_num ) = @_;
    $iMutePicks2par->{_gather_num} = $gather_num if defined($gather_num);

}

=head2 sub purpose 

  define the type of mute to use 
  e.g., top or bottom

=cut

sub purpose {
    my ( $variable, $type ) = @_;
    if ( defined($type) ) {
        $iMutePicks2par->{_purpose} = $type;
    }
}

=head2 subroutine calc 

 main processing flow
 reformats data  

=cut

sub calc {

=head2MAKE PARAMETER FILE

  CONVERT TEXT FILE TO PAR FILE

=cut

=head2

 establish par file names

 TODO if no sorting is ever needed
 rm file name from $itemp_top_mute_picks_sorted_par to itemp_top_mute_picks
 print("mkparfile in $mkparfile_in\n\n");
 print("mkparfile out $mkparfile_out\n\n");

=cut

    $mkparfile_in =
        'itemp_'
      . $iMutePicks2par->{_purpose}
      . '_picks_'
      . $iMutePicks2par->{_file_in} . '_'
      . $iMutePicks2par->{_gather_type}
      . $iMutePicks2par->{_gather_num};

    $mkparfile_out =
        'itemp_'
      . $iMutePicks2par->{_purpose}
      . '_picks_sorted_par_'
      . $iMutePicks2par->{_file_in} . '_'
      . $iMutePicks2par->{_gather_type}
      . $iMutePicks2par->{_gather_num};

    $iMutePicks2par->{TX_inbound}  = $PL_SEISMIC . '/' . $mkparfile_in;
    $iMutePicks2par->{TX_outbound} = $PL_SEISMIC . '/' . $mkparfile_out;

    $mkparfile->clear();
    $mkparfile->string1('tmute');
    $mkparfile->string2('xmute');
    $mkparfile[1] = $mkparfile->Step();

=head2 DEFINE
 
 FLOW(S)

=cut

    @items = (
        $mkparfile[1], $in, $iMutePicks2par->{TX_inbound},
        $out, $iMutePicks2par->{TX_outbound}
    );
    $flow[1] = $run->modules( \@items );

=head2 RUN

  FLOW(S)
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

}    # end calc subroutine

1;
