package App::SeismicUnixGui::sunix::model::susynlvcw;

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
 SUSYNLVCW - SYNthetic seismograms for Linear Velocity function	

 		for mode Converted Waves				



 susynlvcw >outfile [optional parameters]				



 Optional Parameters:							

 nt=101		number of time samples				

 dt=0.04		time sampling interval (sec)			

 ft=0.0		first time (sec)				

 nxo=1			number of source-receiver offsets		

 dxo=0.05		offset sampling interval (km)			

 fxo=0.0		first offset (km, see notes below)		

 xo=fxo,fxo+dxo,...	array of offsets (use only for non-uniform offsets)

 nxm=101		number of midpoints (see notes below)		

 dxm=0.05		midpoint sampling interval (km)		

 fxm=0.0		first midpoint (km)				

 nxs=101		number of shotpoints (see notes below)		

 dxs=0.05		shotpoint sampling interval (km)		

 fxs=0.0		first shotpoint (km)				

 x0=0.0		distance x at which v00 is specified		

 z0=0.0		depth z at which v00 is specified		

 v00=2.0		velocity at x0,z0 (km/sec)			

 gamma=1.0		velocity ratio, upgoing/downgoing		

 dvdx=0.0		derivative of velocity with distance x (dv/dx)	

 dvdz=0.0		derivative of velocity with depth z (dv/dz)	

 fpeak=0.2/dt		peak frequency of symmetric Ricker wavelet (Hz)	

 ref="1:1,2;4,2"	reflector(s):  "amplitude:x1,z1;x2,z2;x3,z3;...

 smooth=0		=1 for smooth (piecewise cubic spline) reflectors

 er=0			=1 for exploding reflector amplitudes		

 ls=0			=1 for line source; default is point source	

 ob=1			=1 to include obliquity factors		

 sp=1			=1 to account for amplitude spreading		

 			=0 for constant amplitudes throught out		

 tmin=10.0*dt		minimum time of interest (sec)			

 ndpfz=5		number of diffractors per Fresnel zone		

 verbose=0		=1 to print some useful information		



 Notes:								



 Offsets are signed - may be positive or negative.  Receiver locations	

 are computed by adding the signed offset to the source location.	



 Specify either midpoint sampling or shotpoint sampling, but not both.	

 If neither is specified, the default is the midpoint sampling above.	



 More than one ref (reflector) may be specified.  When obliquity factors

 are included, then only the left side of each reflector (as the x,z	

 reflector coordinates are traversed) is reflecting.  For example, if x

 coordinates increase, then the top side of a reflector is reflecting.	

 Note that reflectors are encoded as quoted strings, with an optional	

 reflector amplitude: preceding the x,z coordinates of each reflector.	

 Default amplitude is 1.0 if amplitude: part of the string is omitted.	



 Note that gamma<1 implies P-SV mode conversion, gamma>1 implies SV-P,	

 and gamma=1 implies no mode conversion.				







 based on Dave Hale's code susynlv, but modified

 by Mohammed Alfaraj to handle mode conversion

 Date of modification: 01/07/92



 Trace header fields set: trid, counit, ns, dt, delrt,

				tracl. tracr, fldr, tracf,

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

