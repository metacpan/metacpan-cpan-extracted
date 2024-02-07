package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sutivel;

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
  SUTIVEL -  SU Transversely Isotropic velocity table builder		

	computes vnmo or vphase as a function of Thomsen's parameters and

	theta and optionally interpolate to constant increments in slowness



 Optional Parameters:							

 a=2500.		alpha (vertical p velocity)			

 b=1250.		beta (vertical sv velocity)			

 e=.20			epsilon (horiz p-wave anisotropy)		

 d=.10			delta (strange parameter)			

 maxangle=90.0		max angle in degrees				

 nangle=9001		number of angles to compute			

 verbose=0		set to 1 to see full listing			

 np=8001		number of slowness values to output		

 option=1		1=output vnmo(p) (result used for TI DMO)	

			option=2:output vnmo(theta) in degrees			

			option=3:output vnmo(theta) in radians			

			option=4:output vphase(p)				

			option=5:output vphase(theta) in degrees		

			option=6:output vphase(theta) in radians		

			option=7:output first derivative vphase(p)		

			option=8:output first derivative vphase(theta) in degrees

			option=9:output first derivative vphase(theta) in radians

			option=10:output second derivative vphase(p)		

			option=11:output second derivative vphase(theta) in degrees

			option=12:output second derivative vphase(theta) in radians

			option=13:( 1/vnmo(0)^2 -1/vnmo(theta)^2 )/p^2 test vs theta

			   (result should be zero for all theta for d=e)

			option=14:return vnmo(p) for weak anisotropy		

 normalize=0		=1 means scale vnmo by cosine and scale vphase by

 			    1/sqrt(1+2*e*sin(theta)*sin(theta)		

	 		   (only useful for vphase when d=e for constant

				result)					

			=0 means output vnmo or vphase unnormalized	



 Output on standard output is ascii text with:				

 line   1: number of values						

 line   2: abscissa increment (p or theta increment, always starts at zero)

 line 3-n: one value per line						







 Author: (visitor to CSM form Mobil) John E. Anderson, Spring 1994



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

my $sutivel			= {
	_a					=> '',
	_b					=> '',
	_d					=> '',
	_e					=> '',
	_maxangle					=> '',
	_nangle					=> '',
	_normalize					=> '',
	_np					=> '',
	_option					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sutivel->{_Step}     = 'sutivel'.$sutivel->{_Step};
	return ( $sutivel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sutivel->{_note}     = 'sutivel'.$sutivel->{_note};
	return ( $sutivel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sutivel->{_a}			= '';
		$sutivel->{_b}			= '';
		$sutivel->{_d}			= '';
		$sutivel->{_e}			= '';
		$sutivel->{_maxangle}			= '';
		$sutivel->{_nangle}			= '';
		$sutivel->{_normalize}			= '';
		$sutivel->{_np}			= '';
		$sutivel->{_option}			= '';
		$sutivel->{_verbose}			= '';
		$sutivel->{_Step}			= '';
		$sutivel->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$sutivel->{_a}		= $a;
		$sutivel->{_note}		= $sutivel->{_note}.' a='.$sutivel->{_a};
		$sutivel->{_Step}		= $sutivel->{_Step}.' a='.$sutivel->{_a};

	} else { 
		print("sutivel, a, missing a,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$sutivel->{_b}		= $b;
		$sutivel->{_note}		= $sutivel->{_note}.' b='.$sutivel->{_b};
		$sutivel->{_Step}		= $sutivel->{_Step}.' b='.$sutivel->{_b};

	} else { 
		print("sutivel, b, missing b,\n");
	 }
 }


=head2 sub d 


=cut

 sub d {

	my ( $self,$d )		= @_;
	if ( $d ne $empty_string ) {

		$sutivel->{_d}		= $d;
		$sutivel->{_note}		= $sutivel->{_note}.' d='.$sutivel->{_d};
		$sutivel->{_Step}		= $sutivel->{_Step}.' d='.$sutivel->{_d};

	} else { 
		print("sutivel, d, missing d,\n");
	 }
 }


=head2 sub e 


=cut

 sub e {

	my ( $self,$e )		= @_;
	if ( $e ne $empty_string ) {

		$sutivel->{_e}		= $e;
		$sutivel->{_note}		= $sutivel->{_note}.' e='.$sutivel->{_e};
		$sutivel->{_Step}		= $sutivel->{_Step}.' e='.$sutivel->{_e};

	} else { 
		print("sutivel, e, missing e,\n");
	 }
 }


=head2 sub maxangle 


=cut

 sub maxangle {

	my ( $self,$maxangle )		= @_;
	if ( $maxangle ne $empty_string ) {

		$sutivel->{_maxangle}		= $maxangle;
		$sutivel->{_note}		= $sutivel->{_note}.' maxangle='.$sutivel->{_maxangle};
		$sutivel->{_Step}		= $sutivel->{_Step}.' maxangle='.$sutivel->{_maxangle};

	} else { 
		print("sutivel, maxangle, missing maxangle,\n");
	 }
 }


=head2 sub nangle 


=cut

 sub nangle {

	my ( $self,$nangle )		= @_;
	if ( $nangle ne $empty_string ) {

		$sutivel->{_nangle}		= $nangle;
		$sutivel->{_note}		= $sutivel->{_note}.' nangle='.$sutivel->{_nangle};
		$sutivel->{_Step}		= $sutivel->{_Step}.' nangle='.$sutivel->{_nangle};

	} else { 
		print("sutivel, nangle, missing nangle,\n");
	 }
 }


=head2 sub normalize 


=cut

 sub normalize {

	my ( $self,$normalize )		= @_;
	if ( $normalize ne $empty_string ) {

		$sutivel->{_normalize}		= $normalize;
		$sutivel->{_note}		= $sutivel->{_note}.' normalize='.$sutivel->{_normalize};
		$sutivel->{_Step}		= $sutivel->{_Step}.' normalize='.$sutivel->{_normalize};

	} else { 
		print("sutivel, normalize, missing normalize,\n");
	 }
 }


=head2 sub np 


=cut

 sub np {

	my ( $self,$np )		= @_;
	if ( $np ne $empty_string ) {

		$sutivel->{_np}		= $np;
		$sutivel->{_note}		= $sutivel->{_note}.' np='.$sutivel->{_np};
		$sutivel->{_Step}		= $sutivel->{_Step}.' np='.$sutivel->{_np};

	} else { 
		print("sutivel, np, missing np,\n");
	 }
 }


=head2 sub option 


=cut

 sub option {

	my ( $self,$option )		= @_;
	if ( $option ne $empty_string ) {

		$sutivel->{_option}		= $option;
		$sutivel->{_note}		= $sutivel->{_note}.' option='.$sutivel->{_option};
		$sutivel->{_Step}		= $sutivel->{_Step}.' option='.$sutivel->{_option};

	} else { 
		print("sutivel, option, missing option,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sutivel->{_verbose}		= $verbose;
		$sutivel->{_note}		= $sutivel->{_note}.' verbose='.$sutivel->{_verbose};
		$sutivel->{_Step}		= $sutivel->{_Step}.' verbose='.$sutivel->{_verbose};

	} else { 
		print("sutivel, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 9;

    return($max_index);
}
 
 
1;
