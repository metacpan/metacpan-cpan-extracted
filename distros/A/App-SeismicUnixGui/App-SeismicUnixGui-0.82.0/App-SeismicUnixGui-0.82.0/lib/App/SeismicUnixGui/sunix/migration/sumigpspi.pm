package App::SeismicUnixGui::sunix::migration::sumigpspi;

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
 SUMIGPSPI - Gazdag's phase-shift plus interpolation depth migration   

            for zero-offset data, which can handle the lateral         

            velocity variation.                                        



 sumigpspi <infile >outfile vfile= [optional parameters]               

 

 Required Parameters:							

 nz=		number of depth sapmles					

 dz=		depth sampling interval					

 vfile=	name of file containing velocities			

		(Please see Notes below concerning the format of vfile)	



 Optional Parameters:                                                  

 dt=from header(dt) or .004    time sampling interval                  

 dx=from header(d2) or 1.0     midpoint sampling interval              



 tmpdir=        if non-empty, use the value as a directory path        

                prefix for storing temporary files; else if the        

                the CWP_TMPDIR environment variable is set use         

                its value for the path; else use tmpfile()             



 Notes:								

 The input velocity file 'vfile' consists of C-style binary floats.	

 The structure of this file is vfile[iz][ix]. Note that this means that

 the x-direction is the fastest direction instead of z-direction! Such a

 structure is more convenient for the downward continuation type	

 migration algorithm than using z as fastest dimension as in other SU	

 programs. (In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]	

 denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 programmers may expect.)						



 Because most of the tools in the SU package (such as  unif2, unisam2,	

 and makevel) produce output with the structure vfile[ix][iz], you will

 need to transpose the velocity files created by these programs. You may

 use the SU program 'transp' in SU to transpose such files into the	

 required vfile[iz][ix] structure.					









 Credits: CWP, Baoniu Han, April 20th, 1998



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

my $sumigpspi			= {
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_nz					=> '',
	_tmpdir					=> '',
	_vfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sumigpspi->{_Step}     = 'sumigpspi'.$sumigpspi->{_Step};
	return ( $sumigpspi->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigpspi->{_note}     = 'sumigpspi'.$sumigpspi->{_note};
	return ( $sumigpspi->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigpspi->{_dt}			= '';
		$sumigpspi->{_dx}			= '';
		$sumigpspi->{_dz}			= '';
		$sumigpspi->{_nz}			= '';
		$sumigpspi->{_tmpdir}			= '';
		$sumigpspi->{_vfile}			= '';
		$sumigpspi->{_Step}			= '';
		$sumigpspi->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumigpspi->{_dt}		= $dt;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' dt='.$sumigpspi->{_dt};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' dt='.$sumigpspi->{_dt};

	} else { 
		print("sumigpspi, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigpspi->{_dx}		= $dx;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' dx='.$sumigpspi->{_dx};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' dx='.$sumigpspi->{_dx};

	} else { 
		print("sumigpspi, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigpspi->{_dz}		= $dz;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' dz='.$sumigpspi->{_dz};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' dz='.$sumigpspi->{_dz};

	} else { 
		print("sumigpspi, dz, missing dz,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigpspi->{_nz}		= $nz;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' nz='.$sumigpspi->{_nz};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' nz='.$sumigpspi->{_nz};

	} else { 
		print("sumigpspi, nz, missing nz,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumigpspi->{_tmpdir}		= $tmpdir;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' tmpdir='.$sumigpspi->{_tmpdir};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' tmpdir='.$sumigpspi->{_tmpdir};

	} else { 
		print("sumigpspi, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigpspi->{_vfile}		= $vfile;
		$sumigpspi->{_note}		= $sumigpspi->{_note}.' vfile='.$sumigpspi->{_vfile};
		$sumigpspi->{_Step}		= $sumigpspi->{_Step}.' vfile='.$sumigpspi->{_vfile};

	} else { 
		print("sumigpspi, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
