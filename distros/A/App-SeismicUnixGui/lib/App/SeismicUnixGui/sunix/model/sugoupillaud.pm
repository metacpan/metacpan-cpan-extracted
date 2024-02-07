package App::SeismicUnixGui::sunix::model::sugoupillaud;

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
 SUGOUPILLAUD - calculate 1D impulse response of	 		

     non-absorbing Goupillaud medium					



 sugoupillaud < stdin > stdout [optional parameters]			



 Required parameters:							

	none								



 Optional parameters:							

l=1 source layer number; 1 <= l <= tr.ns				

			Source is located at the top of layer l.	

	k=1		receiver layer number; 1 <= k			

Receiver is located at the top of layer k.				

tmax  number of output time-samples; default:				

tmax=NINT((2*tr.ns-(l-1)-(k-1))/2)  if k < tr.ns			

			tmax=k				if k >=tr.ns	

pV=1  flag for vector field seismogram					

	(displacement, velocity, acceleration);				

=-1 for pressure seismogram.						

verbose=0  silent operation, =1 list warnings				



 Input: Reflection coefficient series:					



	 impedance[i]-impedance[i+1]					

 r[i] = ----------------------------- 					

	 impedance[i]+impedance[i+1]					



	r[0]= surface refl. coef. (as seen from above)			

r[n]= refl. coef. of the deepest interface				



 Input file is to be in SU format, i.e., binary floats with a SU header.



 Remarks:								

 1. For vector fields, a buried source produces a spike of amplitude 1	

 propagating downwards and a spike of amplitude -1 propagating upwards.

 A buried pressure source produces spikes of amplitude 1 both in the up

 and downward directions.						



 A surface source induces only a downgoing spike of amplitude 1 at the	

 top of the first layer (both for vector and pressure fields).		

 2. The sampling interval dt in the header of the input reflectivity file

 is interpreted as a two-way traveltime thicknes of the layers. The sampling

 interval of the output seismogram is the same as that of the input file.



 

 Credits:

	CWP: Albena Mateeva, May 2000, a summer project at Western Geophysical





 ANOTATION used in the code comments [arises from the use of z-transforms]:

		Z-sampled: sampling interval equal to the TWO-way 

			traveltime of the layers; 

		z-sampled: sampling interval equal to the ONE-way

			traveltime of the layers;



 REFERENCES:



	1. Ganley, D. C., 1981, A method for calculating synthetic seismograms 

	which include the effects of absorption and dispersion. 

	Geophysics, Vol.46, No. 8, p. 1100-1107.

 

	The burial of the source is based on the Appendix of that article.



	2. Robinson, E. A., Multichannel Time Series Analysis with Digital 

	Computer Programs: 1983 Goose Pond Press, 2nd edition.



	The recursive polynomials Q, P used in this code are described

	in Chapter 3 of the book: Wave Propagation in Layered Media.



	My polynomial multiplication and division functions "prod" and

	"pratio" are based on Robinson's Fortran subroutines in Chapter 1.



	4. Clearbout, J. F., Fundamentals of Geophysical Data Processing with

	Applications to Petroleum Prospecting: 1985 Blackwell Scientific 

	Publications.



	Chapter 8, Section 3: Introduces recursive polynomials F, G in a 

	more intuitive way than Robinson.

	

	The connection between the Robinson's P_k, Q_k and Clearbout's 

	F_k, G_k is:

				P_k(Z) = F_k(Z)

				Q_k(Z) = - Z^(k) G_k(1/Z)





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

my $sugoupillaud			= {
	_k					=> '',
	_l					=> '',
	_pV					=> '',
	_tmax					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sugoupillaud->{_Step}     = 'sugoupillaud'.$sugoupillaud->{_Step};
	return ( $sugoupillaud->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sugoupillaud->{_note}     = 'sugoupillaud'.$sugoupillaud->{_note};
	return ( $sugoupillaud->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sugoupillaud->{_k}			= '';
		$sugoupillaud->{_l}			= '';
		$sugoupillaud->{_pV}			= '';
		$sugoupillaud->{_tmax}			= '';
		$sugoupillaud->{_verbose}			= '';
		$sugoupillaud->{_Step}			= '';
		$sugoupillaud->{_note}			= '';
 }


=head2 sub k 


=cut

 sub k {

	my ( $self,$k )		= @_;
	if ( $k ne $empty_string ) {

		$sugoupillaud->{_k}		= $k;
		$sugoupillaud->{_note}		= $sugoupillaud->{_note}.' k='.$sugoupillaud->{_k};
		$sugoupillaud->{_Step}		= $sugoupillaud->{_Step}.' k='.$sugoupillaud->{_k};

	} else { 
		print("sugoupillaud, k, missing k,\n");
	 }
 }


=head2 sub l 


=cut

 sub l {

	my ( $self,$l )		= @_;
	if ( $l ne $empty_string ) {

		$sugoupillaud->{_l}		= $l;
		$sugoupillaud->{_note}		= $sugoupillaud->{_note}.' l='.$sugoupillaud->{_l};
		$sugoupillaud->{_Step}		= $sugoupillaud->{_Step}.' l='.$sugoupillaud->{_l};

	} else { 
		print("sugoupillaud, l, missing l,\n");
	 }
 }


=head2 sub pV 


=cut

 sub pV {

	my ( $self,$pV )		= @_;
	if ( $pV ne $empty_string ) {

		$sugoupillaud->{_pV}		= $pV;
		$sugoupillaud->{_note}		= $sugoupillaud->{_note}.' pV='.$sugoupillaud->{_pV};
		$sugoupillaud->{_Step}		= $sugoupillaud->{_Step}.' pV='.$sugoupillaud->{_pV};

	} else { 
		print("sugoupillaud, pV, missing pV,\n");
	 }
 }


=head2 sub tmax 


=cut

 sub tmax {

	my ( $self,$tmax )		= @_;
	if ( $tmax ne $empty_string ) {

		$sugoupillaud->{_tmax}		= $tmax;
		$sugoupillaud->{_note}		= $sugoupillaud->{_note}.' tmax='.$sugoupillaud->{_tmax};
		$sugoupillaud->{_Step}		= $sugoupillaud->{_Step}.' tmax='.$sugoupillaud->{_tmax};

	} else { 
		print("sugoupillaud, tmax, missing tmax,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sugoupillaud->{_verbose}		= $verbose;
		$sugoupillaud->{_note}		= $sugoupillaud->{_note}.' verbose='.$sugoupillaud->{_verbose};
		$sugoupillaud->{_Step}		= $sugoupillaud->{_Step}.' verbose='.$sugoupillaud->{_verbose};

	} else { 
		print("sugoupillaud, verbose, missing verbose,\n");
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
