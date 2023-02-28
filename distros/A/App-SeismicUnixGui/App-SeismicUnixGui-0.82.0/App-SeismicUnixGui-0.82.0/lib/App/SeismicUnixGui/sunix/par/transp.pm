package App::SeismicUnixGui::sunix::par::transp;

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
 TRANSP - TRANSPose an n1 by n2 element matrix				



 transp <infile >outfile n1= [optional parameters]			



 Required Parameters:							

 n1                     number of elements in 1st (fast) dimension of matrix



 Optional Parameters:							

 n2=all                 number of elements in 2nd (slow) dimension of matrix

 nbpe=sizeof(float)     number of bytes per matrix element		

 verbose=0              =1 for diagnostic information			



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

my $transp			= {
	_n1					=> '',
	_n2					=> '',
	_nbpe					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$transp->{_Step}     = 'transp'.$transp->{_Step};
	return ( $transp->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$transp->{_note}     = 'transp'.$transp->{_note};
	return ( $transp->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$transp->{_n1}			= '';
		$transp->{_n2}			= '';
		$transp->{_nbpe}			= '';
		$transp->{_verbose}			= '';
		$transp->{_Step}			= '';
		$transp->{_note}			= '';
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$transp->{_n1}		= $n1;
		$transp->{_note}		= $transp->{_note}.' n1='.$transp->{_n1};
		$transp->{_Step}		= $transp->{_Step}.' n1='.$transp->{_n1};

	} else { 
		print("transp, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$transp->{_n2}		= $n2;
		$transp->{_note}		= $transp->{_note}.' n2='.$transp->{_n2};
		$transp->{_Step}		= $transp->{_Step}.' n2='.$transp->{_n2};

	} else { 
		print("transp, n2, missing n2,\n");
	 }
 }


=head2 sub nbpe 


=cut

 sub nbpe {

	my ( $self,$nbpe )		= @_;
	if ( $nbpe ne $empty_string ) {

		$transp->{_nbpe}		= $nbpe;
		$transp->{_note}		= $transp->{_note}.' nbpe='.$transp->{_nbpe};
		$transp->{_Step}		= $transp->{_Step}.' nbpe='.$transp->{_nbpe};

	} else { 
		print("transp, nbpe, missing nbpe,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$transp->{_verbose}		= $verbose;
		$transp->{_note}		= $transp->{_note}.' verbose='.$transp->{_verbose};
		$transp->{_Step}		= $transp->{_Step}.' verbose='.$transp->{_verbose};

	} else { 
		print("transp, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 3;

    return($max_index);
}
 
 
1; 
