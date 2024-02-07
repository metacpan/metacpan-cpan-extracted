package App::SeismicUnixGui::sunix::inversion::suinvvxzco;

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
 SUINVVXZCO - Seismic INVersion of Common Offset data for a smooth 	

             velocity function V(X,Z) plus a slowness perturbation vp(x,z)



     suinvvxzco <infile >outfile [optional parameters] 		



 Required Parameters:							

 vfile=                  file containing velocity array v[nx][nz]	

 nx=                    number of x samples (2nd dimension) in velocity

 nz=                    number of z samples (1st dimension) in velocity

 nxm=			number of midpoints of input traces		



 Optional Parameters:							

 dt= or from header (dt) 	time sampling interval of input data	

 offs= or from header (offset) 	source-receiver offset	 	

 dxm= or from header (d2) 	sampling interval of midpoints 		

 fxm=0		first midpoint in input trace				

 nxd=5		skipped number of midpoints (see note)			

 dx=50.0	x sampling interval of velocity				

 fx=0.0	first x sample of velocity				

 dz=50.0	z sampling interval of velocity				

 nxb=nx/2	band centered at midpoints (see note)			

 nxc=0		hozizontal range in which velocity is changed		

 nzc=0		vertical range in which velocity is changed		

 fxo=0.0	x-coordinate of first output trace 			

 dxo=15.0	horizontal spacing of output trace 			

 nxo=101	number of output traces 				",	

 fzo=0.0	z-coordinate of first point in output trace 		

 dzo=15.0	vertical spacing of output trace 			

 nzo=101	number of points in output trace			",	

 fmax=0.25/dt	Maximum frequency set for operator antialiasing		

 ang=180	Maximum dip angle allowed in the image			

 ls=0		=1 for line source; =0 for point source			

 pert=0	=1 calculate time correction from v_p[nx][nz]		

 vpfile=file containing slowness perturbation array v_p[nx][nz]	

 verbose=1              =1 to print some useful information		



 Notes:								

 Traveltime and amplitude are calculated by finite difference which	

 is done only in one of every NXD midpoints; in the skipped midpoint, 	

 interpolation is used to calculate traveltime and amplitude.		", 

 For each midpoint, traveltime and amplitude are calculated in the 	

 horizontal range of (xm-nxb*dx, xm+nxb*dx). Velocity is changed by 	

 constant extropolation in two upper trianglar corners whose width is 	

 nxc*dx and height is nzc*dz.						



 Eikonal equation will fail to solve if there is a polar turned ray.	

 In this case, the program shows the related geometric information. 	

 There are three ways to remove the turned ray: smoothing velocity, 	

 reducing nxb, and increaing nxc and nzc (if the turned ray occurs  	

 in the shallow areas). To prevent traveltime distortion from a over	

 smoothed velocity, traveltime is corrected based on the slowness 	

 perturbation.								



 Offsets are signed - may be positive or negative. 			









 Author:  Zhenyue Liu, 08/28/93,  Colorado School of Mines 



 Reference:

 Bleistein, N., Cohen, J. K., and Hagin, F., 1987,

  Two-and-one-half dimensional Born inversion with an arbitrary reference

         Geophysics Vol. 52, no.1, 26-36.





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

