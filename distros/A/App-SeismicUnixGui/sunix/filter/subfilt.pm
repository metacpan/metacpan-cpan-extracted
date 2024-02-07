package App::SeismicUnixGui::sunix::filter::subfilt;

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
 SUBFILT - apply Butterworth bandpass filter 			



 subfilt <stdin >stdout [optional parameters]			



 Required parameters:						

 	if dt is not set in header, then dt is mandatory	



 Optional parameters: (nyquist calculated internally)		

 	zerophase=1		=0 for minimum phase filter 	

 	locut=1			=0 for no low cut filter 	

 	hicut=1			=0 for no high cut filter 	

 	fstoplo=0.10*(nyq)	freq(Hz) in low cut stop band	

 	astoplo=0.05		upper bound on amp at fstoplo 	

 	fpasslo=0.15*(nyq)	freq(Hz) in low cut pass band	

 	apasslo=0.95		lower bound on amp at fpasslo 	

 	fpasshi=0.40*(nyq)	freq(Hz) in high cut pass band	

 	apasshi=0.95		lower bound on amp at fpasshi 	

 	fstophi=0.55*(nyq)	freq(Hz) in high cut stop band	

 	astophi=0.05		upper bound on amp at fstophi 	

 	verbose=0		=1 for filter design info 	

 	dt = (from header)	time sampling interval (sec)	



 ... or  set filter by defining  poles and 3db cutoff frequencies

	npoleselo=calculated     number of poles of the lo pass band

	npolesehi=calculated     number of poles of the lo pass band

	f3dblo=calculated	frequency of 3db cutoff frequency

	f3dbhi=calculated	frequency of 3db cutoff frequency



 Notes:						        

 Butterworth filters were originally of interest because they  

 can be implemented in hardware form through the combination of

 inductors, capacitors, and an amplifier. Such a filter can be 

 constructed in such a way as to have very small oscillations	

 in the flat portion of the bandpass---a desireable attribute.	

 Because the filters are composed of LC circuits, the impulse  

 response is an ordinary differential equation, which translates

 into a polynomial in the transform domain. The filter is expressed

 as the division by this polynomial. Hence the poles of the filter

 are of interest.					        



 The user may define low pass, high pass, and band pass filters

 that are either minimum phase or are zero phase.  The default	

 is to let the program calculate the optimal number of poles in

 low and high cut bands. 					



 Alternately the user may manually define the filter by the 3db

 frequency and by the number of poles in the low and or high	

 cut region. 							



 The advantage of using the alternate method is that the user  

 can control the smoothness of the filter. Greater smoothness  

 through a larger pole number results in a more bell shaped    

 amplitude spectrum.						



 For simple zero phase filtering with sin squared tapering use 

 "sufilter".						        



 Credits:

	CWP: Dave Hale c. 1993 for bf.c subs and test drivers

	CWP: Jack K. Cohen for su wrapper c. 1993

      SEAM Project: Bruce Verwest 2009 added explicit pole option

                    in a program called "subfiltpole"

      CWP: John Stockwell (2012) combined Bruce Verwests changes

           into the original subfilt.



 Caveat: zerophase will not do good if trace has a spike near

	   the end.  One could make a try at getting the "effective"

	   length of the causal filter, but padding the traces seems

	   painful in an already expensive algorithm.





 Theory:

 The 



 Trace header fields accessed: ns, dt, trid



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

