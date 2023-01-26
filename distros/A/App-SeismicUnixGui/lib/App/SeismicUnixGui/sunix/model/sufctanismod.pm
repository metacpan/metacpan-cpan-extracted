package App::SeismicUnixGui::sunix::model::sufctanismod;

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
 SUFCTANISMOD - Flux-Corrected Transport correction applied to the 2D

	  elastic wave equation for finite difference modeling in 	

	  anisotropic media						



 sufctanismod > outfile [optional parameters]				

		outfile is the final wavefield snapshot x-component	

		x-component of wavefield snapshot is in snapshotx.data	

		y-component of wavefield snapshot is in snapshoty.data	

		z-component of wavefield snapshot is in snapshotz.data	



 Optional Output Files:						

 reflxfile=	reflection seismogram file name for x-component		

		no output produced if no name specified	 		

 reflyfile=	reflection seismogram file name for y-component		

		no output produced if no name specified	 		

 reflzfile=	reflection seismogram file name for z-component		

		no output produced if no name specified	 		

 vspxfile=	VSP seismogram file name for x-component		

		no output produced if no name specified	 		

 vspyfile=	VSP seismogram file name for y-component		

		no output produced if no name specified	 		

 vspzfile=	VSP seismogram file name for z-component		

		no output produced if no name specified	 		



 suhead=1      To get SU-header output seismograms (else suhead=0)	



 New parameter:							

     

 Optional Parameters:							

 mt=1          number of time steps per output snapshot  		

 dofct=1 	1 do the FCT correction					

		0 do not do the FCT correction 				

 FCT Related parameters:						

 eta0=0.03	diffusion coefficient					

		typical values ranging from 0.008 to 0.06		

		about 0.03 for the second-order method 			

		about 0.012 for the fourth-order method 		

 eta=0.04	anti-diffusion coefficient 				

		typical values ranging from 0.008 to 0.06		

		about 0.04 for the second-order method  		

		about 0.015 for the fourth-order method 		

 fctxbeg=0 	x coordinate to begin applying the FCT correction	

 fctzbeg=0 	z coordinate to begin applying the FCT correction	

 fctxend=nx 	x coordinate to stop applying the FCT correction	

 fctzend=nz 	z coordinate to stop applying the FCT correction	



 deta0dx=0.0	gradient of eta0 in x-direction  d(eta0)/dx		

 deta0dz=0.0	gradient of eta0 in z-direction  d(eta0)/dz		

 detadx=0.0	gradient of eta in x-direction 	 d(eta)/dx		

 detadz=0.0	gradient of eta in z-direction 	 d(eta)/dz		



 General Parameters:							

 order=2	2 second-order finite-difference 			

		4 fourth-order finite-difference 			



 nt=200        number of time steps 			 		

 dt=0.004	time step  						



 nx=100 	number of grid points in x-direction 			

 nz=100 	number of grid points in z-direction 			



 dx=0.02	spatial step in x-direction 				

 dz=0.02	spatial step in z-direction 				



 sx=nx/2	source x-coordinate (in gridpoints)			

 sz=nz/2	source z-coordinate (in gridpoints)			



 fpeak=20	peak frequency of the wavelet 				



 receiverdepth=sz  depth of horizontal receivers (in gridpoints)      

 vspnx=sx			x grid loc of vsp				



 verbose=0     silent operation							

				=1 for diagnostic messages, =2 for more		



 wavelet=1	1 AKB wavelet						

 		2 Ricker wavelet 					

		3 impulse 						

		4 unity 						



 isurf=2	1 absorbing surface condition 				

		2 free surface condition 				

		3 zero surface condition 				



 source=1	1 point source 						

 		2 sources are located on a given refelector 	        ", 

			(two horizontal and one dipping reflectors) 	

 		3 sources are located on a given dipping refelector     ", 



 sfile= 	the name of input source file, if no name specified then

		use default source location. (source=1 or 2) 		



 Density and Elastic Parameters:					

 dfile= 	the name of input density file,                         

               if no name specified then                             

		assume a linear density profile with ...		

 rho00=2.0	density at (0, 0) 					

 drhodx=0.0	density gradient in x-direction  d(rho)/dx		

 drhodz=0.0	density gradient in z-direction  d(rho)/dz		



 afile= 	name of input elastic param.  (c11) aa file, if no name 

		specified then, assume a linear profile with ...	

 aa00=2.0	elastic parameter at (0, 0) 				

 daadx=0.0	parameter gradient in x-direction  d(aa)/dx		

 daadz=0.0	parameter gradient in z-direction  d(aa)/dz		



 cfile= 	name of input elastic param. (c33)  cc file, if no name 

		specified then, assume a linear profile with ...	

 cc00=2.0	elastic parameter at (0, 0) 				

 dccdx=0.0	parameter gradient in x-direction  d(cc)/dx		

 dccdz=0.0	parameter gradient in z-direction  d(cc)/dz		



 ffile= 	name of input elastic param.  (c13) ff file, if no name 

		specified then, assume a linear profile with ...	

 ff00=2.0	elastic parameter at (0, 0) 				

 dffdx=0.0	parameter gradient in x-direction  d(ff)/dx		

 dffdz=0.0	parameter gradient in z-direction  d(ff)/dz		



 lfile= 	name of input elastic param.  (c44) ll file, if no name 

		specified then, assume a linear profile with ...	

 ll00=2.0	elastic parameter at (0, 0) 				

 dlldx=0.0	parameter gradient in x-direction  d(ll)/dx		

 dlldz=0.0	parameter gradient in z-direction  d(ll)/dz		



 nfile= 	name of input elastic param. (c66)  nn file, if no name 

		specified then, assume a linear profile with ...	

 nn00=2.0	elastic parameter at (0, 0) 				

 dnndx=0.0	parameter gradient in x-direction  d(nn)/dx		

 dnndz=0.0	parameter gradient in z-direction  d(nn)/dz		



 Optimizations:							

 The moving boundary option permits the user to restrict the computations

 of the wavefield to be confined to a specific range of spatial coordinates.

 The boundary of this restricted area moves with the wavefield		

 movebc=0	0 do not use moving boundary optimization		

		1 use moving boundaries					







 Author: Tong Fei,	Center for Wave Phenomena, 

		Colorado School of Mines, Dec 1993

 Some additional features by: Stig-Kyrre Foss, CWP

		Colorado School of Mines, Oct 2001

 New features (Oct 2001): 

 - setting receiver depth

 - outputfiles with SU-headers

 - additional commentary

 Modifications (Mar 2010) Chris Liner, U Houston

 - added snapshot mt param to parallel sufdmod2d functionality

 - added verbose and some basic info echos

 - error check that source loc is in grid

 - dropped mbx1 etc from selfdoc (they were internally computed)

 - moved default receiver depth to source depth

 - added vspnx to selfdoc and moved default vspnx to source x

 - changed sy in selfdoc to sz (typo)

 - fixed bug in vsp file(s) allocation: was [nt,nx] now is [nt,nz]





 

