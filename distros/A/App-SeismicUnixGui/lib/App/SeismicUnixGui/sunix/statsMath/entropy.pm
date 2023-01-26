package App::SeismicUnixGui::sunix::statsMath::entropy;

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
 ENTROPY - compute the ENTROPY of a signal			



  entropy < stdin n= > stdout					



 Required Parameter:						

  n		number of values in data set			



 Optional Parameters:						

  none								







 Author: CWP: Tong Chen, 1995.

 



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

my $entropy			= {
	_n					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$entropy->{_Step}     = 'entropy'.$entropy->{_Step};
	return ( $entropy->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$entropy->{_note}     = 'entropy'.$entropy->{_note};
	return ( $entropy->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$entropy->{_n}			= '';
		$entropy->{_Step}			= '';
		$entropy->{_note}			= '';
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$entropy->{_n}		= $n;
		$entropy->{_note}		= $entropy->{_note}.' n='.$entropy->{_n};
		$entropy->{_Step}		= $entropy->{_Step}.' n='.$entropy->{_n};

	} else { 
		print("entropy, n, missing n,\n");
	 }
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
