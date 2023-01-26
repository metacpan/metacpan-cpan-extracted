package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudmotivz;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUDMOTIVZ - DMO for Transeversely Isotropic V(Z) media for common-offset

            gathers							



 sudmotivz <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [...]	



 Required Parameters:							

 cdpmin=         minimum cdp (integer number) for which to apply DMO	

 cdpmax=         maximum cdp (integer number) for which to apply DMO	

 dxcdp=          distance between adjacent cdp bins (m)			

 noffmix        number of offsets to mix (see notes)			



 Optional Parameters:							

 vnfile=        binary (non-ascii) file containing NMO interval	

                  velocities (m/s)					

 vfile=         binary (non-ascii) file containing interval velocities	(m/s)

 etafile=       binary (non-ascii) file containing eta interval values (m/s)

 tdmo=0.0       times corresponding to interval velocities in vdmo (s)	

 vndmo=1500.0   NMO interval velocities corresponding to times in tdmo (m/s)

 vdmo=vndmo    interval velocities corresponding to times in tdmo (m/s)

 etadmo=1500.0  eta interval values corresponding to times in tdmo (m/s)

 fmax=0.5/dt    maximum frequency in input traces (Hz)			

 smute=1.5      stretch mute used for NMO correction			

 speed=1.0      twist this knob for speed (and aliasing)		

 verbose=0      =1 for diagnostic print				



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



 vnfile, vfile and etafile should contain the regularly sampled interval

 values of NMO velocity, velocity and eta respectivily as a		

 function of time.  If, for example, vfile is not supplied, the interval

 velocity function is defined by linear interpolation of the values in the

 tdmo and vdmo arrays.  The times in tdmo must be monotonically increasing.

 If vfile or vdmo are not given it will be equated to vnfile or vndmo. 



 For each offset, the minimum time to process is determined using the	

 smute parameter.  The DMO correction is not computed for samples that	

 have experienced greater stretch during NMO.				



 Trace header fields accessed:  nt, dt, delrt, offset, cdp.		

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