Notes:

	This program performs seismic modeling for elastic anisotropic 

	media with vertical axis of symmetry.  

	The finite-difference method with the FCT correction is used.



	Stability condition:	vmax*dt /(sqrt(2)*min(dx,dz)) < 1

	

	Two major stages are used in the algorithm:

	(1) conventional finite-difference wave extrapolation

	(2) followed by an FCT correction 

	

	Additional notes:

	

	The demos also use the following parameters

   Using moving boundaries



	mbx1=10

	mbx2=900

	mbz1=10

	mbz2=90

	

	Source information (index.direction of source)

    indexux=0 

    indexuy=0 

    indexuz=1 

	indexdt =0 speeds up the operation

	

	time=0.25

	

	impulse is 1 is a single source

	impulse=1



References:

	The detailed algorithm description is given in the article

	"Elimination of dispersion in finite-difference modeling 

	and migration"	in CWP-137, project review, page 155-174.



	Original reference to the FCT method:

	Boris, J., and Book, D., 1973, Flux-corrected transport. I.

	SHASTA, a fluid transport algorithm that works: 

	Journal of Computational Physics, vol. 11, p. 38-69.

=head2 User's notes

dx	

Use dx to convert gridpoints to distances:
	
e.g. ,dx=3 nx =100
	
The maximim lateral reach of the model is 300 units ( i.e., m or ft)


nx

Changes the lateral reach of the model (in gridpoints)


nt

If nt is large enough, the seismograms will more clearly include later reflections 
	

from the vertical edges of the model

Possible sources of error: Inconsistent value of variables betwen flows:
e.g.,
 nx =100 in ALL the files
 
 suhead
 
 If you want to manipulate the seismograms using Seismic Unix modules,
 remember to set suhead=1



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

