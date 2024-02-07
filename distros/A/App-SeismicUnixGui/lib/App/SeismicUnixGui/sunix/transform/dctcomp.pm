package App::SeismicUnixGui::sunix::transform::dctcomp;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 DCTCOMP - Compression by Discrete Cosine Transform			



   dctcomp < stdin n1= n2=   [optional parameter] > sdtout		



 Required Parameters:							

 n1=			number of samples in the fast (first) dimension	

 n2=			number of samples in the slow (second) dimension

 Optional Parameters:							

 blocksize1=16		blocksize in direction 1			

 blocksize2=16		blocksize in direction 2			

 error=0.01		acceptable error				


 Author:  CWP: Tong Chen   Dec 1995


=head2 User's notes: Juan Lorenzo

Untested  9.4.21

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

my $dctcomp			= {
	_blocksize1					=> '',
	_blocksize2					=> '',
	_error					=> '',
	_n1					=> '',
	_n2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$dctcomp->{_Step}     = 'dctcomp'.$dctcomp->{_Step};
	return ( $dctcomp->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$dctcomp->{_note}     = 'dctcomp'.$dctcomp->{_note};
	return ( $dctcomp->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$dctcomp->{_blocksize1}			= '';
		$dctcomp->{_blocksize2}			= '';
		$dctcomp->{_error}			= '';
		$dctcomp->{_n1}			= '';
		$dctcomp->{_n2}			= '';
		$dctcomp->{_Step}			= '';
		$dctcomp->{_note}			= '';
 }


=head2 sub blocksize1 


=cut

 sub blocksize1 {

	my ( $self,$blocksize1 )		= @_;
	if ( $blocksize1 ne $empty_string ) {

		$dctcomp->{_blocksize1}		= $blocksize1;
		$dctcomp->{_note}		= $dctcomp->{_note}.' blocksize1='.$dctcomp->{_blocksize1};
		$dctcomp->{_Step}		= $dctcomp->{_Step}.' blocksize1='.$dctcomp->{_blocksize1};

	} else { 
		print("dctcomp, blocksize1, missing blocksize1,\n");
	 }
 }


=head2 sub blocksize2 


=cut

 sub blocksize2 {

	my ( $self,$blocksize2 )		= @_;
	if ( $blocksize2 ne $empty_string ) {

		$dctcomp->{_blocksize2}		= $blocksize2;
		$dctcomp->{_note}		= $dctcomp->{_note}.' blocksize2='.$dctcomp->{_blocksize2};
		$dctcomp->{_Step}		= $dctcomp->{_Step}.' blocksize2='.$dctcomp->{_blocksize2};

	} else { 
		print("dctcomp, blocksize2, missing blocksize2,\n");
	 }
 }


=head2 sub error 


=cut

 sub error {

	my ( $self,$error )		= @_;
	if ( $error ne $empty_string ) {

		$dctcomp->{_error}		= $error;
		$dctcomp->{_note}		= $dctcomp->{_note}.' error='.$dctcomp->{_error};
		$dctcomp->{_Step}		= $dctcomp->{_Step}.' error='.$dctcomp->{_error};

	} else { 
		print("dctcomp, error, missing error,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$dctcomp->{_n1}		= $n1;
		$dctcomp->{_note}		= $dctcomp->{_note}.' n1='.$dctcomp->{_n1};
		$dctcomp->{_Step}		= $dctcomp->{_Step}.' n1='.$dctcomp->{_n1};

	} else { 
		print("dctcomp, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$dctcomp->{_n2}		= $n2;
		$dctcomp->{_note}		= $dctcomp->{_note}.' n2='.$dctcomp->{_n2};
		$dctcomp->{_Step}		= $dctcomp->{_Step}.' n2='.$dctcomp->{_n2};

	} else { 
		print("dctcomp, n2, missing n2,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 4;

    return($max_index);
}
 
 
1; 
