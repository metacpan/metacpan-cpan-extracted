package App::SeismicUnixGui::sunix::migration::sumigprepspi;

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
 char *sdoc[] = {

 

 " SUMIGPREPSPI --- The 2-D PREstack commom-shot Phase-Shift-Plus 	

 "			interpolation depth MIGration.			

 

 "   sumigprepspi <indata >outfile [parameters] 			", 

 

 " Required Parameters:						   	

 

 " nxo=     number of total horizontal output samples			

 " nxshot=  number of shot gathers to be migrated		   	

 " nz=      number of depth samples				 	

 " dx=      horizontal sampling interval			  	",   

 " dz=      depth sampling interval				 	

 " vfile=   velocity profile, it must be binary format.                 

 

 " Optional Parameters:						   	

 " fmax=25    the peak frequency of Ricker wavelet used as source wavelet

 " f1=5

   f2=1

   f3=4

   f4=50     frequencies to build a Hamming window     

 " lpad=9999

   rpad=9999        number of zero traces padded on both	

 "                            sides of depth section to determine the	

 "                            migration aperture, the default values    

 "                            are using the full aperture.              

 " nflag=0    normalization of cross-correlation:                       

 "            0: none, 1: by source wave field                          

 " verbose=0  silent, =1 additional runtime information	                

   

 " Notes:								

 " The input velocity file \'vfile\' consists of C-style binary floats.	",  

 " The structure of this file is vfile[iz][ix]. Note that this means that

 " the x-direction is the fastest direction instead of z-direction! Such a

 " structure is more convenient for the downward continuation type	

 " migration algorithm than using z as fastest dimension as in other SU  ", 

 " programs.						   		

 

 " Because most of the tools in the SU package (such as  unif2, unisam2, ", 

 " and makevel) produce output with the structure vfile[ix][iz], you will

 " need to transpose the velocity files created by these programs. You may

 " use the SU program \'transp\' in SU to transpose such files into the  

 " required vfile[iz][ix] structure.					

 

 " (In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]  		

 " denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 " programmers may expect.)						", 

 

 " Also, sx must be monotonically increasing throughout the dataset, and 

 " and gx must be monotonically increasing within a shot. You may resort 

 " your data with \'susort\', accordingly.				

 

 " The scalco header field is honored so this field must be set correctly.

 " See selfdocs of \'susort\', \'suchw\'. Also:   sukeyword scalco	

 





  * Credits: CWP, Baoniu Han, bhan@dix.mines.edu, April 19th, 1998

  *	  Modified: Chris Stolk, 11 Dec 2005, - changed data input

  *		    to remove erroneous time delay.

  *	  Modified: CWP, John Stockwell 26 Sept 2006 - replaced Han's

  *	  "goto-loop" in two places with "do { }while loops".

  *	  Fixed it so that sx, gx, and scalco are honored.

  *

  *

  * Trace header fields accessed: ns, dt, delrt, d2

  * Trace header fields modified: ns, dt, delrt

 



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

