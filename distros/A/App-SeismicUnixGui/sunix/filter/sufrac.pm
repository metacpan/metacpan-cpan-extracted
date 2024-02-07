package App::SeismicUnixGui::sunix::filter::sufrac;

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
 SUFRAC -- take general (fractional) time derivative or integral of	

	    data, plus a phase shift.  Input is CAUSAL time-indexed	

	    or depth-indexed data.					



 sufrac power= [optional parameters] <indata >outdata 			



 Optional parameters:							

	power=0		exponent of (-i*omega)	 			

			=0  ==> phase shift only			

			>0  ==> differentiation				

			<0  ==> integration				



	sign=-1			sign in front of i * omega		

	dt=(from header)	time sample interval (in seconds)	

	phasefac=0		phase shift by phase=phasefac*PI	

	verbose=0		=1 for advisory messages		



 Examples:								

  preprocess to correct 3D data for 2.5D migration			

         sufrac < sudata power=.5 sign=1 | ...				

  preprocess to correct susynlv, susynvxz, etc. (2D data) for 2D migration

         sufrac < sudata phasefac=.25 | ...				

 The filter is applied in frequency domain.				

 if dt is not set in header, then dt is mandatory			



 Algorithm:								

		g(t) = Re[INVFTT{ ( (sign) iw)^power FFT(f)}]		

 Caveat:								

 Large amplitude errors will result if the data set has too few points.



 Good numerical integration routine needed!				

 For example, see Gnu Scientific Library.				





 Credits:

	CWP: Chris Liner, Jack K. Cohen, Dave Hale (pfas)

      CWP: Zhenyue Liu and John Stockwell added phase shift option

	CENPET: Werner M. Heigl - added well log support



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

my $sufrac			= {
	_dt					=> '',
	_phasefac					=> '',
	_power					=> '',
	_sign					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sufrac->{_Step}     = 'sufrac'.$sufrac->{_Step};
	return ( $sufrac->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufrac->{_note}     = 'sufrac'.$sufrac->{_note};
	return ( $sufrac->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufrac->{_dt}			= '';
		$sufrac->{_phasefac}			= '';
		$sufrac->{_power}			= '';
		$sufrac->{_sign}			= '';
		$sufrac->{_verbose}			= '';
		$sufrac->{_Step}			= '';
		$sufrac->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sufrac->{_dt}		= $dt;
		$sufrac->{_note}		= $sufrac->{_note}.' dt='.$sufrac->{_dt};
		$sufrac->{_Step}		= $sufrac->{_Step}.' dt='.$sufrac->{_dt};

	} else { 
		print("sufrac, dt, missing dt,\n");
	 }
 }


=head2 sub phasefac 


=cut

 sub phasefac {

	my ( $self,$phasefac )		= @_;
	if ( $phasefac ne $empty_string ) {

		$sufrac->{_phasefac}		= $phasefac;
		$sufrac->{_note}		= $sufrac->{_note}.' phasefac='.$sufrac->{_phasefac};
		$sufrac->{_Step}		= $sufrac->{_Step}.' phasefac='.$sufrac->{_phasefac};

	} else { 
		print("sufrac, phasefac, missing phasefac,\n");
	 }
 }


=head2 sub power 


=cut

 sub power {

	my ( $self,$power )		= @_;
	if ( $power ne $empty_string ) {

		$sufrac->{_power}		= $power;
		$sufrac->{_note}		= $sufrac->{_note}.' power='.$sufrac->{_power};
		$sufrac->{_Step}		= $sufrac->{_Step}.' power='.$sufrac->{_power};

	} else { 
		print("sufrac, power, missing power,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sufrac->{_sign}		= $sign;
		$sufrac->{_note}		= $sufrac->{_note}.' sign='.$sufrac->{_sign};
		$sufrac->{_Step}		= $sufrac->{_Step}.' sign='.$sufrac->{_sign};

	} else { 
		print("sufrac, sign, missing sign,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sufrac->{_verbose}		= $verbose;
		$sufrac->{_note}		= $sufrac->{_note}.' verbose='.$sufrac->{_verbose};
		$sufrac->{_Step}		= $sufrac->{_Step}.' verbose='.$sufrac->{_verbose};

	} else { 
		print("sufrac, verbose, missing verbose,\n");
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
