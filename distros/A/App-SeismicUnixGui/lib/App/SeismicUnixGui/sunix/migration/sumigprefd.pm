package App::SeismicUnixGui::sunix::migration::sumigprefd;

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
 SUMIGPREFD --- The 2-D prestack common-shot 45-90 degree		

			finite-difference depth migration. 		



    sumigprefd <indata >outfile [parameters] 				", 



 Required Parameters:							",  

 nxo=		number of total horizontal output samples		

 nxshot=	number of shot gathers to be migrated			

 nz=		number of depth sapmles					

 dx=		horizontal sampling interval				",	

 dz=		depth sampling interval				 	

 vfile=	velocity profile, it must be binary format (see Notes)	

  

 Optional Parameters:							

 dip=79	the maximum dip to migrate, possible values are:	

		45,65,79,80,87,89,90 degrees				

		The computation cost is 45 equals 65equals 79<80<87<89<90		

 fmax=25	peak frequency of Ricker wavelet used as source wavelet	

 f1=5

 f2=10

 f3=40

 f4=50	 frequencies to build a Hamming window	



 lpad=9999

 rpad=9999	number of zero traces padded on both		

			sides of depth section to determine the		

			migration aperature, the default values 	

			are using the full aperature.			

 verbose=0		silent, =1 additional runtime information	



 Notes:								

 The input velocity file \'vfile\' consists of C-style binary floats.  

 The structure of this file is vfile[iz][ix]. Note that this means that

 the x-direction is the fastest direction instead of z-direction! Such a

 structure is more convenient for the downward continuation type	

 migration algorithm than using z as fastest dimension as in other SU  

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

	  "goto-loop" in two places with "do { }while loops".

	  Fixed it so that sx, gx, and scalco are honored.







 Trace header fields accessed: ns, dt, delrt, d2, sx, gx, 

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

my $sumigprefd			= {
	_dip					=> '',
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

	$sumigprefd->{_Step}     = 'sumigprefd'.$sumigprefd->{_Step};
	return ( $sumigprefd->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigprefd->{_note}     = 'sumigprefd'.$sumigprefd->{_note};
	return ( $sumigprefd->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigprefd->{_dip}			= '';
		$sumigprefd->{_dx}			= '';
		$sumigprefd->{_dz}			= '';
		$sumigprefd->{_f1}			= '';
		$sumigprefd->{_f2}			= '';
		$sumigprefd->{_f3}			= '';
		$sumigprefd->{_f4}			= '';
		$sumigprefd->{_fmax}			= '';
		$sumigprefd->{_lpad}			= '';
		$sumigprefd->{_nxo}			= '';
		$sumigprefd->{_nxshot}			= '';
		$sumigprefd->{_nz}			= '';
		$sumigprefd->{_rpad}			= '';
		$sumigprefd->{_verbose}			= '';
		$sumigprefd->{_vfile}			= '';
		$sumigprefd->{_Step}			= '';
		$sumigprefd->{_note}			= '';
 }


=head2 sub dip 


=cut

 sub dip {

	my ( $self,$dip )		= @_;
	if ( $dip ne $empty_string ) {

		$sumigprefd->{_dip}		= $dip;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' dip='.$sumigprefd->{_dip};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' dip='.$sumigprefd->{_dip};

	} else { 
		print("sumigprefd, dip, missing dip,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigprefd->{_dx}		= $dx;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' dx='.$sumigprefd->{_dx};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' dx='.$sumigprefd->{_dx};

	} else { 
		print("sumigprefd, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigprefd->{_dz}		= $dz;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' dz='.$sumigprefd->{_dz};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' dz='.$sumigprefd->{_dz};

	} else { 
		print("sumigprefd, dz, missing dz,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$sumigprefd->{_f1}		= $f1;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' f1='.$sumigprefd->{_f1};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' f1='.$sumigprefd->{_f1};

	} else { 
		print("sumigprefd, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$sumigprefd->{_f2}		= $f2;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' f2='.$sumigprefd->{_f2};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' f2='.$sumigprefd->{_f2};

	} else { 
		print("sumigprefd, f2, missing f2,\n");
	 }
 }


=head2 sub f3 


=cut

 sub f3 {

	my ( $self,$f3 )		= @_;
	if ( $f3 ne $empty_string ) {

		$sumigprefd->{_f3}		= $f3;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' f3='.$sumigprefd->{_f3};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' f3='.$sumigprefd->{_f3};

	} else { 
		print("sumigprefd, f3, missing f3,\n");
	 }
 }


=head2 sub f4 


=cut

 sub f4 {

	my ( $self,$f4 )		= @_;
	if ( $f4 ne $empty_string ) {

		$sumigprefd->{_f4}		= $f4;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' f4='.$sumigprefd->{_f4};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' f4='.$sumigprefd->{_f4};

	} else { 
		print("sumigprefd, f4, missing f4,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumigprefd->{_fmax}		= $fmax;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' fmax='.$sumigprefd->{_fmax};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' fmax='.$sumigprefd->{_fmax};

	} else { 
		print("sumigprefd, fmax, missing fmax,\n");
	 }
 }


=head2 sub lpad 


=cut

 sub lpad {

	my ( $self,$lpad )		= @_;
	if ( $lpad ne $empty_string ) {

		$sumigprefd->{_lpad}		= $lpad;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' lpad='.$sumigprefd->{_lpad};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' lpad='.$sumigprefd->{_lpad};

	} else { 
		print("sumigprefd, lpad, missing lpad,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$sumigprefd->{_nxo}		= $nxo;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' nxo='.$sumigprefd->{_nxo};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' nxo='.$sumigprefd->{_nxo};

	} else { 
		print("sumigprefd, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxshot 


=cut

 sub nxshot {

	my ( $self,$nxshot )		= @_;
	if ( $nxshot ne $empty_string ) {

		$sumigprefd->{_nxshot}		= $nxshot;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' nxshot='.$sumigprefd->{_nxshot};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' nxshot='.$sumigprefd->{_nxshot};

	} else { 
		print("sumigprefd, nxshot, missing nxshot,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigprefd->{_nz}		= $nz;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' nz='.$sumigprefd->{_nz};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' nz='.$sumigprefd->{_nz};

	} else { 
		print("sumigprefd, nz, missing nz,\n");
	 }
 }


=head2 sub rpad 


=cut

 sub rpad {

	my ( $self,$rpad )		= @_;
	if ( $rpad ne $empty_string ) {

		$sumigprefd->{_rpad}		= $rpad;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' rpad='.$sumigprefd->{_rpad};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' rpad='.$sumigprefd->{_rpad};

	} else { 
		print("sumigprefd, rpad, missing rpad,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigprefd->{_verbose}		= $verbose;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' verbose='.$sumigprefd->{_verbose};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' verbose='.$sumigprefd->{_verbose};

	} else { 
		print("sumigprefd, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigprefd->{_vfile}		= $vfile;
		$sumigprefd->{_note}		= $sumigprefd->{_note}.' vfile='.$sumigprefd->{_vfile};
		$sumigprefd->{_Step}		= $sumigprefd->{_Step}.' vfile='.$sumigprefd->{_vfile};

	} else { 
		print("sumigprefd, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 14;

    return($max_index);
}
 
 
1;