my $subfilt			= {
	_apasshi					=> '',
	_apasslo					=> '',
	_astophi					=> '',
	_astoplo					=> '',
	_dt					=> '',
	_f3dbhi					=> '',
	_f3dblo					=> '',
	_fpasshi					=> '',
	_fpasslo					=> '',
	_fstophi					=> '',
	_fstoplo					=> '',
	_hicut					=> '',
	_locut					=> '',
	_npolesehi					=> '',
	_npoleselo					=> '',
	_verbose					=> '',
	_zerophase					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$subfilt->{_Step}     = 'subfilt'.$subfilt->{_Step};
	return ( $subfilt->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$subfilt->{_note}     = 'subfilt'.$subfilt->{_note};
	return ( $subfilt->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$subfilt->{_apasshi}			= '';
		$subfilt->{_apasslo}			= '';
		$subfilt->{_astophi}			= '';
		$subfilt->{_astoplo}			= '';
		$subfilt->{_dt}			= '';
		$subfilt->{_f3dbhi}			= '';
		$subfilt->{_f3dblo}			= '';
		$subfilt->{_fpasshi}			= '';
		$subfilt->{_fpasslo}			= '';
		$subfilt->{_fstophi}			= '';
		$subfilt->{_fstoplo}			= '';
		$subfilt->{_hicut}			= '';
		$subfilt->{_locut}			= '';
		$subfilt->{_npolesehi}			= '';
		$subfilt->{_npoleselo}			= '';
		$subfilt->{_verbose}			= '';
		$subfilt->{_zerophase}			= '';
		$subfilt->{_Step}			= '';
		$subfilt->{_note}			= '';
 }


=head2 sub apasshi 


=cut

 sub apasshi {

	my ( $self,$apasshi )		= @_;
	if ( $apasshi ne $empty_string ) {

		$subfilt->{_apasshi}		= $apasshi;
		$subfilt->{_note}		= $subfilt->{_note}.' apasshi='.$subfilt->{_apasshi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' apasshi='.$subfilt->{_apasshi};

	} else { 
		print("subfilt, apasshi, missing apasshi,\n");
	 }
 }


=head2 sub apasslo 


=cut

 sub apasslo {

	my ( $self,$apasslo )		= @_;
	if ( $apasslo ne $empty_string ) {

		$subfilt->{_apasslo}		= $apasslo;
		$subfilt->{_note}		= $subfilt->{_note}.' apasslo='.$subfilt->{_apasslo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' apasslo='.$subfilt->{_apasslo};

	} else { 
		print("subfilt, apasslo, missing apasslo,\n");
	 }
 }


=head2 sub astophi 


=cut

 sub astophi {

	my ( $self,$astophi )		= @_;
	if ( $astophi ne $empty_string ) {

		$subfilt->{_astophi}		= $astophi;
		$subfilt->{_note}		= $subfilt->{_note}.' astophi='.$subfilt->{_astophi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' astophi='.$subfilt->{_astophi};

	} else { 
		print("subfilt, astophi, missing astophi,\n");
	 }
 }


=head2 sub astoplo 


=cut

 sub astoplo {

	my ( $self,$astoplo )		= @_;
	if ( $astoplo ne $empty_string ) {

		$subfilt->{_astoplo}		= $astoplo;
		$subfilt->{_note}		= $subfilt->{_note}.' astoplo='.$subfilt->{_astoplo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' astoplo='.$subfilt->{_astoplo};

	} else { 
		print("subfilt, astoplo, missing astoplo,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$subfilt->{_dt}		= $dt;
		$subfilt->{_note}		= $subfilt->{_note}.' dt='.$subfilt->{_dt};
		$subfilt->{_Step}		= $subfilt->{_Step}.' dt='.$subfilt->{_dt};

	} else { 
		print("subfilt, dt, missing dt,\n");
	 }
 }


=head2 sub f3dbhi 


=cut

 sub f3dbhi {

	my ( $self,$f3dbhi )		= @_;
	if ( $f3dbhi ne $empty_string ) {

		$subfilt->{_f3dbhi}		= $f3dbhi;
		$subfilt->{_note}		= $subfilt->{_note}.' f3dbhi='.$subfilt->{_f3dbhi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' f3dbhi='.$subfilt->{_f3dbhi};

	} else { 
		print("subfilt, f3dbhi, missing f3dbhi,\n");
	 }
 }


=head2 sub f3dblo 


=cut

 sub f3dblo {

	my ( $self,$f3dblo )		= @_;
	if ( $f3dblo ne $empty_string ) {

		$subfilt->{_f3dblo}		= $f3dblo;
		$subfilt->{_note}		= $subfilt->{_note}.' f3dblo='.$subfilt->{_f3dblo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' f3dblo='.$subfilt->{_f3dblo};

	} else { 
		print("subfilt, f3dblo, missing f3dblo,\n");
	 }
 }


=head2 sub fpasshi 


=cut

 sub fpasshi {

	my ( $self,$fpasshi )		= @_;
	if ( $fpasshi ne $empty_string ) {

		$subfilt->{_fpasshi}		= $fpasshi;
		$subfilt->{_note}		= $subfilt->{_note}.' fpasshi='.$subfilt->{_fpasshi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' fpasshi='.$subfilt->{_fpasshi};

	} else { 
		print("subfilt, fpasshi, missing fpasshi,\n");
	 }
 }


=head2 sub fpasslo 


=cut

 sub fpasslo {

	my ( $self,$fpasslo )		= @_;
	if ( $fpasslo ne $empty_string ) {

		$subfilt->{_fpasslo}		= $fpasslo;
		$subfilt->{_note}		= $subfilt->{_note}.' fpasslo='.$subfilt->{_fpasslo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' fpasslo='.$subfilt->{_fpasslo};

	} else { 
		print("subfilt, fpasslo, missing fpasslo,\n");
	 }
 }


=head2 sub fstophi 


=cut

 sub fstophi {

	my ( $self,$fstophi )		= @_;
	if ( $fstophi ne $empty_string ) {

		$subfilt->{_fstophi}		= $fstophi;
		$subfilt->{_note}		= $subfilt->{_note}.' fstophi='.$subfilt->{_fstophi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' fstophi='.$subfilt->{_fstophi};

	} else { 
		print("subfilt, fstophi, missing fstophi,\n");
	 }
 }


=head2 sub fstoplo 


=cut

 sub fstoplo {

	my ( $self,$fstoplo )		= @_;
	if ( $fstoplo ne $empty_string ) {

		$subfilt->{_fstoplo}		= $fstoplo;
		$subfilt->{_note}		= $subfilt->{_note}.' fstoplo='.$subfilt->{_fstoplo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' fstoplo='.$subfilt->{_fstoplo};

	} else { 
		print("subfilt, fstoplo, missing fstoplo,\n");
	 }
 }


=head2 sub hicut 


=cut

 sub hicut {

	my ( $self,$hicut )		= @_;
	if ( $hicut ne $empty_string ) {

		$subfilt->{_hicut}		= $hicut;
		$subfilt->{_note}		= $subfilt->{_note}.' hicut='.$subfilt->{_hicut};
		$subfilt->{_Step}		= $subfilt->{_Step}.' hicut='.$subfilt->{_hicut};

	} else { 
		print("subfilt, hicut, missing hicut,\n");
	 }
 }


=head2 sub locut 


=cut

 sub locut {

	my ( $self,$locut )		= @_;
	if ( $locut ne $empty_string ) {

		$subfilt->{_locut}		= $locut;
		$subfilt->{_note}		= $subfilt->{_note}.' locut='.$subfilt->{_locut};
		$subfilt->{_Step}		= $subfilt->{_Step}.' locut='.$subfilt->{_locut};

	} else { 
		print("subfilt, locut, missing locut,\n");
	 }
 }


=head2 sub npolesehi 


=cut

 sub npolesehi {

	my ( $self,$npolesehi )		= @_;
	if ( $npolesehi ne $empty_string ) {

		$subfilt->{_npolesehi}		= $npolesehi;
		$subfilt->{_note}		= $subfilt->{_note}.' npolesehi='.$subfilt->{_npolesehi};
		$subfilt->{_Step}		= $subfilt->{_Step}.' npolesehi='.$subfilt->{_npolesehi};

	} else { 
		print("subfilt, npolesehi, missing npolesehi,\n");
	 }
 }


=head2 sub npoleselo 


=cut

 sub npoleselo {

	my ( $self,$npoleselo )		= @_;
	if ( $npoleselo ne $empty_string ) {

		$subfilt->{_npoleselo}		= $npoleselo;
		$subfilt->{_note}		= $subfilt->{_note}.' npoleselo='.$subfilt->{_npoleselo};
		$subfilt->{_Step}		= $subfilt->{_Step}.' npoleselo='.$subfilt->{_npoleselo};

	} else { 
		print("subfilt, npoleselo, missing npoleselo,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$subfilt->{_verbose}		= $verbose;
		$subfilt->{_note}		= $subfilt->{_note}.' verbose='.$subfilt->{_verbose};
		$subfilt->{_Step}		= $subfilt->{_Step}.' verbose='.$subfilt->{_verbose};

	} else { 
		print("subfilt, verbose, missing verbose,\n");
	 }
 }


=head2 sub zerophase 


=cut

 sub zerophase {

	my ( $self,$zerophase )		= @_;
	if ( $zerophase ne $empty_string ) {

		$subfilt->{_zerophase}		= $zerophase;
		$subfilt->{_note}		= $subfilt->{_note}.' zerophase='.$subfilt->{_zerophase};
		$subfilt->{_Step}		= $subfilt->{_Step}.' zerophase='.$subfilt->{_zerophase};

	} else { 
		print("subfilt, zerophase, missing zerophase,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 16;

    return($max_index);
}
 
 
1;
