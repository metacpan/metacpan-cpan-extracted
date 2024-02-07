package App::SeismicUnixGui::sunix::model::susynlvfti;

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
 SUSYNLVFTI - SYNthetic seismograms for Linear Velocity function in a  

              Factorized Transversely Isotropic medium			



 susynlvfti >outfile [optional parameters]				



 Optional Parameters:							

 nt=101		number of time samples				

 dt=0.04		time sampling interval (sec)			

 ft=0.0		first time (sec)				

 kilounits=1            input length units are km or kilo-feet         

                        =0 for m or ft                                 

                        Note: Output (sx,gx,offset) are always m or ft 

 nxo=1			number of source-receiver offsets		

 dxo=0.05		offset sampling interval (kilounits)		

 fxo=0.0		first offset (kilounits, see notes below)	

 xo=fxo,fxo+dxo,...    array of offsets (use only for non-uniform offsets)

 nxm=101		number of midpoints (see notes below)		

 dxm=0.05		midpoint sampling interval (kilounits)		

 fxm=0.0		first midpoint (kilounits)			

 nxs=101		number of shotpoints (see notes below)		

 dxs=0.05		shotpoint sampling interval (kilounits)		

 fxs=0.0		first shotpoint (kilounits)			

 x0=0.0		distance x at which v00 is specified		

 z0=0.0		depth z at which v00 is specified		

 v00=2.0		velocity at x0,z0 (kilounits/sec)		

 dvdx=0.0		derivative of velocity with distance x (dv/dx)	

 dvdz=0.0		derivative of velocity with depth z (dv/dz)	

 fpeak=0.2/dt		peak frequency of symmetric Ricker wavelet (Hz)	

 ref=1:1,2;4,2		reflector(s):  "amplitude:x1,z1;x2,z2;x3,z3;...

 smooth=0		=1 for smooth (piecewise cubic spline) reflectors

 er=0			=1 for exploding reflector amplitudes		

 ls=0			=1 for line source; default is point source	

 ob=0			=1 to include obliquity factors			

 tmin=10.0*dt		minimum time of interest (sec)			

 ndpfz=5		number of diffractors per Fresnel zone		

 verbose=1		=1 to print some useful information		



 For transversely isotropic media:					

 angxs=0.0		angle of symmetry axis with the vertical (degrees)

 define the media using either						

 a=1.0		corresponding to the ratio of elastic coef.(c1111/c3333)

 f=0.4		corresponding to the ratio of elastic coef. (c1133/c3333)

 l=0.3		corresponding to the ratio of elastic coef. (c1313/c3333)

 Alternately use Tompson\'s parameters:				

 delta=0	Thomsen's 1986 defined parameter			

 epsilon=0	Thomsen's 1986 defined parameter			

 ntries=40	number of iterations in Snell's law and offset searches 

 epsx=.001	lateral offset tolerance				

 epst=.0001	reflection time tolerance				

 nitmax=12	max number of iterations in travel time integrations	



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



 Concerning the choice of delta and epsilon. The difference between delta", 

 and epsilon should not exceed one. A possible break down of the program

 is the result. This is caused primarly by the break down in the two point", 

 ray-tracing. Also keep the values of delta and epsilon between 2 and -2.

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

