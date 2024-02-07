package App::SeismicUnixGui::sunix::inversion::suinvco3d;

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
 SUINVCO3D - Seismic INVersion of Common Offset data with V(X,Y,Z) velocity	

	     function in 3D							



     suinvco3d <infile >outfile [optional parameters] 				



 Required Parameters:								

 vfile=		  file containing velocity array v[nvy][nvx][nvz]	

 nzv=		   number of z samples (1st dimension) in velocity		

 nxm=			number of midpoints of input traces			

 nym=			number of lines 					

 geo_type=		geometry type						

			1 ---- general velocity distribution v(x,y,z)		

			2 ---- v(x,z) medium					

			3 ---- v(z) medium					

 com_type=		computation type, determines what tables are needed	

			1 ---- only needs traveltime,	   weight=1.0		

			2 ---- traveltime, propagation angles,  weight=ctheta	

			3 ---- traveltime, angle and amplitude,			

						  weight = det/as/ag/(1+ctheta)	

 nzt=		   number of z samples (1st dimension) in traveltime		

 nxt=		   number of x samples (2nd dimension) in traveltime		

 nyt=		   number of y samples (3rd dimension) in traveltime		

 tfile=		  file containing traveltime array t[nyt][nxt][nzt]		

 ampfile		file containing amplitude array amp[nyt][nxt][nzt]	

 d21file=		file containing Beylkin determinant component array	

 d22file=		file containing Beylkin determinant component array	

 d23file=		file containing Beylkin determinant component array	

 d31file=		file containing Beylkin determinant component array	

 d32file=		file containing Beylkin determinant component array	

 d33file=		file containing Beylkin determinant component array	

 a1file=		 file containing ray propagation angle (polar) array	

 b1file=		 file containing ray propagation angle (azimuth) array	



 Optional Parameters:								

 dt= or from header (dt) 	time sampling interval of input data		

 offs= or from header (offset) 	source-receiver offset 			

 dxm= or from header (d2) 	x sampling interval of midpoints 		

 fxm=0		  first midpoint in input trace					

 dym=50.0		y sampling interval of midpoints 			

 fym=0		  y-coordinate of first midpoint in input trace			

 nxv=		   number of x samples (2nd dimension) in velocity		

 nyv=		   number of y samples (3rd dimension) in velocity		

 dxv=50.0		x sampling interval of velocity				

 fxv=0.0		first x sample of velocity				

 dyv=50.0		y sampling interval of velocity				

 fyv=0.0		first y sample of velocity				

 dzv=50.0		z sampling interval of velocity				

 fzv=0.0		first z sample of velocity				

 nxb=nx/2		band centered at midpoints (see note)			

 fxo=0.0		x-coordinate of first output trace 			

 dxo=15.0		horizontal spacing of output trace 			

 nxo=101		number of output traces 				",	

 fyo=0.0		y-coordinate of first output trace			

 dyo=15.0		y-coordinate spacing of output trace			

 nyo=101		number of output traces in y-direction			

 fzo=0.0		z-coordinate of first point in output trace 		

 dzo=15.0		vertical spacing of output trace 			

 nzo=101		number of points in output trace			",	

 dxt=100.0		x-coordinate spacing of input tables(traveltime, etc)	

 dyt=100.0		y-coordinate spacing of input tables(traveltime, etc)	

 dzt=100.0		z-coordinate spacing of input tables(traveltime, etc)	

 xt0=0.0		x-coordinate of first input tables			

 xt1=0.0		x-coordinate of last input tables			

 yt0=0.0		y-coordinate of first input tables		 	

 yt1=0.0		y-coordinate of last input tables			

 fmax=0.25/dt		Maximum frequency set for operator antialiasing		

 ang=180		Maximum dip angle allowed in the image			

 apet=45		aperture open angle for summation			

 alias=0		=1 to set the anti-aliasing filter			

 verbose=1		=1 to print some useful information			



 Notes:									



 The information needed in the computation of the weighting factor		

 in Kirchhoff inversion formula includes traveltime, amplitude, 		

 and Beylkin determinant at each grid point for each source/receiver		

 point. For a 3-D nonzero common-offset inversion, the Beylkin			

 determinant is computed from a 3x3 matrix with each element 			

 containing a sum of quantities from the source and the receiver.		

 The nine elements in the Beylkin matrix for each source/receiver		

 can be determined by eight quantities. These quantities can be		

 computed by the dynamic ray tracer. Tables of traveltime, amplitude,		

 and Beylkin matrix elements from each source and receiver are			

 pre-computed and stored in files.						



 For each trace, tables of traveltime, amplitude and Beylkin matrix		

 at the source and receiver location are input or interpolated from		

 neighboring tables. For the computation of weighting factor, linear		

 interpolation is used to determine the weighting factor at each		

 output grid point, and weighted diffraction summation is then 		

 applied. For each midpoint, the traveltimes and weight factors are		

 calculated in the horizontal range of (xm-nxb*dx-z*tan(apet),			

 xm+nxb*dx+z*tan(apet)).							



 Offsets are signed - may be positive or negative. 				", 







 This algorithm is based on the inversion formulas in chaper 5 of

 _Mathematics of Multimensional Seismic Migration, Imaging and Inversion_ 

 (Springer-Verlag, 2000), by Bleistein, N., Cohen, J.K.

 and Stockwell, Jr., J. W.



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

