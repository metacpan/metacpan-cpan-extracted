package App::SeismicUnixGui::sunix::NMO_Vel_Stk::surecip;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SURECIP - sum opposing offsets in prepared data (see below)	



 surecip <stdin >stdout	 		               	



opt=null

 Sum traces with equal positive and negative offsets (i.e. assume

 reciprocity holds). 						



 Usage:							

	suabshw <data >absdata					

	susort cdp offset <absdata | surecip >sumdata		



 Note that this processing stream can be simply evoked by:	



	recip data sumdata					





 Credits:

	SEP: Shuki Ronen

	CWP: Jack Cohen



 Caveat:

	The assumption is that this operation is not a mainstay processing

	item.  Hence the recommended implemention via the 'recip' shell

	script.  If it becomes a mainstay, then a much faster code can

	quickly drummed up by incorporating portions of suabshw and

	susort.



 Trace header fields accessed: ns

 Trace header fields modified: nhs, tracl, sx, gx



=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $surecip			= {
	_opt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$surecip->{_Step}     = 'surecip'.$surecip->{_Step};
	return ( $surecip->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$surecip->{_note}     = 'surecip'.$surecip->{_note};
	return ( $surecip->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$surecip->{_opt}			= '';
		$surecip->{_Step}			= '';
		$surecip->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
#	if ( $opt ne $empty_string ) {
#
#		$surecip->{_opt}		= $opt;
#		$surecip->{_note}		= $surecip->{_note}.' opt='.$surecip->{_opt};
#		$surecip->{_Step}		= $surecip->{_Step}.' opt='.$surecip->{_opt};
#
#	} else { 
#		print("surecip, opt, missing opt,\n");
#	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 0;

    return($max_index);
}
 
 
1;