my $susynlvfti			= {
	_a					=> '',
	_angxs					=> '',
	_delta					=> '',
	_dt					=> '',
	_dvdx					=> '',
	_dvdz					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dxs					=> '',
	_epsilon					=> '',
	_epst					=> '',
	_epsx					=> '',
	_er					=> '',
	_f					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_fxs					=> '',
	_kilounits					=> '',
	_l					=> '',
	_ls					=> '',
	_ndpfz					=> '',
	_nitmax					=> '',
	_nt					=> '',
	_ntries					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_nxs					=> '',
	_ob					=> '',
	_ref					=> '',
	_smooth					=> '',
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

	$susynlvfti->{_Step}     = 'susynlvfti'.$susynlvfti->{_Step};
	return ( $susynlvfti->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susynlvfti->{_note}     = 'susynlvfti'.$susynlvfti->{_note};
	return ( $susynlvfti->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susynlvfti->{_a}			= '';
		$susynlvfti->{_angxs}			= '';
		$susynlvfti->{_delta}			= '';
		$susynlvfti->{_dt}			= '';
		$susynlvfti->{_dvdx}			= '';
		$susynlvfti->{_dvdz}			= '';
		$susynlvfti->{_dxm}			= '';
		$susynlvfti->{_dxo}			= '';
		$susynlvfti->{_dxs}			= '';
		$susynlvfti->{_epsilon}			= '';
		$susynlvfti->{_epst}			= '';
		$susynlvfti->{_epsx}			= '';
		$susynlvfti->{_er}			= '';
		$susynlvfti->{_f}			= '';
		$susynlvfti->{_fpeak}			= '';
		$susynlvfti->{_ft}			= '';
		$susynlvfti->{_fxm}			= '';
		$susynlvfti->{_fxo}			= '';
		$susynlvfti->{_fxs}			= '';
		$susynlvfti->{_kilounits}			= '';
		$susynlvfti->{_l}			= '';
		$susynlvfti->{_ls}			= '';
		$susynlvfti->{_ndpfz}			= '';
		$susynlvfti->{_nitmax}			= '';
		$susynlvfti->{_nt}			= '';
		$susynlvfti->{_ntries}			= '';
		$susynlvfti->{_nxm}			= '';
		$susynlvfti->{_nxo}			= '';
		$susynlvfti->{_nxs}			= '';
		$susynlvfti->{_ob}			= '';
		$susynlvfti->{_ref}			= '';
		$susynlvfti->{_smooth}			= '';
		$susynlvfti->{_tmin}			= '';
		$susynlvfti->{_v00}			= '';
		$susynlvfti->{_verbose}			= '';
		$susynlvfti->{_x0}			= '';
		$susynlvfti->{_xo}			= '';
		$susynlvfti->{_z0}			= '';
		$susynlvfti->{_Step}			= '';
		$susynlvfti->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$susynlvfti->{_a}		= $a;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' a='.$susynlvfti->{_a};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' a='.$susynlvfti->{_a};

	} else { 
		print("susynlvfti, a, missing a,\n");
	 }
 }


=head2 sub angxs 


=cut

 sub angxs {

	my ( $self,$angxs )		= @_;
	if ( $angxs ne $empty_string ) {

		$susynlvfti->{_angxs}		= $angxs;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' angxs='.$susynlvfti->{_angxs};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' angxs='.$susynlvfti->{_angxs};

	} else { 
		print("susynlvfti, angxs, missing angxs,\n");
	 }
 }


=head2 sub delta 


=cut

 sub delta {

	my ( $self,$delta )		= @_;
	if ( $delta ne $empty_string ) {

		$susynlvfti->{_delta}		= $delta;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' delta='.$susynlvfti->{_delta};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' delta='.$susynlvfti->{_delta};

	} else { 
		print("susynlvfti, delta, missing delta,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susynlvfti->{_dt}		= $dt;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dt='.$susynlvfti->{_dt};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dt='.$susynlvfti->{_dt};

	} else { 
		print("susynlvfti, dt, missing dt,\n");
	 }
 }


=head2 sub dvdx 


=cut

 sub dvdx {

	my ( $self,$dvdx )		= @_;
	if ( $dvdx ne $empty_string ) {

		$susynlvfti->{_dvdx}		= $dvdx;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dvdx='.$susynlvfti->{_dvdx};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dvdx='.$susynlvfti->{_dvdx};

	} else { 
		print("susynlvfti, dvdx, missing dvdx,\n");
	 }
 }


=head2 sub dvdz 


=cut

 sub dvdz {

	my ( $self,$dvdz )		= @_;
	if ( $dvdz ne $empty_string ) {

		$susynlvfti->{_dvdz}		= $dvdz;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dvdz='.$susynlvfti->{_dvdz};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dvdz='.$susynlvfti->{_dvdz};

	} else { 
		print("susynlvfti, dvdz, missing dvdz,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$susynlvfti->{_dxm}		= $dxm;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dxm='.$susynlvfti->{_dxm};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dxm='.$susynlvfti->{_dxm};

	} else { 
		print("susynlvfti, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$susynlvfti->{_dxo}		= $dxo;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dxo='.$susynlvfti->{_dxo};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dxo='.$susynlvfti->{_dxo};

	} else { 
		print("susynlvfti, dxo, missing dxo,\n");
	 }
 }


=head2 sub dxs 


=cut

 sub dxs {

	my ( $self,$dxs )		= @_;
	if ( $dxs ne $empty_string ) {

		$susynlvfti->{_dxs}		= $dxs;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' dxs='.$susynlvfti->{_dxs};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' dxs='.$susynlvfti->{_dxs};

	} else { 
		print("susynlvfti, dxs, missing dxs,\n");
	 }
 }


=head2 sub epsilon 


=cut

 sub epsilon {

	my ( $self,$epsilon )		= @_;
	if ( $epsilon ne $empty_string ) {

		$susynlvfti->{_epsilon}		= $epsilon;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' epsilon='.$susynlvfti->{_epsilon};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' epsilon='.$susynlvfti->{_epsilon};

	} else { 
		print("susynlvfti, epsilon, missing epsilon,\n");
	 }
 }


=head2 sub epst 


=cut

 sub epst {

	my ( $self,$epst )		= @_;
	if ( $epst ne $empty_string ) {

		$susynlvfti->{_epst}		= $epst;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' epst='.$susynlvfti->{_epst};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' epst='.$susynlvfti->{_epst};

	} else { 
		print("susynlvfti, epst, missing epst,\n");
	 }
 }


=head2 sub epsx 


=cut

 sub epsx {

	my ( $self,$epsx )		= @_;
	if ( $epsx ne $empty_string ) {

		$susynlvfti->{_epsx}		= $epsx;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' epsx='.$susynlvfti->{_epsx};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' epsx='.$susynlvfti->{_epsx};

	} else { 
		print("susynlvfti, epsx, missing epsx,\n");
	 }
 }


=head2 sub er 


=cut

 sub er {

	my ( $self,$er )		= @_;
	if ( $er ne $empty_string ) {

		$susynlvfti->{_er}		= $er;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' er='.$susynlvfti->{_er};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' er='.$susynlvfti->{_er};

	} else { 
		print("susynlvfti, er, missing er,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$susynlvfti->{_f}		= $f;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' f='.$susynlvfti->{_f};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' f='.$susynlvfti->{_f};

	} else { 
		print("susynlvfti, f, missing f,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$susynlvfti->{_fpeak}		= $fpeak;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' fpeak='.$susynlvfti->{_fpeak};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' fpeak='.$susynlvfti->{_fpeak};

	} else { 
		print("susynlvfti, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$susynlvfti->{_ft}		= $ft;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ft='.$susynlvfti->{_ft};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ft='.$susynlvfti->{_ft};

	} else { 
		print("susynlvfti, ft, missing ft,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$susynlvfti->{_fxm}		= $fxm;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' fxm='.$susynlvfti->{_fxm};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' fxm='.$susynlvfti->{_fxm};

	} else { 
		print("susynlvfti, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$susynlvfti->{_fxo}		= $fxo;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' fxo='.$susynlvfti->{_fxo};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' fxo='.$susynlvfti->{_fxo};

	} else { 
		print("susynlvfti, fxo, missing fxo,\n");
	 }
 }


=head2 sub fxs 


=cut

 sub fxs {

	my ( $self,$fxs )		= @_;
	if ( $fxs ne $empty_string ) {

		$susynlvfti->{_fxs}		= $fxs;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' fxs='.$susynlvfti->{_fxs};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' fxs='.$susynlvfti->{_fxs};

	} else { 
		print("susynlvfti, fxs, missing fxs,\n");
	 }
 }


=head2 sub kilounits 


=cut

 sub kilounits {

	my ( $self,$kilounits )		= @_;
	if ( $kilounits ne $empty_string ) {

		$susynlvfti->{_kilounits}		= $kilounits;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' kilounits='.$susynlvfti->{_kilounits};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' kilounits='.$susynlvfti->{_kilounits};

	} else { 
		print("susynlvfti, kilounits, missing kilounits,\n");
	 }
 }


=head2 sub l 


=cut

 sub l {

	my ( $self,$l )		= @_;
	if ( $l ne $empty_string ) {

		$susynlvfti->{_l}		= $l;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' l='.$susynlvfti->{_l};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' l='.$susynlvfti->{_l};

	} else { 
		print("susynlvfti, l, missing l,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$susynlvfti->{_ls}		= $ls;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ls='.$susynlvfti->{_ls};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ls='.$susynlvfti->{_ls};

	} else { 
		print("susynlvfti, ls, missing ls,\n");
	 }
 }


=head2 sub ndpfz 


=cut

 sub ndpfz {

	my ( $self,$ndpfz )		= @_;
	if ( $ndpfz ne $empty_string ) {

		$susynlvfti->{_ndpfz}		= $ndpfz;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ndpfz='.$susynlvfti->{_ndpfz};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ndpfz='.$susynlvfti->{_ndpfz};

	} else { 
		print("susynlvfti, ndpfz, missing ndpfz,\n");
	 }
 }


=head2 sub nitmax 


=cut

 sub nitmax {

	my ( $self,$nitmax )		= @_;
	if ( $nitmax ne $empty_string ) {

		$susynlvfti->{_nitmax}		= $nitmax;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' nitmax='.$susynlvfti->{_nitmax};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' nitmax='.$susynlvfti->{_nitmax};

	} else { 
		print("susynlvfti, nitmax, missing nitmax,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susynlvfti->{_nt}		= $nt;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' nt='.$susynlvfti->{_nt};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' nt='.$susynlvfti->{_nt};

	} else { 
		print("susynlvfti, nt, missing nt,\n");
	 }
 }


=head2 sub ntries 


=cut

 sub ntries {

	my ( $self,$ntries )		= @_;
	if ( $ntries ne $empty_string ) {

		$susynlvfti->{_ntries}		= $ntries;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ntries='.$susynlvfti->{_ntries};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ntries='.$susynlvfti->{_ntries};

	} else { 
		print("susynlvfti, ntries, missing ntries,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$susynlvfti->{_nxm}		= $nxm;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' nxm='.$susynlvfti->{_nxm};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' nxm='.$susynlvfti->{_nxm};

	} else { 
		print("susynlvfti, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$susynlvfti->{_nxo}		= $nxo;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' nxo='.$susynlvfti->{_nxo};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' nxo='.$susynlvfti->{_nxo};

	} else { 
		print("susynlvfti, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxs 


=cut

 sub nxs {

	my ( $self,$nxs )		= @_;
	if ( $nxs ne $empty_string ) {

		$susynlvfti->{_nxs}		= $nxs;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' nxs='.$susynlvfti->{_nxs};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' nxs='.$susynlvfti->{_nxs};

	} else { 
		print("susynlvfti, nxs, missing nxs,\n");
	 }
 }


=head2 sub ob 


=cut

 sub ob {

	my ( $self,$ob )		= @_;
	if ( $ob ne $empty_string ) {

		$susynlvfti->{_ob}		= $ob;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ob='.$susynlvfti->{_ob};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ob='.$susynlvfti->{_ob};

	} else { 
		print("susynlvfti, ob, missing ob,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$susynlvfti->{_ref}		= $ref;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' ref='.$susynlvfti->{_ref};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' ref='.$susynlvfti->{_ref};

	} else { 
		print("susynlvfti, ref, missing ref,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$susynlvfti->{_smooth}		= $smooth;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' smooth='.$susynlvfti->{_smooth};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' smooth='.$susynlvfti->{_smooth};

	} else { 
		print("susynlvfti, smooth, missing smooth,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$susynlvfti->{_tmin}		= $tmin;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' tmin='.$susynlvfti->{_tmin};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' tmin='.$susynlvfti->{_tmin};

	} else { 
		print("susynlvfti, tmin, missing tmin,\n");
	 }
 }


=head2 sub v00 


=cut

 sub v00 {

	my ( $self,$v00 )		= @_;
	if ( $v00 ne $empty_string ) {

		$susynlvfti->{_v00}		= $v00;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' v00='.$susynlvfti->{_v00};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' v00='.$susynlvfti->{_v00};

	} else { 
		print("susynlvfti, v00, missing v00,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$susynlvfti->{_verbose}		= $verbose;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' verbose='.$susynlvfti->{_verbose};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' verbose='.$susynlvfti->{_verbose};

	} else { 
		print("susynlvfti, verbose, missing verbose,\n");
	 }
 }


=head2 sub x0 


=cut

 sub x0 {

	my ( $self,$x0 )		= @_;
	if ( $x0 ne $empty_string ) {

		$susynlvfti->{_x0}		= $x0;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' x0='.$susynlvfti->{_x0};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' x0='.$susynlvfti->{_x0};

	} else { 
		print("susynlvfti, x0, missing x0,\n");
	 }
 }


=head2 sub xo 


=cut

 sub xo {

	my ( $self,$xo )		= @_;
	if ( $xo ne $empty_string ) {

		$susynlvfti->{_xo}		= $xo;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' xo='.$susynlvfti->{_xo};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' xo='.$susynlvfti->{_xo};

	} else { 
		print("susynlvfti, xo, missing xo,\n");
	 }
 }


=head2 sub z0 


=cut

 sub z0 {

	my ( $self,$z0 )		= @_;
	if ( $z0 ne $empty_string ) {

		$susynlvfti->{_z0}		= $z0;
		$susynlvfti->{_note}		= $susynlvfti->{_note}.' z0='.$susynlvfti->{_z0};
		$susynlvfti->{_Step}		= $susynlvfti->{_Step}.' z0='.$susynlvfti->{_z0};

	} else { 
		print("susynlvfti, z0, missing z0,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 37;

    return($max_index);
}
 
 
1;
