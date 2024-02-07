package App::SeismicUnixGui::sunix::inversion::suinvzco3d;

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
 SUINVZCO3D - Seismic INVersion of Common Offset data with V(Z) velocity

             function in 3D						



     suinvzco3d <infile >outfile [optional parameters] 		



 Required Parameters:							

 vfile=                  file containing velocity array v[nz]		

 nz=                    number of z samples (1st dimension) in velocity

 nxm=			number of midpoints of input traces		

 ny=			number of lines 				



 Optional Parameters:							

 dt= or from header (dt) 	time sampling interval of input data	

 offs= or from header (offset) 	source-receiver offset	 	

 dxm= or from header (d2) 	sampling interval of midpoints 		

 fxm=0                  first midpoint in input trace			

 nxd=5			skipped number of midpoints (see note)		

 dx=50.0                x sampling interval of velocity		

 fx=0.0                 first x sample of velocity			

 dz=50.0                z sampling interval of velocity		

 nxb=nx/2		band centered at midpoints (see note)		

 fxo=0.0                x-coordinate of first output trace 		

 dxo=15.0		horizontal spacing of output trace 		

 nxo=101                number of output traces 			",	

 fyo=0.0		y-coordinate of first output trace		

 dyo=15.0		y-coordinate spacing of output trace		

 nyo=101		number of output traces in y-direction		

 fzo=0.0                z-coordinate of first point in output trace 	

 dzo=15.0               vertical spacing of output trace 		

 nzo=101                number of points in output trace		",	

 fmax=0.25/dt		Maximum frequency set for operator antialiasing 

 ang=180		Maximum dip angle allowed in the image		

 verbose=1              =1 to print some useful information		



 Notes:									



 This algorithm is based on formula (50) in Geophysics Vol. 51, 	

 1552-1558, by Cohen, J., Hagin, F., and Bleistein, N.			



 Traveltime and amplitude are calculated by ray tracing.		

 Interpolation is used to calculate traveltime and amplitude.		", 

 For each midpoint, traveltime and amplitude are calculated in the 	

 horizontal range of (xm-nxb*dx, xm+nxb*dx). Velocity is changed by 	

 linear interpolation in two upper trianglar corners whose width is 	

 nxc*dx and height is nzc*dz.						",	



 Eikonal equation will fail to solve if there is a polar turned ray.	

 In this case, the program shows the related geometric information. 	

 

 Offsets are signed - may be positive or negative. 			", 



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

