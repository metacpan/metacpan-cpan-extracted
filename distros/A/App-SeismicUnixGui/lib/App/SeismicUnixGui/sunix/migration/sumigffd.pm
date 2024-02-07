package App::SeismicUnixGui::sunix::migration::sumigffd;

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
 SUMIGFFD - Fourier finite difference depth migration for		

	    zero-offset data. This method is a hybrid migration which	

	    combines the advantages of phase shift and finite difference", 

	    migrations.							



 sumigffd <infile >outfile vfile= [optional parameters]		



 Required Parameters:						  	

 nz=		   number of depth sapmles			 	", 

 dz=		   depth sampling interval			 	

 vfile=		name of file containing velocities	      	



 Optional Parameters:						  	

 dt=from header(dt) or .004    time sampling interval		  	

 dx=from header(d2) or 1.0     midpoint sampling interval	  	

 ft=0.0			first time sample			

 fz=0.0			first depth sample		      	



 tmpdir=	if non-empty, use the value as a directory path		

		prefix for storing temporary files; else if the		

		the CWP_TMPDIR environment variable is set use		

		its value for the path; else use tmpfile()		

 

 The input velocity file \'vfile\' consists of C-style binary floats.  ",  

 The structure of this file is vfile[iz][ix]. Note that this means that

 the x-direction is the fastest direction instead of z-direction! Such a

 structure is more convenient for the downward continuation type	

 migration algorithm than using z as fastest dimension as in other SU  ", 

 programs. (In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]  

 denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 programmers may expect.)						", 



 Because most of the tools in the SU package (such as  unif2, unisam2, ", 

 and makevel) produce output with the structure vfile[ix][iz], you will

 need to transpose the velocity files created by these programs. You may

 use the SU program \'transp\' in SU to transpose such files into the  

 required vfile[iz][ix] structure.					









 Credits: CWP Baoniu Han, July 21th, 1997





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

my $sumigffd			= {
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_ft					=> '',
	_fz					=> '',
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

	$sumigffd->{_Step}     = 'sumigffd'.$sumigffd->{_Step};
	return ( $sumigffd->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigffd->{_note}     = 'sumigffd'.$sumigffd->{_note};
	return ( $sumigffd->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigffd->{_dt}			= '';
		$sumigffd->{_dx}			= '';
		$sumigffd->{_dz}			= '';
		$sumigffd->{_ft}			= '';
		$sumigffd->{_fz}			= '';
		$sumigffd->{_nz}			= '';
		$sumigffd->{_tmpdir}			= '';
		$sumigffd->{_vfile}			= '';
		$sumigffd->{_Step}			= '';
		$sumigffd->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumigffd->{_dt}		= $dt;
		$sumigffd->{_note}		= $sumigffd->{_note}.' dt='.$sumigffd->{_dt};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' dt='.$sumigffd->{_dt};

	} else { 
		print("sumigffd, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigffd->{_dx}		= $dx;
		$sumigffd->{_note}		= $sumigffd->{_note}.' dx='.$sumigffd->{_dx};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' dx='.$sumigffd->{_dx};

	} else { 
		print("sumigffd, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigffd->{_dz}		= $dz;
		$sumigffd->{_note}		= $sumigffd->{_note}.' dz='.$sumigffd->{_dz};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' dz='.$sumigffd->{_dz};

	} else { 
		print("sumigffd, dz, missing dz,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$sumigffd->{_ft}		= $ft;
		$sumigffd->{_note}		= $sumigffd->{_note}.' ft='.$sumigffd->{_ft};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' ft='.$sumigffd->{_ft};

	} else { 
		print("sumigffd, ft, missing ft,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$sumigffd->{_fz}		= $fz;
		$sumigffd->{_note}		= $sumigffd->{_note}.' fz='.$sumigffd->{_fz};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' fz='.$sumigffd->{_fz};

	} else { 
		print("sumigffd, fz, missing fz,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigffd->{_nz}		= $nz;
		$sumigffd->{_note}		= $sumigffd->{_note}.' nz='.$sumigffd->{_nz};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' nz='.$sumigffd->{_nz};

	} else { 
		print("sumigffd, nz, missing nz,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumigffd->{_tmpdir}		= $tmpdir;
		$sumigffd->{_note}		= $sumigffd->{_note}.' tmpdir='.$sumigffd->{_tmpdir};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' tmpdir='.$sumigffd->{_tmpdir};

	} else { 
		print("sumigffd, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigffd->{_vfile}		= $vfile;
		$sumigffd->{_note}		= $sumigffd->{_note}.' vfile='.$sumigffd->{_vfile};
		$sumigffd->{_Step}		= $sumigffd->{_Step}.' vfile='.$sumigffd->{_vfile};

	} else { 
		print("sumigffd, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
