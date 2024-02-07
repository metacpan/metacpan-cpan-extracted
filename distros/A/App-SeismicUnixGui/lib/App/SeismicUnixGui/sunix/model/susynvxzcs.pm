package App::SeismicUnixGui::sunix::model::susynvxzcs;

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
 SUSYNVXZCS - SYNthetic seismograms of common shot in V(X,Z) media via	

 		Kirchhoff-style modeling				



 susynvxzcs<vfile >outfile  nx= nz= [optional parameters]		



 Required Parameters:							

 <vfile        file containing velocities v[nx][nz]			

 >outfile      file containing seismograms of common ofset		

 nx=           number of x samples (2nd dimension) in velocity 

 nz=           number of z samples (1st dimension) in velocity 



 Optional Parameters:							

 nt=501        	number of time samples				

 dt=0.004      	time sampling interval (sec)			

 ft=0.0        	first time (sec)				

 fpeak=0.2/dt		peak frequency of symmetric Ricker wavelet (Hz)	

 nxg=			number of receivers of input traces		

 dxg=15		receiver sampling interval (m)			

 fxg=0.0		first receiver (m)				

 nxd=5         	skipped number of receivers			

 nxs=1			number of offsets				

 dxs=50		shot sampling interval (m)			

 fxs=0.0		first shot (m)				

 dx=50         	x sampling interval (m)				

 fx=0.         	first x sample (m)				

 dz=50         	z sampling interval (m)				

 nxb=nx/2    	band width centered at midpoint (see note)	

 nxc=0         hozizontal range in which velocity is changed	

 nzc=0         vertical range in which velocity is changed	

 pert=0        =1 calculate time correction from v_p[nx][nz]	

 vpfile        file containing slowness perturbation array v_p[nx][nz]	

 ref="1:1,2;4,2"	reflector(s):  "amplitude:x1,z1;x2,z2;x3,z3;...

 smooth=0		=1 for smooth (piecewise cubic spline) reflectors

 ls=0			=1 for line source; =0 for point source		

 tmin=10.0*dt		minimum time of interest (sec)			

 ndpfz=5		number of diffractors per Fresnel zone		

 cable=1		roll reciever spread with shot			

 			=0 static reciever spread			

 verbose=0		=1 to print some useful information		



 Notes:								

 This algorithm is based on formula (58) in Geo. Pros. 34, 686-703,	

 by N. Bleistein.							



 Traveltime and amplitude are calculated by finite difference which	

 is done only in one of every NXD receivers; in skipped receivers, 	

 interpolation is used to calculate traveltime and amplitude.		", 

 For each receiver, traveltime and amplitude are calculated in the 	

 horizontal range of (xg-nxb*dx, xg+nxb*dx). Velocity is changed by 	

 constant extropolation in two upper trianglar corners whose width is 	

 nxc*dx and height is nzc*dz.						



 Eikonal equation will fail to solve if there is a polar turned ray.	

 In this case, the program shows the related geometric information. 	

 There are three ways to remove the turned rays: smoothing velocity, 	

 reducing nxb, and increaing nxc and nzc (if the turned ray occurs  	

 in shallow areas). To prevent traveltime distortion from an over-	

 smoothed velocity, traveltime is corrected based on the slowness 	

 perturbation.								



 More than one ref (reflector) may be specified.			

 Note that reflectors are encoded as quoted strings, with an optional	

 reflector amplitude: preceding the x,z coordinates of each reflector.	

 Default amplitude is 1.0 if amplitude: part of the string is omitted.	







	Author: Zhenyue Liu, 07/20/92, Center for Wave Phenomena

		Many subroutines borrowed from Dave Hale's program: SUSYNLV



		Trino Salinas, 07/30/96, fixed a bug in the geometry

		setting to allow the spread move with the shots.



		Chris Liner 12/10/08  added cable option, set fldr header word



 Trace header fields set: trid, counit, ns, dt, delrt,

				tracl. tracr, fldr, tracf,

				sx, gx



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

