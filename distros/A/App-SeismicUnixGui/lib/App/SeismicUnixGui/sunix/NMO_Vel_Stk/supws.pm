package App::SeismicUnixGui::sunix::NMO_Vel_Stk::supws;

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
 SUPWS - Phase stack or phase-weighted stack (PWS) of adjacent traces	

	 having the same key header word				



 supws <stdin >stdout [optional parameters]				



 Required parameters:							

	none								



 Optional parameters:						 	

	key=cdp	   key header word to stack on				

	pwr=1.0	   raise phase stack to power pwr			

	dt=(from header)  time sampling intervall in seconds		

	sl=0.0		window length in seconds used for smoothing	

			of the phase stack (weights)			

	ps=0		0 = output is PWS, 1 = output is phase stack	

	verbose=0	 1 = echo additional information		



 Note:								 	

	Phase weighted stacking is a tool for efficient incoherent noise

	reduction. An amplitude-unbiased coherency measure is designed	

	based on the instantaneous phase, which is used to weight the	

	samples of an ordinary, linear stack. The result is called the	

	phase-weighted stack (PWS) and is cleaned from incoherent noise.

	PWS thus permits detection of weak but coherent arrivals.	



	The phase-stack (coherency measure) has values between 0 and 1.	



	If the stacking is over cdp and the PWS option is set, then the	

	offset header field is set to zero. Otherwise, output traces get

	their headers from the first trace of each data ensemble to stack,

	including the offset field. Use "sushw" afterwards, if this is

	not acceptable.							







 Author: Nils Maercklin,

	 GeoForschungsZentrum (GFZ) Potsdam, Germany, 2001.

	 E-mail: nils@gfz-potsdam.de



 References:

	B. L. N. Kennett, 2000: Stacking three-component seismograms.

	 Geophysical Journal International, vol. 141, p. 263-269.

	M. Schimmel and H. Paulssen, 1997: Noise reduction and detection

	 of weak , coherent signals through phase-weighted stacks.

	 Geophysical Journal International, vol. 130, p. 497-505.

	M. T. Taner, A. F. Koehler, and R. E. Sheriff, 1979: Complex

	 seismic trace analysis. Geophysics, vol. 44, p. 1041-1063.



 Trace header fields accessed: ns

 Trace header fields modified: nhs, offset





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

my $supws			= {
	_dt					=> '',
	_key					=> '',
	_ps					=> '',
	_pwr					=> '',
	_sl					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supws->{_Step}     = 'supws'.$supws->{_Step};
	return ( $supws->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supws->{_note}     = 'supws'.$supws->{_note};
	return ( $supws->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supws->{_dt}			= '';
		$supws->{_key}			= '';
		$supws->{_ps}			= '';
		$supws->{_pwr}			= '';
		$supws->{_sl}			= '';
		$supws->{_verbose}			= '';
		$supws->{_Step}			= '';
		$supws->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$supws->{_dt}		= $dt;
		$supws->{_note}		= $supws->{_note}.' dt='.$supws->{_dt};
		$supws->{_Step}		= $supws->{_Step}.' dt='.$supws->{_dt};

	} else { 
		print("supws, dt, missing dt,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$supws->{_key}		= $key;
		$supws->{_note}		= $supws->{_note}.' key='.$supws->{_key};
		$supws->{_Step}		= $supws->{_Step}.' key='.$supws->{_key};

	} else { 
		print("supws, key, missing key,\n");
	 }
 }


=head2 sub ps 


=cut

 sub ps {

	my ( $self,$ps )		= @_;
	if ( $ps ne $empty_string ) {

		$supws->{_ps}		= $ps;
		$supws->{_note}		= $supws->{_note}.' ps='.$supws->{_ps};
		$supws->{_Step}		= $supws->{_Step}.' ps='.$supws->{_ps};

	} else { 
		print("supws, ps, missing ps,\n");
	 }
 }


=head2 sub pwr 


=cut

 sub pwr {

	my ( $self,$pwr )		= @_;
	if ( $pwr ne $empty_string ) {

		$supws->{_pwr}		= $pwr;
		$supws->{_note}		= $supws->{_note}.' pwr='.$supws->{_pwr};
		$supws->{_Step}		= $supws->{_Step}.' pwr='.$supws->{_pwr};

	} else { 
		print("supws, pwr, missing pwr,\n");
	 }
 }


=head2 sub sl 


=cut

 sub sl {

	my ( $self,$sl )		= @_;
	if ( $sl ne $empty_string ) {

		$supws->{_sl}		= $sl;
		$supws->{_note}		= $supws->{_note}.' sl='.$supws->{_sl};
		$supws->{_Step}		= $supws->{_Step}.' sl='.$supws->{_sl};

	} else { 
		print("supws, sl, missing sl,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supws->{_verbose}		= $verbose;
		$supws->{_note}		= $supws->{_note}.' verbose='.$supws->{_verbose};
		$supws->{_Step}		= $supws->{_Step}.' verbose='.$supws->{_verbose};

	} else { 
		print("supws, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
