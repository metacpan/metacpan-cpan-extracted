package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudmofk;

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
 SUDMOFK - DMO via F-K domain (log-stretch) method for common-offset gathers



 sudmofk <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [...]		



 Required Parameters:							

 cdpmin=	minimum cdp (integer number) for which to apply DMO	

 cdpmax=	maximum cdp (integer number) for which to apply DMO	

 dxcdp=		distance between adjacent cdp bins (m)			

 noffmix=	number of offsets to mix (see notes)			



 Optional Parameters:							

 tdmo=0.0	times corresponding to rms velocities in vdmo (s)	

 vdmo=1500.0	rms velocities corresponding to times in tdmo (m/s)	

 sdmo=1.0	DMO stretch factor; try 0.6 for typical v(z)		

 fmax=0.5/dt	maximum frequency in input traces (Hz)			

 verbose=0	=1 for diagnostic print					

 tmpdir=	if non-empty, use the value as a directory path	prefix	

		for storing temporary files; else if the CWP_TMPDIR	

		environment variable is set use	its value for the path;	

		else use tmpfile()					



 Notes:								

 Input traces should be sorted into common-offset gathers.  One common- 

 offset gather ends and another begins when the offset field of the trace

 headers changes.							



 The cdp field of the input trace headers must be the cdp bin NUMBER, NOT

 the cdp location expressed in units of meters or feet.		



 The number of offsets to mix (noffmix) should typically no smaller than

 the ratio of the shotpoint spacing to the cdp spacing.  This choice	

 ensures that every cdp will be represented in each offset mix.  Traces 

 in each mix will contribute through DMO to other traces in adjacent cdps

 within that mix. (Values of noffmix 2 or 3 times the ratio of shotpoint

 spacing to the cdp spacing often yield better results.)		



 The tdmo and vdmo arrays specify a velocity function of time that is	

 used to implement a first-order correction for depth-variable velocity.

 The times in tdmo must be monotonically increasing.			



 For each offset, the minimum time at which a non-zero sample exists is 

 used to determine a mute time.  Output samples for times earlier than this", 

 mute time will be zeroed.  Computation time may be significantly reduced

 if the input traces are zeroed (muted) for early times at large offsets.



 Credits:

	CWP: Dave



 Technical Reference:

	Dip-Moveout Processing - SEG Course Notes

	Dave Hale, 1988



 Trace header fields accessed:  ns, dt, delrt, offset, cdp.



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

my $sudmofk			= {
	_cdpmax					=> '',
	_cdpmin					=> '',
	_dxcdp					=> '',
	_fmax					=> '',
	_noffmix					=> '',
	_sdmo					=> '',
	_tdmo					=> '',
	_tmpdir					=> '',
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

	$sudmofk->{_Step}     = 'sudmofk'.$sudmofk->{_Step};
	return ( $sudmofk->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudmofk->{_note}     = 'sudmofk'.$sudmofk->{_note};
	return ( $sudmofk->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudmofk->{_cdpmax}			= '';
		$sudmofk->{_cdpmin}			= '';
		$sudmofk->{_dxcdp}			= '';
		$sudmofk->{_fmax}			= '';
		$sudmofk->{_noffmix}			= '';
		$sudmofk->{_sdmo}			= '';
		$sudmofk->{_tdmo}			= '';
		$sudmofk->{_tmpdir}			= '';
		$sudmofk->{_vdmo}			= '';
		$sudmofk->{_verbose}			= '';
		$sudmofk->{_Step}			= '';
		$sudmofk->{_note}			= '';
 }


=head2 sub cdpmax 


=cut

 sub cdpmax {

	my ( $self,$cdpmax )		= @_;
	if ( $cdpmax ne $empty_string ) {

		$sudmofk->{_cdpmax}		= $cdpmax;
		$sudmofk->{_note}		= $sudmofk->{_note}.' cdpmax='.$sudmofk->{_cdpmax};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' cdpmax='.$sudmofk->{_cdpmax};

	} else { 
		print("sudmofk, cdpmax, missing cdpmax,\n");
	 }
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sudmofk->{_cdpmin}		= $cdpmin;
		$sudmofk->{_note}		= $sudmofk->{_note}.' cdpmin='.$sudmofk->{_cdpmin};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' cdpmin='.$sudmofk->{_cdpmin};

	} else { 
		print("sudmofk, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub dxcdp 


=cut

 sub dxcdp {

	my ( $self,$dxcdp )		= @_;
	if ( $dxcdp ne $empty_string ) {

		$sudmofk->{_dxcdp}		= $dxcdp;
		$sudmofk->{_note}		= $sudmofk->{_note}.' dxcdp='.$sudmofk->{_dxcdp};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' dxcdp='.$sudmofk->{_dxcdp};

	} else { 
		print("sudmofk, dxcdp, missing dxcdp,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sudmofk->{_fmax}		= $fmax;
		$sudmofk->{_note}		= $sudmofk->{_note}.' fmax='.$sudmofk->{_fmax};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' fmax='.$sudmofk->{_fmax};

	} else { 
		print("sudmofk, fmax, missing fmax,\n");
	 }
 }


=head2 sub noffmix 


=cut

 sub noffmix {

	my ( $self,$noffmix )		= @_;
	if ( $noffmix ne $empty_string ) {

		$sudmofk->{_noffmix}		= $noffmix;
		$sudmofk->{_note}		= $sudmofk->{_note}.' noffmix='.$sudmofk->{_noffmix};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' noffmix='.$sudmofk->{_noffmix};

	} else { 
		print("sudmofk, noffmix, missing noffmix,\n");
	 }
 }


=head2 sub sdmo 


=cut

 sub sdmo {

	my ( $self,$sdmo )		= @_;
	if ( $sdmo ne $empty_string ) {

		$sudmofk->{_sdmo}		= $sdmo;
		$sudmofk->{_note}		= $sudmofk->{_note}.' sdmo='.$sudmofk->{_sdmo};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' sdmo='.$sudmofk->{_sdmo};

	} else { 
		print("sudmofk, sdmo, missing sdmo,\n");
	 }
 }


=head2 sub tdmo 


=cut

 sub tdmo {

	my ( $self,$tdmo )		= @_;
	if ( $tdmo ne $empty_string ) {

		$sudmofk->{_tdmo}		= $tdmo;
		$sudmofk->{_note}		= $sudmofk->{_note}.' tdmo='.$sudmofk->{_tdmo};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' tdmo='.$sudmofk->{_tdmo};

	} else { 
		print("sudmofk, tdmo, missing tdmo,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sudmofk->{_tmpdir}		= $tmpdir;
		$sudmofk->{_note}		= $sudmofk->{_note}.' tmpdir='.$sudmofk->{_tmpdir};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' tmpdir='.$sudmofk->{_tmpdir};

	} else { 
		print("sudmofk, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub vdmo 


=cut

 sub vdmo {

	my ( $self,$vdmo )		= @_;
	if ( $vdmo ne $empty_string ) {

		$sudmofk->{_vdmo}		= $vdmo;
		$sudmofk->{_note}		= $sudmofk->{_note}.' vdmo='.$sudmofk->{_vdmo};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' vdmo='.$sudmofk->{_vdmo};

	} else { 
		print("sudmofk, vdmo, missing vdmo,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudmofk->{_verbose}		= $verbose;
		$sudmofk->{_note}		= $sudmofk->{_note}.' verbose='.$sudmofk->{_verbose};
		$sudmofk->{_Step}		= $sudmofk->{_Step}.' verbose='.$sudmofk->{_verbose};

	} else { 
		print("sudmofk, verbose, missing verbose,\n");
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