my $suinvzco3d			= {
	_ang					=> '',
	_dt					=> '',
	_dx					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dyo					=> '',
	_dz					=> '',
	_dzo					=> '',
	_fmax					=> '',
	_fx					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_fyo					=> '',
	_fzo					=> '',
	_nxb					=> '',
	_nxd					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_ny					=> '',
	_nyo					=> '',
	_nz					=> '',
	_nzo					=> '',
	_offs					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suinvzco3d->{_Step}     = 'suinvzco3d'.$suinvzco3d->{_Step};
	return ( $suinvzco3d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suinvzco3d->{_note}     = 'suinvzco3d'.$suinvzco3d->{_note};
	return ( $suinvzco3d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suinvzco3d->{_ang}			= '';
		$suinvzco3d->{_dt}			= '';
		$suinvzco3d->{_dx}			= '';
		$suinvzco3d->{_dxm}			= '';
		$suinvzco3d->{_dxo}			= '';
		$suinvzco3d->{_dyo}			= '';
		$suinvzco3d->{_dz}			= '';
		$suinvzco3d->{_dzo}			= '';
		$suinvzco3d->{_fmax}			= '';
		$suinvzco3d->{_fx}			= '';
		$suinvzco3d->{_fxm}			= '';
		$suinvzco3d->{_fxo}			= '';
		$suinvzco3d->{_fyo}			= '';
		$suinvzco3d->{_fzo}			= '';
		$suinvzco3d->{_nxb}			= '';
		$suinvzco3d->{_nxd}			= '';
		$suinvzco3d->{_nxm}			= '';
		$suinvzco3d->{_nxo}			= '';
		$suinvzco3d->{_ny}			= '';
		$suinvzco3d->{_nyo}			= '';
		$suinvzco3d->{_nz}			= '';
		$suinvzco3d->{_nzo}			= '';
		$suinvzco3d->{_offs}			= '';
		$suinvzco3d->{_verbose}			= '';
		$suinvzco3d->{_vfile}			= '';
		$suinvzco3d->{_Step}			= '';
		$suinvzco3d->{_note}			= '';
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$suinvzco3d->{_ang}		= $ang;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' ang='.$suinvzco3d->{_ang};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' ang='.$suinvzco3d->{_ang};

	} else { 
		print("suinvzco3d, ang, missing ang,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suinvzco3d->{_dt}		= $dt;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dt='.$suinvzco3d->{_dt};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dt='.$suinvzco3d->{_dt};

	} else { 
		print("suinvzco3d, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suinvzco3d->{_dx}		= $dx;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dx='.$suinvzco3d->{_dx};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dx='.$suinvzco3d->{_dx};

	} else { 
		print("suinvzco3d, dx, missing dx,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$suinvzco3d->{_dxm}		= $dxm;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dxm='.$suinvzco3d->{_dxm};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dxm='.$suinvzco3d->{_dxm};

	} else { 
		print("suinvzco3d, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$suinvzco3d->{_dxo}		= $dxo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dxo='.$suinvzco3d->{_dxo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dxo='.$suinvzco3d->{_dxo};

	} else { 
		print("suinvzco3d, dxo, missing dxo,\n");
	 }
 }


=head2 sub dyo 


=cut

 sub dyo {

	my ( $self,$dyo )		= @_;
	if ( $dyo ne $empty_string ) {

		$suinvzco3d->{_dyo}		= $dyo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dyo='.$suinvzco3d->{_dyo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dyo='.$suinvzco3d->{_dyo};

	} else { 
		print("suinvzco3d, dyo, missing dyo,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$suinvzco3d->{_dz}		= $dz;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dz='.$suinvzco3d->{_dz};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dz='.$suinvzco3d->{_dz};

	} else { 
		print("suinvzco3d, dz, missing dz,\n");
	 }
 }


=head2 sub dzo 


=cut

 sub dzo {

	my ( $self,$dzo )		= @_;
	if ( $dzo ne $empty_string ) {

		$suinvzco3d->{_dzo}		= $dzo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' dzo='.$suinvzco3d->{_dzo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' dzo='.$suinvzco3d->{_dzo};

	} else { 
		print("suinvzco3d, dzo, missing dzo,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$suinvzco3d->{_fmax}		= $fmax;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fmax='.$suinvzco3d->{_fmax};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fmax='.$suinvzco3d->{_fmax};

	} else { 
		print("suinvzco3d, fmax, missing fmax,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$suinvzco3d->{_fx}		= $fx;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fx='.$suinvzco3d->{_fx};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fx='.$suinvzco3d->{_fx};

	} else { 
		print("suinvzco3d, fx, missing fx,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$suinvzco3d->{_fxm}		= $fxm;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fxm='.$suinvzco3d->{_fxm};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fxm='.$suinvzco3d->{_fxm};

	} else { 
		print("suinvzco3d, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$suinvzco3d->{_fxo}		= $fxo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fxo='.$suinvzco3d->{_fxo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fxo='.$suinvzco3d->{_fxo};

	} else { 
		print("suinvzco3d, fxo, missing fxo,\n");
	 }
 }


=head2 sub fyo 


=cut

 sub fyo {

	my ( $self,$fyo )		= @_;
	if ( $fyo ne $empty_string ) {

		$suinvzco3d->{_fyo}		= $fyo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fyo='.$suinvzco3d->{_fyo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fyo='.$suinvzco3d->{_fyo};

	} else { 
		print("suinvzco3d, fyo, missing fyo,\n");
	 }
 }


=head2 sub fzo 


=cut

 sub fzo {

	my ( $self,$fzo )		= @_;
	if ( $fzo ne $empty_string ) {

		$suinvzco3d->{_fzo}		= $fzo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' fzo='.$suinvzco3d->{_fzo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' fzo='.$suinvzco3d->{_fzo};

	} else { 
		print("suinvzco3d, fzo, missing fzo,\n");
	 }
 }


=head2 sub nxb 


=cut

 sub nxb {

	my ( $self,$nxb )		= @_;
	if ( $nxb ne $empty_string ) {

		$suinvzco3d->{_nxb}		= $nxb;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nxb='.$suinvzco3d->{_nxb};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nxb='.$suinvzco3d->{_nxb};

	} else { 
		print("suinvzco3d, nxb, missing nxb,\n");
	 }
 }


=head2 sub nxd 


=cut

 sub nxd {

	my ( $self,$nxd )		= @_;
	if ( $nxd ne $empty_string ) {

		$suinvzco3d->{_nxd}		= $nxd;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nxd='.$suinvzco3d->{_nxd};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nxd='.$suinvzco3d->{_nxd};

	} else { 
		print("suinvzco3d, nxd, missing nxd,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$suinvzco3d->{_nxm}		= $nxm;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nxm='.$suinvzco3d->{_nxm};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nxm='.$suinvzco3d->{_nxm};

	} else { 
		print("suinvzco3d, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$suinvzco3d->{_nxo}		= $nxo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nxo='.$suinvzco3d->{_nxo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nxo='.$suinvzco3d->{_nxo};

	} else { 
		print("suinvzco3d, nxo, missing nxo,\n");
	 }
 }


=head2 sub ny 


=cut

 sub ny {

	my ( $self,$ny )		= @_;
	if ( $ny ne $empty_string ) {

		$suinvzco3d->{_ny}		= $ny;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' ny='.$suinvzco3d->{_ny};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' ny='.$suinvzco3d->{_ny};

	} else { 
		print("suinvzco3d, ny, missing ny,\n");
	 }
 }


=head2 sub nyo 


=cut

 sub nyo {

	my ( $self,$nyo )		= @_;
	if ( $nyo ne $empty_string ) {

		$suinvzco3d->{_nyo}		= $nyo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nyo='.$suinvzco3d->{_nyo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nyo='.$suinvzco3d->{_nyo};

	} else { 
		print("suinvzco3d, nyo, missing nyo,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$suinvzco3d->{_nz}		= $nz;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nz='.$suinvzco3d->{_nz};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nz='.$suinvzco3d->{_nz};

	} else { 
		print("suinvzco3d, nz, missing nz,\n");
	 }
 }


=head2 sub nzo 


=cut

 sub nzo {

	my ( $self,$nzo )		= @_;
	if ( $nzo ne $empty_string ) {

		$suinvzco3d->{_nzo}		= $nzo;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' nzo='.$suinvzco3d->{_nzo};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' nzo='.$suinvzco3d->{_nzo};

	} else { 
		print("suinvzco3d, nzo, missing nzo,\n");
	 }
 }


=head2 sub offs 


=cut

 sub offs {

	my ( $self,$offs )		= @_;
	if ( $offs ne $empty_string ) {

		$suinvzco3d->{_offs}		= $offs;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' offs='.$suinvzco3d->{_offs};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' offs='.$suinvzco3d->{_offs};

	} else { 
		print("suinvzco3d, offs, missing offs,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suinvzco3d->{_verbose}		= $verbose;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' verbose='.$suinvzco3d->{_verbose};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' verbose='.$suinvzco3d->{_verbose};

	} else { 
		print("suinvzco3d, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suinvzco3d->{_vfile}		= $vfile;
		$suinvzco3d->{_note}		= $suinvzco3d->{_note}.' vfile='.$suinvzco3d->{_vfile};
		$suinvzco3d->{_Step}		= $suinvzco3d->{_Step}.' vfile='.$suinvzco3d->{_vfile};

	} else { 
		print("suinvzco3d, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 24;

    return($max_index);
}
 
 
1;
