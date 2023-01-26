package App::SeismicUnixGui::sunix::migration::sumigpreffd;

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
SUMIGPREFFD - The 2-D prestack common-shot Fourier finite-difference	

		depth  migration.					



  sumigpreffd <indata >outfile [parameters]				", 



 Required Parameters:							",  

 nxo=	   number of total horizontal output samples			

 nxshot=	number of shot gathers to be migrated			

 nz=		number of depth sapmles					

 dx=		horizontal sampling interval				

 dz=		depth sampling interval					

 vfile=	 velocity profile, it must be binary format.		

  

 Optional Parameters:							

 fmax=25	the peak frequency of Ricker wavelet used as source wavelet

 f1=5

 f2=10

 f3=40

 f4=50	frequencies to build a Hamming window	

 lpad=9999

 rpad=9999		number of zero traces padded on both	

				sides of depth section to determine the 

				migration aperature, the default	

				values are using the full aperature.	

 verbose=0		silent, =1 additional runtime information	

  

 Notes:								

 The input velocity file consists of C-style binary floats.		",  

 The structure of this file is vfile[iz][ix]. Note that this means that

 the x-direction is the fastest direction instead of z-direction! Such a

 structure is more convenient for the downward continuation type	

 migration algorithm than using z as fastest dimension as in other SU  ", 

 programs.								



 Because most of the tools in the SU package (such as  unif2, unisam2, ", 

 and makevel) produce output with the structure vfile[ix][iz], you will

 need to transpose the velocity files created by these programs. You may

 use the SU program \'transp\' in SU to transpose such files into the  

 required vfile[iz][ix] structure.					

 (In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]  		

 denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 programmers may expect.)						", 



 Also, sx must be monotonically increasing throughout the dataset, and 

 and gx must be monotonically increasing within a shot. You may resort 

 your data with \'susort\', accordingly.				



 The scalco header field is honored so this field must be set correctly.

 See selfdocs of \'susort\', \'suchw\'. Also:   sukeyword scalco	







 Credits: CWP, Baoniu Han, bhan@dix.mines.edu, April 19th, 1998



	  Modified: Chris Stolk, 11 Dec 2005, - changed data input

		    to remove erroneous time delay.

	  Modified: CWP, John Stockwell 26 Sept 2006 - replaced Han's

	  "goto-loop" with  "do { }while loops".

	  Fixed it so that sx, gx, and scalco are honored.







 Trace header fields accessed: ns, dt, delrt, d2

 Trace header fields modified: ns, dt, delrt





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