my $susynlvcw			= {
	_dt					=> '',
	_dvdx					=> '',
	_dvdz					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dxs					=> '',
	_er					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_fxs					=> '',
	_gamma					=> '',
	_ls					=> '',
	_ndpfz					=> '',
	_nt					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_nxs					=> '',
	_ob					=> '',
	_ref					=> '',
	_smooth					=> '',
	_sp					=> '',
	_tmin					=> '',
	_v00					=> '',
	_verbose					=> '',
	_x0					=> '',
	_xo					=> '',
	_z0					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susynlvcw->{_Step}     = 'susynlvcw'.$susynlvcw->{_Step};
	return ( $susynlvcw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susynlvcw->{_note}     = 'susynlvcw'.$susynlvcw->{_note};
	return ( $susynlvcw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susynlvcw->{_dt}			= '';
		$susynlvcw->{_dvdx}			= '';
		$susynlvcw->{_dvdz}			= '';
		$susynlvcw->{_dxm}			= '';
		$susynlvcw->{_dxo}			= '';
		$susynlvcw->{_dxs}			= '';
		$susynlvcw->{_er}			= '';
		$susynlvcw->{_fpeak}			= '';
		$susynlvcw->{_ft}			= '';
		$susynlvcw->{_fxm}			= '';
		$susynlvcw->{_fxo}			= '';
		$susynlvcw->{_fxs}			= '';
		$susynlvcw->{_gamma}			= '';
		$susynlvcw->{_ls}			= '';
		$susynlvcw->{_ndpfz}			= '';
		$susynlvcw->{_nt}			= '';
		$susynlvcw->{_nxm}			= '';
		$susynlvcw->{_nxo}			= '';
		$susynlvcw->{_nxs}			= '';
		$susynlvcw->{_ob}			= '';
		$susynlvcw->{_ref}			= '';
		$susynlvcw->{_smooth}			= '';
		$susynlvcw->{_sp}			= '';
		$susynlvcw->{_tmin}			= '';
		$susynlvcw->{_v00}			= '';
		$susynlvcw->{_verbose}			= '';
		$susynlvcw->{_x0}			= '';
		$susynlvcw->{_xo}			= '';
		$susynlvcw->{_z0}			= '';
		$susynlvcw->{_Step}			= '';
		$susynlvcw->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susynlvcw->{_dt}		= $dt;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dt='.$susynlvcw->{_dt};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dt='.$susynlvcw->{_dt};

	} else { 
		print("susynlvcw, dt, missing dt,\n");
	 }
 }


=head2 sub dvdx 


=cut

 sub dvdx {

	my ( $self,$dvdx )		= @_;
	if ( $dvdx ne $empty_string ) {

		$susynlvcw->{_dvdx}		= $dvdx;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dvdx='.$susynlvcw->{_dvdx};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dvdx='.$susynlvcw->{_dvdx};

	} else { 
		print("susynlvcw, dvdx, missing dvdx,\n");
	 }
 }


=head2 sub dvdz 


=cut

 sub dvdz {

	my ( $self,$dvdz )		= @_;
	if ( $dvdz ne $empty_string ) {

		$susynlvcw->{_dvdz}		= $dvdz;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dvdz='.$susynlvcw->{_dvdz};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dvdz='.$susynlvcw->{_dvdz};

	} else { 
		print("susynlvcw, dvdz, missing dvdz,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$susynlvcw->{_dxm}		= $dxm;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dxm='.$susynlvcw->{_dxm};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dxm='.$susynlvcw->{_dxm};

	} else { 
		print("susynlvcw, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$susynlvcw->{_dxo}		= $dxo;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dxo='.$susynlvcw->{_dxo};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dxo='.$susynlvcw->{_dxo};

	} else { 
		print("susynlvcw, dxo, missing dxo,\n");
	 }
 }


=head2 sub dxs 


=cut

 sub dxs {

	my ( $self,$dxs )		= @_;
	if ( $dxs ne $empty_string ) {

		$susynlvcw->{_dxs}		= $dxs;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' dxs='.$susynlvcw->{_dxs};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' dxs='.$susynlvcw->{_dxs};

	} else { 
		print("susynlvcw, dxs, missing dxs,\n");
	 }
 }


=head2 sub er 


=cut

 sub er {

	my ( $self,$er )		= @_;
	if ( $er ne $empty_string ) {

		$susynlvcw->{_er}		= $er;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' er='.$susynlvcw->{_er};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' er='.$susynlvcw->{_er};

	} else { 
		print("susynlvcw, er, missing er,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$susynlvcw->{_fpeak}		= $fpeak;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' fpeak='.$susynlvcw->{_fpeak};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' fpeak='.$susynlvcw->{_fpeak};

	} else { 
		print("susynlvcw, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$susynlvcw->{_ft}		= $ft;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' ft='.$susynlvcw->{_ft};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' ft='.$susynlvcw->{_ft};

	} else { 
		print("susynlvcw, ft, missing ft,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$susynlvcw->{_fxm}		= $fxm;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' fxm='.$susynlvcw->{_fxm};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' fxm='.$susynlvcw->{_fxm};

	} else { 
		print("susynlvcw, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$susynlvcw->{_fxo}		= $fxo;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' fxo='.$susynlvcw->{_fxo};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' fxo='.$susynlvcw->{_fxo};

	} else { 
		print("susynlvcw, fxo, missing fxo,\n");
	 }
 }


=head2 sub fxs 


=cut

 sub fxs {

	my ( $self,$fxs )		= @_;
	if ( $fxs ne $empty_string ) {

		$susynlvcw->{_fxs}		= $fxs;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' fxs='.$susynlvcw->{_fxs};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' fxs='.$susynlvcw->{_fxs};

	} else { 
		print("susynlvcw, fxs, missing fxs,\n");
	 }
 }


=head2 sub gamma 


=cut

 sub gamma {

	my ( $self,$gamma )		= @_;
	if ( $gamma ne $empty_string ) {

		$susynlvcw->{_gamma}		= $gamma;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' gamma='.$susynlvcw->{_gamma};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' gamma='.$susynlvcw->{_gamma};

	} else { 
		print("susynlvcw, gamma, missing gamma,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$susynlvcw->{_ls}		= $ls;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' ls='.$susynlvcw->{_ls};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' ls='.$susynlvcw->{_ls};

	} else { 
		print("susynlvcw, ls, missing ls,\n");
	 }
 }


=head2 sub ndpfz 


=cut

 sub ndpfz {

	my ( $self,$ndpfz )		= @_;
	if ( $ndpfz ne $empty_string ) {

		$susynlvcw->{_ndpfz}		= $ndpfz;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' ndpfz='.$susynlvcw->{_ndpfz};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' ndpfz='.$susynlvcw->{_ndpfz};

	} else { 
		print("susynlvcw, ndpfz, missing ndpfz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susynlvcw->{_nt}		= $nt;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' nt='.$susynlvcw->{_nt};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' nt='.$susynlvcw->{_nt};

	} else { 
		print("susynlvcw, nt, missing nt,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$susynlvcw->{_nxm}		= $nxm;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' nxm='.$susynlvcw->{_nxm};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' nxm='.$susynlvcw->{_nxm};

	} else { 
		print("susynlvcw, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$susynlvcw->{_nxo}		= $nxo;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' nxo='.$susynlvcw->{_nxo};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' nxo='.$susynlvcw->{_nxo};

	} else { 
		print("susynlvcw, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxs 


=cut

 sub nxs {

	my ( $self,$nxs )		= @_;
	if ( $nxs ne $empty_string ) {

		$susynlvcw->{_nxs}		= $nxs;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' nxs='.$susynlvcw->{_nxs};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' nxs='.$susynlvcw->{_nxs};

	} else { 
		print("susynlvcw, nxs, missing nxs,\n");
	 }
 }


=head2 sub ob 


=cut

 sub ob {

	my ( $self,$ob )		= @_;
	if ( $ob ne $empty_string ) {

		$susynlvcw->{_ob}		= $ob;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' ob='.$susynlvcw->{_ob};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' ob='.$susynlvcw->{_ob};

	} else { 
		print("susynlvcw, ob, missing ob,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$susynlvcw->{_ref}		= $ref;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' ref='.$susynlvcw->{_ref};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' ref='.$susynlvcw->{_ref};

	} else { 
		print("susynlvcw, ref, missing ref,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$susynlvcw->{_smooth}		= $smooth;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' smooth='.$susynlvcw->{_smooth};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' smooth='.$susynlvcw->{_smooth};

	} else { 
		print("susynlvcw, smooth, missing smooth,\n");
	 }
 }


=head2 sub sp 


=cut

 sub sp {

	my ( $self,$sp )		= @_;
	if ( $sp ne $empty_string ) {

		$susynlvcw->{_sp}		= $sp;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' sp='.$susynlvcw->{_sp};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' sp='.$susynlvcw->{_sp};

	} else { 
		print("susynlvcw, sp, missing sp,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$susynlvcw->{_tmin}		= $tmin;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' tmin='.$susynlvcw->{_tmin};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' tmin='.$susynlvcw->{_tmin};

	} else { 
		print("susynlvcw, tmin, missing tmin,\n");
	 }
 }


=head2 sub v00 


=cut

 sub v00 {

	my ( $self,$v00 )		= @_;
	if ( $v00 ne $empty_string ) {

		$susynlvcw->{_v00}		= $v00;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' v00='.$susynlvcw->{_v00};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' v00='.$susynlvcw->{_v00};

	} else { 
		print("susynlvcw, v00, missing v00,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$susynlvcw->{_verbose}		= $verbose;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' verbose='.$susynlvcw->{_verbose};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' verbose='.$susynlvcw->{_verbose};

	} else { 
		print("susynlvcw, verbose, missing verbose,\n");
	 }
 }


=head2 sub x0 


=cut

 sub x0 {

	my ( $self,$x0 )		= @_;
	if ( $x0 ne $empty_string ) {

		$susynlvcw->{_x0}		= $x0;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' x0='.$susynlvcw->{_x0};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' x0='.$susynlvcw->{_x0};

	} else { 
		print("susynlvcw, x0, missing x0,\n");
	 }
 }


=head2 sub xo 


=cut

 sub xo {

	my ( $self,$xo )		= @_;
	if ( $xo ne $empty_string ) {

		$susynlvcw->{_xo}		= $xo;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' xo='.$susynlvcw->{_xo};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' xo='.$susynlvcw->{_xo};

	} else { 
		print("susynlvcw, xo, missing xo,\n");
	 }
 }


=head2 sub z0 


=cut

 sub z0 {

	my ( $self,$z0 )		= @_;
	if ( $z0 ne $empty_string ) {

		$susynlvcw->{_z0}		= $z0;
		$susynlvcw->{_note}		= $susynlvcw->{_note}.' z0='.$susynlvcw->{_z0};
		$susynlvcw->{_Step}		= $susynlvcw->{_Step}.' z0='.$susynlvcw->{_z0};

	} else { 
		print("susynlvcw, z0, missing z0,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 28;

    return($max_index);
}
 
 
1;