my $suinvvxzco			= {
	_ang					=> '',
	_dt					=> '',
	_dx					=> '',
	_dxm					=> '',
	_dxo					=> '',
	_dz					=> '',
	_dzo					=> '',
	_fmax					=> '',
	_fx					=> '',
	_fxm					=> '',
	_fxo					=> '',
	_fzo					=> '',
	_ls					=> '',
	_nx					=> '',
	_nxb					=> '',
	_nxc					=> '',
	_nxd					=> '',
	_nxm					=> '',
	_nxo					=> '',
	_nz					=> '',
	_nzc					=> '',
	_nzo					=> '',
	_offs					=> '',
	_pert					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_vpfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suinvvxzco->{_Step}     = 'suinvvxzco'.$suinvvxzco->{_Step};
	return ( $suinvvxzco->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suinvvxzco->{_note}     = 'suinvvxzco'.$suinvvxzco->{_note};
	return ( $suinvvxzco->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suinvvxzco->{_ang}			= '';
		$suinvvxzco->{_dt}			= '';
		$suinvvxzco->{_dx}			= '';
		$suinvvxzco->{_dxm}			= '';
		$suinvvxzco->{_dxo}			= '';
		$suinvvxzco->{_dz}			= '';
		$suinvvxzco->{_dzo}			= '';
		$suinvvxzco->{_fmax}			= '';
		$suinvvxzco->{_fx}			= '';
		$suinvvxzco->{_fxm}			= '';
		$suinvvxzco->{_fxo}			= '';
		$suinvvxzco->{_fzo}			= '';
		$suinvvxzco->{_ls}			= '';
		$suinvvxzco->{_nx}			= '';
		$suinvvxzco->{_nxb}			= '';
		$suinvvxzco->{_nxc}			= '';
		$suinvvxzco->{_nxd}			= '';
		$suinvvxzco->{_nxm}			= '';
		$suinvvxzco->{_nxo}			= '';
		$suinvvxzco->{_nz}			= '';
		$suinvvxzco->{_nzc}			= '';
		$suinvvxzco->{_nzo}			= '';
		$suinvvxzco->{_offs}			= '';
		$suinvvxzco->{_pert}			= '';
		$suinvvxzco->{_verbose}			= '';
		$suinvvxzco->{_vfile}			= '';
		$suinvvxzco->{_vpfile}			= '';
		$suinvvxzco->{_Step}			= '';
		$suinvvxzco->{_note}			= '';
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$suinvvxzco->{_ang}		= $ang;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' ang='.$suinvvxzco->{_ang};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' ang='.$suinvvxzco->{_ang};

	} else { 
		print("suinvvxzco, ang, missing ang,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suinvvxzco->{_dt}		= $dt;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dt='.$suinvvxzco->{_dt};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dt='.$suinvvxzco->{_dt};

	} else { 
		print("suinvvxzco, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suinvvxzco->{_dx}		= $dx;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dx='.$suinvvxzco->{_dx};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dx='.$suinvvxzco->{_dx};

	} else { 
		print("suinvvxzco, dx, missing dx,\n");
	 }
 }


=head2 sub dxm 


=cut

 sub dxm {

	my ( $self,$dxm )		= @_;
	if ( $dxm ne $empty_string ) {

		$suinvvxzco->{_dxm}		= $dxm;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dxm='.$suinvvxzco->{_dxm};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dxm='.$suinvvxzco->{_dxm};

	} else { 
		print("suinvvxzco, dxm, missing dxm,\n");
	 }
 }


=head2 sub dxo 


=cut

 sub dxo {

	my ( $self,$dxo )		= @_;
	if ( $dxo ne $empty_string ) {

		$suinvvxzco->{_dxo}		= $dxo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dxo='.$suinvvxzco->{_dxo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dxo='.$suinvvxzco->{_dxo};

	} else { 
		print("suinvvxzco, dxo, missing dxo,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$suinvvxzco->{_dz}		= $dz;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dz='.$suinvvxzco->{_dz};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dz='.$suinvvxzco->{_dz};

	} else { 
		print("suinvvxzco, dz, missing dz,\n");
	 }
 }


=head2 sub dzo 


=cut

 sub dzo {

	my ( $self,$dzo )		= @_;
	if ( $dzo ne $empty_string ) {

		$suinvvxzco->{_dzo}		= $dzo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' dzo='.$suinvvxzco->{_dzo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' dzo='.$suinvvxzco->{_dzo};

	} else { 
		print("suinvvxzco, dzo, missing dzo,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$suinvvxzco->{_fmax}		= $fmax;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' fmax='.$suinvvxzco->{_fmax};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' fmax='.$suinvvxzco->{_fmax};

	} else { 
		print("suinvvxzco, fmax, missing fmax,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$suinvvxzco->{_fx}		= $fx;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' fx='.$suinvvxzco->{_fx};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' fx='.$suinvvxzco->{_fx};

	} else { 
		print("suinvvxzco, fx, missing fx,\n");
	 }
 }


=head2 sub fxm 


=cut

 sub fxm {

	my ( $self,$fxm )		= @_;
	if ( $fxm ne $empty_string ) {

		$suinvvxzco->{_fxm}		= $fxm;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' fxm='.$suinvvxzco->{_fxm};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' fxm='.$suinvvxzco->{_fxm};

	} else { 
		print("suinvvxzco, fxm, missing fxm,\n");
	 }
 }


=head2 sub fxo 


=cut

 sub fxo {

	my ( $self,$fxo )		= @_;
	if ( $fxo ne $empty_string ) {

		$suinvvxzco->{_fxo}		= $fxo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' fxo='.$suinvvxzco->{_fxo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' fxo='.$suinvvxzco->{_fxo};

	} else { 
		print("suinvvxzco, fxo, missing fxo,\n");
	 }
 }


=head2 sub fzo 


=cut

 sub fzo {

	my ( $self,$fzo )		= @_;
	if ( $fzo ne $empty_string ) {

		$suinvvxzco->{_fzo}		= $fzo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' fzo='.$suinvvxzco->{_fzo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' fzo='.$suinvvxzco->{_fzo};

	} else { 
		print("suinvvxzco, fzo, missing fzo,\n");
	 }
 }


=head2 sub ls 


=cut

 sub ls {

	my ( $self,$ls )		= @_;
	if ( $ls ne $empty_string ) {

		$suinvvxzco->{_ls}		= $ls;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' ls='.$suinvvxzco->{_ls};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' ls='.$suinvvxzco->{_ls};

	} else { 
		print("suinvvxzco, ls, missing ls,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$suinvvxzco->{_nx}		= $nx;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nx='.$suinvvxzco->{_nx};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nx='.$suinvvxzco->{_nx};

	} else { 
		print("suinvvxzco, nx, missing nx,\n");
	 }
 }


=head2 sub nxb 


=cut

 sub nxb {

	my ( $self,$nxb )		= @_;
	if ( $nxb ne $empty_string ) {

		$suinvvxzco->{_nxb}		= $nxb;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nxb='.$suinvvxzco->{_nxb};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nxb='.$suinvvxzco->{_nxb};

	} else { 
		print("suinvvxzco, nxb, missing nxb,\n");
	 }
 }


=head2 sub nxc 


=cut

 sub nxc {

	my ( $self,$nxc )		= @_;
	if ( $nxc ne $empty_string ) {

		$suinvvxzco->{_nxc}		= $nxc;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nxc='.$suinvvxzco->{_nxc};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nxc='.$suinvvxzco->{_nxc};

	} else { 
		print("suinvvxzco, nxc, missing nxc,\n");
	 }
 }


=head2 sub nxd 


=cut

 sub nxd {

	my ( $self,$nxd )		= @_;
	if ( $nxd ne $empty_string ) {

		$suinvvxzco->{_nxd}		= $nxd;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nxd='.$suinvvxzco->{_nxd};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nxd='.$suinvvxzco->{_nxd};

	} else { 
		print("suinvvxzco, nxd, missing nxd,\n");
	 }
 }


=head2 sub nxm 


=cut

 sub nxm {

	my ( $self,$nxm )		= @_;
	if ( $nxm ne $empty_string ) {

		$suinvvxzco->{_nxm}		= $nxm;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nxm='.$suinvvxzco->{_nxm};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nxm='.$suinvvxzco->{_nxm};

	} else { 
		print("suinvvxzco, nxm, missing nxm,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$suinvvxzco->{_nxo}		= $nxo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nxo='.$suinvvxzco->{_nxo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nxo='.$suinvvxzco->{_nxo};

	} else { 
		print("suinvvxzco, nxo, missing nxo,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$suinvvxzco->{_nz}		= $nz;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nz='.$suinvvxzco->{_nz};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nz='.$suinvvxzco->{_nz};

	} else { 
		print("suinvvxzco, nz, missing nz,\n");
	 }
 }


=head2 sub nzc 


=cut

 sub nzc {

	my ( $self,$nzc )		= @_;
	if ( $nzc ne $empty_string ) {

		$suinvvxzco->{_nzc}		= $nzc;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nzc='.$suinvvxzco->{_nzc};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nzc='.$suinvvxzco->{_nzc};

	} else { 
		print("suinvvxzco, nzc, missing nzc,\n");
	 }
 }


=head2 sub nzo 


=cut

 sub nzo {

	my ( $self,$nzo )		= @_;
	if ( $nzo ne $empty_string ) {

		$suinvvxzco->{_nzo}		= $nzo;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' nzo='.$suinvvxzco->{_nzo};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' nzo='.$suinvvxzco->{_nzo};

	} else { 
		print("suinvvxzco, nzo, missing nzo,\n");
	 }
 }


=head2 sub offs 


=cut

 sub offs {

	my ( $self,$offs )		= @_;
	if ( $offs ne $empty_string ) {

		$suinvvxzco->{_offs}		= $offs;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' offs='.$suinvvxzco->{_offs};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' offs='.$suinvvxzco->{_offs};

	} else { 
		print("suinvvxzco, offs, missing offs,\n");
	 }
 }


=head2 sub pert 


=cut

 sub pert {

	my ( $self,$pert )		= @_;
	if ( $pert ne $empty_string ) {

		$suinvvxzco->{_pert}		= $pert;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' pert='.$suinvvxzco->{_pert};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' pert='.$suinvvxzco->{_pert};

	} else { 
		print("suinvvxzco, pert, missing pert,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suinvvxzco->{_verbose}		= $verbose;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' verbose='.$suinvvxzco->{_verbose};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' verbose='.$suinvvxzco->{_verbose};

	} else { 
		print("suinvvxzco, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suinvvxzco->{_vfile}		= $vfile;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' vfile='.$suinvvxzco->{_vfile};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' vfile='.$suinvvxzco->{_vfile};

	} else { 
		print("suinvvxzco, vfile, missing vfile,\n");
	 }
 }


=head2 sub vpfile 


=cut

 sub vpfile {

	my ( $self,$vpfile )		= @_;
	if ( $vpfile ne $empty_string ) {

		$suinvvxzco->{_vpfile}		= $vpfile;
		$suinvvxzco->{_note}		= $suinvvxzco->{_note}.' vpfile='.$suinvvxzco->{_vpfile};
		$suinvvxzco->{_Step}		= $suinvvxzco->{_Step}.' vpfile='.$suinvvxzco->{_vpfile};

	} else { 
		print("suinvvxzco, vpfile, missing vpfile,\n");
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
