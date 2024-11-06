package App::SeismicUnixGui::sunix::transform::sucwt;

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
 SUCWT - generates Continous Wavelet Transform amplitude, regularity	

         analysis in the wavelet basis					



     sucwt < stdin [Optional parameters ] > stdout			



 Required Parameters:							

 none									



 Optional Parameters:							

 base=10	Base value for wavelet transform scales			

 first=-1	First exponent value for wavelet transform scales	

 expinc=0.01	Exponent increment for wavelet transform scales		

 last=1.5	Last exponent value for wavelet transform scales	



 Wavelet Parameters:							

 wtype=0		2nd derivative of Gaussian (Mexican hat)	

			=1 4th derivative of Gaussian (witch's hat)	

			=2 6th derivative of Gaussian (wizard's hat)	

 nwavelet=1024		number of samples in the wavelet		

 xmin=-20		minimum x value wavelet is computed		

 xcenter=0		center x value  wavelet is computed 		

 xmax=20		maximum x value wavelet is computed		

 sigma=1		sharpness parameter ( sigma > 1 sharper)	



 verbose=0		silent, =1 chatty				

 holder=0		=1 compute Holder regularity estimate		

 divisor=1.0		a floating point number >= 1.0 (see notes)	



 Notes: 								

 This is the CWT version of the time frequency analysis notion that is 

 applied in sugabor.							

 The parameter base is the base of the power that is applied to scale	

 the wavelet. Some mathematical literature assume base 2. Base 10 works

 well here.								



 Default option yields an output similar to that of sugabor. With the  

 parameter holder=1 an estimate of the instantaneous Holder regularity 

 (the Holder exponent) is output for each input data value. The result 

 is a Holder exponent trace for each corresponding input data trace.	



 The strict definition of the Holder exponent is the maximum slope of  

 the rise of the spectrum in the log(amplitude) versus log(scale) domain:



 divisor=1.0 means the exponent is computed simply by fitting a line   

 through all of the values in the transform. A value of divisor>1.0    

 indicates that the Holder exponent is determined as the max of slopes 

 found in (total scales)/divisor length segments.			



 Some experimentation with the parameters nwavelet, first, last, and   

 expinc may be necessary before a desirable output is obtained. The	

 most effective way to proceed is to perform a number of tests with    

 holder=0 to determine the range of first, last, and expinc that best  

 represents the data in the wavelet domain. Then experimentation with  

 holder=1 and values of divisor>=1.0 may proceed.			







 Credits: 

	CWP: John Stockwell, Nov 2004

 inspired in part by "bhpcwt" in the BHP_SU package, code written by

	BHP: Michael Glinsky,	c. 2002, based loosely on a Matlab CWT function



 References: 

         

 Li C.H., (2004), Information passage from acoustic impedence to

 seismogram: Perspectives from wavelet-based multiscale analysis, 

 Journal of Geophysical Research, vol. 109, B07301, p.1-10.

         

 Mallat, S. and  W. L. Hwang, (1992),  Singularity detection and

 processing with wavelets,  IEEE Transactions on information, v 38,

 March 1992, p.617 - 643.

         





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

my $sucwt			= {
	_base					=> '',
	_divisor					=> '',
	_expinc					=> '',
	_first					=> '',
	_holder					=> '',
	_last					=> '',
	_nwavelet					=> '',
	_sigma					=> '',
	_verbose					=> '',
	_wtype					=> '',
	_xcenter					=> '',
	_xmax					=> '',
	_xmin					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucwt->{_Step}     = 'sucwt'.$sucwt->{_Step};
	return ( $sucwt->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucwt->{_note}     = 'sucwt'.$sucwt->{_note};
	return ( $sucwt->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucwt->{_base}			= '';
		$sucwt->{_divisor}			= '';
		$sucwt->{_expinc}			= '';
		$sucwt->{_first}			= '';
		$sucwt->{_holder}			= '';
		$sucwt->{_last}			= '';
		$sucwt->{_nwavelet}			= '';
		$sucwt->{_sigma}			= '';
		$sucwt->{_verbose}			= '';
		$sucwt->{_wtype}			= '';
		$sucwt->{_xcenter}			= '';
		$sucwt->{_xmax}			= '';
		$sucwt->{_xmin}			= '';
		$sucwt->{_Step}			= '';
		$sucwt->{_note}			= '';
 }


=head2 sub base 


=cut

 sub base {

	my ( $self,$base )		= @_;
	if ( $base ne $empty_string ) {

		$sucwt->{_base}		= $base;
		$sucwt->{_note}		= $sucwt->{_note}.' base='.$sucwt->{_base};
		$sucwt->{_Step}		= $sucwt->{_Step}.' base='.$sucwt->{_base};

	} else { 
		print("sucwt, base, missing base,\n");
	 }
 }


=head2 sub divisor 


=cut

 sub divisor {

	my ( $self,$divisor )		= @_;
	if ( $divisor ne $empty_string ) {

		$sucwt->{_divisor}		= $divisor;
		$sucwt->{_note}		= $sucwt->{_note}.' divisor='.$sucwt->{_divisor};
		$sucwt->{_Step}		= $sucwt->{_Step}.' divisor='.$sucwt->{_divisor};

	} else { 
		print("sucwt, divisor, missing divisor,\n");
	 }
 }


=head2 sub expinc 


=cut

 sub expinc {

	my ( $self,$expinc )		= @_;
	if ( $expinc ne $empty_string ) {

		$sucwt->{_expinc}		= $expinc;
		$sucwt->{_note}		= $sucwt->{_note}.' expinc='.$sucwt->{_expinc};
		$sucwt->{_Step}		= $sucwt->{_Step}.' expinc='.$sucwt->{_expinc};

	} else { 
		print("sucwt, expinc, missing expinc,\n");
	 }
 }


=head2 sub first 


=cut

 sub first {

	my ( $self,$first )		= @_;
	if ( $first ne $empty_string ) {

		$sucwt->{_first}		= $first;
		$sucwt->{_note}		= $sucwt->{_note}.' first='.$sucwt->{_first};
		$sucwt->{_Step}		= $sucwt->{_Step}.' first='.$sucwt->{_first};

	} else { 
		print("sucwt, first, missing first,\n");
	 }
 }


=head2 sub holder 


=cut

 sub holder {

	my ( $self,$holder )		= @_;
	if ( $holder ne $empty_string ) {

		$sucwt->{_holder}		= $holder;
		$sucwt->{_note}		= $sucwt->{_note}.' holder='.$sucwt->{_holder};
		$sucwt->{_Step}		= $sucwt->{_Step}.' holder='.$sucwt->{_holder};

	} else { 
		print("sucwt, holder, missing holder,\n");
	 }
 }


=head2 sub last 


=cut

 sub last {

	my ( $self,$last )		= @_;
	if ( $last ne $empty_string ) {

		$sucwt->{_last}		= $last;
		$sucwt->{_note}		= $sucwt->{_note}.' last='.$sucwt->{_last};
		$sucwt->{_Step}		= $sucwt->{_Step}.' last='.$sucwt->{_last};

	} else { 
		print("sucwt, last, missing last,\n");
	 }
 }


=head2 sub nwavelet 


=cut

 sub nwavelet {

	my ( $self,$nwavelet )		= @_;
	if ( $nwavelet ne $empty_string ) {

		$sucwt->{_nwavelet}		= $nwavelet;
		$sucwt->{_note}		= $sucwt->{_note}.' nwavelet='.$sucwt->{_nwavelet};
		$sucwt->{_Step}		= $sucwt->{_Step}.' nwavelet='.$sucwt->{_nwavelet};

	} else { 
		print("sucwt, nwavelet, missing nwavelet,\n");
	 }
 }


=head2 sub sigma 


=cut

 sub sigma {

	my ( $self,$sigma )		= @_;
	if ( $sigma ne $empty_string ) {

		$sucwt->{_sigma}		= $sigma;
		$sucwt->{_note}		= $sucwt->{_note}.' sigma='.$sucwt->{_sigma};
		$sucwt->{_Step}		= $sucwt->{_Step}.' sigma='.$sucwt->{_sigma};

	} else { 
		print("sucwt, sigma, missing sigma,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sucwt->{_verbose}		= $verbose;
		$sucwt->{_note}		= $sucwt->{_note}.' verbose='.$sucwt->{_verbose};
		$sucwt->{_Step}		= $sucwt->{_Step}.' verbose='.$sucwt->{_verbose};

	} else { 
		print("sucwt, verbose, missing verbose,\n");
	 }
 }


=head2 sub wtype 


=cut

 sub wtype {

	my ( $self,$wtype )		= @_;
	if ( $wtype ne $empty_string ) {

		$sucwt->{_wtype}		= $wtype;
		$sucwt->{_note}		= $sucwt->{_note}.' wtype='.$sucwt->{_wtype};
		$sucwt->{_Step}		= $sucwt->{_Step}.' wtype='.$sucwt->{_wtype};

	} else { 
		print("sucwt, wtype, missing wtype,\n");
	 }
 }


=head2 sub xcenter 


=cut

 sub xcenter {

	my ( $self,$xcenter )		= @_;
	if ( $xcenter ne $empty_string ) {

		$sucwt->{_xcenter}		= $xcenter;
		$sucwt->{_note}		= $sucwt->{_note}.' xcenter='.$sucwt->{_xcenter};
		$sucwt->{_Step}		= $sucwt->{_Step}.' xcenter='.$sucwt->{_xcenter};

	} else { 
		print("sucwt, xcenter, missing xcenter,\n");
	 }
 }


=head2 sub xmax 


=cut

 sub xmax {

	my ( $self,$xmax )		= @_;
	if ( $xmax ne $empty_string ) {

		$sucwt->{_xmax}		= $xmax;
		$sucwt->{_note}		= $sucwt->{_note}.' xmax='.$sucwt->{_xmax};
		$sucwt->{_Step}		= $sucwt->{_Step}.' xmax='.$sucwt->{_xmax};

	} else { 
		print("sucwt, xmax, missing xmax,\n");
	 }
 }


=head2 sub xmin 


=cut

 sub xmin {

	my ( $self,$xmin )		= @_;
	if ( $xmin ne $empty_string ) {

		$sucwt->{_xmin}		= $xmin;
		$sucwt->{_note}		= $sucwt->{_note}.' xmin='.$sucwt->{_xmin};
		$sucwt->{_Step}		= $sucwt->{_Step}.' xmin='.$sucwt->{_xmin};

	} else { 
		print("sucwt, xmin, missing xmin,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
