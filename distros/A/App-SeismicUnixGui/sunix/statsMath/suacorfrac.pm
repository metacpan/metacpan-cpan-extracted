package App::SeismicUnixGui::sunix::statsMath::suacorfrac;

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
 SUACORFRAC -- general FRACtional Auto-CORrelation/convolution		



 suacorfrac power= [optional parameters] <indata >outdata 		



 Optional parameters:							

 a=0			exponent of complex amplitude	 		

 b=0			multiplier of complex phase	 		

 dt=(from header)	time sample interval (in seconds)		

 verbose=0		=1 for advisory messages			

 ntout=tr.ns		number of time samples output			

 sym=0			if non-zero, produce a symmetric output from	

			lag -(ntout-1)/2 to lag +(ntout-1)/2		

 Notes:								

 The calculation is performed in the frequency domain.			

 The fractional autocorrelation/convolution is obtained by raising	

 Fourier coefficients to separate real powers 				

		(a,b) for amp and phase:				

		     Aout exp[-i Pout] = Ain Ain^a exp[-i (1+b) Pin] 	

		where A=amplitude  P=phase.				

 Some special cases:							

		(a,b)=(1,1)	-->	auto-correlation		

		(a,b)=(0.5,0.5)	-->	half-auto-correlation		

		(a,b)=(0,0)	-->	no change to data		

		(a,b)=(0.5,-0.5)-->	half-auto-convolution		

		(a,b)=(1,-1)	-->	auto-convolution		





 Credits:

	UHouston: Chris Liner, Sept 2009

	CWP: Based on Hale's crpow



 Trace header fields accessed: ns, dt, trid, d1

/

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

my $suacorfrac			= {
	_A					=> '',
	_a					=> '',
	_b					=> '',
	_dt					=> '',
	_ntout					=> '',
	_power					=> '',
	_sym					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suacorfrac->{_Step}     = 'suacorfrac'.$suacorfrac->{_Step};
	return ( $suacorfrac->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suacorfrac->{_note}     = 'suacorfrac'.$suacorfrac->{_note};
	return ( $suacorfrac->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suacorfrac->{_A}			= '';
		$suacorfrac->{_a}			= '';
		$suacorfrac->{_b}			= '';
		$suacorfrac->{_dt}			= '';
		$suacorfrac->{_ntout}			= '';
		$suacorfrac->{_power}			= '';
		$suacorfrac->{_sym}			= '';
		$suacorfrac->{_verbose}			= '';
		$suacorfrac->{_Step}			= '';
		$suacorfrac->{_note}			= '';
 }


=head2 sub A 


=cut

 sub A {

	my ( $self,$A )		= @_;
	if ( $A ne $empty_string ) {

		$suacorfrac->{_A}		= $A;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' A='.$suacorfrac->{_A};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' A='.$suacorfrac->{_A};

	} else { 
		print("suacorfrac, A, missing A,\n");
	 }
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$suacorfrac->{_a}		= $a;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' a='.$suacorfrac->{_a};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' a='.$suacorfrac->{_a};

	} else { 
		print("suacorfrac, a, missing a,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$suacorfrac->{_b}		= $b;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' b='.$suacorfrac->{_b};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' b='.$suacorfrac->{_b};

	} else { 
		print("suacorfrac, b, missing b,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suacorfrac->{_dt}		= $dt;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' dt='.$suacorfrac->{_dt};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' dt='.$suacorfrac->{_dt};

	} else { 
		print("suacorfrac, dt, missing dt,\n");
	 }
 }


=head2 sub ntout 


=cut

 sub ntout {

	my ( $self,$ntout )		= @_;
	if ( $ntout ne $empty_string ) {

		$suacorfrac->{_ntout}		= $ntout;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' ntout='.$suacorfrac->{_ntout};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' ntout='.$suacorfrac->{_ntout};

	} else { 
		print("suacorfrac, ntout, missing ntout,\n");
	 }
 }


=head2 sub power 


=cut

 sub power {

	my ( $self,$power )		= @_;
	if ( $power ne $empty_string ) {

		$suacorfrac->{_power}		= $power;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' power='.$suacorfrac->{_power};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' power='.$suacorfrac->{_power};

	} else { 
		print("suacorfrac, power, missing power,\n");
	 }
 }


=head2 sub sym 


=cut

 sub sym {

	my ( $self,$sym )		= @_;
	if ( $sym ne $empty_string ) {

		$suacorfrac->{_sym}		= $sym;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' sym='.$suacorfrac->{_sym};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' sym='.$suacorfrac->{_sym};

	} else { 
		print("suacorfrac, sym, missing sym,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suacorfrac->{_verbose}		= $verbose;
		$suacorfrac->{_note}		= $suacorfrac->{_note}.' verbose='.$suacorfrac->{_verbose};
		$suacorfrac->{_Step}		= $suacorfrac->{_Step}.' verbose='.$suacorfrac->{_verbose};

	} else { 
		print("suacorfrac, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
