package App::SeismicUnixGui::sunix::model::suremel2dan;

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
 SUREMEL2DAN - Elastic anisotropic 2D Fourier method modeling with high 

               accuracy Rapid Expansion Method (REM) time integration   



 suremel2dan [parameters]                                               



 Required parameters:                                                   



 nx=         number of grid points in horizontal direction              

 nz=         number of grid points in vertical direction                

 nt=         number of time samples                                     

 dx=         spatial increment in horizontal direction                  

 dz=         spatial increment in vertical direction                    

 dt=         time sample interval in seconds                            

 isx=        grid point # of horizontal source positions                

 isz=        grid point # of vertical source positions                  

 styp=       source types (pressure, shear, single forces)              

 samp=       amplitudes of sources                                      

 amode=      0: isotropic,  1: anisotropic                              

 vmax=       global maximum velocity (only if amode=1)                  

 vmin=       global minimum velocity (only if amode=1)                  



 Optional parameters:                                                   

 fx=0.0      first horizontal coordinate                                

 fz=0.0      first vertical coordinate                                  

 irx=        horizontal grid point # of vertical receiver lines         

 irz=        vertical grid point # of horizontal receiver lines         

 rxtyp=      types of horizontal receiver lines                         

 rztyp=      types of vertical receivers lines                          

 sntyp=      types of snapshots                                         

             0: P,  1: S,  2: UX,  3: UZ                                

 w=0.1       width of spatial source distribution (see notes)           

 sflag=2     source time function                                       

             0: user supplied source function                           

             1: impulse (spike at t=0)                                  

             2: Ricker wavelet                                          

 fmax=       maximum frequency of Ricker (default) wavelet              

 amps=1.0    amplitudes of sources                                      

 prec=0      1: precompute Bessel coefficients b_k (see notes)          

             2: use precomputed Bessel coefficients b_k                 

 vmaxu=      user-defined maximum velocity                              

 dtsnap=0.0  time interval in seconds of wave field snapshots           

 iabso=1     apply absorbing boundary conditions (0: none)              

 abso=0.1    damping parameter for absorbing boundaries                 

 nbwx=20     horizontal width of absorbing boundary                     

 nbwz=20     vertical width of absorbing boundary                       

 verbose=0   1: show parameters used                                    

             2: print maximum amplitude at every expansion term         



 c11file=c11       c11 filename                                         

 c13file=c13       c13 filename                                         

 c15file=c15       c15 filename                                         

 c33file=c33       c33 filename                                         

 c35file=c35       c35 filename                                         

 c55file=c55       c55 filename                                         

 vpfile=vp         P-velocity filename                                  

 vsfile=vs         S-velocity filename                                  

 densfile=dens     density filename                                     



 sname=wavelet.su  user supplied source time function filename          



 Basenames of seismogram and snapshot files:                            

 xsect=xsect_     x-direction section files basename                    

 zsect=zsect_     z-direction section files basename                    

 snap=snap_       snapshot files basename                               



 jpfile=stderr        diagnostic output                                 



 Notes:                                                                 

  0. The combination of the Fourier method with REM time integration    

     allows the computation of synthetic seismograms which are free     

     of numerical grid dispersion. REM has no restriction on the        

     time step size dt. The Fourier method requires at least two        

     grid points per shortest wavelength.                               

  1. nx and nz must be valid numbers for pfafft transform lengths.      

     nx and nz must be odd numbers. For valid numbers see e.g.          

     numbers in structure 'nctab' in source file                        

     $CWPROOT/src/cwp/lib/pfafft.c.                                     

  2. Velocities and densities are stored as plain C style files         

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

  6. If source is not single force (i.e. pressure or shear source)      

     it should be not a spike in space; the parameter w determines      

     at which distance (in grid points) from the source's center        

     the Gaussian weight decays to 10 percent of its maximum.           

     w=2 may be a reasonable choice; however, the waveform will be      

     distorted.                                                         

  7. Horizontal and vertical receiver line sections are written to      

     separate files. Each file can hold more than one line.             

  8. Parameter vmaxu may be enlarged if the modeling run becomes        

     unstable. This happens if the largest eigenvalue of the modeling   

     operator L is larger than estimated from the largest velocity.     

  9. Bessel coefficients can be precomputed (prec=1) and stored on      

     disk to save CPU time when several shots need to be run.           

     In this case computation of Bessel coefficients can be skipped     

     and read from disk file for reuse (prec=2).                        

     For reuse of Bessel coefficients the user may need to define       

     the overall maximum velocity (vmaxu).                              

 10. If snapshots are not required, a spike source (sflag=1) may be     

     applied and the resulting impulse response seismograms can be      

     convolved later with a desired wavelet.                            

 11. Output is written to SU style files.                               ", 

     Basenames of seismogram and snapshot output files will be          

     extended by the type of the data (p, s, ux, or uz).                

     Additionally seismogram files will be consecutively numbered.      



 Caveat:                                                                

     Time sections and snapshots are kept entirely in memory during     

     run time. Therefore, lots of time section and snapshots may        

     eat up a large amount of memory.                                   

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