my $sudmotivz			= {
	_cdpmax					=> '',
	_cdpmin					=> '',
	_dxcdp					=> '',
	_etadmo					=> '',
	_etafile					=> '',
	_fmax					=> '',
	_smute					=> '',
	_speed					=> '',
	_tdmo					=> '',
	_vdmo					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_vndmo					=> '',
	_vnfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudmotivz->{_Step}     = 'sudmotivz'.$sudmotivz->{_Step};
	return ( $sudmotivz->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudmotivz->{_note}     = 'sudmotivz'.$sudmotivz->{_note};
	return ( $sudmotivz->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudmotivz->{_cdpmax}			= '';
		$sudmotivz->{_cdpmin}			= '';
		$sudmotivz->{_dxcdp}			= '';
		$sudmotivz->{_etadmo}			= '';
		$sudmotivz->{_etafile}			= '';
		$sudmotivz->{_fmax}			= '';
		$sudmotivz->{_smute}			= '';
		$sudmotivz->{_speed}			= '';
		$sudmotivz->{_tdmo}			= '';
		$sudmotivz->{_vdmo}			= '';
		$sudmotivz->{_verbose}			= '';
		$sudmotivz->{_vfile}			= '';
		$sudmotivz->{_vndmo}			= '';
		$sudmotivz->{_vnfile}			= '';
		$sudmotivz->{_Step}			= '';
		$sudmotivz->{_note}			= '';
 }


=head2 sub cdpmax 


=cut

 sub cdpmax {

	my ( $self,$cdpmax )		= @_;
	if ( $cdpmax ne $empty_string ) {

		$sudmotivz->{_cdpmax}		= $cdpmax;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' cdpmax='.$sudmotivz->{_cdpmax};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' cdpmax='.$sudmotivz->{_cdpmax};

	} else { 
		print("sudmotivz, cdpmax, missing cdpmax,\n");
	 }
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sudmotivz->{_cdpmin}		= $cdpmin;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' cdpmin='.$sudmotivz->{_cdpmin};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' cdpmin='.$sudmotivz->{_cdpmin};

	} else { 
		print("sudmotivz, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub dxcdp 


=cut

 sub dxcdp {

	my ( $self,$dxcdp )		= @_;
	if ( $dxcdp ne $empty_string ) {

		$sudmotivz->{_dxcdp}		= $dxcdp;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' dxcdp='.$sudmotivz->{_dxcdp};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' dxcdp='.$sudmotivz->{_dxcdp};

	} else { 
		print("sudmotivz, dxcdp, missing dxcdp,\n");
	 }
 }


=head2 sub etadmo 


=cut

 sub etadmo {

	my ( $self,$etadmo )		= @_;
	if ( $etadmo ne $empty_string ) {

		$sudmotivz->{_etadmo}		= $etadmo;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' etadmo='.$sudmotivz->{_etadmo};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' etadmo='.$sudmotivz->{_etadmo};

	} else { 
		print("sudmotivz, etadmo, missing etadmo,\n");
	 }
 }


=head2 sub etafile 


=cut

 sub etafile {

	my ( $self,$etafile )		= @_;
	if ( $etafile ne $empty_string ) {

		$sudmotivz->{_etafile}		= $etafile;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' etafile='.$sudmotivz->{_etafile};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' etafile='.$sudmotivz->{_etafile};

	} else { 
		print("sudmotivz, etafile, missing etafile,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sudmotivz->{_fmax}		= $fmax;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' fmax='.$sudmotivz->{_fmax};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' fmax='.$sudmotivz->{_fmax};

	} else { 
		print("sudmotivz, fmax, missing fmax,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$sudmotivz->{_smute}		= $smute;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' smute='.$sudmotivz->{_smute};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' smute='.$sudmotivz->{_smute};

	} else { 
		print("sudmotivz, smute, missing smute,\n");
	 }
 }


=head2 sub speed 


=cut

 sub speed {

	my ( $self,$speed )		= @_;
	if ( $speed ne $empty_string ) {

		$sudmotivz->{_speed}		= $speed;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' speed='.$sudmotivz->{_speed};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' speed='.$sudmotivz->{_speed};

	} else { 
		print("sudmotivz, speed, missing speed,\n");
	 }
 }


=head2 sub tdmo 


=cut

 sub tdmo {

	my ( $self,$tdmo )		= @_;
	if ( $tdmo ne $empty_string ) {

		$sudmotivz->{_tdmo}		= $tdmo;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' tdmo='.$sudmotivz->{_tdmo};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' tdmo='.$sudmotivz->{_tdmo};

	} else { 
		print("sudmotivz, tdmo, missing tdmo,\n");
	 }
 }


=head2 sub vdmo 


=cut

 sub vdmo {

	my ( $self,$vdmo )		= @_;
	if ( $vdmo ne $empty_string ) {

		$sudmotivz->{_vdmo}		= $vdmo;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' vdmo='.$sudmotivz->{_vdmo};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' vdmo='.$sudmotivz->{_vdmo};

	} else { 
		print("sudmotivz, vdmo, missing vdmo,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudmotivz->{_verbose}		= $verbose;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' verbose='.$sudmotivz->{_verbose};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' verbose='.$sudmotivz->{_verbose};

	} else { 
		print("sudmotivz, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sudmotivz->{_vfile}		= $vfile;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' vfile='.$sudmotivz->{_vfile};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' vfile='.$sudmotivz->{_vfile};

	} else { 
		print("sudmotivz, vfile, missing vfile,\n");
	 }
 }


=head2 sub vndmo 


=cut

 sub vndmo {

	my ( $self,$vndmo )		= @_;
	if ( $vndmo ne $empty_string ) {

		$sudmotivz->{_vndmo}		= $vndmo;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' vndmo='.$sudmotivz->{_vndmo};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' vndmo='.$sudmotivz->{_vndmo};

	} else { 
		print("sudmotivz, vndmo, missing vndmo,\n");
	 }
 }


=head2 sub vnfile 


=cut

 sub vnfile {

	my ( $self,$vnfile )		= @_;
	if ( $vnfile ne $empty_string ) {

		$sudmotivz->{_vnfile}		= $vnfile;
		$sudmotivz->{_note}		= $sudmotivz->{_note}.' vnfile='.$sudmotivz->{_vnfile};
		$sudmotivz->{_Step}		= $sudmotivz->{_Step}.' vnfile='.$sudmotivz->{_vnfile};

	} else { 
		print("sudmotivz, vnfile, missing vnfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 13;

    return($max_index);
}
 
 
1;
