package App::SeismicUnixGui::sunix::model::suremac2d;

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
 SUREMAC2D - Acoustic 2D Fourier method modeling with high accuracy     

             Rapid Expansion Method (REM) time integration              



 suremac2d [parameters]                                                 



 Required parameters:                                                   



 opflag=     0: variable density wave equation                          

             1: constant density wave equation                          

             2: non-reflecting wave equation                            



 nx=         number of grid points in horizontal direction              

 nz=         number of grid points in vertical direction                

 nt=         number of time samples                                     

 dx=         spatial increment in horizontal direction                  

 dz=         spatial increment in vertical direction                    

 dt=         time sample interval in seconds                            

 isx=        grid point # of horizontal source positions                

 isz=        grid point # of vertical source positions                  



 Optional parameters:                                                   

 fx=0.0      first horizontal coordinate                                

 fz=0.0      first vertical coordinate                                  

 irx=        horizontal grid point # of vertical receiver lines         

 irz=        vertical grid point # of horizontal receiver lines         

 w=0.1       width of spatial source distribution (see notes)           

 sflag=2     source time function                                       

             0: user supplied source function                           

             1: impulse (spike at t=0)                                  

             2: Ricker wavelet                                          

 fmax=       maximum frequency of Ricker (default) wavelet              

 amps=1.0    amplitudes of sources                                      

 prec=0      1: precompute Bessel coefficients b_k (see notes)          

             2: use precomputed Bessel coefficients b_k                 

 fsflag=0    1: perform run with free surface b.c.                      

 vmaxu=      user-defined maximum velocity                              

 dtsnap=0.0  time interval in seconds of wave field snapshots           

 iabso=1     apply absorbing boundary conditions (0: none)              

 abso=0.1    damping parameter for absorbing boundaries                 

 nbwx=20     horizontal width of absorbing boundary                     

 nbwz=20     vertical width of absorbing boundary                       

 verbose=0   1: show parameters used                                    

             2: print maximum amplitude at every expansion term         



 velfile=vel          velocity filename                                 

 densfile=dens        density filename                                  

 sname=wavelet.su     user supplied source time function filename       

 sepxname=sectx.su    x-direction pressure sections filename            

 sepzname=sectz.su    z-direction pressure sections filename            

 snpname=snap.su      pressure snapshot filename                        

 jpfile=stderr        diagnostic output                                 

m is  bound 

 Notes:                                                                 

  0. The combination of the Fourier method with REM time integration    

     allows the computation of synthetic seismograms which are free     

     of numerical grid dispersion. REM has no restriction on the        

     time step size dt. The Fourier method requires at least two        

     grid points per shortest wavelength.                               

  1. nx and nz must be valid numbers for pfafft transform lengths.      

     nx and nz must be odd numbers (unless opflag=1). For valid         

     numbers see e.g. numbers in structure 'nctab' in source file       

     $CWPROOT/src/cwp/lib/pfafft.c.                                     

  2. Velocities (and densities) are stored as plain C style files       

     of floats where the fast dimension is along the z-direction.       

  3. Units must be consistent, e.g. m, s and m/s.                       

  4. A 20 grid points wide border at the sides and the bottom of        

     the modeling grid is used for sponge boundary conditions           

     (default: iabso=1).                                                

     Source and receiver lines should be placed some (e.g. 10) grid     

     points away from the absorbing boundaries in order to reduce       

     reflections due to obliquely incident wavefronts.                  

  5. Dominant frequency is about fmax/2 (sflag=2), absolute maximum     

     is delayed by 3/fmax from beginning of wavelet.                    

  6. If opflag!=1 the source should be not a spike in space; the        

     parameter w determines at which distance (in grid points) from     

     the source's center the Gaussian weight decays to 10 percent       

     of its maximum. w=2 may be a reasonable choice; however, the       

     waveform will be distorted.                                        

  7. Horizontal and vertical receiver line sections are written to      

     separate files. Each file can hold more than one line.             

  8. Parameter vmaxu may be enlarged if the modeling run becomes        

     unstable. This happens if the largest eigenvalue of the modeling   

     operator L is larger than estimated from the largest velocity.     

     In particular if using the variable density acoustic wave          

     equation the eigenvalues depend also on the density and it is      

     impossible to estimated the largest eigenvalue analytically.       

  9. Bessel coefficients can be precomputed (prec=1) and stored on      

     disk to save CPU time when several shots need to be run.           

     In this case computation of Bessel coefficients can be skipped     

     and read from disk file for reuse (prec=2).                        

     For reuse of Bessel coefficients the user may need to define       

     the overall maximum velocity (vmaxu).                              

 10. If snapshots are not required, a spike source (sflag=1) may be     

     applied and the resulting impulse response seismograms can be      

     convolved later with a desired wavelet.                            

 11. The free surface (fsflag=1) does not coincide with the first       

     vertical grid index (0). It appears to be half a grid spacing      

     above that position.                                               



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

