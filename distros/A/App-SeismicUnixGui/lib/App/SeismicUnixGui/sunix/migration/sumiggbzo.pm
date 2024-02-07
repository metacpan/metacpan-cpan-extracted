package App::SeismicUnixGui::sunix::migration::sumiggbzo;

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
 SUMIGGBZO - MIGration via Gaussian Beams of Zero-Offset SU data	



 sumiggbzo <infile >outfile vfile=  nz= [optional parameters]		



 Required Parameters:							

 vfile=                 name of file containing v(z,x)			

 nz=                    number of depth samples			



 Optional Parameters:							

 dt=from header		time sampling interval			

 dx=from header(d2) or 1.0	spatial sampling interval 		

 dz=1.0                 depth sampling interval			

 fmin=0.025/dt          minimum frequency				

 fmax=10*fmin           maximum frequency				

 amin=-amax             minimum emergence angle; must be > -90 degrees	

 amax=60                maximum emergence angle; must be < 90 degrees	

 bwh=0.5*vavg/fmin      beam half-width; vavg denotes average velocity	

 verbose=0		 =0 silent; =1 chatty				



 Note: spatial units of v(z,x) must be the same as those of dx.	

 v(z,x) is represented numerically in C-style binary floats v[x][z],	

 where the depth direction is the fast direction in the data. Such	

 models can be created with unif2 or makevel.				



(In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]  		

 denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 programmers may expect.)						", 



 Caveat:								

 In the event of a "Segmentation Violation" try reducing the value of

 the "bwh" parameter. Run program with verbose=1 do see the default	

 value.								



 Credits:



 CWP: Dave Hale (algorithm), Jack K. Cohen, and John Stockwell

 (reformatting for SU)





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

my $sumiggbzo			= {
	_amax					=> '',
	_amin					=> '',
	_bwh					=> '',
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_fmax					=> '',
	_fmin					=> '',
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

	$sumiggbzo->{_Step}     = 'sumiggbzo'.$sumiggbzo->{_Step};
	return ( $sumiggbzo->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumiggbzo->{_note}     = 'sumiggbzo'.$sumiggbzo->{_note};
	return ( $sumiggbzo->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumiggbzo->{_amax}			= '';
		$sumiggbzo->{_amin}			= '';
		$sumiggbzo->{_bwh}			= '';
		$sumiggbzo->{_dt}			= '';
		$sumiggbzo->{_dx}			= '';
		$sumiggbzo->{_dz}			= '';
		$sumiggbzo->{_fmax}			= '';
		$sumiggbzo->{_fmin}			= '';
		$sumiggbzo->{_nz}			= '';
		$sumiggbzo->{_verbose}			= '';
		$sumiggbzo->{_vfile}			= '';
		$sumiggbzo->{_Step}			= '';
		$sumiggbzo->{_note}			= '';
 }


=head2 sub amax 


=cut

 sub amax {

	my ( $self,$amax )		= @_;
	if ( $amax ne $empty_string ) {

		$sumiggbzo->{_amax}		= $amax;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' amax='.$sumiggbzo->{_amax};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' amax='.$sumiggbzo->{_amax};

	} else { 
		print("sumiggbzo, amax, missing amax,\n");
	 }
 }


=head2 sub amin 


=cut

 sub amin {

	my ( $self,$amin )		= @_;
	if ( $amin ne $empty_string ) {

		$sumiggbzo->{_amin}		= $amin;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' amin='.$sumiggbzo->{_amin};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' amin='.$sumiggbzo->{_amin};

	} else { 
		print("sumiggbzo, amin, missing amin,\n");
	 }
 }


=head2 sub bwh 


=cut

 sub bwh {

	my ( $self,$bwh )		= @_;
	if ( $bwh ne $empty_string ) {

		$sumiggbzo->{_bwh}		= $bwh;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' bwh='.$sumiggbzo->{_bwh};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' bwh='.$sumiggbzo->{_bwh};

	} else { 
		print("sumiggbzo, bwh, missing bwh,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumiggbzo->{_dt}		= $dt;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' dt='.$sumiggbzo->{_dt};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' dt='.$sumiggbzo->{_dt};

	} else { 
		print("sumiggbzo, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumiggbzo->{_dx}		= $dx;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' dx='.$sumiggbzo->{_dx};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' dx='.$sumiggbzo->{_dx};

	} else { 
		print("sumiggbzo, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumiggbzo->{_dz}		= $dz;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' dz='.$sumiggbzo->{_dz};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' dz='.$sumiggbzo->{_dz};

	} else { 
		print("sumiggbzo, dz, missing dz,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumiggbzo->{_fmax}		= $fmax;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' fmax='.$sumiggbzo->{_fmax};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' fmax='.$sumiggbzo->{_fmax};

	} else { 
		print("sumiggbzo, fmax, missing fmax,\n");
	 }
 }


=head2 sub fmin 


=cut

 sub fmin {

	my ( $self,$fmin )		= @_;
	if ( $fmin ne $empty_string ) {

		$sumiggbzo->{_fmin}		= $fmin;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' fmin='.$sumiggbzo->{_fmin};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' fmin='.$sumiggbzo->{_fmin};

	} else { 
		print("sumiggbzo, fmin, missing fmin,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumiggbzo->{_nz}		= $nz;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' nz='.$sumiggbzo->{_nz};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' nz='.$sumiggbzo->{_nz};

	} else { 
		print("sumiggbzo, nz, missing nz,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumiggbzo->{_verbose}		= $verbose;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' verbose='.$sumiggbzo->{_verbose};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' verbose='.$sumiggbzo->{_verbose};

	} else { 
		print("sumiggbzo, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumiggbzo->{_vfile}		= $vfile;
		$sumiggbzo->{_note}		= $sumiggbzo->{_note}.' vfile='.$sumiggbzo->{_vfile};
		$sumiggbzo->{_Step}		= $sumiggbzo->{_Step}.' vfile='.$sumiggbzo->{_vfile};

	} else { 
		print("sumiggbzo, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 10;

    return($max_index);
}
 
 
1;