my $suinvco3d			= {
	_a1file					=> '',
	_alias					=> '',
	_ang					=> '',
	_apet					=> '',
	_b1file					=> '',
	_com_type					=> '',
	_d21file					=> '',
	_d22file					=> '',
	_d23file					=> '',
	_d31file					=> '',
	_d32file					=> '',
	_d33file					=> '',
	_dt					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dxt					=> '',
	_dxv					=> '',
	_dym					=> '',
	_dyo					=> '',
	_dyt					=> '',
	_dyv					=> '',
	_dzo					=> '',
	_dzt					=> '',
	_dzv					=> '',
	_fmax					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_fxv					=> '',
	_fym					=> '',
	_fyo					=> '',
	_fyv					=> '',
	_fzo					=> '',
	_fzv					=> '',
	_geo_type					=> '',
	_nxb					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_nxt					=> '',
	_nxv					=> '',
	_nym					=> '',
	_nyo					=> '',
	_nyt					=> '',
	_nyv					=> '',
	_nzo					=> '',
	_nzt					=> '',
	_nzv					=> '',
	_offs					=> '',
	_tfile					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_weight					=> '',
	_xt0					=> '',
	_xt1					=> '',
	_yt0					=> '',
	_yt1					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suinvco3d->{_Step}     = 'suinvco3d'.$suinvco3d->{_Step};
	return ( $suinvco3d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suinvco3d->{_note}     = 'suinvco3d'.$suinvco3d->{_note};
	return ( $suinvco3d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suinvco3d->{_a1file}			= '';
		$suinvco3d->{_alias}			= '';
		$suinvco3d->{_ang}			= '';
		$suinvco3d->{_apet}			= '';
		$suinvco3d->{_b1file}			= '';
		$suinvco3d->{_com_type}			= '';
		$suinvco3d->{_d21file}			= '';
		$suinvco3d->{_d22file}			= '';
		$suinvco3d->{_d23file}			= '';
		$suinvco3d->{_d31file}			= '';
		$suinvco3d->{_d32file}			= '';
		$suinvco3d->{_d33file}			= '';
		$suinvco3d->{_dt}			= '';
		$suinvco3d->{_dxm}			= '';
		$suinvco3d->{_dxo}			= '';
		$suinvco3d->{_dxt}			= '';
		$suinvco3d->{_dxv}			= '';
		$suinvco3d->{_dym}			= '';
		$suinvco3d->{_dyo}			= '';
		$suinvco3d->{_dyt}			= '';
		$suinvco3d->{_dyv}			= '';
		$suinvco3d->{_dzo}			= '';
		$suinvco3d->{_dzt}			= '';
		$suinvco3d->{_dzv}			= '';
		$suinvco3d->{_fmax}			= '';
		$suinvco3d->{_fxm}			= '';
		$suinvco3d->{_fxo}			= '';
		$suinvco3d->{_fxv}			= '';
		$suinvco3d->{_fym}			= '';
		$suinvco3d->{_fyo}			= '';
		$suinvco3d->{_fyv}			= '';
		$suinvco3d->{_fzo}			= '';
		$suinvco3d->{_fzv}			= '';
		$suinvco3d->{_geo_type}			= '';
		$suinvco3d->{_nxb}			= '';
		$suinvco3d->{_nxm}			= '';
		$suinvco3d->{_nxo}			= '';
		$suinvco3d->{_nxt}			= '';
		$suinvco3d->{_nxv}			= '';
		$suinvco3d->{_nym}			= '';
		$suinvco3d->{_nyo}			= '';
		$suinvco3d->{_nyt}			= '';
		$suinvco3d->{_nyv}			= '';
		$suinvco3d->{_nzo}			= '';
		$suinvco3d->{_nzt}			= '';
		$suinvco3d->{_nzv}			= '';
		$suinvco3d->{_offs}			= '';
		$suinvco3d->{_tfile}			= '';
		$suinvco3d->{_verbose}			= '';
		$suinvco3d->{_vfile}			= '';
		$suinvco3d->{_weight}			= '';
		$suinvco3d->{_xt0}			= '';
		$suinvco3d->{_xt1}			= '';
		$suinvco3d->{_yt0}			= '';
		$suinvco3d->{_yt1}			= '';
		$suinvco3d->{_Step}			= '';
		$suinvco3d->{_note}			= '';
 }


=head2 sub a1file 


=cut

 sub a1file {

	my ( $self,$a1file )		= @_;
	if ( $a1file ne $empty_string ) {

		$suinvco3d->{_a1file}		= $a1file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' a1file='.$suinvco3d->{_a1file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' a1file='.$suinvco3d->{_a1file};

	} else { 
		print("suinvco3d, a1file, missing a1file,\n");
	 }
 }


=head2 sub alias 


=cut

 sub alias {

	my ( $self,$alias )		= @_;
	if ( $alias ne $empty_string ) {

		$suinvco3d->{_alias}		= $alias;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' alias='.$suinvco3d->{_alias};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' alias='.$suinvco3d->{_alias};

	} else { 
		print("suinvco3d, alias, missing alias,\n");
	 }
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$suinvco3d->{_ang}		= $ang;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' ang='.$suinvco3d->{_ang};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' ang='.$suinvco3d->{_ang};

	} else { 
		print("suinvco3d, ang, missing ang,\n");
	 }
 }


=head2 sub apet 


=cut

 sub apet {

	my ( $self,$apet )		= @_;
	if ( $apet ne $empty_string ) {

		$suinvco3d->{_apet}		= $apet;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' apet='.$suinvco3d->{_apet};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' apet='.$suinvco3d->{_apet};

	} else { 
		print("suinvco3d, apet, missing apet,\n");
	 }
 }


=head2 sub b1file 


=cut

 sub b1file {

	my ( $self,$b1file )		= @_;
	if ( $b1file ne $empty_string ) {

		$suinvco3d->{_b1file}		= $b1file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' b1file='.$suinvco3d->{_b1file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' b1file='.$suinvco3d->{_b1file};

	} else { 
		print("suinvco3d, b1file, missing b1file,\n");
	 }
 }


=head2 sub com_type 


=cut

 sub com_type {

	my ( $self,$com_type )		= @_;
	if ( $com_type ne $empty_string ) {

		$suinvco3d->{_com_type}		= $com_type;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' com_type='.$suinvco3d->{_com_type};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' com_type='.$suinvco3d->{_com_type};

	} else { 
		print("suinvco3d, com_type, missing com_type,\n");
	 }
 }


=head2 sub d21file 


=cut

 sub d21file {

	my ( $self,$d21file )		= @_;
	if ( $d21file ne $empty_string ) {

		$suinvco3d->{_d21file}		= $d21file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d21file='.$suinvco3d->{_d21file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d21file='.$suinvco3d->{_d21file};

	} else { 
		print("suinvco3d, d21file, missing d21file,\n");
	 }
 }


=head2 sub d22file 


=cut

 sub d22file {

	my ( $self,$d22file )		= @_;
	if ( $d22file ne $empty_string ) {

		$suinvco3d->{_d22file}		= $d22file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d22file='.$suinvco3d->{_d22file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d22file='.$suinvco3d->{_d22file};

	} else { 
		print("suinvco3d, d22file, missing d22file,\n");
	 }
 }


=head2 sub d23file 


=cut

 sub d23file {

	my ( $self,$d23file )		= @_;
	if ( $d23file ne $empty_string ) {

		$suinvco3d->{_d23file}		= $d23file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d23file='.$suinvco3d->{_d23file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d23file='.$suinvco3d->{_d23file};

	} else { 
		print("suinvco3d, d23file, missing d23file,\n");
	 }
 }


=head2 sub d31file 


=cut

 sub d31file {

	my ( $self,$d31file )		= @_;
	if ( $d31file ne $empty_string ) {

		$suinvco3d->{_d31file}		= $d31file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d31file='.$suinvco3d->{_d31file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d31file='.$suinvco3d->{_d31file};

	} else { 
		print("suinvco3d, d31file, missing d31file,\n");
	 }
 }


=head2 sub d32file 


=cut

 sub d32file {

	my ( $self,$d32file )		= @_;
	if ( $d32file ne $empty_string ) {

		$suinvco3d->{_d32file}		= $d32file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d32file='.$suinvco3d->{_d32file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d32file='.$suinvco3d->{_d32file};

	} else { 
		print("suinvco3d, d32file, missing d32file,\n");
	 }
 }


=head2 sub d33file 


=cut

 sub d33file {

	my ( $self,$d33file )		= @_;
	if ( $d33file ne $empty_string ) {

		$suinvco3d->{_d33file}		= $d33file;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' d33file='.$suinvco3d->{_d33file};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' d33file='.$suinvco3d->{_d33file};

	} else { 
		print("suinvco3d, d33file, missing d33file,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suinvco3d->{_dt}		= $dt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dt='.$suinvco3d->{_dt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dt='.$suinvco3d->{_dt};

	} else { 
		print("suinvco3d, dt, missing dt,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$suinvco3d->{_dxm}		= $dxm;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dxm='.$suinvco3d->{_dxm};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dxm='.$suinvco3d->{_dxm};

	} else { 
		print("suinvco3d, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$suinvco3d->{_dxo}		= $dxo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dxo='.$suinvco3d->{_dxo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dxo='.$suinvco3d->{_dxo};

	} else { 
		print("suinvco3d, dxo, missing dxo,\n");
	 }
 }


=head2 sub dxt 


=cut

 sub dxt {

	my ( $self,$dxt )		= @_;
	if ( $dxt ne $empty_string ) {

		$suinvco3d->{_dxt}		= $dxt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dxt='.$suinvco3d->{_dxt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dxt='.$suinvco3d->{_dxt};

	} else { 
		print("suinvco3d, dxt, missing dxt,\n");
	 }
 }


=head2 sub dxv 


=cut

 sub dxv {

	my ( $self,$dxv )		= @_;
	if ( $dxv ne $empty_string ) {

		$suinvco3d->{_dxv}		= $dxv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dxv='.$suinvco3d->{_dxv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dxv='.$suinvco3d->{_dxv};

	} else { 
		print("suinvco3d, dxv, missing dxv,\n");
	 }
 }


=head2 sub dym 


=cut

 sub dym {

	my ( $self,$dym )		= @_;
	if ( $dym ne $empty_string ) {

		$suinvco3d->{_dym}		= $dym;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dym='.$suinvco3d->{_dym};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dym='.$suinvco3d->{_dym};

	} else { 
		print("suinvco3d, dym, missing dym,\n");
	 }
 }


=head2 sub dyo 


=cut

 sub dyo {

	my ( $self,$dyo )		= @_;
	if ( $dyo ne $empty_string ) {

		$suinvco3d->{_dyo}		= $dyo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dyo='.$suinvco3d->{_dyo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dyo='.$suinvco3d->{_dyo};

	} else { 
		print("suinvco3d, dyo, missing dyo,\n");
	 }
 }


=head2 sub dyt 


=cut

 sub dyt {

	my ( $self,$dyt )		= @_;
	if ( $dyt ne $empty_string ) {

		$suinvco3d->{_dyt}		= $dyt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dyt='.$suinvco3d->{_dyt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dyt='.$suinvco3d->{_dyt};

	} else { 
		print("suinvco3d, dyt, missing dyt,\n");
	 }
 }


=head2 sub dyv 


=cut

 sub dyv {

	my ( $self,$dyv )		= @_;
	if ( $dyv ne $empty_string ) {

		$suinvco3d->{_dyv}		= $dyv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dyv='.$suinvco3d->{_dyv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dyv='.$suinvco3d->{_dyv};

	} else { 
		print("suinvco3d, dyv, missing dyv,\n");
	 }
 }


=head2 sub dzo 


=cut

 sub dzo {

	my ( $self,$dzo )		= @_;
	if ( $dzo ne $empty_string ) {

		$suinvco3d->{_dzo}		= $dzo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dzo='.$suinvco3d->{_dzo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dzo='.$suinvco3d->{_dzo};

	} else { 
		print("suinvco3d, dzo, missing dzo,\n");
	 }
 }


=head2 sub dzt 


=cut

 sub dzt {

	my ( $self,$dzt )		= @_;
	if ( $dzt ne $empty_string ) {

		$suinvco3d->{_dzt}		= $dzt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dzt='.$suinvco3d->{_dzt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dzt='.$suinvco3d->{_dzt};

	} else { 
		print("suinvco3d, dzt, missing dzt,\n");
	 }
 }


=head2 sub dzv 


=cut

 sub dzv {

	my ( $self,$dzv )		= @_;
	if ( $dzv ne $empty_string ) {

		$suinvco3d->{_dzv}		= $dzv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' dzv='.$suinvco3d->{_dzv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' dzv='.$suinvco3d->{_dzv};

	} else { 
		print("suinvco3d, dzv, missing dzv,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$suinvco3d->{_fmax}		= $fmax;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fmax='.$suinvco3d->{_fmax};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fmax='.$suinvco3d->{_fmax};

	} else { 
		print("suinvco3d, fmax, missing fmax,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$suinvco3d->{_fxm}		= $fxm;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fxm='.$suinvco3d->{_fxm};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fxm='.$suinvco3d->{_fxm};

	} else { 
		print("suinvco3d, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$suinvco3d->{_fxo}		= $fxo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fxo='.$suinvco3d->{_fxo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fxo='.$suinvco3d->{_fxo};

	} else { 
		print("suinvco3d, fxo, missing fxo,\n");
	 }
 }


=head2 sub fxv 


=cut

 sub fxv {

	my ( $self,$fxv )		= @_;
	if ( $fxv ne $empty_string ) {

		$suinvco3d->{_fxv}		= $fxv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fxv='.$suinvco3d->{_fxv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fxv='.$suinvco3d->{_fxv};

	} else { 
		print("suinvco3d, fxv, missing fxv,\n");
	 }
 }


=head2 sub fym 


=cut

 sub fym {

	my ( $self,$fym )		= @_;
	if ( $fym ne $empty_string ) {

		$suinvco3d->{_fym}		= $fym;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fym='.$suinvco3d->{_fym};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fym='.$suinvco3d->{_fym};

	} else { 
		print("suinvco3d, fym, missing fym,\n");
	 }
 }


=head2 sub fyo 


=cut

 sub fyo {

	my ( $self,$fyo )		= @_;
	if ( $fyo ne $empty_string ) {

		$suinvco3d->{_fyo}		= $fyo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fyo='.$suinvco3d->{_fyo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fyo='.$suinvco3d->{_fyo};

	} else { 
		print("suinvco3d, fyo, missing fyo,\n");
	 }
 }


=head2 sub fyv 


=cut

 sub fyv {

	my ( $self,$fyv )		= @_;
	if ( $fyv ne $empty_string ) {

		$suinvco3d->{_fyv}		= $fyv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fyv='.$suinvco3d->{_fyv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fyv='.$suinvco3d->{_fyv};

	} else { 
		print("suinvco3d, fyv, missing fyv,\n");
	 }
 }


=head2 sub fzo 


=cut

 sub fzo {

	my ( $self,$fzo )		= @_;
	if ( $fzo ne $empty_string ) {

		$suinvco3d->{_fzo}		= $fzo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fzo='.$suinvco3d->{_fzo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fzo='.$suinvco3d->{_fzo};

	} else { 
		print("suinvco3d, fzo, missing fzo,\n");
	 }
 }


=head2 sub fzv 


=cut

 sub fzv {

	my ( $self,$fzv )		= @_;
	if ( $fzv ne $empty_string ) {

		$suinvco3d->{_fzv}		= $fzv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' fzv='.$suinvco3d->{_fzv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' fzv='.$suinvco3d->{_fzv};

	} else { 
		print("suinvco3d, fzv, missing fzv,\n");
	 }
 }


=head2 sub geo_type 


=cut

 sub geo_type {

	my ( $self,$geo_type )		= @_;
	if ( $geo_type ne $empty_string ) {

		$suinvco3d->{_geo_type}		= $geo_type;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' geo_type='.$suinvco3d->{_geo_type};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' geo_type='.$suinvco3d->{_geo_type};

	} else { 
		print("suinvco3d, geo_type, missing geo_type,\n");
	 }
 }


=head2 sub nxb 


=cut

 sub nxb {

	my ( $self,$nxb )		= @_;
	if ( $nxb ne $empty_string ) {

		$suinvco3d->{_nxb}		= $nxb;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nxb='.$suinvco3d->{_nxb};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nxb='.$suinvco3d->{_nxb};

	} else { 
		print("suinvco3d, nxb, missing nxb,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$suinvco3d->{_nxm}		= $nxm;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nxm='.$suinvco3d->{_nxm};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nxm='.$suinvco3d->{_nxm};

	} else { 
		print("suinvco3d, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$suinvco3d->{_nxo}		= $nxo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nxo='.$suinvco3d->{_nxo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nxo='.$suinvco3d->{_nxo};

	} else { 
		print("suinvco3d, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxt 


=cut

 sub nxt {

	my ( $self,$nxt )		= @_;
	if ( $nxt ne $empty_string ) {

		$suinvco3d->{_nxt}		= $nxt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nxt='.$suinvco3d->{_nxt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nxt='.$suinvco3d->{_nxt};

	} else { 
		print("suinvco3d, nxt, missing nxt,\n");
	 }
 }


=head2 sub nxv 


=cut

 sub nxv {

	my ( $self,$nxv )		= @_;
	if ( $nxv ne $empty_string ) {

		$suinvco3d->{_nxv}		= $nxv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nxv='.$suinvco3d->{_nxv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nxv='.$suinvco3d->{_nxv};

	} else { 
		print("suinvco3d, nxv, missing nxv,\n");
	 }
 }


=head2 sub nym 


=cut

 sub nym {

	my ( $self,$nym )		= @_;
	if ( $nym ne $empty_string ) {

		$suinvco3d->{_nym}		= $nym;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nym='.$suinvco3d->{_nym};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nym='.$suinvco3d->{_nym};

	} else { 
		print("suinvco3d, nym, missing nym,\n");
	 }
 }


=head2 sub nyo 


=cut

 sub nyo {

	my ( $self,$nyo )		= @_;
	if ( $nyo ne $empty_string ) {

		$suinvco3d->{_nyo}		= $nyo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nyo='.$suinvco3d->{_nyo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nyo='.$suinvco3d->{_nyo};

	} else { 
		print("suinvco3d, nyo, missing nyo,\n");
	 }
 }


=head2 sub nyt 


=cut

 sub nyt {

	my ( $self,$nyt )		= @_;
	if ( $nyt ne $empty_string ) {

		$suinvco3d->{_nyt}		= $nyt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nyt='.$suinvco3d->{_nyt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nyt='.$suinvco3d->{_nyt};

	} else { 
		print("suinvco3d, nyt, missing nyt,\n");
	 }
 }


=head2 sub nyv 


=cut

 sub nyv {

	my ( $self,$nyv )		= @_;
	if ( $nyv ne $empty_string ) {

		$suinvco3d->{_nyv}		= $nyv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nyv='.$suinvco3d->{_nyv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nyv='.$suinvco3d->{_nyv};

	} else { 
		print("suinvco3d, nyv, missing nyv,\n");
	 }
 }


=head2 sub nzo 


=cut

 sub nzo {

	my ( $self,$nzo )		= @_;
	if ( $nzo ne $empty_string ) {

		$suinvco3d->{_nzo}		= $nzo;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nzo='.$suinvco3d->{_nzo};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nzo='.$suinvco3d->{_nzo};

	} else { 
		print("suinvco3d, nzo, missing nzo,\n");
	 }
 }


=head2 sub nzt 


=cut

 sub nzt {

	my ( $self,$nzt )		= @_;
	if ( $nzt ne $empty_string ) {

		$suinvco3d->{_nzt}		= $nzt;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nzt='.$suinvco3d->{_nzt};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nzt='.$suinvco3d->{_nzt};

	} else { 
		print("suinvco3d, nzt, missing nzt,\n");
	 }
 }


=head2 sub nzv 


=cut

 sub nzv {

	my ( $self,$nzv )		= @_;
	if ( $nzv ne $empty_string ) {

		$suinvco3d->{_nzv}		= $nzv;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' nzv='.$suinvco3d->{_nzv};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' nzv='.$suinvco3d->{_nzv};

	} else { 
		print("suinvco3d, nzv, missing nzv,\n");
	 }
 }


=head2 sub offs 


=cut

 sub offs {

	my ( $self,$offs )		= @_;
	if ( $offs ne $empty_string ) {

		$suinvco3d->{_offs}		= $offs;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' offs='.$suinvco3d->{_offs};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' offs='.$suinvco3d->{_offs};

	} else { 
		print("suinvco3d, offs, missing offs,\n");
	 }
 }


=head2 sub tfile 


=cut

 sub tfile {

	my ( $self,$tfile )		= @_;
	if ( $tfile ne $empty_string ) {

		$suinvco3d->{_tfile}		= $tfile;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' tfile='.$suinvco3d->{_tfile};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' tfile='.$suinvco3d->{_tfile};

	} else { 
		print("suinvco3d, tfile, missing tfile,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suinvco3d->{_verbose}		= $verbose;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' verbose='.$suinvco3d->{_verbose};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' verbose='.$suinvco3d->{_verbose};

	} else { 
		print("suinvco3d, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suinvco3d->{_vfile}		= $vfile;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' vfile='.$suinvco3d->{_vfile};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' vfile='.$suinvco3d->{_vfile};

	} else { 
		print("suinvco3d, vfile, missing vfile,\n");
	 }
 }


=head2 sub weight 


=cut

 sub weight {

	my ( $self,$weight )		= @_;
	if ( $weight ne $empty_string ) {

		$suinvco3d->{_weight}		= $weight;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' weight='.$suinvco3d->{_weight};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' weight='.$suinvco3d->{_weight};

	} else { 
		print("suinvco3d, weight, missing weight,\n");
	 }
 }


=head2 sub xt0 


=cut

 sub xt0 {

	my ( $self,$xt0 )		= @_;
	if ( $xt0 ne $empty_string ) {

		$suinvco3d->{_xt0}		= $xt0;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' xt0='.$suinvco3d->{_xt0};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' xt0='.$suinvco3d->{_xt0};

	} else { 
		print("suinvco3d, xt0, missing xt0,\n");
	 }
 }


=head2 sub xt1 


=cut

 sub xt1 {

	my ( $self,$xt1 )		= @_;
	if ( $xt1 ne $empty_string ) {

		$suinvco3d->{_xt1}		= $xt1;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' xt1='.$suinvco3d->{_xt1};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' xt1='.$suinvco3d->{_xt1};

	} else { 
		print("suinvco3d, xt1, missing xt1,\n");
	 }
 }


=head2 sub yt0 


=cut

 sub yt0 {

	my ( $self,$yt0 )		= @_;
	if ( $yt0 ne $empty_string ) {

		$suinvco3d->{_yt0}		= $yt0;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' yt0='.$suinvco3d->{_yt0};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' yt0='.$suinvco3d->{_yt0};

	} else { 
		print("suinvco3d, yt0, missing yt0,\n");
	 }
 }


=head2 sub yt1 


=cut

 sub yt1 {

	my ( $self,$yt1 )		= @_;
	if ( $yt1 ne $empty_string ) {

		$suinvco3d->{_yt1}		= $yt1;
		$suinvco3d->{_note}		= $suinvco3d->{_note}.' yt1='.$suinvco3d->{_yt1};
		$suinvco3d->{_Step}		= $suinvco3d->{_Step}.' yt1='.$suinvco3d->{_yt1};

	} else { 
		print("suinvco3d, yt1, missing yt1,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 54;

    return($max_index);
}
 
 
1;
