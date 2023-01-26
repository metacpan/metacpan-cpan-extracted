package App::SeismicUnixGui::big_streams::iPicks2par;

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::mkparfile';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head1 DOCUMENTATION

=head2 SYNOPSIS System_Variables::

 PACKAGE NAME:iPicks2par.pm
 AUTHOR: Juan Lorenzo
 DATE: June 14 2019

 DESCRIPTION: 

 Purpose: write data pairs to par format for input 
	into another progam 


=head2 USE
			_taup_inbound		=>'',
			_taup_outbound		=>'',
=head3 NOTES 

=head4 
Examples

=head3 SEISMIC UNIX NOTES  

=head4 CHANGES and their DATES


=head3 STEPS

1. define the types of variables you are using
    these would be the values you enter into 
    each of the Seismic Unix programs  each of the 
    Seismic Unix programs

 2. build a list or hash with all the possible variable
    names you may use and you canSystem_Variables:: even change them

=cut

=pod

 instantiate classes

=cut

my $control   = control->new();
my $get       = L_SU_global_constants->new();
my $log       = message->new();
my $run       = flow->new();
my $mkparfile = mkparfile->new();
my $Project   = Project_config->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

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

my $iPicks2par = {
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

use App::SeismicUnixGui::misc::SeismicUnix qw($true $false $in $out $to $ipicks_par_
  $itemp_picks_ $itemp_picks_sorted_par_
  $out $suffix_su);

my ($PL_SEISMIC)       = $Project->PL_SEISMIC();
my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

=head2 subroutine clear

  sets all variable strings to '' 

=cut

sub clear {
    $iPicks2par->{_TX_inbound}    = '';
    $iPicks2par->{_TX_outbound}   = '';
    $iPicks2par->{_taup_inbound}  = '';
    $iPicks2par->{_taup_outbound} = '';
    $iPicks2par->{_gather_num}    = '';
    $iPicks2par->{_exists}        = '';
    $iPicks2par->{_textfile_in}   = '';
    $iPicks2par->{_textfile_out}  = '';
    $iPicks2par->{_type}          = '';
}

=head2 subroutine file_in

 Required file name
 on which to pick x,t values

=cut

sub file_in {

    my ( $self, $file_in ) = @_;

    if ( defined $file_in
        && $file_in ne $empty_string )
    {

        # e.g., 'sp1' becomes sp1
        $control->set_infection($file_in);
        $file_in = control->get_ticksBgone();
        $iPicks2par->{_file_in} = $file_in;

        # print("iPicks2par, file_in: $iPicks2par->{_file_in} \n");

    }
    else {
        print("iPicks2par, file_in: unexpected file_in \n");
    }
}

=head2 sub type

  switches for old data of two different types

   for type: tx or taup


=cut

sub type {
    my ( $variable, $type ) = @_;
    $iPicks2par->{_type} = $iPicks2par if defined($iPicks2par);
}

=head2 subroutine calc 

 main processing flow
 reformats data 
 MAKE PARAMETER FILE
  CONVERT TEXT FILE TO PAR FILE

  In the old manner:
  $mkparfile	=  ("mkparfile	\\
	string1=t 				\\
	string2=x 				\\
	");

=cut

sub calc {

=head2 establish par file names

 TODO if no sorting is ever needed
 rm file name from $itemp_picks_sorted_par to itemp_picks

=cut

    $mkparfile_in = $itemp_picks_ . $iPicks2par->{_file_in};

    $mkparfile_out = $itemp_picks_sorted_par_ . $iPicks2par->{_file_in};

    $iPicks2par->{_TX_inbound}  = $DATA_SEISMIC_TXT . '/' . $mkparfile_in;
    $iPicks2par->{_TX_outbound} = $DATA_SEISMIC_TXT . '/' . $mkparfile_out;

    # print("iPicks2par,calc,inbound is: $iPicks2par->{_TX_inbound} \n");

    $mkparfile->clear();
    $mkparfile->string1('t');
    $mkparfile->string2('x');
    $mkparfile[1] = $mkparfile->Step();

    # SORT a TEXT FILE
    my @sort;
    $sort[1] = (
        " sort 			\\
		-n								\\
		"
    );

=head2 DEFINE FLOW(S)
 
 
 In the old manner (non oops):

	$flow[1] = (" 						\\
		$mkparfile[1] 					\\
		< $mkparfile_inbound[1]			\\
		>$mkparfile_outbound[1]			\\
										\\
		"); 

=cut

    #   print("Regular xt data\n\n");

    @items = (
        $sort[1], $in, $iPicks2par->{_TX_inbound},
        $to, $mkparfile[1], $out, $iPicks2par->{_TX_outbound}
    );

    $flow[1] = $run->modules( \@items );

=head2

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
    # $log->file($flow[1]);

}    # end calc subroutine

1;
