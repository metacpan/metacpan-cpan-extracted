package App::SeismicUnixGui::sunix::model::sunull;

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
 SUNULL - create null (all zeroes) traces	 		



 sunull nt=   [optional parameters] >outdata			



 Required parameter						

 	nt=		number of samples per trace		



 Optional parameters						

 	ntr=5		number of null traces to create		

 	dt=0.004	time sampling interval			



 Rationale: It is sometimes useful to insert null traces	

	 between "panels" in a shell loop.			



 See also: sukill, sumute, suzero				





 Credits:

	CWP: Jack K. Cohen



 Trace header fields set: ns, dt, tracl



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

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $sunull			= {
	_dt					=> '',
	_nt					=> '',
	_ntr					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sunull->{_Step}     = 'sunull'.$sunull->{_Step};
	return ( $sunull->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sunull->{_note}     = 'sunull'.$sunull->{_note};
	return ( $sunull->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sunull->{_dt}			= '';
		$sunull->{_nt}			= '';
		$sunull->{_ntr}			= '';
		$sunull->{_Step}			= '';
		$sunull->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sunull->{_dt}		= $dt;
		$sunull->{_note}		= $sunull->{_note}.' dt='.$sunull->{_dt};
		$sunull->{_Step}		= $sunull->{_Step}.' dt='.$sunull->{_dt};

	} else { 
		print("sunull, dt, missing dt,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sunull->{_nt}		= $nt;
		$sunull->{_note}		= $sunull->{_note}.' nt='.$sunull->{_nt};
		$sunull->{_Step}		= $sunull->{_Step}.' nt='.$sunull->{_nt};

	} else { 
		print("sunull, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$sunull->{_ntr}		= $ntr;
		$sunull->{_note}		= $sunull->{_note}.' ntr='.$sunull->{_ntr};
		$sunull->{_Step}		= $sunull->{_Step}.' ntr='.$sunull->{_ntr};

	} else { 
		print("sunull, ntr, missing ntr,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 2;

    return($max_index);
}
 
 
1;
