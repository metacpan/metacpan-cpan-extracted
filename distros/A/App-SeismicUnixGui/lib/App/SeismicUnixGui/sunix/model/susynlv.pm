package susynlv;

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
 SUSYNLV - SYNthetic seismograms for Linear Velocity function		



 susynlv >outfile [optional parameters]				



 Optional Parameters:							

 nt=101                 number of time samples				

 dt=0.04                time sampling interval (sec)			

 ft=0.0                 first time (sec)				

 kilounits=1            input length units are km or kilo-feet		

			 =0 for m or ft					

                        Note: Output (sx,gx,offset) are always m or ft 

 nxo=1                  number of source-receiver offsets		

 dxo=0.05               offset sampling interval (kilounits)		

 fxo=0.0                first offset (kilounits, see notes below)	

 xo=fxo,fxo+dxo,...     array of offsets (use only for non-uniform offsets)

 nxm=101                number of midpoints (see notes below)		

 dxm=0.05               midpoint sampling interval (kilounits)		

 fxm=0.0                first midpoint (kilounits)			

 nxs=101                number of shotpoints (see notes below)		

 dxs=0.05               shotpoint sampling interval (kilounits)	

 fxs=0.0                first shotpoint (kilounits)			

 x0=0.0                 distance x at which v00 is specified		

 z0=0.0                 depth z at which v00 is specified		

 v00=2.0                velocity at x0,z0 (kilounits/sec)		

 dvdx=0.0               derivative of velocity with distance x (dv/dx)	

 dvdz=0.0               derivative of velocity with depth z (dv/dz)	

 fpeak=0.2/dt           peak frequency of symmetric Ricker wavelet (Hz)

 ref="1:1,2;4,2"        reflector(s):  "amplitude:x1,z1;x2,z2;x3,z3;...

 smooth=0               =1 for smooth (piecewise cubic spline) reflectors

 er=0                   =1 for exploding reflector amplitudes		

 ls=0                   =1 for line source; default is point source	

 ob=1                   =1 to include obliquity factors		

 tmin=10.0*dt           minimum time of interest (sec)			

 ndpfz=5                number of diffractors per Fresnel zone		

 verbose=0              =1 to print some useful information		



Notes:								

Offsets are signed - may be positive or negative.  Receiver locations	

are computed by adding the signed offset to the source location.	



Specify either midpoint sampling or shotpoint sampling, but not both.	

If neither is specified, the default is the midpoint sampling above.	



More than one ref (reflector) may be specified. Do this by putting	

additional ref= entries on the commandline. When obliquity factors	

are included, then only the left side of each reflector (as the x,z	

reflector coordinates are traversed) is reflecting.  For example, if x	

coordinates increase, then the top side of a reflector is reflecting.	

Note that reflectors are encoded as quoted strings, with an optional	

reflector amplitude: preceding the x,z coordinates of each reflector.	

Default amplitude is 1.0 if amplitude: part of the string is omitted.	





 Credits: CWP Dave Hale, 09/17/91,  Colorado School of Mines

	    UTulsa Chris Liner 5/22/03 added kilounits flag



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

