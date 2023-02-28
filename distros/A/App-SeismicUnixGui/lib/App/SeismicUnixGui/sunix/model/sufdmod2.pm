package App::SeismicUnixGui::sunix::model::sufdmod2;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUFDMOD2 - Finite-Difference MODeling (2nd order) for acoustic wave equation
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUFDMOD2 - Finite-Difference MODeling (2nd order) for acoustic wave equation

 sufdmod2 <vfile >wfile nx= nz= tmax= xs= zs= [optional parameters]	

 Required Parameters:							
 <vfile		  file containing velocity[nx][nz]
SeismicUnixGui: data_in  suffix_type= bin
 
 >wfile	file containing waves[nx][nz] for time steps
SeismicUnixGui: data_out suffix_type= bin
 
 nx=			number of x samples (2nd dimension)		
 nz=			number of z samples (1st dimension)		
 xs=			x coordinates of source, or, alternatively, the name
			of a file that contains the x- and z-coordinates,
			with the number of pairs as the first record and
			the actual pairs of (x,z) locations following.  
 zs=			z coordinates of source				
 tmax=			maximum time					

 Optional Parameters:							
 sstrength=1.0		strength of source				
 pw=0			use point or extended source geometry parameters
 			=1  use horizontal plane wave source 		
 pwt=20		amp taper on ends of line src (in grid points)  
 mono=0		use ricker wavelet as source function 		
 			=1  use single frequency src (freq=2*fpeak)	
 nt=1+tmax/dt		number of time samples (dt determined for stability)
 mt=1			number of time steps (dt) per output time step	

 dx=1.0		x sampling interval				
 fx=0.0		first x sample					
 dz=1.0		z sampling interval				
 fz=0.0		first z sample					

 fmax = vmin/(10.0*h)	maximum frequency in source 			
 fpeak=0.5*fmax	peak frequency in ricker wavelet		

 dfile=		input file containing density[nx][nz]		
 vsx=			x coordinate of vertical line of seismograms	
 hsz=			z coordinate of horizontal line of seismograms	
 vsfile=		output file for vertical line of seismograms[nz][nt]
 SeismicUnixGui: vsfile goes to $DATA_SEIMICS_BIN
 	
 hsfile=		output file for horizontal line of seismograms[nx][nt]
  SeismicUnixGui: hsfile goes to $DATA_SEIMICS_BIN
 	
 ssfile=		output file for source point seismograms[nt]
 SeismicUnixGui:  ssfile goes to $DATA_SEIMICS_BIN
 	
 verbose=0		=1 for diagnostic messages, =2 for more		
 abs=1,1,1,1		absorbing boundary conditions on top,left,bottom,right
			sides of the model. 				
 			=0,1,1,1 for free surface condition on the top	

 Notes:								

 This program uses the traditional explicit second order differencing	
 method. 								



 Authors:  CWP:Dave Hale
           CWP:modified for SU by John Stockwell, 1993.
           U Houston: added plane wave and monochromatic wave 
                        source options.  Chris Liner, 2010


 Trace header fields set: sx, gx, ns, delrt, tracl, tracr, offset, d1, d2,
                          sdepth, trid

 Modifications: Tony Kocurko (TK:)
                Memorial University in Newfoundland and Labrador
                - Allow user to supply the name of a file containing
                  shot point locations, rather than supplying them
                  as values to the xs= and zs= command line arguments.
                - Correct the calculation of izs[is].

 Technical reference:
 Kelly, K. R., R. W. Ward, S. Treitel, and R. M. Alford (1976),
 Synthetic Seismograms: A finite-difference approach, 
 Geophysics, Vol. 41. No. I (February, 1976), p. 2-27.


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sufdmod2 = {
	_abs       => '',
	_dfile     => '',
	_dx        => '',
	_dz        => '',
	_fmax      => '',
	_fpeak     => '',
	_freq      => '',
	_fx        => '',
	_fz        => '',
	_hsfile    => '',
	_hsz       => '',
	_mono      => '',
	_mt        => '',
	_nt        => '',
	_nx        => '',
	_nz        => '',
	_pw        => '',
	_pwt       => '',
	_ssfile    => '',
	_sstrength => '',
	_tmax      => '',
	_verbose   => '',
	_vsfile    => '',
	_vsx       => '',
	_xs        => '',
	_zs        => '',
	_Step      => '',
	_note      => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$sufdmod2->{_Step} = 'sufdmod2' . $sufdmod2->{_Step};
	return ( $sufdmod2->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$sufdmod2->{_note} = 'sufdmod2' . $sufdmod2->{_note};
	return ( $sufdmod2->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$sufdmod2->{_abs}       = '';
	$sufdmod2->{_dfile}     = '';
	$sufdmod2->{_dx}        = '';
	$sufdmod2->{_dz}        = '';
	$sufdmod2->{_fmax}      = '';
	$sufdmod2->{_fpeak}     = '';
	$sufdmod2->{_freq}      = '';
	$sufdmod2->{_fx}        = '';
	$sufdmod2->{_fz}        = '';
	$sufdmod2->{_hsfile}    = '';
	$sufdmod2->{_hsz}       = '';
	$sufdmod2->{_mono}      = '';
	$sufdmod2->{_mt}        = '';
	$sufdmod2->{_nt}        = '';
	$sufdmod2->{_nx}        = '';
	$sufdmod2->{_nz}        = '';
	$sufdmod2->{_pw}        = '';
	$sufdmod2->{_pwt}       = '';
	$sufdmod2->{_ssfile}    = '';
	$sufdmod2->{_sstrength} = '';
	$sufdmod2->{_tmax}      = '';
	$sufdmod2->{_verbose}   = '';
	$sufdmod2->{_vsfile}    = '';
	$sufdmod2->{_vsx}       = '';
	$sufdmod2->{_xs}        = '';
	$sufdmod2->{_zs}        = '';
	$sufdmod2->{_Step}      = '';
	$sufdmod2->{_note}      = '';
}

=head2 sub abs 


=cut

sub abs {

	my ( $self, $abs ) = @_;
	if ( $abs ne $empty_string ) {

		$sufdmod2->{_abs}  = $abs;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' abs=' . $sufdmod2->{_abs};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' abs=' . $sufdmod2->{_abs};

	}
	else {
		print("sufdmod2, abs, missing abs,\n");
	}
}

=head2 sub boundary_conditions 


=cut

sub boundary_conditions {

	my ( $self, $abs ) = @_;
	if ( $abs ne $empty_string ) {

		$sufdmod2->{_abs}  = $abs;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' abs=' . $sufdmod2->{_abs};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' abs=' . $sufdmod2->{_abs};

	}
	else {
		print("sufdmod2, boundary_conditions, missing abs,\n");
	}
}

=head2 sub dfile 


=cut

sub dfile {

	my ( $self, $dfile ) = @_;
	if ( $dfile ne $empty_string ) {

		$sufdmod2->{_dfile} = $dfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' dfile=' . $sufdmod2->{_dfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' dfile=' . $sufdmod2->{_dfile};

	}
	else {
		print("sufdmod2, dfile, missing dfile,\n");
	}
}

=head2 sub dx 


=cut

sub dx {

	my ( $self, $dx ) = @_;
	if ( $dx ne $empty_string ) {

		$sufdmod2->{_dx}   = $dx;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' dx=' . $sufdmod2->{_dx};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' dx=' . $sufdmod2->{_dx};

	}
	else {
		print("sufdmod2, dx, missing dx,\n");
	}
}

=head2 sub dz 


=cut

sub dz {

	my ( $self, $dz ) = @_;
	if ( $dz ne $empty_string ) {

		$sufdmod2->{_dz}   = $dz;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' dz=' . $sufdmod2->{_dz};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' dz=' . $sufdmod2->{_dz};

	}
	else {
		print("sufdmod2, dz, missing dz,\n");
	}
}

=head2 sub fmax 


=cut

sub fmax {

	my ( $self, $fmax ) = @_;
	if ( $fmax ne $empty_string ) {

		$sufdmod2->{_fmax} = $fmax;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' fmax=' . $sufdmod2->{_fmax};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' fmax=' . $sufdmod2->{_fmax};

	}
	else {
		print("sufdmod2, fmax, missing fmax,\n");
	}
}

=head2 sub fpeak 


=cut

sub fpeak {

	my ( $self, $fpeak ) = @_;
	if ( $fpeak ne $empty_string ) {

		$sufdmod2->{_fpeak} = $fpeak;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' fpeak=' . $sufdmod2->{_fpeak};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' fpeak=' . $sufdmod2->{_fpeak};

	}
	else {
		print("sufdmod2, fpeak, missing fpeak,\n");
	}
}

=head2 sub freq 


=cut

sub freq {

	my ( $self, $freq ) = @_;
	if ( $freq ne $empty_string ) {

		$sufdmod2->{_freq} = $freq;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' freq=' . $sufdmod2->{_freq};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' freq=' . $sufdmod2->{_freq};

	}
	else {
		print("sufdmod2, freq, missing freq,\n");
	}
}

=head2 sub fx 


=cut

sub fx {

	my ( $self, $fx ) = @_;
	if ( $fx ne $empty_string ) {

		$sufdmod2->{_fx}   = $fx;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' fx=' . $sufdmod2->{_fx};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' fx=' . $sufdmod2->{_fx};

	}
	else {
		print("sufdmod2, fx, missing fx,\n");
	}
}

=head2 sub fz 


=cut

sub fz {

	my ( $self, $fz ) = @_;
	if ( $fz ne $empty_string ) {

		$sufdmod2->{_fz}   = $fz;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' fz=' . $sufdmod2->{_fz};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' fz=' . $sufdmod2->{_fz};

	}
	else {
		print("sufdmod2, fz, missing fz,\n");
	}
}

=head2 sub hsfile 


=cut

sub hsfile {

	my ( $self, $hsfile ) = @_;
	if ( $hsfile ne $empty_string ) {

		$sufdmod2->{_hsfile} = $hsfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' hsfile=' . $sufdmod2->{_hsfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' hsfile=' . $sufdmod2->{_hsfile};

	}
	else {
		print("sufdmod2, hsfile, missing hsfile,\n");
	}
}

=head2 sub hsfile_out 


=cut

sub hsfile_out {

	my ( $self, $hsfile ) = @_;
	if ( $hsfile ne $empty_string ) {

		$sufdmod2->{_hsfile} = $hsfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' hsfile=' . $sufdmod2->{_hsfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' hsfile=' . $sufdmod2->{_hsfile};

	}
	else {
		print("sufdmod2, hsfile_out, missing hsfile,\n");
	}
}

=head2 sub hsz 


=cut

sub hsz {

	my ( $self, $hsz ) = @_;
	if ( $hsz ne $empty_string ) {

		$sufdmod2->{_hsz}  = $hsz;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' hsz=' . $sufdmod2->{_hsz};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' hsz=' . $sufdmod2->{_hsz};

	}
	else {
		print("sufdmod2, hsz, missing hsz,\n");
	}
}

=head2 sub mono 


=cut

sub mono {

	my ( $self, $mono ) = @_;
	if ( $mono ne $empty_string ) {

		$sufdmod2->{_mono} = $mono;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' mono=' . $sufdmod2->{_mono};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' mono=' . $sufdmod2->{_mono};

	}
	else {
		print("sufdmod2, mono, missing mono,\n");
	}
}

=head2 sub mt 


=cut

sub mt {

	my ( $self, $mt ) = @_;
	if ( $mt ne $empty_string ) {

		$sufdmod2->{_mt}   = $mt;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' mt=' . $sufdmod2->{_mt};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' mt=' . $sufdmod2->{_mt};

	}
	else {
		print("sufdmod2, mt, missing mt,\n");
	}
}

=head2 sub nt 


=cut

sub nt {

	my ( $self, $nt ) = @_;
	if ( $nt ne $empty_string ) {

		$sufdmod2->{_nt}   = $nt;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' nt=' . $sufdmod2->{_nt};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' nt=' . $sufdmod2->{_nt};

	}
	else {
		print("sufdmod2, nt, missing nt,\n");
	}
}

=head2 sub nx 


=cut

sub nx {

	my ( $self, $nx ) = @_;
	if ( $nx ne $empty_string ) {

		$sufdmod2->{_nx}   = $nx;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' nx=' . $sufdmod2->{_nx};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' nx=' . $sufdmod2->{_nx};

	}
	else {
		print("sufdmod2, nx, missing nx,\n");
	}
}

=head2 sub nz 


=cut

sub nz {

	my ( $self, $nz ) = @_;
	if ( $nz ne $empty_string ) {

		$sufdmod2->{_nz}   = $nz;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' nz=' . $sufdmod2->{_nz};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' nz=' . $sufdmod2->{_nz};

	}
	else {
		print("sufdmod2, nz, missing nz,\n");
	}
}

=head2 sub pw 


=cut

sub pw {

	my ( $self, $pw ) = @_;
	if ( $pw ne $empty_string ) {

		$sufdmod2->{_pw}   = $pw;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' pw=' . $sufdmod2->{_pw};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' pw=' . $sufdmod2->{_pw};

	}
	else {
		print("sufdmod2, pw, missing pw,\n");
	}
}

=head2 sub pwt 


=cut

sub pwt {

	my ( $self, $pwt ) = @_;
	if ( $pwt ne $empty_string ) {

		$sufdmod2->{_pwt}  = $pwt;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' pwt=' . $sufdmod2->{_pwt};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' pwt=' . $sufdmod2->{_pwt};

	}
	else {
		print("sufdmod2, pwt, missing pwt,\n");
	}
}

=head2 sub seismogram_out 


=cut

sub source_seismogram_out {

	my ( $self, $ssfile ) = @_;
	if ( $ssfile ne $empty_string ) {

		$sufdmod2->{_ssfile} = $ssfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' ssfile=' . $sufdmod2->{_ssfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' ssfile=' . $sufdmod2->{_ssfile};

	}
	else {
		print("sufdmod2, source_seismogram_out, missing ssfile,\n");
	}
}

=head2 sub ssfile 


=cut

sub ssfile {

	my ( $self, $ssfile ) = @_;
	if ( $ssfile ne $empty_string ) {

		$sufdmod2->{_ssfile} = $ssfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' ssfile=' . $sufdmod2->{_ssfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' ssfile=' . $sufdmod2->{_ssfile};

	}
	else {
		print("sufdmod2, ssfile, missing ssfile,\n");
	}
}

=head2 sub sstrength 


=cut

sub sstrength {

	my ( $self, $sstrength ) = @_;
	if ( $sstrength ne $empty_string ) {

		$sufdmod2->{_sstrength} = $sstrength;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' sstrength=' . $sufdmod2->{_sstrength};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' sstrength=' . $sufdmod2->{_sstrength};

	}
	else {
		print("sufdmod2, sstrength, missing sstrength,\n");
	}
}

=head2 sub tmax 


=cut

sub tmax {

	my ( $self, $tmax ) = @_;
	if ( $tmax ne $empty_string ) {
		
		$sufdmod2->{_tmax} = $tmax;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' tmax=' . $sufdmod2->{_tmax};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' tmax=' . $sufdmod2->{_tmax};

	}
	else {
		print("sufdmod2, tmax, missing tmax,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$sufdmod2->{_verbose} = $verbose;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' verbose=' . $sufdmod2->{_verbose};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' verbose=' . $sufdmod2->{_verbose};

	}
	else {
		print("sufdmod2, verbose, missing verbose,\n");
	}
}

=head2 sub vsfile 


=cut

sub vsfile {

	my ( $self, $vsfile ) = @_;
	if ( $vsfile ne $empty_string ) {

		$sufdmod2->{_vsfile} = $vsfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' vsfile=' . $sufdmod2->{_vsfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' vsfile=' . $sufdmod2->{_vsfile};

	}
	else {
		print("sufdmod2, vsfile, missing vsfile,\n");
	}
}

=head2 sub vsfile_out 


=cut

sub vsfile_out {

	my ( $self, $vsfile ) = @_;
	if ( $vsfile ne $empty_string ) {

		$sufdmod2->{_vsfile} = $vsfile;
		$sufdmod2->{_note} =
			$sufdmod2->{_note} . ' vsfile=' . $sufdmod2->{_vsfile};
		$sufdmod2->{_Step} =
			$sufdmod2->{_Step} . ' vsfile=' . $sufdmod2->{_vsfile};

	}
	else {
		print("sufdmod2, vsfile_out, missing vsfile,\n");
	}
}

=head2 sub vsx 


=cut

sub vsx {

	my ( $self, $vsx ) = @_;
	if ( $vsx ne $empty_string ) {

		$sufdmod2->{_vsx}  = $vsx;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' vsx=' . $sufdmod2->{_vsx};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' vsx=' . $sufdmod2->{_vsx};

	}
	else {
		print("sufdmod2, vsx, missing vsx,\n");
	}
}

=head2 sub xs 


=cut

sub xs {

	my ( $self, $xs ) = @_;
	if ( $xs ne $empty_string ) {

		$sufdmod2->{_xs}   = $xs;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' xs=' . $sufdmod2->{_xs};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' xs=' . $sufdmod2->{_xs};

	}
	else {
		print("sufdmod2, xs, missing xs,\n");
	}
}

=head2 sub zs 


=cut

sub zs {

	my ( $self, $zs ) = @_;
	if ( $zs ne $empty_string ) {

		$sufdmod2->{_zs}   = $zs;
		$sufdmod2->{_note} = $sufdmod2->{_note} . ' zs=' . $sufdmod2->{_zs};
		$sufdmod2->{_Step} = $sufdmod2->{_Step} . ' zs=' . $sufdmod2->{_zs};

	}
	else {
		print("sufdmod2, zs, missing zs,\n");
	}
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 24;

	return ($max_index);
}

1;
