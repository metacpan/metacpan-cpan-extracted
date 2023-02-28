package App::SeismicUnixGui::sunix::model::susynvxz;

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
 SUSYNVXZ - SYNthetic seismograms of common offset V(X,Z) media via	

 		Kirchhoff-style modeling				



 susynvxz >outfile [optional parameters]				



 Required Parameters:							

 <vfile		file containing velocities v[nx][nz]		

 nx=			number of x samples (2nd dimension)		

 nz=			number of z samples (1st dimension)		

 Optional Parameters:							

 nxb=nx		band centered at midpoint			

 nxd=1			skipped number of midponits			

 dx=100		x sampling interval (m)				

 fx=0.0		first x sample					

 dz=100		z sampling interval (m)				

 nt=101		number of time samples				

 dt=0.04		time sampling interval (sec)			

 ft=0.0		first time (sec)				

 nxo=1		 	number of offsets				

 dxo=50		offset sampling interval (m)			

 fxo=0.0		first offset (m)				

 nxm=101		number of midpoints				

 dxm=50		midpoint sampling interval (m)			

 fxm=0.0		first midpoint (m)				

 fpeak=0.2/dt		peak frequency of symmetric Ricker wavelet (Hz)	

 ref="1:1,2;4,2"	reflector(s):  "amplitude:x1,z1;x2,z2;x3,z3;...

 smooth=0		=1 for smooth (piecewise cubic spline) reflectors

 ls=0			=1 for line source; default is point source	

 tmin=10.0*dt		minimum time of interest (sec)			

 ndpfz=5		number of diffractors per Fresnel zone		

 verbose=0		=1 to print some useful information		



 Notes:								

 This algorithm is based on formula (58) in Geo. Pros. 34, 686-703,	

 by N. Bleistein.							



 Offsets are signed - may be positive or negative.			", 

 Traveltime and amplitude are calculated by finite differences which	

 is done only in part of midpoints; in the skiped midpoint, interpolation

 is used to calculate traveltime and amplitude.			", 



 More than one ref (reflector) may be specified.			

 Note that reflectors are encoded as quoted strings, with an optional	

 reflector amplitude: preceding the x,z coordinates of each reflector.	

 Default amplitude is 1.0 if amplitude: part of the string is omitted.	







   CWP:  Zhenyue Liu, 07/20/92

	Many subroutines borrowed from Dave Hale's program: SUSYNLV



 Trace header fields set: trid, counit, ns, dt, delrt,

				tracl. tracr,

				cdp, cdpt, d2, f2, offset, sx, gx



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

