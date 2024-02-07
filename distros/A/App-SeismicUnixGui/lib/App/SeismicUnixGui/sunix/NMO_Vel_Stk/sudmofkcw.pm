package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudmofkcw;

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
 SUDMOFKCW - converted-wave DMO via F-K domain (log-stretch) method for

 		common-offset gathers					



 sudmofkcw <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [...]	



 Required Parameters:							

 cdpmin=		  minimum cdp (integer number) for which to apply DMO

 cdpmax=		  maximum cdp (integer number) for which to apply DMO

 dxcdp=		   distance between adjacent cdp bins (m)		

 noffmix=		 number of offsets to mix (see notes)		



 Optional Parameters:							

 tdmo=0.0		times corresponding to rms velocities in vdmo (s)

 vdmo=1500.0		rms velocities corresponding to times in tdmo (m/s)

 gamma=0.5		 velocity ratio, upgoing/downgoing		

 ntable=1000		 number of tabulated z/h and b/h (see notes)	

 sdmo=1.0		DMO stretch factor; try 0.6 for typical v(z)	

 flip=0		 =1 for negative shifts and exchanging s1 and s2

 			 (see notes below)				

 fmax=0.5/dt		maximum frequency in input traces (Hz)		

 verbose=0		=1 for diagnostic print				



 Notes:								

 Input traces should be sorted into common-offset gathers.  One common-

 offset gather ends and another begins when the offset field of the trace

 headers changes.							



 The cdp field of the input trace headers must be the cdp bin NUMBER, NOT

 the cdp location expressed in units of meters or feet.		



 The number of offsets to mix (noffmix) should typically equal the ratio of

 the shotpoint spacing to the cdp spacing.  This choice ensures that every

 cdp will be represented in each offset mix.  Traces in each mix will	

 contribute through DMO to other traces in adjacent cdps within that mix.



 The tdmo and vdmo arrays specify a velocity function of time that is	

 used to implement a first-order correction for depth-variable velocity.

 The times in tdmo must be monotonically increasing. The velocity function

 is assumed to have been gotten by traditional NMO. 			



 For each offset, the minimum time at which a non-zero sample exists is

 used to determine a mute time.  Output samples for times earlier than this

 mute time will be zeroed.  Computation time may be significantly reduced

 if the input traces are zeroed (muted) for early times at large offsets.



 z/h is horizontal-reflector depth normalized to half source-reciver offset

 h.  Normalized shift of conversion point is b/h.  The code now does not

 support signed offsets, therefore it is recommended that only end-on data,

 not split-spread, be used as input (of course after being sorted into	

 common-offset gathers).  z/h vs b/h depends on gamma (see Alfaraj's Ph.D.

 thesis, 1993).							



 Flip factor = 1 implies positive shift of traces (in the increasing CDP

 bin number direction).  When processing split-spread data, for example,

 if one side of the spread is processed with flip=0, then the other side

 of the spread should be processed with flip=1.  The flip factor also	

 determines the actions of the factors s1 and s2, i.e., stretching or	

 squeezing.								



 Trace header fields accessed:  nt, dt, delrt, offset, cdp.		





 Credits:

	CWP: Mohamed Alfaraj

		Dave Hale



 Technical Reference:

	Transformation to zero offset for mode-converted waves

	Mohammed Alfaraj, Ph.D. thesis, 1993, Colorado School of Mines



	Dip-Moveout Processing - SEG Course Notes

	Dave Hale, 1988



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

