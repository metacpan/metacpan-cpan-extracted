package App::SeismicUnixGui::sunix::filter::susmgauss2;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUSMGAUSS2 --- SMOOTH a uniformly sampled 2d array of velocities	

		using a Gaussian filter specified with correlation 	

	lengths a1 and a2.	



 susmgauss2 < stdin [optional parameters ] > stdout			



 Optional Parameters:							

 a1=0			smoothing parameter in the 1 direction		

 a2=0			smoothing parameter in the 2 direction		



 Notes:								

 Larger a1 and a2 result in a smoother velocity. The velocities are	

 first transformed to slowness and then a Gaussian filter is applied	

 in the wavenumber domain.						



 Input file must be in SU format. The output file is smoothed velocity 







	Credits: 

		CWP: Carlos Pacheco, 2005



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

my $susmgauss2			= {
	_a1					=> '',
	_a2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susmgauss2->{_Step}     = 'susmgauss2'.$susmgauss2->{_Step};
	return ( $susmgauss2->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susmgauss2->{_note}     = 'susmgauss2'.$susmgauss2->{_note};
	return ( $susmgauss2->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susmgauss2->{_a1}			= '';
		$susmgauss2->{_a2}			= '';
		$susmgauss2->{_Step}			= '';
		$susmgauss2->{_note}			= '';
 }


=head2 sub a1 


=cut

 sub a1 {

	my ( $self,$a1 )		= @_;
	if ( $a1 ne $empty_string ) {

		$susmgauss2->{_a1}		= $a1;
		$susmgauss2->{_note}		= $susmgauss2->{_note}.' a1='.$susmgauss2->{_a1};
		$susmgauss2->{_Step}		= $susmgauss2->{_Step}.' a1='.$susmgauss2->{_a1};

	} else { 
		print("susmgauss2, a1, missing a1,\n");
	 }
 }


=head2 sub a2 


=cut

 sub a2 {

	my ( $self,$a2 )		= @_;
	if ( $a2 ne $empty_string ) {

		$susmgauss2->{_a2}		= $a2;
		$susmgauss2->{_note}		= $susmgauss2->{_note}.' a2='.$susmgauss2->{_a2};
		$susmgauss2->{_Step}		= $susmgauss2->{_Step}.' a2='.$susmgauss2->{_a2};

	} else { 
		print("susmgauss2, a2, missing a2,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 1;

    return($max_index);
}
 
 
1;