my $susynvxz			= {
	_dt					=> '',
	_dx					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dz					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_fx					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_ls					=> '',
	_ndpfz					=> '',
	_nt					=> '',
	_nx					=> '',
	_nxb					=> '',
	_nxd					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_nz					=> '',
	_ref					=> '',
	_smooth					=> '',
	_tmin					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susynvxz->{_Step}     = 'susynvxz'.$susynvxz->{_Step};
	return ( $susynvxz->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susynvxz->{_note}     = 'susynvxz'.$susynvxz->{_note};
	return ( $susynvxz->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susynvxz->{_dt}			= '';
		$susynvxz->{_dx}			= '';
		$susynvxz->{_dxm}			= '';
		$susynvxz->{_dxo}			= '';
		$susynvxz->{_dz}			= '';
		$susynvxz->{_fpeak}			= '';
		$susynvxz->{_ft}			= '';
		$susynvxz->{_fx}			= '';
		$susynvxz->{_fxm}			= '';
		$susynvxz->{_fxo}			= '';
		$susynvxz->{_ls}			= '';
		$susynvxz->{_ndpfz}			= '';
		$susynvxz->{_nt}			= '';
		$susynvxz->{_nx}			= '';
		$susynvxz->{_nxb}			= '';
		$susynvxz->{_nxd}			= '';
		$susynvxz->{_nxm}			= '';
		$susynvxz->{_nxo}			= '';
		$susynvxz->{_nz}			= '';
		$susynvxz->{_ref}			= '';
		$susynvxz->{_smooth}			= '';
		$susynvxz->{_tmin}			= '';
		$susynvxz->{_verbose}			= '';
		$susynvxz->{_Step}			= '';
		$susynvxz->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susynvxz->{_dt}		= $dt;
		$susynvxz->{_note}		= $susynvxz->{_note}.' dt='.$susynvxz->{_dt};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' dt='.$susynvxz->{_dt};

	} else { 
		print("susynvxz, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$susynvxz->{_dx}		= $dx;
		$susynvxz->{_note}		= $susynvxz->{_note}.' dx='.$susynvxz->{_dx};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' dx='.$susynvxz->{_dx};

	} else { 
		print("susynvxz, dx, missing dx,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$susynvxz->{_dxm}		= $dxm;
		$susynvxz->{_note}		= $susynvxz->{_note}.' dxm='.$susynvxz->{_dxm};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' dxm='.$susynvxz->{_dxm};

	} else { 
		print("susynvxz, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$susynvxz->{_dxo}		= $dxo;
		$susynvxz->{_note}		= $susynvxz->{_note}.' dxo='.$susynvxz->{_dxo};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' dxo='.$susynvxz->{_dxo};

	} else { 
		print("susynvxz, dxo, missing dxo,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$susynvxz->{_dz}		= $dz;
		$susynvxz->{_note}		= $susynvxz->{_note}.' dz='.$susynvxz->{_dz};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' dz='.$susynvxz->{_dz};

	} else { 
		print("susynvxz, dz, missing dz,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$susynvxz->{_fpeak}		= $fpeak;
		$susynvxz->{_note}		= $susynvxz->{_note}.' fpeak='.$susynvxz->{_fpeak};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' fpeak='.$susynvxz->{_fpeak};

	} else { 
		print("susynvxz, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$susynvxz->{_ft}		= $ft;
		$susynvxz->{_note}		= $susynvxz->{_note}.' ft='.$susynvxz->{_ft};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' ft='.$susynvxz->{_ft};

	} else { 
		print("susynvxz, ft, missing ft,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$susynvxz->{_fx}		= $fx;
		$susynvxz->{_note}		= $susynvxz->{_note}.' fx='.$susynvxz->{_fx};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' fx='.$susynvxz->{_fx};

	} else { 
		print("susynvxz, fx, missing fx,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$susynvxz->{_fxm}		= $fxm;
		$susynvxz->{_note}		= $susynvxz->{_note}.' fxm='.$susynvxz->{_fxm};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' fxm='.$susynvxz->{_fxm};

	} else { 
		print("susynvxz, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$susynvxz->{_fxo}		= $fxo;
		$susynvxz->{_note}		= $susynvxz->{_note}.' fxo='.$susynvxz->{_fxo};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' fxo='.$susynvxz->{_fxo};

	} else { 
		print("susynvxz, fxo, missing fxo,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$susynvxz->{_ls}		= $ls;
		$susynvxz->{_note}		= $susynvxz->{_note}.' ls='.$susynvxz->{_ls};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' ls='.$susynvxz->{_ls};

	} else { 
		print("susynvxz, ls, missing ls,\n");
	 }
 }


=head2 sub ndpfz 


=cut

 sub ndpfz {

	my ( $self,$ndpfz )		= @_;
	if ( $ndpfz ne $empty_string ) {

		$susynvxz->{_ndpfz}		= $ndpfz;
		$susynvxz->{_note}		= $susynvxz->{_note}.' ndpfz='.$susynvxz->{_ndpfz};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' ndpfz='.$susynvxz->{_ndpfz};

	} else { 
		print("susynvxz, ndpfz, missing ndpfz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susynvxz->{_nt}		= $nt;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nt='.$susynvxz->{_nt};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nt='.$susynvxz->{_nt};

	} else { 
		print("susynvxz, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$susynvxz->{_nx}		= $nx;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nx='.$susynvxz->{_nx};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nx='.$susynvxz->{_nx};

	} else { 
		print("susynvxz, nx, missing nx,\n");
	 }
 }


=head2 sub nxb 


=cut

 sub nxb {

	my ( $self,$nxb )		= @_;
	if ( $nxb ne $empty_string ) {

		$susynvxz->{_nxb}		= $nxb;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nxb='.$susynvxz->{_nxb};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nxb='.$susynvxz->{_nxb};

	} else { 
		print("susynvxz, nxb, missing nxb,\n");
	 }
 }


=head2 sub nxd 


=cut

 sub nxd {

	my ( $self,$nxd )		= @_;
	if ( $nxd ne $empty_string ) {

		$susynvxz->{_nxd}		= $nxd;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nxd='.$susynvxz->{_nxd};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nxd='.$susynvxz->{_nxd};

	} else { 
		print("susynvxz, nxd, missing nxd,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$susynvxz->{_nxm}		= $nxm;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nxm='.$susynvxz->{_nxm};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nxm='.$susynvxz->{_nxm};

	} else { 
		print("susynvxz, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$susynvxz->{_nxo}		= $nxo;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nxo='.$susynvxz->{_nxo};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nxo='.$susynvxz->{_nxo};

	} else { 
		print("susynvxz, nxo, missing nxo,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$susynvxz->{_nz}		= $nz;
		$susynvxz->{_note}		= $susynvxz->{_note}.' nz='.$susynvxz->{_nz};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' nz='.$susynvxz->{_nz};

	} else { 
		print("susynvxz, nz, missing nz,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$susynvxz->{_ref}		= $ref;
		$susynvxz->{_note}		= $susynvxz->{_note}.' ref='.$susynvxz->{_ref};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' ref='.$susynvxz->{_ref};

	} else { 
		print("susynvxz, ref, missing ref,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$susynvxz->{_smooth}		= $smooth;
		$susynvxz->{_note}		= $susynvxz->{_note}.' smooth='.$susynvxz->{_smooth};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' smooth='.$susynvxz->{_smooth};

	} else { 
		print("susynvxz, smooth, missing smooth,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$susynvxz->{_tmin}		= $tmin;
		$susynvxz->{_note}		= $susynvxz->{_note}.' tmin='.$susynvxz->{_tmin};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' tmin='.$susynvxz->{_tmin};

	} else { 
		print("susynvxz, tmin, missing tmin,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$susynvxz->{_verbose}		= $verbose;
		$susynvxz->{_note}		= $susynvxz->{_note}.' verbose='.$susynvxz->{_verbose};
		$susynvxz->{_Step}		= $susynvxz->{_Step}.' verbose='.$susynvxz->{_verbose};

	} else { 
		print("susynvxz, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 22;

    return($max_index);
}
 
 
1;