my $susynvxzcs			= {
	_cable					=> '',
	_dt					=> '',
	_dx					=> '',
	_dxg					=> '',
	_dxs					=> '',
	_dz					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_fx					=> '',
	_fxg					=> '',
	_fxs					=> '',
	_ls					=> '',
	_ndpfz					=> '',
	_nt					=> '',
	_nx					=> '',
	_nxb					=> '',
	_nxc					=> '',
	_nxd					=> '',
	_nxg					=> '',
	_nxs					=> '',
	_nz					=> '',
	_nzc					=> '',
	_pert					=> '',
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

	$susynvxzcs->{_Step}     = 'susynvxzcs'.$susynvxzcs->{_Step};
	return ( $susynvxzcs->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susynvxzcs->{_note}     = 'susynvxzcs'.$susynvxzcs->{_note};
	return ( $susynvxzcs->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susynvxzcs->{_cable}			= '';
		$susynvxzcs->{_dt}			= '';
		$susynvxzcs->{_dx}			= '';
		$susynvxzcs->{_dxg}			= '';
		$susynvxzcs->{_dxs}			= '';
		$susynvxzcs->{_dz}			= '';
		$susynvxzcs->{_fpeak}			= '';
		$susynvxzcs->{_ft}			= '';
		$susynvxzcs->{_fx}			= '';
		$susynvxzcs->{_fxg}			= '';
		$susynvxzcs->{_fxs}			= '';
		$susynvxzcs->{_ls}			= '';
		$susynvxzcs->{_ndpfz}			= '';
		$susynvxzcs->{_nt}			= '';
		$susynvxzcs->{_nx}			= '';
		$susynvxzcs->{_nxb}			= '';
		$susynvxzcs->{_nxc}			= '';
		$susynvxzcs->{_nxd}			= '';
		$susynvxzcs->{_nxg}			= '';
		$susynvxzcs->{_nxs}			= '';
		$susynvxzcs->{_nz}			= '';
		$susynvxzcs->{_nzc}			= '';
		$susynvxzcs->{_pert}			= '';
		$susynvxzcs->{_ref}			= '';
		$susynvxzcs->{_smooth}			= '';
		$susynvxzcs->{_tmin}			= '';
		$susynvxzcs->{_verbose}			= '';
		$susynvxzcs->{_Step}			= '';
		$susynvxzcs->{_note}			= '';
 }


=head2 sub cable 


=cut

 sub cable {

	my ( $self,$cable )		= @_;
	if ( $cable ne $empty_string ) {

		$susynvxzcs->{_cable}		= $cable;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' cable='.$susynvxzcs->{_cable};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' cable='.$susynvxzcs->{_cable};

	} else { 
		print("susynvxzcs, cable, missing cable,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susynvxzcs->{_dt}		= $dt;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' dt='.$susynvxzcs->{_dt};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' dt='.$susynvxzcs->{_dt};

	} else { 
		print("susynvxzcs, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$susynvxzcs->{_dx}		= $dx;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' dx='.$susynvxzcs->{_dx};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' dx='.$susynvxzcs->{_dx};

	} else { 
		print("susynvxzcs, dx, missing dx,\n");
	 }
 }


=head2 sub dxg 


=cut

 sub dxg {

	my ( $self,$dxg )		= @_;
	if ( $dxg ne $empty_string ) {

		$susynvxzcs->{_dxg}		= $dxg;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' dxg='.$susynvxzcs->{_dxg};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' dxg='.$susynvxzcs->{_dxg};

	} else { 
		print("susynvxzcs, dxg, missing dxg,\n");
	 }
 }


=head2 sub dxs 


=cut

 sub dxs {

	my ( $self,$dxs )		= @_;
	if ( $dxs ne $empty_string ) {

		$susynvxzcs->{_dxs}		= $dxs;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' dxs='.$susynvxzcs->{_dxs};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' dxs='.$susynvxzcs->{_dxs};

	} else { 
		print("susynvxzcs, dxs, missing dxs,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$susynvxzcs->{_dz}		= $dz;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' dz='.$susynvxzcs->{_dz};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' dz='.$susynvxzcs->{_dz};

	} else { 
		print("susynvxzcs, dz, missing dz,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$susynvxzcs->{_fpeak}		= $fpeak;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' fpeak='.$susynvxzcs->{_fpeak};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' fpeak='.$susynvxzcs->{_fpeak};

	} else { 
		print("susynvxzcs, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$susynvxzcs->{_ft}		= $ft;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' ft='.$susynvxzcs->{_ft};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' ft='.$susynvxzcs->{_ft};

	} else { 
		print("susynvxzcs, ft, missing ft,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$susynvxzcs->{_fx}		= $fx;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' fx='.$susynvxzcs->{_fx};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' fx='.$susynvxzcs->{_fx};

	} else { 
		print("susynvxzcs, fx, missing fx,\n");
	 }
 }


=head2 sub fxg 


=cut

 sub fxg {

	my ( $self,$fxg )		= @_;
	if ( $fxg ne $empty_string ) {

		$susynvxzcs->{_fxg}		= $fxg;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' fxg='.$susynvxzcs->{_fxg};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' fxg='.$susynvxzcs->{_fxg};

	} else { 
		print("susynvxzcs, fxg, missing fxg,\n");
	 }
 }


=head2 sub fxs 


=cut

 sub fxs {

	my ( $self,$fxs )		= @_;
	if ( $fxs ne $empty_string ) {

		$susynvxzcs->{_fxs}		= $fxs;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' fxs='.$susynvxzcs->{_fxs};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' fxs='.$susynvxzcs->{_fxs};

	} else { 
		print("susynvxzcs, fxs, missing fxs,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$susynvxzcs->{_ls}		= $ls;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' ls='.$susynvxzcs->{_ls};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' ls='.$susynvxzcs->{_ls};

	} else { 
		print("susynvxzcs, ls, missing ls,\n");
	 }
 }


=head2 sub ndpfz 


=cut

 sub ndpfz {

	my ( $self,$ndpfz )		= @_;
	if ( $ndpfz ne $empty_string ) {

		$susynvxzcs->{_ndpfz}		= $ndpfz;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' ndpfz='.$susynvxzcs->{_ndpfz};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' ndpfz='.$susynvxzcs->{_ndpfz};

	} else { 
		print("susynvxzcs, ndpfz, missing ndpfz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susynvxzcs->{_nt}		= $nt;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nt='.$susynvxzcs->{_nt};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nt='.$susynvxzcs->{_nt};

	} else { 
		print("susynvxzcs, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$susynvxzcs->{_nx}		= $nx;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nx='.$susynvxzcs->{_nx};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nx='.$susynvxzcs->{_nx};

	} else { 
		print("susynvxzcs, nx, missing nx,\n");
	 }
 }


=head2 sub nxb 


=cut

 sub nxb {

	my ( $self,$nxb )		= @_;
	if ( $nxb ne $empty_string ) {

		$susynvxzcs->{_nxb}		= $nxb;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nxb='.$susynvxzcs->{_nxb};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nxb='.$susynvxzcs->{_nxb};

	} else { 
		print("susynvxzcs, nxb, missing nxb,\n");
	 }
 }


=head2 sub nxc 


=cut

 sub nxc {

	my ( $self,$nxc )		= @_;
	if ( $nxc ne $empty_string ) {

		$susynvxzcs->{_nxc}		= $nxc;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nxc='.$susynvxzcs->{_nxc};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nxc='.$susynvxzcs->{_nxc};

	} else { 
		print("susynvxzcs, nxc, missing nxc,\n");
	 }
 }


=head2 sub nxd 


=cut

 sub nxd {

	my ( $self,$nxd )		= @_;
	if ( $nxd ne $empty_string ) {

		$susynvxzcs->{_nxd}		= $nxd;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nxd='.$susynvxzcs->{_nxd};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nxd='.$susynvxzcs->{_nxd};

	} else { 
		print("susynvxzcs, nxd, missing nxd,\n");
	 }
 }


=head2 sub nxg 


=cut

 sub nxg {

	my ( $self,$nxg )		= @_;
	if ( $nxg ne $empty_string ) {

		$susynvxzcs->{_nxg}		= $nxg;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nxg='.$susynvxzcs->{_nxg};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nxg='.$susynvxzcs->{_nxg};

	} else { 
		print("susynvxzcs, nxg, missing nxg,\n");
	 }
 }


=head2 sub nxs 


=cut

 sub nxs {

	my ( $self,$nxs )		= @_;
	if ( $nxs ne $empty_string ) {

		$susynvxzcs->{_nxs}		= $nxs;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nxs='.$susynvxzcs->{_nxs};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nxs='.$susynvxzcs->{_nxs};

	} else { 
		print("susynvxzcs, nxs, missing nxs,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$susynvxzcs->{_nz}		= $nz;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nz='.$susynvxzcs->{_nz};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nz='.$susynvxzcs->{_nz};

	} else { 
		print("susynvxzcs, nz, missing nz,\n");
	 }
 }


=head2 sub nzc 


=cut

 sub nzc {

	my ( $self,$nzc )		= @_;
	if ( $nzc ne $empty_string ) {

		$susynvxzcs->{_nzc}		= $nzc;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' nzc='.$susynvxzcs->{_nzc};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' nzc='.$susynvxzcs->{_nzc};

	} else { 
		print("susynvxzcs, nzc, missing nzc,\n");
	 }
 }


=head2 sub pert 


=cut

 sub pert {

	my ( $self,$pert )		= @_;
	if ( $pert ne $empty_string ) {

		$susynvxzcs->{_pert}		= $pert;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' pert='.$susynvxzcs->{_pert};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' pert='.$susynvxzcs->{_pert};

	} else { 
		print("susynvxzcs, pert, missing pert,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$susynvxzcs->{_ref}		= $ref;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' ref='.$susynvxzcs->{_ref};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' ref='.$susynvxzcs->{_ref};

	} else { 
		print("susynvxzcs, ref, missing ref,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$susynvxzcs->{_smooth}		= $smooth;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' smooth='.$susynvxzcs->{_smooth};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' smooth='.$susynvxzcs->{_smooth};

	} else { 
		print("susynvxzcs, smooth, missing smooth,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$susynvxzcs->{_tmin}		= $tmin;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' tmin='.$susynvxzcs->{_tmin};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' tmin='.$susynvxzcs->{_tmin};

	} else { 
		print("susynvxzcs, tmin, missing tmin,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$susynvxzcs->{_verbose}		= $verbose;
		$susynvxzcs->{_note}		= $susynvxzcs->{_note}.' verbose='.$susynvxzcs->{_verbose};
		$susynvxzcs->{_Step}		= $susynvxzcs->{_Step}.' verbose='.$susynvxzcs->{_verbose};

	} else { 
		print("susynvxzcs, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 26;

    return($max_index);
}
 
 
1;
