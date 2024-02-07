package App::SeismicUnixGui::sunix::migration::sumiggbzoan;

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
 SUMIGGBZOAN - MIGration via Gaussian beams ANisotropic media (P-wave)	



 sumiggbzoan <infile >outfile vfile= nt= nx= nz= [optional parameters]	



 Required Parameters:							

 a3333file=		name of file containing a3333(x,z)		

 nx=                    number of inline samples (traces)		

 nz=                    number of depth samples			



 Optional Parameters:							

 dt=tr.dt               time sampling interval				

 dx=tr.d2               inline sampling interval (trace spacing)	

 dz=1.0                 depth sampling interval			

 fmin=0.025/dt          minimum frequency				

 fmax=10*fmin           maximum frequency				

 amin=-amax             minimum emergence angle; must be > -90 degrees	

 amax=60                maximum emergence angle; must be < 90 degrees	

 bwh=0.5*vavg/fmin      beam half-width; vavg denotes average velocity	

 verbose=0		 silent, =1 chatty 				



 Files for general anisotropic parameters confined to a vertical plane:

 a1111file=		name of file containing a1111(x,z)		

 a1133file=          	name of file containing a1133(x,z)		

 a1313file=          	name of file containing a1313(x,z)		

 a1113file=          	name of file containing a1113(x,z)		

 a3313file=          	name of file containing a3313(x,z)		



 For transversely isotropic media Thomsen's parameters could be used:	

 deltafile=		name of file containing delta(x,z)		

 epsilonfile=		name of file containing epsilon(x,z)		

 a1313file=          	name of file containing a1313(x,z)		



 if anisotropy parameters are not given the program considers		", 

 the medium to be isotropic.						





 Credits:

	CWP: Tariq Alkhalifah,  based on MIGGBZO by Dave Hale

      CWP: repackaged as an SU program by John Stockwell, April 2006

      

   Technical Reference:



      Alkhailfah, T., 1993, Gaussian beam migration for

      anisotropic media: submitted to Geophysics.



	Cerveny, V., 1972, Seismic rays and ray intensities 

	in inhomogeneous anisotropic media: 

	Geophys. J. R. Astr. Soc., 29, 1--13.



	Hale, D., 1992, Migration by the Kirchhoff, 

	slant stack, and Gaussian beam methods:

      CWP,1992 Report 121, Colorado School of Mines.



	Hale, D., 1992, Computational Aspects of Gaussian

      Beam migration:

     	CWP,1992 Report 121, Colorado School of Mines.









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