my $suremac2d			= {
	_abso					=> '',
	_amps					=> '',
	_densfile					=> '',
	_dt					=> '',
	_dtsnap					=> '',
	_dx					=> '',
	_dz					=> '',
	_fmax					=> '',
	_fsflag					=> '',
	_fx					=> '',
	_fz					=> '',
	_iabso					=> '',
	_irx					=> '',
	_irz					=> '',
	_isx					=> '',
	_isz					=> '',
	_jpfile					=> '',
	_nbwx					=> '',
	_nbwz					=> '',
	_nt					=> '',
	_nx					=> '',
	_nz					=> '',
	_opflag					=> '',
	_prec					=> '',
	_sepxname					=> '',
	_sepzname					=> '',
	_sflag					=> '',
	_sname					=> '',
	_snpname					=> '',
	_t					=> '',
	_velfile					=> '',
	_verbose					=> '',
	_vmaxu					=> '',
	_w					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suremac2d->{_Step}     = 'suremac2d'.$suremac2d->{_Step};
	return ( $suremac2d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suremac2d->{_note}     = 'suremac2d'.$suremac2d->{_note};
	return ( $suremac2d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suremac2d->{_abso}			= '';
		$suremac2d->{_amps}			= '';
		$suremac2d->{_densfile}			= '';
		$suremac2d->{_dt}			= '';
		$suremac2d->{_dtsnap}			= '';
		$suremac2d->{_dx}			= '';
		$suremac2d->{_dz}			= '';
		$suremac2d->{_fmax}			= '';
		$suremac2d->{_fsflag}			= '';
		$suremac2d->{_fx}			= '';
		$suremac2d->{_fz}			= '';
		$suremac2d->{_iabso}			= '';
		$suremac2d->{_irx}			= '';
		$suremac2d->{_irz}			= '';
		$suremac2d->{_isx}			= '';
		$suremac2d->{_isz}			= '';
		$suremac2d->{_jpfile}			= '';
		$suremac2d->{_nbwx}			= '';
		$suremac2d->{_nbwz}			= '';
		$suremac2d->{_nt}			= '';
		$suremac2d->{_nx}			= '';
		$suremac2d->{_nz}			= '';
		$suremac2d->{_opflag}			= '';
		$suremac2d->{_prec}			= '';
		$suremac2d->{_sepxname}			= '';
		$suremac2d->{_sepzname}			= '';
		$suremac2d->{_sflag}			= '';
		$suremac2d->{_sname}			= '';
		$suremac2d->{_snpname}			= '';
		$suremac2d->{_t}			= '';
		$suremac2d->{_velfile}			= '';
		$suremac2d->{_verbose}			= '';
		$suremac2d->{_vmaxu}			= '';
		$suremac2d->{_w}			= '';
		$suremac2d->{_Step}			= '';
		$suremac2d->{_note}			= '';
 }


=head2 sub abso 


=cut

 sub abso {

	my ( $self,$abso )		= @_;
	if ( $abso ne $empty_string ) {

		$suremac2d->{_abso}		= $abso;
		$suremac2d->{_note}		= $suremac2d->{_note}.' abso='.$suremac2d->{_abso};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' abso='.$suremac2d->{_abso};

	} else { 
		print("suremac2d, abso, missing abso,\n");
	 }
 }


=head2 sub amps 


=cut

 sub amps {

	my ( $self,$amps )		= @_;
	if ( $amps ne $empty_string ) {

		$suremac2d->{_amps}		= $amps;
		$suremac2d->{_note}		= $suremac2d->{_note}.' amps='.$suremac2d->{_amps};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' amps='.$suremac2d->{_amps};

	} else { 
		print("suremac2d, amps, missing amps,\n");
	 }
 }


=head2 sub densfile 


=cut

 sub densfile {

	my ( $self,$densfile )		= @_;
	if ( $densfile ne $empty_string ) {

		$suremac2d->{_densfile}		= $densfile;
		$suremac2d->{_note}		= $suremac2d->{_note}.' densfile='.$suremac2d->{_densfile};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' densfile='.$suremac2d->{_densfile};

	} else { 
		print("suremac2d, densfile, missing densfile,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suremac2d->{_dt}		= $dt;
		$suremac2d->{_note}		= $suremac2d->{_note}.' dt='.$suremac2d->{_dt};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' dt='.$suremac2d->{_dt};

	} else { 
		print("suremac2d, dt, missing dt,\n");
	 }
 }


=head2 sub dtsnap 


=cut

 sub dtsnap {

	my ( $self,$dtsnap )		= @_;
	if ( $dtsnap ne $empty_string ) {

		$suremac2d->{_dtsnap}		= $dtsnap;
		$suremac2d->{_note}		= $suremac2d->{_note}.' dtsnap='.$suremac2d->{_dtsnap};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' dtsnap='.$suremac2d->{_dtsnap};

	} else { 
		print("suremac2d, dtsnap, missing dtsnap,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suremac2d->{_dx}		= $dx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' dx='.$suremac2d->{_dx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' dx='.$suremac2d->{_dx};

	} else { 
		print("suremac2d, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$suremac2d->{_dz}		= $dz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' dz='.$suremac2d->{_dz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' dz='.$suremac2d->{_dz};

	} else { 
		print("suremac2d, dz, missing dz,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$suremac2d->{_fmax}		= $fmax;
		$suremac2d->{_note}		= $suremac2d->{_note}.' fmax='.$suremac2d->{_fmax};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' fmax='.$suremac2d->{_fmax};

	} else { 
		print("suremac2d, fmax, missing fmax,\n");
	 }
 }


=head2 sub fsflag 


=cut

 sub fsflag {

	my ( $self,$fsflag )		= @_;
	if ( $fsflag ne $empty_string ) {

		$suremac2d->{_fsflag}		= $fsflag;
		$suremac2d->{_note}		= $suremac2d->{_note}.' fsflag='.$suremac2d->{_fsflag};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' fsflag='.$suremac2d->{_fsflag};

	} else { 
		print("suremac2d, fsflag, missing fsflag,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$suremac2d->{_fx}		= $fx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' fx='.$suremac2d->{_fx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' fx='.$suremac2d->{_fx};

	} else { 
		print("suremac2d, fx, missing fx,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$suremac2d->{_fz}		= $fz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' fz='.$suremac2d->{_fz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' fz='.$suremac2d->{_fz};

	} else { 
		print("suremac2d, fz, missing fz,\n");
	 }
 }


=head2 sub iabso 


=cut

 sub iabso {

	my ( $self,$iabso )		= @_;
	if ( $iabso ne $empty_string ) {

		$suremac2d->{_iabso}		= $iabso;
		$suremac2d->{_note}		= $suremac2d->{_note}.' iabso='.$suremac2d->{_iabso};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' iabso='.$suremac2d->{_iabso};

	} else { 
		print("suremac2d, iabso, missing iabso,\n");
	 }
 }


=head2 sub irx 


=cut

 sub irx {

	my ( $self,$irx )		= @_;
	if ( $irx ne $empty_string ) {

		$suremac2d->{_irx}		= $irx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' irx='.$suremac2d->{_irx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' irx='.$suremac2d->{_irx};

	} else { 
		print("suremac2d, irx, missing irx,\n");
	 }
 }


=head2 sub irz 


=cut

 sub irz {

	my ( $self,$irz )		= @_;
	if ( $irz ne $empty_string ) {

		$suremac2d->{_irz}		= $irz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' irz='.$suremac2d->{_irz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' irz='.$suremac2d->{_irz};

	} else { 
		print("suremac2d, irz, missing irz,\n");
	 }
 }


=head2 sub isx 


=cut

 sub isx {

	my ( $self,$isx )		= @_;
	if ( $isx ne $empty_string ) {

		$suremac2d->{_isx}		= $isx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' isx='.$suremac2d->{_isx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' isx='.$suremac2d->{_isx};

	} else { 
		print("suremac2d, isx, missing isx,\n");
	 }
 }


=head2 sub isz 


=cut

 sub isz {

	my ( $self,$isz )		= @_;
	if ( $isz ne $empty_string ) {

		$suremac2d->{_isz}		= $isz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' isz='.$suremac2d->{_isz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' isz='.$suremac2d->{_isz};

	} else { 
		print("suremac2d, isz, missing isz,\n");
	 }
 }


=head2 sub jpfile 


=cut

 sub jpfile {

	my ( $self,$jpfile )		= @_;
	if ( $jpfile ne $empty_string ) {

		$suremac2d->{_jpfile}		= $jpfile;
		$suremac2d->{_note}		= $suremac2d->{_note}.' jpfile='.$suremac2d->{_jpfile};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' jpfile='.$suremac2d->{_jpfile};

	} else { 
		print("suremac2d, jpfile, missing jpfile,\n");
	 }
 }


=head2 sub nbwx 


=cut

 sub nbwx {

	my ( $self,$nbwx )		= @_;
	if ( $nbwx ne $empty_string ) {

		$suremac2d->{_nbwx}		= $nbwx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' nbwx='.$suremac2d->{_nbwx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' nbwx='.$suremac2d->{_nbwx};

	} else { 
		print("suremac2d, nbwx, missing nbwx,\n");
	 }
 }


=head2 sub nbwz 


=cut

 sub nbwz {

	my ( $self,$nbwz )		= @_;
	if ( $nbwz ne $empty_string ) {

		$suremac2d->{_nbwz}		= $nbwz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' nbwz='.$suremac2d->{_nbwz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' nbwz='.$suremac2d->{_nbwz};

	} else { 
		print("suremac2d, nbwz, missing nbwz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suremac2d->{_nt}		= $nt;
		$suremac2d->{_note}		= $suremac2d->{_note}.' nt='.$suremac2d->{_nt};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' nt='.$suremac2d->{_nt};

	} else { 
		print("suremac2d, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$suremac2d->{_nx}		= $nx;
		$suremac2d->{_note}		= $suremac2d->{_note}.' nx='.$suremac2d->{_nx};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' nx='.$suremac2d->{_nx};

	} else { 
		print("suremac2d, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$suremac2d->{_nz}		= $nz;
		$suremac2d->{_note}		= $suremac2d->{_note}.' nz='.$suremac2d->{_nz};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' nz='.$suremac2d->{_nz};

	} else { 
		print("suremac2d, nz, missing nz,\n");
	 }
 }


=head2 sub opflag 


=cut

 sub opflag {

	my ( $self,$opflag )		= @_;
	if ( $opflag ne $empty_string ) {

		$suremac2d->{_opflag}		= $opflag;
		$suremac2d->{_note}		= $suremac2d->{_note}.' opflag='.$suremac2d->{_opflag};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' opflag='.$suremac2d->{_opflag};

	} else { 
		print("suremac2d, opflag, missing opflag,\n");
	 }
 }


=head2 sub prec 


=cut

 sub prec {

	my ( $self,$prec )		= @_;
	if ( $prec ne $empty_string ) {

		$suremac2d->{_prec}		= $prec;
		$suremac2d->{_note}		= $suremac2d->{_note}.' prec='.$suremac2d->{_prec};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' prec='.$suremac2d->{_prec};

	} else { 
		print("suremac2d, prec, missing prec,\n");
	 }
 }


=head2 sub sepxname 


=cut

 sub sepxname {

	my ( $self,$sepxname )		= @_;
	if ( $sepxname ne $empty_string ) {

		$suremac2d->{_sepxname}		= $sepxname;
		$suremac2d->{_note}		= $suremac2d->{_note}.' sepxname='.$suremac2d->{_sepxname};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' sepxname='.$suremac2d->{_sepxname};

	} else { 
		print("suremac2d, sepxname, missing sepxname,\n");
	 }
 }


=head2 sub sepzname 


=cut

 sub sepzname {

	my ( $self,$sepzname )		= @_;
	if ( $sepzname ne $empty_string ) {

		$suremac2d->{_sepzname}		= $sepzname;
		$suremac2d->{_note}		= $suremac2d->{_note}.' sepzname='.$suremac2d->{_sepzname};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' sepzname='.$suremac2d->{_sepzname};

	} else { 
		print("suremac2d, sepzname, missing sepzname,\n");
	 }
 }


=head2 sub sflag 


=cut

 sub sflag {

	my ( $self,$sflag )		= @_;
	if ( $sflag ne $empty_string ) {

		$suremac2d->{_sflag}		= $sflag;
		$suremac2d->{_note}		= $suremac2d->{_note}.' sflag='.$suremac2d->{_sflag};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' sflag='.$suremac2d->{_sflag};

	} else { 
		print("suremac2d, sflag, missing sflag,\n");
	 }
 }


=head2 sub sname 


=cut

 sub sname {

	my ( $self,$sname )		= @_;
	if ( $sname ne $empty_string ) {

		$suremac2d->{_sname}		= $sname;
		$suremac2d->{_note}		= $suremac2d->{_note}.' sname='.$suremac2d->{_sname};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' sname='.$suremac2d->{_sname};

	} else { 
		print("suremac2d, sname, missing sname,\n");
	 }
 }


=head2 sub snpname 


=cut

 sub snpname {

	my ( $self,$snpname )		= @_;
	if ( $snpname ne $empty_string ) {

		$suremac2d->{_snpname}		= $snpname;
		$suremac2d->{_note}		= $suremac2d->{_note}.' snpname='.$suremac2d->{_snpname};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' snpname='.$suremac2d->{_snpname};

	} else { 
		print("suremac2d, snpname, missing snpname,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$suremac2d->{_t}		= $t;
		$suremac2d->{_note}		= $suremac2d->{_note}.' t='.$suremac2d->{_t};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' t='.$suremac2d->{_t};

	} else { 
		print("suremac2d, t, missing t,\n");
	 }
 }


=head2 sub velfile 


=cut

 sub velfile {

	my ( $self,$velfile )		= @_;
	if ( $velfile ne $empty_string ) {

		$suremac2d->{_velfile}		= $velfile;
		$suremac2d->{_note}		= $suremac2d->{_note}.' velfile='.$suremac2d->{_velfile};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' velfile='.$suremac2d->{_velfile};

	} else { 
		print("suremac2d, velfile, missing velfile,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suremac2d->{_verbose}		= $verbose;
		$suremac2d->{_note}		= $suremac2d->{_note}.' verbose='.$suremac2d->{_verbose};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' verbose='.$suremac2d->{_verbose};

	} else { 
		print("suremac2d, verbose, missing verbose,\n");
	 }
 }


=head2 sub vmaxu 


=cut

 sub vmaxu {

	my ( $self,$vmaxu )		= @_;
	if ( $vmaxu ne $empty_string ) {

		$suremac2d->{_vmaxu}		= $vmaxu;
		$suremac2d->{_note}		= $suremac2d->{_note}.' vmaxu='.$suremac2d->{_vmaxu};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' vmaxu='.$suremac2d->{_vmaxu};

	} else { 
		print("suremac2d, vmaxu, missing vmaxu,\n");
	 }
 }


=head2 sub w 


=cut

 sub w {

	my ( $self,$w )		= @_;
	if ( $w ne $empty_string ) {

		$suremac2d->{_w}		= $w;
		$suremac2d->{_note}		= $suremac2d->{_note}.' w='.$suremac2d->{_w};
		$suremac2d->{_Step}		= $suremac2d->{_Step}.' w='.$suremac2d->{_w};

	} else { 
		print("suremac2d, w, missing w,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 33;

    return($max_index);
}
 
 
1;