my $sumigprepspi			= {
	_dx					=> '',
	_dz					=> '',
	_f1					=> '',
	_f2					=> '',
	_f3					=> '',
	_f4					=> '',
	_fmax					=> '',
	_lpad					=> '',
	_nflag					=> '',
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

	$sumigprepspi->{_Step}     = 'sumigprepspi'.$sumigprepspi->{_Step};
	return ( $sumigprepspi->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigprepspi->{_note}     = 'sumigprepspi'.$sumigprepspi->{_note};
	return ( $sumigprepspi->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigprepspi->{_dx}			= '';
		$sumigprepspi->{_dz}			= '';
		$sumigprepspi->{_f1}			= '';
		$sumigprepspi->{_f2}			= '';
		$sumigprepspi->{_f3}			= '';
		$sumigprepspi->{_f4}			= '';
		$sumigprepspi->{_fmax}			= '';
		$sumigprepspi->{_lpad}			= '';
		$sumigprepspi->{_nflag}			= '';
		$sumigprepspi->{_nxo}			= '';
		$sumigprepspi->{_nxshot}			= '';
		$sumigprepspi->{_nz}			= '';
		$sumigprepspi->{_rpad}			= '';
		$sumigprepspi->{_verbose}			= '';
		$sumigprepspi->{_vfile}			= '';
		$sumigprepspi->{_Step}			= '';
		$sumigprepspi->{_note}			= '';
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigprepspi->{_dx}		= $dx;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' dx='.$sumigprepspi->{_dx};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' dx='.$sumigprepspi->{_dx};

	} else { 
		print("sumigprepspi, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigprepspi->{_dz}		= $dz;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' dz='.$sumigprepspi->{_dz};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' dz='.$sumigprepspi->{_dz};

	} else { 
		print("sumigprepspi, dz, missing dz,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$sumigprepspi->{_f1}		= $f1;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' f1='.$sumigprepspi->{_f1};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' f1='.$sumigprepspi->{_f1};

	} else { 
		print("sumigprepspi, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$sumigprepspi->{_f2}		= $f2;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' f2='.$sumigprepspi->{_f2};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' f2='.$sumigprepspi->{_f2};

	} else { 
		print("sumigprepspi, f2, missing f2,\n");
	 }
 }


=head2 sub f3 


=cut

 sub f3 {

	my ( $self,$f3 )		= @_;
	if ( $f3 ne $empty_string ) {

		$sumigprepspi->{_f3}		= $f3;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' f3='.$sumigprepspi->{_f3};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' f3='.$sumigprepspi->{_f3};

	} else { 
		print("sumigprepspi, f3, missing f3,\n");
	 }
 }


=head2 sub f4 


=cut

 sub f4 {

	my ( $self,$f4 )		= @_;
	if ( $f4 ne $empty_string ) {

		$sumigprepspi->{_f4}		= $f4;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' f4='.$sumigprepspi->{_f4};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' f4='.$sumigprepspi->{_f4};

	} else { 
		print("sumigprepspi, f4, missing f4,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumigprepspi->{_fmax}		= $fmax;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' fmax='.$sumigprepspi->{_fmax};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' fmax='.$sumigprepspi->{_fmax};

	} else { 
		print("sumigprepspi, fmax, missing fmax,\n");
	 }
 }


=head2 sub lpad 


=cut

 sub lpad {

	my ( $self,$lpad )		= @_;
	if ( $lpad ne $empty_string ) {

		$sumigprepspi->{_lpad}		= $lpad;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' lpad='.$sumigprepspi->{_lpad};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' lpad='.$sumigprepspi->{_lpad};

	} else { 
		print("sumigprepspi, lpad, missing lpad,\n");
	 }
 }


=head2 sub nflag 


=cut

 sub nflag {

	my ( $self,$nflag )		= @_;
	if ( $nflag ne $empty_string ) {

		$sumigprepspi->{_nflag}		= $nflag;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' nflag='.$sumigprepspi->{_nflag};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' nflag='.$sumigprepspi->{_nflag};

	} else { 
		print("sumigprepspi, nflag, missing nflag,\n");
	 }
 }


=head2 sub nxo 


=cut

 sub nxo {

	my ( $self,$nxo )		= @_;
	if ( $nxo ne $empty_string ) {

		$sumigprepspi->{_nxo}		= $nxo;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' nxo='.$sumigprepspi->{_nxo};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' nxo='.$sumigprepspi->{_nxo};

	} else { 
		print("sumigprepspi, nxo, missing nxo,\n");
	 }
 }


=head2 sub nxshot 


=cut

 sub nxshot {

	my ( $self,$nxshot )		= @_;
	if ( $nxshot ne $empty_string ) {

		$sumigprepspi->{_nxshot}		= $nxshot;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' nxshot='.$sumigprepspi->{_nxshot};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' nxshot='.$sumigprepspi->{_nxshot};

	} else { 
		print("sumigprepspi, nxshot, missing nxshot,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigprepspi->{_nz}		= $nz;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' nz='.$sumigprepspi->{_nz};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' nz='.$sumigprepspi->{_nz};

	} else { 
		print("sumigprepspi, nz, missing nz,\n");
	 }
 }


=head2 sub rpad 


=cut

 sub rpad {

	my ( $self,$rpad )		= @_;
	if ( $rpad ne $empty_string ) {

		$sumigprepspi->{_rpad}		= $rpad;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' rpad='.$sumigprepspi->{_rpad};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' rpad='.$sumigprepspi->{_rpad};

	} else { 
		print("sumigprepspi, rpad, missing rpad,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigprepspi->{_verbose}		= $verbose;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' verbose='.$sumigprepspi->{_verbose};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' verbose='.$sumigprepspi->{_verbose};

	} else { 
		print("sumigprepspi, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigprepspi->{_vfile}		= $vfile;
		$sumigprepspi->{_note}		= $sumigprepspi->{_note}.' vfile='.$sumigprepspi->{_vfile};
		$sumigprepspi->{_Step}		= $sumigprepspi->{_Step}.' vfile='.$sumigprepspi->{_vfile};

	} else { 
		print("sumigprepspi, vfile, missing vfile,\n");
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