my $sumiggbzoan			= {
	_a1111file					=> '',
	_a1113file					=> '',
	_a1133file					=> '',
	_a1313file					=> '',
	_a3313file					=> '',
	_a3333file					=> '',
	_amax					=> '',
	_amin					=> '',
	_bwh					=> '',
	_deltafile					=> '',
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_epsilonfile					=> '',
	_fmax					=> '',
	_fmin					=> '',
	_nx					=> '',
	_nz					=> '',
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

	$sumiggbzoan->{_Step}     = 'sumiggbzoan'.$sumiggbzoan->{_Step};
	return ( $sumiggbzoan->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumiggbzoan->{_note}     = 'sumiggbzoan'.$sumiggbzoan->{_note};
	return ( $sumiggbzoan->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumiggbzoan->{_a1111file}			= '';
		$sumiggbzoan->{_a1113file}			= '';
		$sumiggbzoan->{_a1133file}			= '';
		$sumiggbzoan->{_a1313file}			= '';
		$sumiggbzoan->{_a3313file}			= '';
		$sumiggbzoan->{_a3333file}			= '';
		$sumiggbzoan->{_amax}			= '';
		$sumiggbzoan->{_amin}			= '';
		$sumiggbzoan->{_bwh}			= '';
		$sumiggbzoan->{_deltafile}			= '';
		$sumiggbzoan->{_dt}			= '';
		$sumiggbzoan->{_dx}			= '';
		$sumiggbzoan->{_dz}			= '';
		$sumiggbzoan->{_epsilonfile}			= '';
		$sumiggbzoan->{_fmax}			= '';
		$sumiggbzoan->{_fmin}			= '';
		$sumiggbzoan->{_nx}			= '';
		$sumiggbzoan->{_nz}			= '';
		$sumiggbzoan->{_verbose}			= '';
		$sumiggbzoan->{_vfile}			= '';
		$sumiggbzoan->{_Step}			= '';
		$sumiggbzoan->{_note}			= '';
 }


=head2 sub a1111file 


=cut

 sub a1111file {

	my ( $self,$a1111file )		= @_;
	if ( $a1111file ne $empty_string ) {

		$sumiggbzoan->{_a1111file}		= $a1111file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a1111file='.$sumiggbzoan->{_a1111file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a1111file='.$sumiggbzoan->{_a1111file};

	} else { 
		print("sumiggbzoan, a1111file, missing a1111file,\n");
	 }
 }


=head2 sub a1113file 


=cut

 sub a1113file {

	my ( $self,$a1113file )		= @_;
	if ( $a1113file ne $empty_string ) {

		$sumiggbzoan->{_a1113file}		= $a1113file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a1113file='.$sumiggbzoan->{_a1113file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a1113file='.$sumiggbzoan->{_a1113file};

	} else { 
		print("sumiggbzoan, a1113file, missing a1113file,\n");
	 }
 }


=head2 sub a1133file 


=cut

 sub a1133file {

	my ( $self,$a1133file )		= @_;
	if ( $a1133file ne $empty_string ) {

		$sumiggbzoan->{_a1133file}		= $a1133file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a1133file='.$sumiggbzoan->{_a1133file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a1133file='.$sumiggbzoan->{_a1133file};

	} else { 
		print("sumiggbzoan, a1133file, missing a1133file,\n");
	 }
 }


=head2 sub a1313file 


=cut

 sub a1313file {

	my ( $self,$a1313file )		= @_;
	if ( $a1313file ne $empty_string ) {

		$sumiggbzoan->{_a1313file}		= $a1313file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a1313file='.$sumiggbzoan->{_a1313file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a1313file='.$sumiggbzoan->{_a1313file};

	} else { 
		print("sumiggbzoan, a1313file, missing a1313file,\n");
	 }
 }


=head2 sub a3313file 


=cut

 sub a3313file {

	my ( $self,$a3313file )		= @_;
	if ( $a3313file ne $empty_string ) {

		$sumiggbzoan->{_a3313file}		= $a3313file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a3313file='.$sumiggbzoan->{_a3313file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a3313file='.$sumiggbzoan->{_a3313file};

	} else { 
		print("sumiggbzoan, a3313file, missing a3313file,\n");
	 }
 }


=head2 sub a3333file 


=cut

 sub a3333file {

	my ( $self,$a3333file )		= @_;
	if ( $a3333file ne $empty_string ) {

		$sumiggbzoan->{_a3333file}		= $a3333file;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' a3333file='.$sumiggbzoan->{_a3333file};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' a3333file='.$sumiggbzoan->{_a3333file};

	} else { 
		print("sumiggbzoan, a3333file, missing a3333file,\n");
	 }
 }


=head2 sub amax 


=cut

 sub amax {

	my ( $self,$amax )		= @_;
	if ( $amax ne $empty_string ) {

		$sumiggbzoan->{_amax}		= $amax;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' amax='.$sumiggbzoan->{_amax};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' amax='.$sumiggbzoan->{_amax};

	} else { 
		print("sumiggbzoan, amax, missing amax,\n");
	 }
 }


=head2 sub amin 


=cut

 sub amin {

	my ( $self,$amin )		= @_;
	if ( $amin ne $empty_string ) {

		$sumiggbzoan->{_amin}		= $amin;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' amin='.$sumiggbzoan->{_amin};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' amin='.$sumiggbzoan->{_amin};

	} else { 
		print("sumiggbzoan, amin, missing amin,\n");
	 }
 }


=head2 sub bwh 


=cut

 sub bwh {

	my ( $self,$bwh )		= @_;
	if ( $bwh ne $empty_string ) {

		$sumiggbzoan->{_bwh}		= $bwh;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' bwh='.$sumiggbzoan->{_bwh};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' bwh='.$sumiggbzoan->{_bwh};

	} else { 
		print("sumiggbzoan, bwh, missing bwh,\n");
	 }
 }


=head2 sub deltafile 


=cut

 sub deltafile {

	my ( $self,$deltafile )		= @_;
	if ( $deltafile ne $empty_string ) {

		$sumiggbzoan->{_deltafile}		= $deltafile;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' deltafile='.$sumiggbzoan->{_deltafile};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' deltafile='.$sumiggbzoan->{_deltafile};

	} else { 
		print("sumiggbzoan, deltafile, missing deltafile,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumiggbzoan->{_dt}		= $dt;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' dt='.$sumiggbzoan->{_dt};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' dt='.$sumiggbzoan->{_dt};

	} else { 
		print("sumiggbzoan, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumiggbzoan->{_dx}		= $dx;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' dx='.$sumiggbzoan->{_dx};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' dx='.$sumiggbzoan->{_dx};

	} else { 
		print("sumiggbzoan, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumiggbzoan->{_dz}		= $dz;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' dz='.$sumiggbzoan->{_dz};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' dz='.$sumiggbzoan->{_dz};

	} else { 
		print("sumiggbzoan, dz, missing dz,\n");
	 }
 }


=head2 sub epsilonfile 


=cut

 sub epsilonfile {

	my ( $self,$epsilonfile )		= @_;
	if ( $epsilonfile ne $empty_string ) {

		$sumiggbzoan->{_epsilonfile}		= $epsilonfile;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' epsilonfile='.$sumiggbzoan->{_epsilonfile};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' epsilonfile='.$sumiggbzoan->{_epsilonfile};

	} else { 
		print("sumiggbzoan, epsilonfile, missing epsilonfile,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumiggbzoan->{_fmax}		= $fmax;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' fmax='.$sumiggbzoan->{_fmax};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' fmax='.$sumiggbzoan->{_fmax};

	} else { 
		print("sumiggbzoan, fmax, missing fmax,\n");
	 }
 }


=head2 sub fmin 


=cut

 sub fmin {

	my ( $self,$fmin )		= @_;
	if ( $fmin ne $empty_string ) {

		$sumiggbzoan->{_fmin}		= $fmin;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' fmin='.$sumiggbzoan->{_fmin};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' fmin='.$sumiggbzoan->{_fmin};

	} else { 
		print("sumiggbzoan, fmin, missing fmin,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$sumiggbzoan->{_nx}		= $nx;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' nx='.$sumiggbzoan->{_nx};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' nx='.$sumiggbzoan->{_nx};

	} else { 
		print("sumiggbzoan, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumiggbzoan->{_nz}		= $nz;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' nz='.$sumiggbzoan->{_nz};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' nz='.$sumiggbzoan->{_nz};

	} else { 
		print("sumiggbzoan, nz, missing nz,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumiggbzoan->{_verbose}		= $verbose;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' verbose='.$sumiggbzoan->{_verbose};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' verbose='.$sumiggbzoan->{_verbose};

	} else { 
		print("sumiggbzoan, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumiggbzoan->{_vfile}		= $vfile;
		$sumiggbzoan->{_note}		= $sumiggbzoan->{_note}.' vfile='.$sumiggbzoan->{_vfile};
		$sumiggbzoan->{_Step}		= $sumiggbzoan->{_Step}.' vfile='.$sumiggbzoan->{_vfile};

	} else { 
		print("sumiggbzoan, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 19;

    return($max_index);
}
 
 
1;