my $sumigpreffd			= {
	_dx					=> '',
	_dz					=> '',
	_f1					=> '',
	_f2					=> '',
	_f3					=> '',
	_f4					=> '',
	_fmax					=> '',
	_lpad					=> '',
	_nxo					=> '',
	_nxshot					=> '',
	_nz					=> '',
	_rpad					=> '',
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

	$sumigpreffd->{_Step}     = 'sumigpreffd'.$sumigpreffd->{_Step};
	return ( $sumigpreffd->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigpreffd->{_note}     = 'sumigpreffd'.$sumigpreffd->{_note};
	return ( $sumigpreffd->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigpreffd->{_dx}			= '';
		$sumigpreffd->{_dz}			= '';
		$sumigpreffd->{_f1}			= '';
		$sumigpreffd->{_f2}			= '';
		$sumigpreffd->{_f3}			= '';
		$sumigpreffd->{_f4}			= '';
		$sumigpreffd->{_fmax}			= '';
		$sumigpreffd->{_lpad}			= '';
		$sumigpreffd->{_nxo}			= '';
		$sumigpreffd->{_nxshot}			= '';
		$sumigpreffd->{_nz}			= '';
		$sumigpreffd->{_rpad}			= '';
		$sumigpreffd->{_verbose}			= '';
		$sumigpreffd->{_vfile}			= '';
		$sumigpreffd->{_Step}			= '';
		$sumigpreffd->{_note}			= '';
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigpreffd->{_dx}		= $dx;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' dx='.$sumigpreffd->{_dx};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' dx='.$sumigpreffd->{_dx};

	} else { 
		print("sumigpreffd, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigpreffd->{_dz}		= $dz;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' dz='.$sumigpreffd->{_dz};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' dz='.$sumigpreffd->{_dz};

	} else { 
		print("sumigpreffd, dz, missing dz,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$sumigpreffd->{_f1}		= $f1;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' f1='.$sumigpreffd->{_f1};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' f1='.$sumigpreffd->{_f1};

	} else { 
		print("sumigpreffd, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$sumigpreffd->{_f2}		= $f2;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' f2='.$sumigpreffd->{_f2};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' f2='.$sumigpreffd->{_f2};

	} else { 
		print("sumigpreffd, f2, missing f2,\n");
	 }
 }


=head2 sub f3 


=cut

 sub f3 {

	my ( $self,$f3 )		= @_;
	if ( $f3 ne $empty_string ) {

		$sumigpreffd->{_f3}		= $f3;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' f3='.$sumigpreffd->{_f3};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' f3='.$sumigpreffd->{_f3};

	} else { 
		print("sumigpreffd, f3, missing f3,\n");
	 }
 }


=head2 sub f4 


=cut

 sub f4 {

	my ( $self,$f4 )		= @_;
	if ( $f4 ne $empty_string ) {

		$sumigpreffd->{_f4}		= $f4;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' f4='.$sumigpreffd->{_f4};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' f4='.$sumigpreffd->{_f4};

	} else { 
		print("sumigpreffd, f4, missing f4,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumigpreffd->{_fmax}		= $fmax;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' fmax='.$sumigpreffd->{_fmax};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' fmax='.$sumigpreffd->{_fmax};

	} else { 
		print("sumigpreffd, fmax, missing fmax,\n");
	 }
 }


=head2 sub lpad 


=cut

 sub lpad {

	my ( $self,$lpad )		= @_;
	if ( $lpad ne $empty_string ) {

		$sumigpreffd->{_lpad}		= $lpad;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' lpad='.$sumigpreffd->{_lpad};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' lpad='.$sumigpreffd->{_lpad};

	} else { 
		print("sumigpreffd, lpad, missing lpad,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$sumigpreffd->{_nxo}		= $nxo;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' nxo='.$sumigpreffd->{_nxo};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' nxo='.$sumigpreffd->{_nxo};

	} else { 
		print("sumigpreffd, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxshot 


=cut

 sub nxshot {

	my ( $self,$nxshot )		= @_;
	if ( $nxshot ne $empty_string ) {

		$sumigpreffd->{_nxshot}		= $nxshot;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' nxshot='.$sumigpreffd->{_nxshot};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' nxshot='.$sumigpreffd->{_nxshot};

	} else { 
		print("sumigpreffd, nxshot, missing nxshot,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigpreffd->{_nz}		= $nz;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' nz='.$sumigpreffd->{_nz};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' nz='.$sumigpreffd->{_nz};

	} else { 
		print("sumigpreffd, nz, missing nz,\n");
	 }
 }


=head2 sub rpad 


=cut

 sub rpad {

	my ( $self,$rpad )		= @_;
	if ( $rpad ne $empty_string ) {

		$sumigpreffd->{_rpad}		= $rpad;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' rpad='.$sumigpreffd->{_rpad};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' rpad='.$sumigpreffd->{_rpad};

	} else { 
		print("sumigpreffd, rpad, missing rpad,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigpreffd->{_verbose}		= $verbose;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' verbose='.$sumigpreffd->{_verbose};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' verbose='.$sumigpreffd->{_verbose};

	} else { 
		print("sumigpreffd, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigpreffd->{_vfile}		= $vfile;
		$sumigpreffd->{_note}		= $sumigpreffd->{_note}.' vfile='.$sumigpreffd->{_vfile};
		$sumigpreffd->{_Step}		= $sumigpreffd->{_Step}.' vfile='.$sumigpreffd->{_vfile};

	} else { 
		print("sumigpreffd, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 13;

    return($max_index);
}
 
 
1;
