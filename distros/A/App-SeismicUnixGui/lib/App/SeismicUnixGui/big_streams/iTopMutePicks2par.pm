package App::SeismicUnixGui::big_streams::iTopMutePicks2par;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::mkparfile';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME:iTopMutePicks2par.pm
 AUTHOR: Juan Lorenzo
 DATE: May 5 2009

 DESCRIPTION: 

 Purpose: write data pairs to par format for input to sumute 


=head2 USE

=head3 NOTES 

=head4 
Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES

  V 1. May 5 2009
  V2 for interactive top mute picks
  V3 Sept.19 2015 perl oops for use with GUI 


=head3 STEPS

1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you can even change them

=cut

=pod

 instantiate classes

=cut

my $log       = message->new();
my $run       = flow->new();
my $mkparfile = mkparfile->new();

=pod
 
 declare variables types
 establish just the locally scoped variables

=cut

my @mkparfile;
my ( $mkparfile_in,  $mkparfile_inbound );
my ( $mkparfile_out, $mkparfile_outbound );
my ( @items,         @flow );

=pod

 create hash with important variables

=cut

my $iTopMutePicks2par = {
    _TX_inbound    => '',
    _TX_outbound   => '',
    _taup_inbound  => '',
    _taup_outbound => '',
    _gather_num    => '',
    _exists        => '',
    _textfile_in   => '',
    _textfile_out  => '',
    _type          => ''
};

=head3

 Import file-name  and directory definitions

=cut 

use App::SeismicUnixGui::misc::SeismicUnix
  qw($true $false $in $out $to $itop_mute_par_ $itemp_top_mute_picks_ $itemp_top_mute_picks_sorted_par_ $out $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
my $Project = Project_config->new();
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $iTopMutePicks2par->{_TX_inbound}    = '';
    $iTopMutePicks2par->{_TX_outbound}   = '';
    $iTopMutePicks2par->{_taup_inbound}  = '';
    $iTopMutePicks2par->{_taup_outbound} = '';
    $iTopMutePicks2par->{_gather_num}    = '';
    $iTopMutePicks2par->{_exists}        = '';
    $iTopMutePicks2par->{_textfile_in}   = '';
    $iTopMutePicks2par->{_textfile_out}  = '';
    $iTopMutePicks2par->{_type}          = '';
}

=head3 subroutine file_in

 Required file name
 on which to pick top mute values

=cut

sub file_in {
    my ( $variable, $file_in ) = @_;
    $iTopMutePicks2par->{_file_in} = $file_in if defined($file_in);

    #print("file name is $iTopMutePicks2par->{_file_in} \n\n");
}

=head3 sub type

  switches for old data of two different types

   for type: tx or taup


=cut

sub type {
    my ( $variable, $type ) = @_;
    $iTopMutePicks2par->{_type} = $iTopMutePicks2par
      if defined($iTopMutePicks2par);
}

=pod subroutine calc 

 main processing flow
 reformats data  

=cut

sub calc {

=pod

  MAKE PARAMETER FILE
  CONVERT TEXT FILE TO PAR FILE

=cut

=pod

 establish par file names

 TODO if no sorting is ever needed
 rm file name from $itemp_top_mute_picks_sorted_par to itemp_top_mute_picks

=cut

    $mkparfile_in = $itemp_top_mute_picks_ . $iTopMutePicks2par->{_file_in};
    $mkparfile_out =
      $itemp_top_mute_picks_sorted_par_ . $iTopMutePicks2par->{_file_in};

    $iTopMutePicks2par->{TX_inbound}  = $DATA_SEISMIC_TXT . '/' . $mkparfile_in;
    $iTopMutePicks2par->{TX_outbound} = $DATA_SEISMIC_TXT . '/' . $mkparfile_out;

    $mkparfile->clear();
    $mkparfile->string1('tmute');
    $mkparfile->string2('xmute');
    $mkparfile[1] = $mkparfile->Step();

    # DEFINE FLOW(s)
    # CONVERT t-p picks to t-trace picks
    #   $taup = $taup_data;
    #
    #   if ($taup == $true) {
    #	print("Mute picks inbound file: $mkparfile_inbound[1]\n\n");
    #	print("This is taup data\n\n");
    #
    #	($ref_inbound) = iTop_Mute::tp_piks2ttr(\@mkparfile_inbound[1]);
    #
    #	$flow[1] = (" 						\\
    #		$mkparfile[1] 					\\
    #		< $$ref_inbound[1] 				\\
    #		>$mkparfile_outbound[1]  			\\
    #								\\
    #		");
    #
    #   }
    #  elsif ($taup == $false) {

    #  in the current flow below
    #  }

=pod
 
  DEFINE FLOW(S)

=cut

    #   print("Regular xt data\n\n");

    @items = (
        $mkparfile[1], $in, $iTopMutePicks2par->{TX_inbound},
        $out, $iTopMutePicks2par->{TX_outbound}
    );
    $flow[1] = $run->modules( \@items );

=pod

  RUN FLOW(S)
  output copy of picked data points
  only occurs after the number of tries
  is updated

=cut

    $run->flow( \$flow[1] );

=pod

  LOG FLOW(S)TO SCREEN AND FILE

=cut

    # print  "$flow[1]\n";
    #$log->file($flow[1]);

}    # end calc subroutine

1;
