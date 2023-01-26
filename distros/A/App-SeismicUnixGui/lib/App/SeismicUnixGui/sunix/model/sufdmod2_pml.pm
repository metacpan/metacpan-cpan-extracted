package App::SeismicUnixGui::sunix::model::sufdmod2l;

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
 SUFDMOD2_PML - Finite-Difference MODeling (2nd order) for acoustic wave

    equation with PML absorbing boundary conditions.			

 Caveat: experimental PML absorbing boundary condition version,	

may be buggy!								



 sufdmod2_pml <vfile >wfile nx= nz= tmax= xs= zs= [optional parameters]



 Required Parameters:							

 <vfile		file containing velocity[nx][nz]		

 >wfile		file containing waves[nx][nz] for time steps	

 nx=			number of x samples (2nd dimension)		

 nz=			number of z samples (1st dimension)		

 xs=			x coordinates of source				

 zs=			z coordinates of source				

 tmax=			maximum time					



 Optional Parameters:							

 nt=1+tmax/dt		number of time samples (dt determined for stability)

 mt=1			number of time steps (dt) per output time step	



 dx=1.0		x sampling interval				

 fx=0.0		first x sample					

 dz=1.0		z sampling interval				

 fz=0.0		first z sample					



 fmax = vmin/(10.0*h)	maximum frequency in source wavelet		

 fpeak=0.5*fmax	peak frequency in ricker wavelet		



 dfile=		input file containing density[nx][nz]		

 vsx=			x coordinate of vertical line of seismograms	

 hsz=			z coordinate of horizontal line of seismograms	

 vsfile=		output file for vertical line of seismograms[nz][nt]

 vsfile_out=

 hsfile=		output file for horizontal line of seismograms[nx][nt]

 hsfile_out=

 ssfile=		output file for source point seismograms[nt]	

 source_seismogram_out=

 verbose=0		=1 for diagnostic messages, =2 for more		



 abs=1,1,1,1		Absorbing boundary conditions on top,left,bottom,right

 			sides of the model. 				

 		=0,1,1,1 for free surface condition on the top		



 ...PML parameters....                                                 

 pml_max=1000.0        PML absorption parameter                        

 pml_thick=0           half-thickness of pml layer (0 = do not use PML)



 Notes:								

 This program uses the traditional explicit second order differencing	

 method. 								



 Two different absorbing boundary condition schemes are available. The 

 first is a traditional absorbing boundary condition scheme created by 

 Hale, 1990. The second is based on the perfectly matched layer (PML)	

 method of Berenger, 1995.						







 Authors:  CWP:Dave Hale

           CWP:modified for SU by John Stockwell, 1993.

           CWP:added frequency specification of wavelet: Craig Artley, 1993

           TAMU:added PML absorbing boundary condition: 

               Michael Holzrichter, 1998

           CWP/WesternGeco:corrected PML code to handle density variations:

               Greg Wimpey, 2006



 References: (Hale's absobing boundary conditions)

 Clayton, R. W., and Engquist, B., 1977, Absorbing boundary conditions

 for acoustic and elastic wave equations, Bull. Seism. Soc. Am., 6,

	1529-1540. 



 Clayton, R. W., and Engquist, B., 1980, Absorbing boundary conditions

 for wave equation migration, Geophysics, 45, 895-904.



 Hale, D.,  1990, Adaptive absorbing boundaries for finite-difference

 modeling of the wave equation migration, unpublished report from the

 Center for Wave Phenomena, Colorado School of Mines.



 Richtmyer, R. D., and Morton, K. W., 1967, Difference methods for

 initial-value problems, John Wiley & Sons, Inc, New York.



 Thomee, V., 1962, A stable difference scheme for the mixed boundary problem

 for a hyperbolic, first-order system in two dimensions, J. Soc. Indust.

 Appl. Math., 10, 229-245.



 Toldi, J. L., and Hale, D., 1982, Data-dependent absorbing side boundaries,

 Stanford Exploration Project Report SEP-30, 111-121.



 References: (PML boundary conditions)

 Jean-Pierre Berenger, ``A Perfectly Matched Layer for the Absorption of

 Electromagnetic Waves,''  Journal of Computational Physics, vol. 114,

 pp. 185-200.



 Hastings, Schneider, and Broschat, ``Application of the perfectly

 matched layer (PML) absorbing boundary condition to elastic wave

 propogation,''  Journal of the Accoustical Society of America,

 November, 1996.



 Allen Taflove, ``Electromagnetic Modeling:  Finite Difference Time

 Domain Methods'', Baltimore, Maryland: Johns Hopkins University Press,

 1995, chap. 7, pp. 181-195.





 Trace header fields set: ns, delrt, tracl, tracr, offset, d1, d2,

                          sdepth, trid



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

my $sufdmod2_pml			= {
	_abs					=> '',
	_dfile					=> '',
	_dx					=> '',
	_dz					=> '',
	_fmax					=> '',
	_fpeak					=> '',
	_fx					=> '',
	_fz					=> '',
	_hsfile					=> '',
	_hsz					=> '',
	_mt					=> '',
	_nt					=> '',
	_nx					=> '',
	_nz					=> '',
	_pml_max					=> '',
	_pml_thick					=> '',
	_ssfile					=> '',
	_tmax					=> '',
	_verbose					=> '',
	_vsfile					=> '',
	_vsx					=> '',
	_xs					=> '',
	_zs					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sufdmod2_pml->{_Step}     = 'sufdmod2_pml'.$sufdmod2_pml->{_Step};
	return ( $sufdmod2_pml->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufdmod2_pml->{_note}     = 'sufdmod2_pml'.$sufdmod2_pml->{_note};
	return ( $sufdmod2_pml->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufdmod2_pml->{_abs}			= '';
		$sufdmod2_pml->{_dfile}			= '';
		$sufdmod2_pml->{_dx}			= '';
		$sufdmod2_pml->{_dz}			= '';
		$sufdmod2_pml->{_fmax}			= '';
		$sufdmod2_pml->{_fpeak}			= '';
		$sufdmod2_pml->{_fx}			= '';
		$sufdmod2_pml->{_fz}			= '';
		$sufdmod2_pml->{_hsfile}			= '';
		$sufdmod2_pml->{_hsz}			= '';
		$sufdmod2_pml->{_mt}			= '';
		$sufdmod2_pml->{_nt}			= '';
		$sufdmod2_pml->{_nx}			= '';
		$sufdmod2_pml->{_nz}			= '';
		$sufdmod2_pml->{_pml_max}			= '';
		$sufdmod2_pml->{_pml_thick}			= '';
		$sufdmod2_pml->{_ssfile}			= '';
		$sufdmod2_pml->{_tmax}			= '';
		$sufdmod2_pml->{_verbose}			= '';
		$sufdmod2_pml->{_vsfile}			= '';
		$sufdmod2_pml->{_vsx}			= '';
		$sufdmod2_pml->{_xs}			= '';
		$sufdmod2_pml->{_zs}			= '';
		$sufdmod2_pml->{_Step}			= '';
		$sufdmod2_pml->{_note}			= '';
 }


=head2 sub abs 


=cut

 sub abs {

	my ( $self,$abs )		= @_;
	if ( $abs ne $empty_string ) {

		$sufdmod2_pml->{_abs}		= $abs;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' abs='.$sufdmod2_pml->{_abs};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' abs='.$sufdmod2_pml->{_abs};

	} else { 
		print("sufdmod2_pml, abs, missing abs,\n");
	 }
 }


=head2 sub dfile 


=cut

 sub dfile {

	my ( $self,$dfile )		= @_;
	if ( $dfile ne $empty_string ) {

		$sufdmod2_pml->{_dfile}		= $dfile;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' dfile='.$sufdmod2_pml->{_dfile};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' dfile='.$sufdmod2_pml->{_dfile};

	} else { 
		print("sufdmod2_pml, dfile, missing dfile,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sufdmod2_pml->{_dx}		= $dx;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' dx='.$sufdmod2_pml->{_dx};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' dx='.$sufdmod2_pml->{_dx};

	} else { 
		print("sufdmod2_pml, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sufdmod2_pml->{_dz}		= $dz;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' dz='.$sufdmod2_pml->{_dz};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' dz='.$sufdmod2_pml->{_dz};

	} else { 
		print("sufdmod2_pml, dz, missing dz,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sufdmod2_pml->{_fmax}		= $fmax;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' fmax='.$sufdmod2_pml->{_fmax};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' fmax='.$sufdmod2_pml->{_fmax};

	} else { 
		print("sufdmod2_pml, fmax, missing fmax,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$sufdmod2_pml->{_fpeak}		= $fpeak;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' fpeak='.$sufdmod2_pml->{_fpeak};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' fpeak='.$sufdmod2_pml->{_fpeak};

	} else { 
		print("sufdmod2_pml, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$sufdmod2_pml->{_fx}		= $fx;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' fx='.$sufdmod2_pml->{_fx};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' fx='.$sufdmod2_pml->{_fx};

	} else { 
		print("sufdmod2_pml, fx, missing fx,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$sufdmod2_pml->{_fz}		= $fz;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' fz='.$sufdmod2_pml->{_fz};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' fz='.$sufdmod2_pml->{_fz};

	} else { 
		print("sufdmod2_pml, fz, missing fz,\n");
	 }
 }


=head2 sub hsfile 


=cut

 sub hsfile {

	my ( $self,$hsfile )		= @_;
	if ( $hsfile ne $empty_string ) {

		$sufdmod2_pml->{_hsfile}		= $hsfile;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' hsfile='.$sufdmod2_pml->{_hsfile};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' hsfile='.$sufdmod2_pml->{_hsfile};

	} else { 
		print("sufdmod2_pml, hsfile, missing hsfile,\n");
	 }
 }


=head2 sub hsz 


=cut

 sub hsz {

	my ( $self,$hsz )		= @_;
	if ( $hsz ne $empty_string ) {

		$sufdmod2_pml->{_hsz}		= $hsz;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' hsz='.$sufdmod2_pml->{_hsz};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' hsz='.$sufdmod2_pml->{_hsz};

	} else { 
		print("sufdmod2_pml, hsz, missing hsz,\n");
	 }
 }


=head2 sub mt 


=cut

 sub mt {

	my ( $self,$mt )		= @_;
	if ( $mt ne $empty_string ) {

		$sufdmod2_pml->{_mt}		= $mt;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' mt='.$sufdmod2_pml->{_mt};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' mt='.$sufdmod2_pml->{_mt};

	} else { 
		print("sufdmod2_pml, mt, missing mt,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sufdmod2_pml->{_nt}		= $nt;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' nt='.$sufdmod2_pml->{_nt};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' nt='.$sufdmod2_pml->{_nt};

	} else { 
		print("sufdmod2_pml, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$sufdmod2_pml->{_nx}		= $nx;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' nx='.$sufdmod2_pml->{_nx};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' nx='.$sufdmod2_pml->{_nx};

	} else { 
		print("sufdmod2_pml, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sufdmod2_pml->{_nz}		= $nz;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' nz='.$sufdmod2_pml->{_nz};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' nz='.$sufdmod2_pml->{_nz};

	} else { 
		print("sufdmod2_pml, nz, missing nz,\n");
	 }
 }


=head2 sub pml_max 


=cut

 sub pml_max {

	my ( $self,$pml_max )		= @_;
	if ( $pml_max ne $empty_string ) {

		$sufdmod2_pml->{_pml_max}		= $pml_max;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' pml_max='.$sufdmod2_pml->{_pml_max};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' pml_max='.$sufdmod2_pml->{_pml_max};

	} else { 
		print("sufdmod2_pml, pml_max, missing pml_max,\n");
	 }
 }


=head2 sub pml_thick 


=cut

 sub pml_thick {

	my ( $self,$pml_thick )		= @_;
	if ( $pml_thick ne $empty_string ) {

		$sufdmod2_pml->{_pml_thick}		= $pml_thick;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' pml_thick='.$sufdmod2_pml->{_pml_thick};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' pml_thick='.$sufdmod2_pml->{_pml_thick};

	} else { 
		print("sufdmod2_pml, pml_thick, missing pml_thick,\n");
	 }
 }


=head2 sub ssfile 


=cut

 sub ssfile {

	my ( $self,$ssfile )		= @_;
	if ( $ssfile ne $empty_string ) {

		$sufdmod2_pml->{_ssfile}		= $ssfile;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' ssfile='.$sufdmod2_pml->{_ssfile};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' ssfile='.$sufdmod2_pml->{_ssfile};

	} else { 
		print("sufdmod2_pml, ssfile, missing ssfile,\n");
	 }
 }


=head2 sub tmax 


=cut

 sub tmax {

	my ( $self,$tmax )		= @_;
	if ( $tmax ne $empty_string ) {

		$sufdmod2_pml->{_tmax}		= $tmax;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' tmax='.$sufdmod2_pml->{_tmax};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' tmax='.$sufdmod2_pml->{_tmax};

	} else { 
		print("sufdmod2_pml, tmax, missing tmax,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sufdmod2_pml->{_verbose}		= $verbose;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' verbose='.$sufdmod2_pml->{_verbose};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' verbose='.$sufdmod2_pml->{_verbose};

	} else { 
		print("sufdmod2_pml, verbose, missing verbose,\n");
	 }
 }


=head2 sub vsfile 


=cut

 sub vsfile {

	my ( $self,$vsfile )		= @_;
	if ( $vsfile ne $empty_string ) {

		$sufdmod2_pml->{_vsfile}		= $vsfile;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' vsfile='.$sufdmod2_pml->{_vsfile};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' vsfile='.$sufdmod2_pml->{_vsfile};

	} else { 
		print("sufdmod2_pml, vsfile, missing vsfile,\n");
	 }
 }


=head2 sub vsx 


=cut

 sub vsx {

	my ( $self,$vsx )		= @_;
	if ( $vsx ne $empty_string ) {

		$sufdmod2_pml->{_vsx}		= $vsx;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' vsx='.$sufdmod2_pml->{_vsx};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' vsx='.$sufdmod2_pml->{_vsx};

	} else { 
		print("sufdmod2_pml, vsx, missing vsx,\n");
	 }
 }


=head2 sub xs 


=cut

 sub xs {

	my ( $self,$xs )		= @_;
	if ( $xs ne $empty_string ) {

		$sufdmod2_pml->{_xs}		= $xs;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' xs='.$sufdmod2_pml->{_xs};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' xs='.$sufdmod2_pml->{_xs};

	} else { 
		print("sufdmod2_pml, xs, missing xs,\n");
	 }
 }


=head2 sub zs 


=cut

 sub zs {

	my ( $self,$zs )		= @_;
	if ( $zs ne $empty_string ) {

		$sufdmod2_pml->{_zs}		= $zs;
		$sufdmod2_pml->{_note}		= $sufdmod2_pml->{_note}.' zs='.$sufdmod2_pml->{_zs};
		$sufdmod2_pml->{_Step}		= $sufdmod2_pml->{_Step}.' zs='.$sufdmod2_pml->{_zs};

	} else { 
		print("sufdmod2_pml, zs, missing zs,\n");
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