my $suremel2dan			= {
	_abso					=> '',
	_amode					=> '',
	_amps					=> '',
	_c11file					=> '',
	_c13file					=> '',
	_c15file					=> '',
	_c33file					=> '',
	_c35file					=> '',
	_c55file					=> '',
	_densfile					=> '',
	_dt					=> '',
	_dtsnap					=> '',
	_dx					=> '',
	_dz					=> '',
	_fmax					=> '',
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
	_prec					=> '',
	_rxtyp					=> '',
	_rztyp					=> '',
	_samp					=> '',
	_sflag					=> '',
	_sname					=> '',
	_snap					=> '',
	_sntyp					=> '',
	_styp					=> '',
	_t					=> '',
	_verbose					=> '',
	_vmax					=> '',
	_vmaxu					=> '',
	_vmin					=> '',
	_vpfile					=> '',
	_vsfile					=> '',
	_w					=> '',
	_xsect					=> '',
	_zsect					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suremel2dan->{_Step}     = 'suremel2dan'.$suremel2dan->{_Step};
	return ( $suremel2dan->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suremel2dan->{_note}     = 'suremel2dan'.$suremel2dan->{_note};
	return ( $suremel2dan->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suremel2dan->{_abso}			= '';
		$suremel2dan->{_amode}			= '';
		$suremel2dan->{_amps}			= '';
		$suremel2dan->{_c11file}			= '';
		$suremel2dan->{_c13file}			= '';
		$suremel2dan->{_c15file}			= '';
		$suremel2dan->{_c33file}			= '';
		$suremel2dan->{_c35file}			= '';
		$suremel2dan->{_c55file}			= '';
		$suremel2dan->{_densfile}			= '';
		$suremel2dan->{_dt}			= '';
		$suremel2dan->{_dtsnap}			= '';
		$suremel2dan->{_dx}			= '';
		$suremel2dan->{_dz}			= '';
		$suremel2dan->{_fmax}			= '';
		$suremel2dan->{_fx}			= '';
		$suremel2dan->{_fz}			= '';
		$suremel2dan->{_iabso}			= '';
		$suremel2dan->{_irx}			= '';
		$suremel2dan->{_irz}			= '';
		$suremel2dan->{_isx}			= '';
		$suremel2dan->{_isz}			= '';
		$suremel2dan->{_jpfile}			= '';
		$suremel2dan->{_nbwx}			= '';
		$suremel2dan->{_nbwz}			= '';
		$suremel2dan->{_nt}			= '';
		$suremel2dan->{_nx}			= '';
		$suremel2dan->{_nz}			= '';
		$suremel2dan->{_prec}			= '';
		$suremel2dan->{_rxtyp}			= '';
		$suremel2dan->{_rztyp}			= '';
		$suremel2dan->{_samp}			= '';
		$suremel2dan->{_sflag}			= '';
		$suremel2dan->{_sname}			= '';
		$suremel2dan->{_snap}			= '';
		$suremel2dan->{_sntyp}			= '';
		$suremel2dan->{_styp}			= '';
		$suremel2dan->{_t}			= '';
		$suremel2dan->{_verbose}			= '';
		$suremel2dan->{_vmax}			= '';
		$suremel2dan->{_vmaxu}			= '';
		$suremel2dan->{_vmin}			= '';
		$suremel2dan->{_vpfile}			= '';
		$suremel2dan->{_vsfile}			= '';
		$suremel2dan->{_w}			= '';
		$suremel2dan->{_xsect}			= '';
		$suremel2dan->{_zsect}			= '';
		$suremel2dan->{_Step}			= '';
		$suremel2dan->{_note}			= '';
 }


=head2 sub abso 


=cut

 sub abso {

	my ( $self,$abso )		= @_;
	if ( $abso ne $empty_string ) {

		$suremel2dan->{_abso}		= $abso;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' abso='.$suremel2dan->{_abso};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' abso='.$suremel2dan->{_abso};

	} else { 
		print("suremel2dan, abso, missing abso,\n");
	 }
 }


=head2 sub amode 


=cut

 sub amode {

	my ( $self,$amode )		= @_;
	if ( $amode ne $empty_string ) {

		$suremel2dan->{_amode}		= $amode;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' amode='.$suremel2dan->{_amode};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' amode='.$suremel2dan->{_amode};

	} else { 
		print("suremel2dan, amode, missing amode,\n");
	 }
 }


=head2 sub amps 


=cut

 sub amps {

	my ( $self,$amps )		= @_;
	if ( $amps ne $empty_string ) {

		$suremel2dan->{_amps}		= $amps;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' amps='.$suremel2dan->{_amps};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' amps='.$suremel2dan->{_amps};

	} else { 
		print("suremel2dan, amps, missing amps,\n");
	 }
 }


=head2 sub c11file 


=cut

 sub c11file {

	my ( $self,$c11file )		= @_;
	if ( $c11file ne $empty_string ) {

		$suremel2dan->{_c11file}		= $c11file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c11file='.$suremel2dan->{_c11file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c11file='.$suremel2dan->{_c11file};

	} else { 
		print("suremel2dan, c11file, missing c11file,\n");
	 }
 }


=head2 sub c13file 


=cut

 sub c13file {

	my ( $self,$c13file )		= @_;
	if ( $c13file ne $empty_string ) {

		$suremel2dan->{_c13file}		= $c13file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c13file='.$suremel2dan->{_c13file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c13file='.$suremel2dan->{_c13file};

	} else { 
		print("suremel2dan, c13file, missing c13file,\n");
	 }
 }


=head2 sub c15file 


=cut

 sub c15file {

	my ( $self,$c15file )		= @_;
	if ( $c15file ne $empty_string ) {

		$suremel2dan->{_c15file}		= $c15file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c15file='.$suremel2dan->{_c15file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c15file='.$suremel2dan->{_c15file};

	} else { 
		print("suremel2dan, c15file, missing c15file,\n");
	 }
 }


=head2 sub c33file 


=cut

 sub c33file {

	my ( $self,$c33file )		= @_;
	if ( $c33file ne $empty_string ) {

		$suremel2dan->{_c33file}		= $c33file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c33file='.$suremel2dan->{_c33file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c33file='.$suremel2dan->{_c33file};

	} else { 
		print("suremel2dan, c33file, missing c33file,\n");
	 }
 }


=head2 sub c35file 


=cut

 sub c35file {

	my ( $self,$c35file )		= @_;
	if ( $c35file ne $empty_string ) {

		$suremel2dan->{_c35file}		= $c35file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c35file='.$suremel2dan->{_c35file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c35file='.$suremel2dan->{_c35file};

	} else { 
		print("suremel2dan, c35file, missing c35file,\n");
	 }
 }


=head2 sub c55file 


=cut

 sub c55file {

	my ( $self,$c55file )		= @_;
	if ( $c55file ne $empty_string ) {

		$suremel2dan->{_c55file}		= $c55file;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' c55file='.$suremel2dan->{_c55file};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' c55file='.$suremel2dan->{_c55file};

	} else { 
		print("suremel2dan, c55file, missing c55file,\n");
	 }
 }


=head2 sub densfile 


=cut

 sub densfile {

	my ( $self,$densfile )		= @_;
	if ( $densfile ne $empty_string ) {

		$suremel2dan->{_densfile}		= $densfile;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' densfile='.$suremel2dan->{_densfile};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' densfile='.$suremel2dan->{_densfile};

	} else { 
		print("suremel2dan, densfile, missing densfile,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suremel2dan->{_dt}		= $dt;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' dt='.$suremel2dan->{_dt};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' dt='.$suremel2dan->{_dt};

	} else { 
		print("suremel2dan, dt, missing dt,\n");
	 }
 }


=head2 sub dtsnap 


=cut

 sub dtsnap {

	my ( $self,$dtsnap )		= @_;
	if ( $dtsnap ne $empty_string ) {

		$suremel2dan->{_dtsnap}		= $dtsnap;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' dtsnap='.$suremel2dan->{_dtsnap};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' dtsnap='.$suremel2dan->{_dtsnap};

	} else { 
		print("suremel2dan, dtsnap, missing dtsnap,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suremel2dan->{_dx}		= $dx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' dx='.$suremel2dan->{_dx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' dx='.$suremel2dan->{_dx};

	} else { 
		print("suremel2dan, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$suremel2dan->{_dz}		= $dz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' dz='.$suremel2dan->{_dz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' dz='.$suremel2dan->{_dz};

	} else { 
		print("suremel2dan, dz, missing dz,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$suremel2dan->{_fmax}		= $fmax;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' fmax='.$suremel2dan->{_fmax};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' fmax='.$suremel2dan->{_fmax};

	} else { 
		print("suremel2dan, fmax, missing fmax,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$suremel2dan->{_fx}		= $fx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' fx='.$suremel2dan->{_fx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' fx='.$suremel2dan->{_fx};

	} else { 
		print("suremel2dan, fx, missing fx,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$suremel2dan->{_fz}		= $fz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' fz='.$suremel2dan->{_fz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' fz='.$suremel2dan->{_fz};

	} else { 
		print("suremel2dan, fz, missing fz,\n");
	 }
 }


=head2 sub iabso 


=cut

 sub iabso {

	my ( $self,$iabso )		= @_;
	if ( $iabso ne $empty_string ) {

		$suremel2dan->{_iabso}		= $iabso;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' iabso='.$suremel2dan->{_iabso};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' iabso='.$suremel2dan->{_iabso};

	} else { 
		print("suremel2dan, iabso, missing iabso,\n");
	 }
 }


=head2 sub irx 


=cut

 sub irx {

	my ( $self,$irx )		= @_;
	if ( $irx ne $empty_string ) {

		$suremel2dan->{_irx}		= $irx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' irx='.$suremel2dan->{_irx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' irx='.$suremel2dan->{_irx};

	} else { 
		print("suremel2dan, irx, missing irx,\n");
	 }
 }


=head2 sub irz 


=cut

 sub irz {

	my ( $self,$irz )		= @_;
	if ( $irz ne $empty_string ) {

		$suremel2dan->{_irz}		= $irz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' irz='.$suremel2dan->{_irz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' irz='.$suremel2dan->{_irz};

	} else { 
		print("suremel2dan, irz, missing irz,\n");
	 }
 }


=head2 sub isx 


=cut

 sub isx {

	my ( $self,$isx )		= @_;
	if ( $isx ne $empty_string ) {

		$suremel2dan->{_isx}		= $isx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' isx='.$suremel2dan->{_isx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' isx='.$suremel2dan->{_isx};

	} else { 
		print("suremel2dan, isx, missing isx,\n");
	 }
 }


=head2 sub isz 


=cut

 sub isz {

	my ( $self,$isz )		= @_;
	if ( $isz ne $empty_string ) {

		$suremel2dan->{_isz}		= $isz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' isz='.$suremel2dan->{_isz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' isz='.$suremel2dan->{_isz};

	} else { 
		print("suremel2dan, isz, missing isz,\n");
	 }
 }


=head2 sub jpfile 


=cut

 sub jpfile {

	my ( $self,$jpfile )		= @_;
	if ( $jpfile ne $empty_string ) {

		$suremel2dan->{_jpfile}		= $jpfile;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' jpfile='.$suremel2dan->{_jpfile};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' jpfile='.$suremel2dan->{_jpfile};

	} else { 
		print("suremel2dan, jpfile, missing jpfile,\n");
	 }
 }


=head2 sub nbwx 


=cut

 sub nbwx {

	my ( $self,$nbwx )		= @_;
	if ( $nbwx ne $empty_string ) {

		$suremel2dan->{_nbwx}		= $nbwx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' nbwx='.$suremel2dan->{_nbwx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' nbwx='.$suremel2dan->{_nbwx};

	} else { 
		print("suremel2dan, nbwx, missing nbwx,\n");
	 }
 }


=head2 sub nbwz 


=cut

 sub nbwz {

	my ( $self,$nbwz )		= @_;
	if ( $nbwz ne $empty_string ) {

		$suremel2dan->{_nbwz}		= $nbwz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' nbwz='.$suremel2dan->{_nbwz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' nbwz='.$suremel2dan->{_nbwz};

	} else { 
		print("suremel2dan, nbwz, missing nbwz,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suremel2dan->{_nt}		= $nt;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' nt='.$suremel2dan->{_nt};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' nt='.$suremel2dan->{_nt};

	} else { 
		print("suremel2dan, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$suremel2dan->{_nx}		= $nx;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' nx='.$suremel2dan->{_nx};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' nx='.$suremel2dan->{_nx};

	} else { 
		print("suremel2dan, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$suremel2dan->{_nz}		= $nz;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' nz='.$suremel2dan->{_nz};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' nz='.$suremel2dan->{_nz};

	} else { 
		print("suremel2dan, nz, missing nz,\n");
	 }
 }


=head2 sub prec 


=cut

 sub prec {

	my ( $self,$prec )		= @_;
	if ( $prec ne $empty_string ) {

		$suremel2dan->{_prec}		= $prec;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' prec='.$suremel2dan->{_prec};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' prec='.$suremel2dan->{_prec};

	} else { 
		print("suremel2dan, prec, missing prec,\n");
	 }
 }


=head2 sub rxtyp 


=cut

 sub rxtyp {

	my ( $self,$rxtyp )		= @_;
	if ( $rxtyp ne $empty_string ) {

		$suremel2dan->{_rxtyp}		= $rxtyp;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' rxtyp='.$suremel2dan->{_rxtyp};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' rxtyp='.$suremel2dan->{_rxtyp};

	} else { 
		print("suremel2dan, rxtyp, missing rxtyp,\n");
	 }
 }


=head2 sub rztyp 


=cut

 sub rztyp {

	my ( $self,$rztyp )		= @_;
	if ( $rztyp ne $empty_string ) {

		$suremel2dan->{_rztyp}		= $rztyp;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' rztyp='.$suremel2dan->{_rztyp};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' rztyp='.$suremel2dan->{_rztyp};

	} else { 
		print("suremel2dan, rztyp, missing rztyp,\n");
	 }
 }


=head2 sub samp 


=cut

 sub samp {

	my ( $self,$samp )		= @_;
	if ( $samp ne $empty_string ) {

		$suremel2dan->{_samp}		= $samp;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' samp='.$suremel2dan->{_samp};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' samp='.$suremel2dan->{_samp};

	} else { 
		print("suremel2dan, samp, missing samp,\n");
	 }
 }


=head2 sub sflag 


=cut

 sub sflag {

	my ( $self,$sflag )		= @_;
	if ( $sflag ne $empty_string ) {

		$suremel2dan->{_sflag}		= $sflag;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' sflag='.$suremel2dan->{_sflag};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' sflag='.$suremel2dan->{_sflag};

	} else { 
		print("suremel2dan, sflag, missing sflag,\n");
	 }
 }


=head2 sub sname 


=cut

 sub sname {

	my ( $self,$sname )		= @_;
	if ( $sname ne $empty_string ) {

		$suremel2dan->{_sname}		= $sname;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' sname='.$suremel2dan->{_sname};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' sname='.$suremel2dan->{_sname};

	} else { 
		print("suremel2dan, sname, missing sname,\n");
	 }
 }


=head2 sub snap 


=cut

 sub snap {

	my ( $self,$snap )		= @_;
	if ( $snap ne $empty_string ) {

		$suremel2dan->{_snap}		= $snap;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' snap='.$suremel2dan->{_snap};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' snap='.$suremel2dan->{_snap};

	} else { 
		print("suremel2dan, snap, missing snap,\n");
	 }
 }


=head2 sub sntyp 


=cut

 sub sntyp {

	my ( $self,$sntyp )		= @_;
	if ( $sntyp ne $empty_string ) {

		$suremel2dan->{_sntyp}		= $sntyp;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' sntyp='.$suremel2dan->{_sntyp};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' sntyp='.$suremel2dan->{_sntyp};

	} else { 
		print("suremel2dan, sntyp, missing sntyp,\n");
	 }
 }


=head2 sub styp 


=cut

 sub styp {

	my ( $self,$styp )		= @_;
	if ( $styp ne $empty_string ) {

		$suremel2dan->{_styp}		= $styp;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' styp='.$suremel2dan->{_styp};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' styp='.$suremel2dan->{_styp};

	} else { 
		print("suremel2dan, styp, missing styp,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$suremel2dan->{_t}		= $t;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' t='.$suremel2dan->{_t};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' t='.$suremel2dan->{_t};

	} else { 
		print("suremel2dan, t, missing t,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suremel2dan->{_verbose}		= $verbose;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' verbose='.$suremel2dan->{_verbose};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' verbose='.$suremel2dan->{_verbose};

	} else { 
		print("suremel2dan, verbose, missing verbose,\n");
	 }
 }


=head2 sub vmax 


=cut

 sub vmax {

	my ( $self,$vmax )		= @_;
	if ( $vmax ne $empty_string ) {

		$suremel2dan->{_vmax}		= $vmax;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' vmax='.$suremel2dan->{_vmax};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' vmax='.$suremel2dan->{_vmax};

	} else { 
		print("suremel2dan, vmax, missing vmax,\n");
	 }
 }


=head2 sub vmaxu 


=cut

 sub vmaxu {

	my ( $self,$vmaxu )		= @_;
	if ( $vmaxu ne $empty_string ) {

		$suremel2dan->{_vmaxu}		= $vmaxu;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' vmaxu='.$suremel2dan->{_vmaxu};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' vmaxu='.$suremel2dan->{_vmaxu};

	} else { 
		print("suremel2dan, vmaxu, missing vmaxu,\n");
	 }
 }


=head2 sub vmin 


=cut

 sub vmin {

	my ( $self,$vmin )		= @_;
	if ( $vmin ne $empty_string ) {

		$suremel2dan->{_vmin}		= $vmin;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' vmin='.$suremel2dan->{_vmin};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' vmin='.$suremel2dan->{_vmin};

	} else { 
		print("suremel2dan, vmin, missing vmin,\n");
	 }
 }


=head2 sub vpfile 


=cut

 sub vpfile {

	my ( $self,$vpfile )		= @_;
	if ( $vpfile ne $empty_string ) {

		$suremel2dan->{_vpfile}		= $vpfile;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' vpfile='.$suremel2dan->{_vpfile};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' vpfile='.$suremel2dan->{_vpfile};

	} else { 
		print("suremel2dan, vpfile, missing vpfile,\n");
	 }
 }


=head2 sub vsfile 


=cut

 sub vsfile {

	my ( $self,$vsfile )		= @_;
	if ( $vsfile ne $empty_string ) {

		$suremel2dan->{_vsfile}		= $vsfile;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' vsfile='.$suremel2dan->{_vsfile};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' vsfile='.$suremel2dan->{_vsfile};

	} else { 
		print("suremel2dan, vsfile, missing vsfile,\n");
	 }
 }


=head2 sub w 


=cut

 sub w {

	my ( $self,$w )		= @_;
	if ( $w ne $empty_string ) {

		$suremel2dan->{_w}		= $w;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' w='.$suremel2dan->{_w};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' w='.$suremel2dan->{_w};

	} else { 
		print("suremel2dan, w, missing w,\n");
	 }
 }


=head2 sub xsect 


=cut

 sub xsect {

	my ( $self,$xsect )		= @_;
	if ( $xsect ne $empty_string ) {

		$suremel2dan->{_xsect}		= $xsect;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' xsect='.$suremel2dan->{_xsect};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' xsect='.$suremel2dan->{_xsect};

	} else { 
		print("suremel2dan, xsect, missing xsect,\n");
	 }
 }


=head2 sub zsect 


=cut

 sub zsect {

	my ( $self,$zsect )		= @_;
	if ( $zsect ne $empty_string ) {

		$suremel2dan->{_zsect}		= $zsect;
		$suremel2dan->{_note}		= $suremel2dan->{_note}.' zsect='.$suremel2dan->{_zsect};
		$suremel2dan->{_Step}		= $suremel2dan->{_Step}.' zsect='.$suremel2dan->{_zsect};

	} else { 
		print("suremel2dan, zsect, missing zsect,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 47;

    return($max_index);
}
 
 
1;