my $susynlv			= {
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
	_kilounits					=> '',
	_ls					=> '',
	_ndpfz					=> '',
	_nt					=> '',
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

	$susynlv->{_Step}     = 'susynlv'.$susynlv->{_Step};
	return ( $susynlv->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susynlv->{_note}     = 'susynlv'.$susynlv->{_note};
	return ( $susynlv->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susynlv->{_dt}			= '';
		$susynlv->{_dvdx}			= '';
		$susynlv->{_dvdz}			= '';
		$susynlv->{_dxm}			= '';
		$susynlv->{_dxo}			= '';
		$susynlv->{_dxs}			= '';
		$susynlv->{_er}			= '';
		$susynlv->{_fpeak}			= '';
		$susynlv->{_ft}			= '';
		$susynlv->{_fxm}			= '';
		$susynlv->{_fxo}			= '';
		$susynlv->{_fxs}			= '';
		$susynlv->{_kilounits}			= '';
		$susynlv->{_ls}			= '';
		$susynlv->{_ndpfz}			= '';
		$susynlv->{_nt}			= '';
		$susynlv->{_nxm}			= '';
		$susynlv->{_nxo}			= '';
		$susynlv->{_nxs}			= '';
		$susynlv->{_ob}			= '';
		$susynlv->{_ref}			= '';
		$susynlv->{_smooth}			= '';
		$susynlv->{_tmin}			= '';
		$susynlv->{_v00}			= '';
		$susynlv->{_verbose}			= '';
		$susynlv->{_x0}			= '';
		$susynlv->{_xo}			= '';
		$susynlv->{_z0}			= '';
		$susynlv->{_Step}			= '';
		$susynlv->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susynlv->{_dt}		= $dt;
		$susynlv->{_note}		= $susynlv->{_note}.' dt='.$susynlv->{_dt};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dt='.$susynlv->{_dt};

	} else { 
		print("susynlv, dt, missing dt,\n");
	 }
 }


=head2 sub dvdx 


=cut

 sub dvdx {

	my ( $self,$dvdx )		= @_;
	if ( $dvdx ne $empty_string ) {

		$susynlv->{_dvdx}		= $dvdx;
		$susynlv->{_note}		= $susynlv->{_note}.' dvdx='.$susynlv->{_dvdx};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dvdx='.$susynlv->{_dvdx};

	} else { 
		print("susynlv, dvdx, missing dvdx,\n");
	 }
 }


=head2 sub dvdz 


=cut

 sub dvdz {

	my ( $self,$dvdz )		= @_;
	if ( $dvdz ne $empty_string ) {

		$susynlv->{_dvdz}		= $dvdz;
		$susynlv->{_note}		= $susynlv->{_note}.' dvdz='.$susynlv->{_dvdz};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dvdz='.$susynlv->{_dvdz};

	} else { 
		print("susynlv, dvdz, missing dvdz,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$susynlv->{_dxm}		= $dxm;
		$susynlv->{_note}		= $susynlv->{_note}.' dxm='.$susynlv->{_dxm};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dxm='.$susynlv->{_dxm};

	} else { 
		print("susynlv, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$susynlv->{_dxo}		= $dxo;
		$susynlv->{_note}		= $susynlv->{_note}.' dxo='.$susynlv->{_dxo};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dxo='.$susynlv->{_dxo};

	} else { 
		print("susynlv, dxo, missing dxo,\n");
	 }
 }


=head2 sub dxs 


=cut

 sub dxs {

	my ( $self,$dxs )		= @_;
	if ( $dxs ne $empty_string ) {

		$susynlv->{_dxs}		= $dxs;
		$susynlv->{_note}		= $susynlv->{_note}.' dxs='.$susynlv->{_dxs};
		$susynlv->{_Step}		= $susynlv->{_Step}.' dxs='.$susynlv->{_dxs};

	} else { 
		print("susynlv, dxs, missing dxs,\n");
	 }
 }


=head2 sub er 


=cut

 sub er {

	my ( $self,$er )		= @_;
	if ( $er ne $empty_string ) {

		$susynlv->{_er}		= $er;
		$susynlv->{_note}		= $susynlv->{_note}.' er='.$susynlv->{_er};
		$susynlv->{_Step}		= $susynlv->{_Step}.' er='.$susynlv->{_er};

	} else { 
		print("susynlv, er, missing er,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$susynlv->{_fpeak}		= $fpeak;
		$susynlv->{_note}		= $susynlv->{_note}.' fpeak='.$susynlv->{_fpeak};
		$susynlv->{_Step}		= $susynlv->{_Step}.' fpeak='.$susynlv->{_fpeak};

	} else { 
		print("susynlv, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$susynlv->{_ft}		= $ft;
		$susynlv->{_note}		= $susynlv->{_note}.' ft='.$susynlv->{_ft};
		$susynlv->{_Step}		= $susynlv->{_Step}.' ft='.$susynlv->{_ft};

	} else { 
		print("susynlv, ft, missing ft,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$susynlv->{_fxm}		= $fxm;
		$susynlv->{_note}		= $susynlv->{_note}.' fxm='.$susynlv->{_fxm};
		$susynlv->{_Step}		= $susynlv->{_Step}.' fxm='.$susynlv->{_fxm};

	} else { 
		print("susynlv, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$susynlv->{_fxo}		= $fxo;
		$susynlv->{_note}		= $susynlv->{_note}.' fxo='.$susynlv->{_fxo};
		$susynlv->{_Step}		= $susynlv->{_Step}.' fxo='.$susynlv->{_fxo};

	} else { 
		print("susynlv, fxo, missing fxo,\n");
	 }
 }


=head2 sub fxs 


=cut

 sub fxs {

	my ( $self,$fxs )		= @_;
	if ( $fxs ne $empty_string ) {

		$susynlv->{_fxs}		= $fxs;
		$susynlv->{_note}		= $susynlv->{_note}.' fxs='.$susynlv->{_fxs};
		$susynlv->{_Step}		= $susynlv->{_Step}.' fxs='.$susynlv->{_fxs};

	} else { 
		print("susynlv, fxs, missing fxs,\n");
	 }
 }


=head2 sub kilounits 


=cut

 sub kilounits {

	my ( $self,$kilounits )		= @_;
	if ( $kilounits ne $empty_string ) {

		$susynlv->{_kilounits}		= $kilounits;
		$susynlv->{_note}		= $susynlv->{_note}.' kilounits='.$susynlv->{_kilounits};
		$susynlv->{_Step}		= $susynlv->{_Step}.' kilounits='.$susynlv->{_kilounits};

	} else { 
		print("susynlv, kilounits, missing kilounits,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$susynlv->{_ls}		= $ls;
		$susynlv->{_note}		= $susynlv->{_note}.' ls='.$susynlv->{_ls};
		$susynlv->{_Step}		= $susynlv->{_Step}.' ls='.$susynlv->{_ls};

	} else { 
		print("susynlv, ls, missing ls,\n");
	 }
 }


=head2 sub ndpfz 


=cut

 sub ndpfz {

	my ( $self,$ndpfz )		= @_;
	if ( $ndpfz ne $empty_string ) {

		$susynlv->{_ndpfz}		= $ndpfz;
		$susynlv->{_note}		= $susynlv->{_note}.' ndpfz='.$susynlv->{_ndpfz};
		$susynlv->{_Step}		= $susynlv->{_Step}.' ndpfz='.$susynlv->{_ndpfz};

	} else { 
		print("susynlv, ndpfz, missing ndpfz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susynlv->{_nt}		= $nt;
		$susynlv->{_note}		= $susynlv->{_note}.' nt='.$susynlv->{_nt};
		$susynlv->{_Step}		= $susynlv->{_Step}.' nt='.$susynlv->{_nt};

	} else { 
		print("susynlv, nt, missing nt,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$susynlv->{_nxm}		= $nxm;
		$susynlv->{_note}		= $susynlv->{_note}.' nxm='.$susynlv->{_nxm};
		$susynlv->{_Step}		= $susynlv->{_Step}.' nxm='.$susynlv->{_nxm};

	} else { 
		print("susynlv, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$susynlv->{_nxo}		= $nxo;
		$susynlv->{_note}		= $susynlv->{_note}.' nxo='.$susynlv->{_nxo};
		$susynlv->{_Step}		= $susynlv->{_Step}.' nxo='.$susynlv->{_nxo};

	} else { 
		print("susynlv, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxs 


=cut

 sub nxs {

	my ( $self,$nxs )		= @_;
	if ( $nxs ne $empty_string ) {

		$susynlv->{_nxs}		= $nxs;
		$susynlv->{_note}		= $susynlv->{_note}.' nxs='.$susynlv->{_nxs};
		$susynlv->{_Step}		= $susynlv->{_Step}.' nxs='.$susynlv->{_nxs};

	} else { 
		print("susynlv, nxs, missing nxs,\n");
	 }
 }


=head2 sub ob 


=cut

 sub ob {

	my ( $self,$ob )		= @_;
	if ( $ob ne $empty_string ) {

		$susynlv->{_ob}		= $ob;
		$susynlv->{_note}		= $susynlv->{_note}.' ob='.$susynlv->{_ob};
		$susynlv->{_Step}		= $susynlv->{_Step}.' ob='.$susynlv->{_ob};

	} else { 
		print("susynlv, ob, missing ob,\n");
	 }
 }


=head2 sub ref 


=cut

 sub ref {

	my ( $self,$ref )		= @_;
	if ( $ref ne $empty_string ) {

		$susynlv->{_ref}		= $ref;
		$susynlv->{_note}		= $susynlv->{_note}.' ref='.$susynlv->{_ref};
		$susynlv->{_Step}		= $susynlv->{_Step}.' ref='.$susynlv->{_ref};

	} else { 
		print("susynlv, ref, missing ref,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$susynlv->{_smooth}		= $smooth;
		$susynlv->{_note}		= $susynlv->{_note}.' smooth='.$susynlv->{_smooth};
		$susynlv->{_Step}		= $susynlv->{_Step}.' smooth='.$susynlv->{_smooth};

	} else { 
		print("susynlv, smooth, missing smooth,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$susynlv->{_tmin}		= $tmin;
		$susynlv->{_note}		= $susynlv->{_note}.' tmin='.$susynlv->{_tmin};
		$susynlv->{_Step}		= $susynlv->{_Step}.' tmin='.$susynlv->{_tmin};

	} else { 
		print("susynlv, tmin, missing tmin,\n");
	 }
 }


=head2 sub v00 


=cut

 sub v00 {

	my ( $self,$v00 )		= @_;
	if ( $v00 ne $empty_string ) {

		$susynlv->{_v00}		= $v00;
		$susynlv->{_note}		= $susynlv->{_note}.' v00='.$susynlv->{_v00};
		$susynlv->{_Step}		= $susynlv->{_Step}.' v00='.$susynlv->{_v00};

	} else { 
		print("susynlv, v00, missing v00,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$susynlv->{_verbose}		= $verbose;
		$susynlv->{_note}		= $susynlv->{_note}.' verbose='.$susynlv->{_verbose};
		$susynlv->{_Step}		= $susynlv->{_Step}.' verbose='.$susynlv->{_verbose};

	} else { 
		print("susynlv, verbose, missing verbose,\n");
	 }
 }


=head2 sub x0 


=cut

 sub x0 {

	my ( $self,$x0 )		= @_;
	if ( $x0 ne $empty_string ) {

		$susynlv->{_x0}		= $x0;
		$susynlv->{_note}		= $susynlv->{_note}.' x0='.$susynlv->{_x0};
		$susynlv->{_Step}		= $susynlv->{_Step}.' x0='.$susynlv->{_x0};

	} else { 
		print("susynlv, x0, missing x0,\n");
	 }
 }


=head2 sub xo 


=cut

 sub xo {

	my ( $self,$xo )		= @_;
	if ( $xo ne $empty_string ) {

		$susynlv->{_xo}		= $xo;
		$susynlv->{_note}		= $susynlv->{_note}.' xo='.$susynlv->{_xo};
		$susynlv->{_Step}		= $susynlv->{_Step}.' xo='.$susynlv->{_xo};

	} else { 
		print("susynlv, xo, missing xo,\n");
	 }
 }


=head2 sub z0 


=cut

 sub z0 {

	my ( $self,$z0 )		= @_;
	if ( $z0 ne $empty_string ) {

		$susynlv->{_z0}		= $z0;
		$susynlv->{_note}		= $susynlv->{_note}.' z0='.$susynlv->{_z0};
		$susynlv->{_Step}		= $susynlv->{_Step}.' z0='.$susynlv->{_z0};

	} else { 
		print("susynlv, z0, missing z0,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 27;

    return($max_index);
}
 
 
1;