my $sudmofkcw			= {
	_cdpmax					=> '',
	_cdpmin					=> '',
	_dxcdp					=> '',
	_factor					=> '',
	_flip					=> '',
	_fmax					=> '',
	_gamma					=> '',
	_noffmix					=> '',
	_ntable					=> '',
	_sdmo					=> '',
	_tdmo					=> '',
	_vdmo					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudmofkcw->{_Step}     = 'sudmofkcw'.$sudmofkcw->{_Step};
	return ( $sudmofkcw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudmofkcw->{_note}     = 'sudmofkcw'.$sudmofkcw->{_note};
	return ( $sudmofkcw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudmofkcw->{_cdpmax}			= '';
		$sudmofkcw->{_cdpmin}			= '';
		$sudmofkcw->{_dxcdp}			= '';
		$sudmofkcw->{_factor}			= '';
		$sudmofkcw->{_flip}			= '';
		$sudmofkcw->{_fmax}			= '';
		$sudmofkcw->{_gamma}			= '';
		$sudmofkcw->{_noffmix}			= '';
		$sudmofkcw->{_ntable}			= '';
		$sudmofkcw->{_sdmo}			= '';
		$sudmofkcw->{_tdmo}			= '';
		$sudmofkcw->{_vdmo}			= '';
		$sudmofkcw->{_verbose}			= '';
		$sudmofkcw->{_Step}			= '';
		$sudmofkcw->{_note}			= '';
 }


=head2 sub cdpmax 


=cut

 sub cdpmax {

	my ( $self,$cdpmax )		= @_;
	if ( $cdpmax ne $empty_string ) {

		$sudmofkcw->{_cdpmax}		= $cdpmax;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' cdpmax='.$sudmofkcw->{_cdpmax};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' cdpmax='.$sudmofkcw->{_cdpmax};

	} else { 
		print("sudmofkcw, cdpmax, missing cdpmax,\n");
	 }
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sudmofkcw->{_cdpmin}		= $cdpmin;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' cdpmin='.$sudmofkcw->{_cdpmin};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' cdpmin='.$sudmofkcw->{_cdpmin};

	} else { 
		print("sudmofkcw, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub dxcdp 


=cut

 sub dxcdp {

	my ( $self,$dxcdp )		= @_;
	if ( $dxcdp ne $empty_string ) {

		$sudmofkcw->{_dxcdp}		= $dxcdp;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' dxcdp='.$sudmofkcw->{_dxcdp};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' dxcdp='.$sudmofkcw->{_dxcdp};

	} else { 
		print("sudmofkcw, dxcdp, missing dxcdp,\n");
	 }
 }


=head2 sub factor 


=cut

 sub factor {

	my ( $self,$factor )		= @_;
	if ( $factor ne $empty_string ) {

		$sudmofkcw->{_factor}		= $factor;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' factor='.$sudmofkcw->{_factor};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' factor='.$sudmofkcw->{_factor};

	} else { 
		print("sudmofkcw, factor, missing factor,\n");
	 }
 }


=head2 sub flip 


=cut

 sub flip {

	my ( $self,$flip )		= @_;
	if ( $flip ne $empty_string ) {

		$sudmofkcw->{_flip}		= $flip;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' flip='.$sudmofkcw->{_flip};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' flip='.$sudmofkcw->{_flip};

	} else { 
		print("sudmofkcw, flip, missing flip,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sudmofkcw->{_fmax}		= $fmax;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' fmax='.$sudmofkcw->{_fmax};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' fmax='.$sudmofkcw->{_fmax};

	} else { 
		print("sudmofkcw, fmax, missing fmax,\n");
	 }
 }


=head2 sub gamma 


=cut

 sub gamma {

	my ( $self,$gamma )		= @_;
	if ( $gamma ne $empty_string ) {

		$sudmofkcw->{_gamma}		= $gamma;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' gamma='.$sudmofkcw->{_gamma};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' gamma='.$sudmofkcw->{_gamma};

	} else { 
		print("sudmofkcw, gamma, missing gamma,\n");
	 }
 }


=head2 sub noffmix 


=cut

 sub noffmix {

	my ( $self,$noffmix )		= @_;
	if ( $noffmix ne $empty_string ) {

		$sudmofkcw->{_noffmix}		= $noffmix;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' noffmix='.$sudmofkcw->{_noffmix};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' noffmix='.$sudmofkcw->{_noffmix};

	} else { 
		print("sudmofkcw, noffmix, missing noffmix,\n");
	 }
 }


=head2 sub ntable 


=cut

 sub ntable {

	my ( $self,$ntable )		= @_;
	if ( $ntable ne $empty_string ) {

		$sudmofkcw->{_ntable}		= $ntable;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' ntable='.$sudmofkcw->{_ntable};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' ntable='.$sudmofkcw->{_ntable};

	} else { 
		print("sudmofkcw, ntable, missing ntable,\n");
	 }
 }


=head2 sub sdmo 


=cut

 sub sdmo {

	my ( $self,$sdmo )		= @_;
	if ( $sdmo ne $empty_string ) {

		$sudmofkcw->{_sdmo}		= $sdmo;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' sdmo='.$sudmofkcw->{_sdmo};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' sdmo='.$sudmofkcw->{_sdmo};

	} else { 
		print("sudmofkcw, sdmo, missing sdmo,\n");
	 }
 }


=head2 sub tdmo 


=cut

 sub tdmo {

	my ( $self,$tdmo )		= @_;
	if ( $tdmo ne $empty_string ) {

		$sudmofkcw->{_tdmo}		= $tdmo;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' tdmo='.$sudmofkcw->{_tdmo};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' tdmo='.$sudmofkcw->{_tdmo};

	} else { 
		print("sudmofkcw, tdmo, missing tdmo,\n");
	 }
 }


=head2 sub vdmo 


=cut

 sub vdmo {

	my ( $self,$vdmo )		= @_;
	if ( $vdmo ne $empty_string ) {

		$sudmofkcw->{_vdmo}		= $vdmo;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' vdmo='.$sudmofkcw->{_vdmo};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' vdmo='.$sudmofkcw->{_vdmo};

	} else { 
		print("sudmofkcw, vdmo, missing vdmo,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudmofkcw->{_verbose}		= $verbose;
		$sudmofkcw->{_note}		= $sudmofkcw->{_note}.' verbose='.$sudmofkcw->{_verbose};
		$sudmofkcw->{_Step}		= $sudmofkcw->{_Step}.' verbose='.$sudmofkcw->{_verbose};

	} else { 
		print("sudmofkcw, verbose, missing verbose,\n");
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