my $sufctanismod			= {
	_aa00					=> '',
	_afile					=> '',
	_cc00					=> '',
	_cfile					=> '',
	_daadx					=> '',
	_daadz					=> '',
	_dccdx					=> '',
	_dccdz					=> '',
	_deta0dx					=> '',
	_deta0dz					=> '',
	_detadx					=> '',
	_detadz					=> '',
	_dffdx					=> '',
	_dffdz					=> '',
	_dfile					=> '',
	_dlldx					=> '',
	_dlldz					=> '',
	_dnndx					=> '',
	_dnndz					=> '',
	_dofct					=> '',
	_drhodx					=> '',
	_drhodz					=> '',
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_eta					=> '',
	_eta0					=> '',
	_fctxbeg					=> '',
	_fctxend					=> '',
	_fctzbeg					=> '',
	_fctzend					=> '',
	_ff00					=> '',
	_ffile					=> '',
	_fpeak					=> '',
	_impulse					=> '',
	_indexdt					=> '',
	_indexux					=> '',
	_indexuy					=> '',
	_indexuz					=> '',
	_isurf					=> '',
	_lfile					=> '',
	_ll00					=> '',
	_mbx1					=> '',
	_mbx2					=> '',
	_mbz1					=> '',
	_mbz2					=> '',
	_movebc					=> '',
	_mt					=> '',
	_nfile					=> '',
	_nn00					=> '',
	_nt					=> '',
	_nx					=> '',
	_nz					=> '',
	_order					=> '',
	_receiverdepth					=> '',
	_reflxfile					=> '',
	_reflyfile					=> '',
	_reflzfile					=> '',
	_rho00					=> '',
	_sfile					=> '',
	_source					=> '',
	_suhead					=> '',
	_sx					=> '',
	_sz					=> '',
	_time					=> '',
	_verbose					=> '',
	_vspnx					=> '',
	_vspxfile					=> '',
	_vspyfile					=> '',
	_vspzfile					=> '',
	_wavelet					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sufctanismod->{_Step}     = 'sufctanismod'.$sufctanismod->{_Step};
	return ( $sufctanismod->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufctanismod->{_note}     = 'sufctanismod'.$sufctanismod->{_note};
	return ( $sufctanismod->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufctanismod->{_aa00}			= '';
		$sufctanismod->{_afile}			= '';
		$sufctanismod->{_cc00}			= '';
		$sufctanismod->{_cfile}			= '';
		$sufctanismod->{_daadx}			= '';
		$sufctanismod->{_daadz}			= '';
		$sufctanismod->{_dccdx}			= '';
		$sufctanismod->{_dccdz}			= '';
		$sufctanismod->{_deta0dx}			= '';
		$sufctanismod->{_deta0dz}			= '';
		$sufctanismod->{_detadx}			= '';
		$sufctanismod->{_detadz}			= '';
		$sufctanismod->{_dffdx}			= '';
		$sufctanismod->{_dffdz}			= '';
		$sufctanismod->{_dfile}			= '';
		$sufctanismod->{_dlldx}			= '';
		$sufctanismod->{_dlldz}			= '';
		$sufctanismod->{_dnndx}			= '';
		$sufctanismod->{_dnndz}			= '';
		$sufctanismod->{_dofct}			= '';
		$sufctanismod->{_drhodx}			= '';
		$sufctanismod->{_drhodz}			= '';
		$sufctanismod->{_dt}			= '';
		$sufctanismod->{_dx}			= '';
		$sufctanismod->{_dz}			= '';
		$sufctanismod->{_eta}			= '';
		$sufctanismod->{_eta0}			= '';
		$sufctanismod->{_fctxbeg}			= '';
		$sufctanismod->{_fctxend}			= '';
		$sufctanismod->{_fctzbeg}			= '';
		$sufctanismod->{_fctzend}			= '';
		$sufctanismod->{_ff00}			= '';
		$sufctanismod->{_ffile}			= '';
		$sufctanismod->{_fpeak}			= '';
		$sufctanismod->{_impulse}			= '';
		$sufctanismod->{_indexdt}			= '';
		$sufctanismod->{_indexux}			= '';
		$sufctanismod->{_indexuy}			= '';
		$sufctanismod->{_indexuz}			= '';
		$sufctanismod->{_isurf}			= '';
		$sufctanismod->{_lfile}			= '';
		$sufctanismod->{_ll00}			= '';
		$sufctanismod->{_mbx1}			= '';
		$sufctanismod->{_mbx2}			= '';
		$sufctanismod->{_mbz1}			= '';
		$sufctanismod->{_mbz2}			= '';
		$sufctanismod->{_movebc}			= '';
		$sufctanismod->{_mt}			= '';
		$sufctanismod->{_nfile}			= '';
		$sufctanismod->{_nn00}			= '';
		$sufctanismod->{_nt}			= '';
		$sufctanismod->{_nx}			= '';
		$sufctanismod->{_nz}			= '';
		$sufctanismod->{_order}			= '';
		$sufctanismod->{_receiverdepth}			= '';
		$sufctanismod->{_reflxfile}			= '';
		$sufctanismod->{_reflyfile}			= '';
		$sufctanismod->{_reflzfile}			= '';
		$sufctanismod->{_rho00}			= '';
		$sufctanismod->{_sfile}			= '';
		$sufctanismod->{_source}			= '';
		$sufctanismod->{_suhead}			= '';
		$sufctanismod->{_sx}			= '';
		$sufctanismod->{_sz}			= '';
		$sufctanismod->{_time}			= '';
		$sufctanismod->{_verbose}			= '';
		$sufctanismod->{_vspnx}			= '';
		$sufctanismod->{_vspxfile}			= '';
		$sufctanismod->{_vspyfile}			= '';
		$sufctanismod->{_vspzfile}			= '';
		$sufctanismod->{_wavelet}			= '';
		$sufctanismod->{_Step}			= '';
		$sufctanismod->{_note}			= '';
 }


=head2 sub aa00 


=cut

 sub aa00 {

	my ( $self,$aa00 )		= @_;
	if ( $aa00 ne $empty_string ) {

		$sufctanismod->{_aa00}		= $aa00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' aa00='.$sufctanismod->{_aa00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' aa00='.$sufctanismod->{_aa00};

	} else { 
		print("sufctanismod, aa00, missing aa00,\n");
	 }
 }


=head2 sub afile 


=cut

 sub afile {

	my ( $self,$afile )		= @_;
	if ( $afile ne $empty_string ) {

		$sufctanismod->{_afile}		= $afile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' afile='.$sufctanismod->{_afile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' afile='.$sufctanismod->{_afile};

	} else { 
		print("sufctanismod, afile, missing afile,\n");
	 }
 }


=head2 sub cc00 


=cut

 sub cc00 {

	my ( $self,$cc00 )		= @_;
	if ( $cc00 ne $empty_string ) {

		$sufctanismod->{_cc00}		= $cc00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' cc00='.$sufctanismod->{_cc00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' cc00='.$sufctanismod->{_cc00};

	} else { 
		print("sufctanismod, cc00, missing cc00,\n");
	 }
 }


=head2 sub cfile 


=cut

 sub cfile {

	my ( $self,$cfile )		= @_;
	if ( $cfile ne $empty_string ) {

		$sufctanismod->{_cfile}		= $cfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' cfile='.$sufctanismod->{_cfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' cfile='.$sufctanismod->{_cfile};

	} else { 
		print("sufctanismod, cfile, missing cfile,\n");
	 }
 }


=head2 sub daadx 


=cut

 sub daadx {

	my ( $self,$daadx )		= @_;
	if ( $daadx ne $empty_string ) {

		$sufctanismod->{_daadx}		= $daadx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' daadx='.$sufctanismod->{_daadx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' daadx='.$sufctanismod->{_daadx};

	} else { 
		print("sufctanismod, daadx, missing daadx,\n");
	 }
 }


=head2 sub daadz 


=cut

 sub daadz {

	my ( $self,$daadz )		= @_;
	if ( $daadz ne $empty_string ) {

		$sufctanismod->{_daadz}		= $daadz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' daadz='.$sufctanismod->{_daadz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' daadz='.$sufctanismod->{_daadz};

	} else { 
		print("sufctanismod, daadz, missing daadz,\n");
	 }
 }


=head2 sub dccdx 


=cut

 sub dccdx {

	my ( $self,$dccdx )		= @_;
	if ( $dccdx ne $empty_string ) {

		$sufctanismod->{_dccdx}		= $dccdx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dccdx='.$sufctanismod->{_dccdx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dccdx='.$sufctanismod->{_dccdx};

	} else { 
		print("sufctanismod, dccdx, missing dccdx,\n");
	 }
 }


=head2 sub dccdz 


=cut

 sub dccdz {

	my ( $self,$dccdz )		= @_;
	if ( $dccdz ne $empty_string ) {

		$sufctanismod->{_dccdz}		= $dccdz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dccdz='.$sufctanismod->{_dccdz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dccdz='.$sufctanismod->{_dccdz};

	} else { 
		print("sufctanismod, dccdz, missing dccdz,\n");
	 }
 }


=head2 sub deta0dx 


=cut

 sub deta0dx {

	my ( $self,$deta0dx )		= @_;
	if ( $deta0dx ne $empty_string ) {

		$sufctanismod->{_deta0dx}		= $deta0dx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' deta0dx='.$sufctanismod->{_deta0dx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' deta0dx='.$sufctanismod->{_deta0dx};

	} else { 
		print("sufctanismod, deta0dx, missing deta0dx,\n");
	 }
 }


=head2 sub deta0dz 


=cut

 sub deta0dz {

	my ( $self,$deta0dz )		= @_;
	if ( $deta0dz ne $empty_string ) {

		$sufctanismod->{_deta0dz}		= $deta0dz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' deta0dz='.$sufctanismod->{_deta0dz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' deta0dz='.$sufctanismod->{_deta0dz};

	} else { 
		print("sufctanismod, deta0dz, missing deta0dz,\n");
	 }
 }


=head2 sub detadx 


=cut

 sub detadx {

	my ( $self,$detadx )		= @_;
	if ( $detadx ne $empty_string ) {

		$sufctanismod->{_detadx}		= $detadx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' detadx='.$sufctanismod->{_detadx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' detadx='.$sufctanismod->{_detadx};

	} else { 
		print("sufctanismod, detadx, missing detadx,\n");
	 }
 }


=head2 sub detadz 


=cut

 sub detadz {

	my ( $self,$detadz )		= @_;
	if ( $detadz ne $empty_string ) {

		$sufctanismod->{_detadz}		= $detadz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' detadz='.$sufctanismod->{_detadz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' detadz='.$sufctanismod->{_detadz};

	} else { 
		print("sufctanismod, detadz, missing detadz,\n");
	 }
 }


=head2 sub dffdx 


=cut

 sub dffdx {

	my ( $self,$dffdx )		= @_;
	if ( $dffdx ne $empty_string ) {

		$sufctanismod->{_dffdx}		= $dffdx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dffdx='.$sufctanismod->{_dffdx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dffdx='.$sufctanismod->{_dffdx};

	} else { 
		print("sufctanismod, dffdx, missing dffdx,\n");
	 }
 }


=head2 sub dffdz 


=cut

 sub dffdz {

	my ( $self,$dffdz )		= @_;
	if ( $dffdz ne $empty_string ) {

		$sufctanismod->{_dffdz}		= $dffdz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dffdz='.$sufctanismod->{_dffdz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dffdz='.$sufctanismod->{_dffdz};

	} else { 
		print("sufctanismod, dffdz, missing dffdz,\n");
	 }
 }


=head2 sub dfile 


=cut

 sub dfile {

	my ( $self,$dfile )		= @_;
	if ( $dfile ne $empty_string ) {

		$sufctanismod->{_dfile}		= $dfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dfile='.$sufctanismod->{_dfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dfile='.$sufctanismod->{_dfile};

	} else { 
		print("sufctanismod, dfile, missing dfile,\n");
	 }
 }


=head2 sub dlldx 


=cut

 sub dlldx {

	my ( $self,$dlldx )		= @_;
	if ( $dlldx ne $empty_string ) {

		$sufctanismod->{_dlldx}		= $dlldx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dlldx='.$sufctanismod->{_dlldx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dlldx='.$sufctanismod->{_dlldx};

	} else { 
		print("sufctanismod, dlldx, missing dlldx,\n");
	 }
 }


=head2 sub dlldz 


=cut

 sub dlldz {

	my ( $self,$dlldz )		= @_;
	if ( $dlldz ne $empty_string ) {

		$sufctanismod->{_dlldz}		= $dlldz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dlldz='.$sufctanismod->{_dlldz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dlldz='.$sufctanismod->{_dlldz};

	} else { 
		print("sufctanismod, dlldz, missing dlldz,\n");
	 }
 }


=head2 sub dnndx 


=cut

 sub dnndx {

	my ( $self,$dnndx )		= @_;
	if ( $dnndx ne $empty_string ) {

		$sufctanismod->{_dnndx}		= $dnndx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dnndx='.$sufctanismod->{_dnndx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dnndx='.$sufctanismod->{_dnndx};

	} else { 
		print("sufctanismod, dnndx, missing dnndx,\n");
	 }
 }


=head2 sub dnndz 


=cut

 sub dnndz {

	my ( $self,$dnndz )		= @_;
	if ( $dnndz ne $empty_string ) {

		$sufctanismod->{_dnndz}		= $dnndz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dnndz='.$sufctanismod->{_dnndz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dnndz='.$sufctanismod->{_dnndz};

	} else { 
		print("sufctanismod, dnndz, missing dnndz,\n");
	 }
 }


=head2 sub dofct 


=cut

 sub dofct {

	my ( $self,$dofct )		= @_;
	if ( $dofct ne $empty_string ) {

		$sufctanismod->{_dofct}		= $dofct;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dofct='.$sufctanismod->{_dofct};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dofct='.$sufctanismod->{_dofct};

	} else { 
		print("sufctanismod, dofct, missing dofct,\n");
	 }
 }


=head2 sub drhodx 


=cut

 sub drhodx {

	my ( $self,$drhodx )		= @_;
	if ( $drhodx ne $empty_string ) {

		$sufctanismod->{_drhodx}		= $drhodx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' drhodx='.$sufctanismod->{_drhodx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' drhodx='.$sufctanismod->{_drhodx};

	} else { 
		print("sufctanismod, drhodx, missing drhodx,\n");
	 }
 }


=head2 sub drhodz 


=cut

 sub drhodz {

	my ( $self,$drhodz )		= @_;
	if ( $drhodz ne $empty_string ) {

		$sufctanismod->{_drhodz}		= $drhodz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' drhodz='.$sufctanismod->{_drhodz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' drhodz='.$sufctanismod->{_drhodz};

	} else { 
		print("sufctanismod, drhodz, missing drhodz,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sufctanismod->{_dt}		= $dt;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dt='.$sufctanismod->{_dt};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dt='.$sufctanismod->{_dt};

	} else { 
		print("sufctanismod, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sufctanismod->{_dx}		= $dx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dx='.$sufctanismod->{_dx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dx='.$sufctanismod->{_dx};

	} else { 
		print("sufctanismod, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sufctanismod->{_dz}		= $dz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' dz='.$sufctanismod->{_dz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' dz='.$sufctanismod->{_dz};

	} else { 
		print("sufctanismod, dz, missing dz,\n");
	 }
 }


=head2 sub eta 


=cut

 sub eta {

	my ( $self,$eta )		= @_;
	if ( $eta ne $empty_string ) {

		$sufctanismod->{_eta}		= $eta;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' eta='.$sufctanismod->{_eta};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' eta='.$sufctanismod->{_eta};

	} else { 
		print("sufctanismod, eta, missing eta,\n");
	 }
 }


=head2 sub eta0 


=cut

 sub eta0 {

	my ( $self,$eta0 )		= @_;
	if ( $eta0 ne $empty_string ) {

		$sufctanismod->{_eta0}		= $eta0;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' eta0='.$sufctanismod->{_eta0};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' eta0='.$sufctanismod->{_eta0};

	} else { 
		print("sufctanismod, eta0, missing eta0,\n");
	 }
 }


=head2 sub fctxbeg 


=cut

 sub fctxbeg {

	my ( $self,$fctxbeg )		= @_;
	if ( $fctxbeg ne $empty_string ) {

		$sufctanismod->{_fctxbeg}		= $fctxbeg;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' fctxbeg='.$sufctanismod->{_fctxbeg};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' fctxbeg='.$sufctanismod->{_fctxbeg};

	} else { 
		print("sufctanismod, fctxbeg, missing fctxbeg,\n");
	 }
 }


=head2 sub fctxend 


=cut

 sub fctxend {

	my ( $self,$fctxend )		= @_;
	if ( $fctxend ne $empty_string ) {

		$sufctanismod->{_fctxend}		= $fctxend;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' fctxend='.$sufctanismod->{_fctxend};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' fctxend='.$sufctanismod->{_fctxend};

	} else { 
		print("sufctanismod, fctxend, missing fctxend,\n");
	 }
 }


=head2 sub fctzbeg 


=cut

 sub fctzbeg {

	my ( $self,$fctzbeg )		= @_;
	if ( $fctzbeg ne $empty_string ) {

		$sufctanismod->{_fctzbeg}		= $fctzbeg;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' fctzbeg='.$sufctanismod->{_fctzbeg};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' fctzbeg='.$sufctanismod->{_fctzbeg};

	} else { 
		print("sufctanismod, fctzbeg, missing fctzbeg,\n");
	 }
 }


=head2 sub fctzend 


=cut

 sub fctzend {

	my ( $self,$fctzend )		= @_;
	if ( $fctzend ne $empty_string ) {

		$sufctanismod->{_fctzend}		= $fctzend;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' fctzend='.$sufctanismod->{_fctzend};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' fctzend='.$sufctanismod->{_fctzend};

	} else { 
		print("sufctanismod, fctzend, missing fctzend,\n");
	 }
 }


=head2 sub ff00 


=cut

 sub ff00 {

	my ( $self,$ff00 )		= @_;
	if ( $ff00 ne $empty_string ) {

		$sufctanismod->{_ff00}		= $ff00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' ff00='.$sufctanismod->{_ff00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' ff00='.$sufctanismod->{_ff00};

	} else { 
		print("sufctanismod, ff00, missing ff00,\n");
	 }
 }


=head2 sub ffile 


=cut

 sub ffile {

	my ( $self,$ffile )		= @_;
	if ( $ffile ne $empty_string ) {

		$sufctanismod->{_ffile}		= $ffile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' ffile='.$sufctanismod->{_ffile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' ffile='.$sufctanismod->{_ffile};

	} else { 
		print("sufctanismod, ffile, missing ffile,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$sufctanismod->{_fpeak}		= $fpeak;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' fpeak='.$sufctanismod->{_fpeak};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' fpeak='.$sufctanismod->{_fpeak};

	} else { 
		print("sufctanismod, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub impulse 


=cut

 sub impulse {

	my ( $self,$impulse )		= @_;
	if ( $impulse ne $empty_string ) {

		$sufctanismod->{_impulse}		= $impulse;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' impulse='.$sufctanismod->{_impulse};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' impulse='.$sufctanismod->{_impulse};

	} else { 
		print("sufctanismod, impulse, missing impulse,\n");
	 }
 }


=head2 sub indexdt 


=cut

 sub indexdt {

	my ( $self,$indexdt )		= @_;
	if ( $indexdt ne $empty_string ) {

		$sufctanismod->{_indexdt}		= $indexdt;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' indexdt='.$sufctanismod->{_indexdt};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' indexdt='.$sufctanismod->{_indexdt};

	} else { 
		print("sufctanismod, indexdt, missing indexdt,\n");
	 }
 }


=head2 sub indexux 


=cut

 sub indexux {

	my ( $self,$indexux )		= @_;
	if ( $indexux ne $empty_string ) {

		$sufctanismod->{_indexux}		= $indexux;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' indexux='.$sufctanismod->{_indexux};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' indexux='.$sufctanismod->{_indexux};

	} else { 
		print("sufctanismod, indexux, missing indexux,\n");
	 }
 }


=head2 sub indexuy 


=cut

 sub indexuy {

	my ( $self,$indexuy )		= @_;
	if ( $indexuy ne $empty_string ) {

		$sufctanismod->{_indexuy}		= $indexuy;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' indexuy='.$sufctanismod->{_indexuy};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' indexuy='.$sufctanismod->{_indexuy};

	} else { 
		print("sufctanismod, indexuy, missing indexuy,\n");
	 }
 }


=head2 sub indexuz 


=cut

 sub indexuz {

	my ( $self,$indexuz )		= @_;
	if ( $indexuz ne $empty_string ) {

		$sufctanismod->{_indexuz}		= $indexuz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' indexuz='.$sufctanismod->{_indexuz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' indexuz='.$sufctanismod->{_indexuz};

	} else { 
		print("sufctanismod, indexuz, missing indexuz,\n");
	 }
 }


=head2 sub isurf 


=cut

 sub isurf {

	my ( $self,$isurf )		= @_;
	if ( $isurf ne $empty_string ) {

		$sufctanismod->{_isurf}		= $isurf;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' isurf='.$sufctanismod->{_isurf};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' isurf='.$sufctanismod->{_isurf};

	} else { 
		print("sufctanismod, isurf, missing isurf,\n");
	 }
 }


=head2 sub lfile 


=cut

 sub lfile {

	my ( $self,$lfile )		= @_;
	if ( $lfile ne $empty_string ) {

		$sufctanismod->{_lfile}		= $lfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' lfile='.$sufctanismod->{_lfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' lfile='.$sufctanismod->{_lfile};

	} else { 
		print("sufctanismod, lfile, missing lfile,\n");
	 }
 }


=head2 sub ll00 


=cut

 sub ll00 {

	my ( $self,$ll00 )		= @_;
	if ( $ll00 ne $empty_string ) {

		$sufctanismod->{_ll00}		= $ll00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' ll00='.$sufctanismod->{_ll00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' ll00='.$sufctanismod->{_ll00};

	} else { 
		print("sufctanismod, ll00, missing ll00,\n");
	 }
 }


=head2 sub mbx1 


=cut

 sub mbx1 {

	my ( $self,$mbx1 )		= @_;
	if ( $mbx1 ne $empty_string ) {

		$sufctanismod->{_mbx1}		= $mbx1;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' mbx1='.$sufctanismod->{_mbx1};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' mbx1='.$sufctanismod->{_mbx1};

	} else { 
		print("sufctanismod, mbx1, missing mbx1,\n");
	 }
 }


=head2 sub mbx2 


=cut

 sub mbx2 {

	my ( $self,$mbx2 )		= @_;
	if ( $mbx2 ne $empty_string ) {

		$sufctanismod->{_mbx2}		= $mbx2;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' mbx2='.$sufctanismod->{_mbx2};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' mbx2='.$sufctanismod->{_mbx2};

	} else { 
		print("sufctanismod, mbx2, missing mbx2,\n");
	 }
 }


=head2 sub mbz1 


=cut

 sub mbz1 {

	my ( $self,$mbz1 )		= @_;
	if ( $mbz1 ne $empty_string ) {

		$sufctanismod->{_mbz1}		= $mbz1;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' mbz1='.$sufctanismod->{_mbz1};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' mbz1='.$sufctanismod->{_mbz1};

	} else { 
		print("sufctanismod, mbz1, missing mbz1,\n");
	 }
 }


=head2 sub mbz2 


=cut

 sub mbz2 {

	my ( $self,$mbz2 )		= @_;
	if ( $mbz2 ne $empty_string ) {

		$sufctanismod->{_mbz2}		= $mbz2;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' mbz2='.$sufctanismod->{_mbz2};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' mbz2='.$sufctanismod->{_mbz2};

	} else { 
		print("sufctanismod, mbz2, missing mbz2,\n");
	 }
 }


=head2 sub movebc 


=cut

 sub movebc {

	my ( $self,$movebc )		= @_;
	if ( $movebc ne $empty_string ) {

		$sufctanismod->{_movebc}		= $movebc;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' movebc='.$sufctanismod->{_movebc};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' movebc='.$sufctanismod->{_movebc};

	} else { 
		print("sufctanismod, movebc, missing movebc,\n");
	 }
 }


=head2 sub mt 


=cut

 sub mt {

	my ( $self,$mt )		= @_;
	if ( $mt ne $empty_string ) {

		$sufctanismod->{_mt}		= $mt;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' mt='.$sufctanismod->{_mt};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' mt='.$sufctanismod->{_mt};

	} else { 
		print("sufctanismod, mt, missing mt,\n");
	 }
 }


=head2 sub nfile 


=cut

 sub nfile {

	my ( $self,$nfile )		= @_;
	if ( $nfile ne $empty_string ) {

		$sufctanismod->{_nfile}		= $nfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' nfile='.$sufctanismod->{_nfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' nfile='.$sufctanismod->{_nfile};

	} else { 
		print("sufctanismod, nfile, missing nfile,\n");
	 }
 }


=head2 sub nn00 


=cut

 sub nn00 {

	my ( $self,$nn00 )		= @_;
	if ( $nn00 ne $empty_string ) {

		$sufctanismod->{_nn00}		= $nn00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' nn00='.$sufctanismod->{_nn00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' nn00='.$sufctanismod->{_nn00};

	} else { 
		print("sufctanismod, nn00, missing nn00,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sufctanismod->{_nt}		= $nt;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' nt='.$sufctanismod->{_nt};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' nt='.$sufctanismod->{_nt};

	} else { 
		print("sufctanismod, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$sufctanismod->{_nx}		= $nx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' nx='.$sufctanismod->{_nx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' nx='.$sufctanismod->{_nx};

	} else { 
		print("sufctanismod, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sufctanismod->{_nz}		= $nz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' nz='.$sufctanismod->{_nz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' nz='.$sufctanismod->{_nz};

	} else { 
		print("sufctanismod, nz, missing nz,\n");
	 }
 }


=head2 sub order 


=cut

 sub order {

	my ( $self,$order )		= @_;
	if ( $order ne $empty_string ) {

		$sufctanismod->{_order}		= $order;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' order='.$sufctanismod->{_order};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' order='.$sufctanismod->{_order};

	} else { 
		print("sufctanismod, order, missing order,\n");
	 }
 }


=head2 sub receiverdepth 


=cut

 sub receiverdepth {

	my ( $self,$receiverdepth )		= @_;
	if ( $receiverdepth ne $empty_string ) {

		$sufctanismod->{_receiverdepth}		= $receiverdepth;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' receiverdepth='.$sufctanismod->{_receiverdepth};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' receiverdepth='.$sufctanismod->{_receiverdepth};

	} else { 
		print("sufctanismod, receiverdepth, missing receiverdepth,\n");
	 }
 }


=head2 sub reflxfile 


=cut

 sub reflxfile {

	my ( $self,$reflxfile )		= @_;
	if ( $reflxfile ne $empty_string ) {

		$sufctanismod->{_reflxfile}		= $reflxfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' reflxfile='.$sufctanismod->{_reflxfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' reflxfile='.$sufctanismod->{_reflxfile};

	} else { 
		print("sufctanismod, reflxfile, missing reflxfile,\n");
	 }
 }


=head2 sub reflyfile 


=cut

 sub reflyfile {

	my ( $self,$reflyfile )		= @_;
	if ( $reflyfile ne $empty_string ) {

		$sufctanismod->{_reflyfile}		= $reflyfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' reflyfile='.$sufctanismod->{_reflyfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' reflyfile='.$sufctanismod->{_reflyfile};

	} else { 
		print("sufctanismod, reflyfile, missing reflyfile,\n");
	 }
 }


=head2 sub reflzfile 


=cut

 sub reflzfile {

	my ( $self,$reflzfile )		= @_;
	if ( $reflzfile ne $empty_string ) {

		$sufctanismod->{_reflzfile}		= $reflzfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' reflzfile='.$sufctanismod->{_reflzfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' reflzfile='.$sufctanismod->{_reflzfile};

	} else { 
		print("sufctanismod, reflzfile, missing reflzfile,\n");
	 }
 }


=head2 sub rho00 


=cut

 sub rho00 {

	my ( $self,$rho00 )		= @_;
	if ( $rho00 ne $empty_string ) {

		$sufctanismod->{_rho00}		= $rho00;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' rho00='.$sufctanismod->{_rho00};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' rho00='.$sufctanismod->{_rho00};

	} else { 
		print("sufctanismod, rho00, missing rho00,\n");
	 }
 }


=head2 sub sfile 


=cut

 sub sfile {

	my ( $self,$sfile )		= @_;
	if ( $sfile ne $empty_string ) {

		$sufctanismod->{_sfile}		= $sfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' sfile='.$sufctanismod->{_sfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' sfile='.$sufctanismod->{_sfile};

	} else { 
		print("sufctanismod, sfile, missing sfile,\n");
	 }
 }


=head2 sub source 


=cut

 sub source {

	my ( $self,$source )		= @_;
	if ( $source ne $empty_string ) {

		$sufctanismod->{_source}		= $source;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' source='.$sufctanismod->{_source};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' source='.$sufctanismod->{_source};

	} else { 
		print("sufctanismod, source, missing source,\n");
	 }
 }


=head2 sub suhead 


=cut

 sub suhead {

	my ( $self,$suhead )		= @_;
	if ( $suhead ne $empty_string ) {

		$sufctanismod->{_suhead}		= $suhead;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' suhead='.$sufctanismod->{_suhead};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' suhead='.$sufctanismod->{_suhead};

	} else { 
		print("sufctanismod, suhead, missing suhead,\n");
	 }
 }


=head2 sub sx 


=cut

 sub sx {

	my ( $self,$sx )		= @_;
	if ( $sx ne $empty_string ) {

		$sufctanismod->{_sx}		= $sx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' sx='.$sufctanismod->{_sx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' sx='.$sufctanismod->{_sx};

	} else { 
		print("sufctanismod, sx, missing sx,\n");
	 }
 }


=head2 sub sz 


=cut

 sub sz {

	my ( $self,$sz )		= @_;
	if ( $sz ne $empty_string ) {

		$sufctanismod->{_sz}		= $sz;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' sz='.$sufctanismod->{_sz};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' sz='.$sufctanismod->{_sz};

	} else { 
		print("sufctanismod, sz, missing sz,\n");
	 }
 }


=head2 sub time 


=cut

 sub time {

	my ( $self,$time )		= @_;
	
	
	if ( length $time) {

		$sufctanismod->{_time}		= $time;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' time='.$sufctanismod->{_time};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' time='.$sufctanismod->{_time};
		
        print("sufctanismod, time=$time,\n");
        
	} else { 
		print("sufctanismod, time, missing time,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sufctanismod->{_verbose}		= $verbose;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' verbose='.$sufctanismod->{_verbose};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' verbose='.$sufctanismod->{_verbose};

	} else { 
		print("sufctanismod, verbose, missing verbose,\n");
	 }
 }


=head2 sub vspnx 


=cut

 sub vspnx {

	my ( $self,$vspnx )		= @_;
	if ( $vspnx ne $empty_string ) {

		$sufctanismod->{_vspnx}		= $vspnx;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' vspnx='.$sufctanismod->{_vspnx};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' vspnx='.$sufctanismod->{_vspnx};

	} else { 
		print("sufctanismod, vspnx, missing vspnx,\n");
	 }
 }


=head2 sub vspxfile 


=cut

 sub vspxfile {

	my ( $self,$vspxfile )		= @_;
	if ( $vspxfile ne $empty_string ) {

		$sufctanismod->{_vspxfile}		= $vspxfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' vspxfile='.$sufctanismod->{_vspxfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' vspxfile='.$sufctanismod->{_vspxfile};

	} else { 
		print("sufctanismod, vspxfile, missing vspxfile,\n");
	 }
 }


=head2 sub vspyfile 


=cut

 sub vspyfile {

	my ( $self,$vspyfile )		= @_;
	if ( $vspyfile ne $empty_string ) {

		$sufctanismod->{_vspyfile}		= $vspyfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' vspyfile='.$sufctanismod->{_vspyfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' vspyfile='.$sufctanismod->{_vspyfile};

	} else { 
		print("sufctanismod, vspyfile, missing vspyfile,\n");
	 }
 }


=head2 sub vspzfile 


=cut

 sub vspzfile {

	my ( $self,$vspzfile )		= @_;
	if ( $vspzfile ne $empty_string ) {

		$sufctanismod->{_vspzfile}		= $vspzfile;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' vspzfile='.$sufctanismod->{_vspzfile};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' vspzfile='.$sufctanismod->{_vspzfile};

	} else { 
		print("sufctanismod, vspzfile, missing vspzfile,\n");
	 }
 }


=head2 sub wavelet 


=cut

 sub wavelet {

	my ( $self,$wavelet )		= @_;
	if ( $wavelet ne $empty_string ) {

		$sufctanismod->{_wavelet}		= $wavelet;
		$sufctanismod->{_note}		= $sufctanismod->{_note}.' wavelet='.$sufctanismod->{_wavelet};
		$sufctanismod->{_Step}		= $sufctanismod->{_Step}.' wavelet='.$sufctanismod->{_wavelet};

	} else { 
		print("sufctanismod, wavelet, missing wavelet,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 70;

    return($max_index);
}
 
 
1; 
