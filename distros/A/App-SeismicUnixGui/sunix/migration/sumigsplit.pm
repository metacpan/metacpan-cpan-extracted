package App::SeismicUnixGui::sunix::migration::sumigsplit;

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
 SUMIGSPLIT - Split-step depth migration for zero-offset data.         



 sumigsplit <infile >outfile vfile= [optional parameters]              



 Required Parameters:                                                  

 nz=                   number of depth sapmles                         

 dz=                   depth sampling interval                         

 vfile=                name of file containing velocities              



 Optional Parameters:                                                  

 dt=from header(dt) or .004    time sampling interval                  

 dx=from header(d2) or 1.0     midpoint sampling interval              

 ft=0.0                        first time sample                       

 fz=                           first depth sample                      



 tmpdir=        if non-empty, use the value as a directory path        

                prefix for storing temporary files; else if the        

                the CWP_TMPDIR environment variable is set use         

                its value for the path; else use tmpfile()             





 Notes:                                                                

 The input velocity file \'vfile\' consists of C-style binary floats.  

 The structure of this file is vfile[iz][ix]. Note that this means that

 the x-direction is the fastest direction instead of z-direction! Such a

 structure is more convenient for the downward continuation type       

 migration algorithm than using z as fastest dimension as in other SU  

 programs.                                                     	



 Because most of the tools in the SU package (such as  unif2, unisam2, 

 and makevel) produce output with the structure vfile[ix][iz], you will

 need to transpose the velocity files created by these programs. You may

 use the SU program \'transp\' in SU to transpose such files into the  

 required vfile[iz][ix] structure.                                     

 (In C  v[iz][ix] denotes a v(x,z) array, whereas v[ix][iz]  		

 denotes a v(z,x) array, the opposite of what Matlab and Fortran	

 programmers may expect.)						", 



  



 Credits: CWP Baoniu Han, July 21th, 1997



 Reference:

  Stoffa, P. L. and Fokkema, J. T. and Freire, R. M. and Kessinger, W. P.,

  1990, Split-step Fourier migration, Geophysics, 55, 410-421.





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

my $sumigsplit			= {
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

	$sumigsplit->{_Step}     = 'sumigsplit'.$sumigsplit->{_Step};
	return ( $sumigsplit->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigsplit->{_note}     = 'sumigsplit'.$sumigsplit->{_note};
	return ( $sumigsplit->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigsplit->{_dt}			= '';
		$sumigsplit->{_dx}			= '';
		$sumigsplit->{_dz}			= '';
		$sumigsplit->{_ft}			= '';
		$sumigsplit->{_fz}			= '';
		$sumigsplit->{_nz}			= '';
		$sumigsplit->{_tmpdir}			= '';
		$sumigsplit->{_vfile}			= '';
		$sumigsplit->{_Step}			= '';
		$sumigsplit->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumigsplit->{_dt}		= $dt;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' dt='.$sumigsplit->{_dt};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' dt='.$sumigsplit->{_dt};

	} else { 
		print("sumigsplit, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigsplit->{_dx}		= $dx;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' dx='.$sumigsplit->{_dx};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' dx='.$sumigsplit->{_dx};

	} else { 
		print("sumigsplit, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sumigsplit->{_dz}		= $dz;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' dz='.$sumigsplit->{_dz};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' dz='.$sumigsplit->{_dz};

	} else { 
		print("sumigsplit, dz, missing dz,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$sumigsplit->{_ft}		= $ft;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' ft='.$sumigsplit->{_ft};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' ft='.$sumigsplit->{_ft};

	} else { 
		print("sumigsplit, ft, missing ft,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$sumigsplit->{_fz}		= $fz;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' fz='.$sumigsplit->{_fz};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' fz='.$sumigsplit->{_fz};

	} else { 
		print("sumigsplit, fz, missing fz,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sumigsplit->{_nz}		= $nz;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' nz='.$sumigsplit->{_nz};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' nz='.$sumigsplit->{_nz};

	} else { 
		print("sumigsplit, nz, missing nz,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumigsplit->{_tmpdir}		= $tmpdir;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' tmpdir='.$sumigsplit->{_tmpdir};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' tmpdir='.$sumigsplit->{_tmpdir};

	} else { 
		print("sumigsplit, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigsplit->{_vfile}		= $vfile;
		$sumigsplit->{_note}		= $sumigsplit->{_note}.' vfile='.$sumigsplit->{_vfile};
		$sumigsplit->{_Step}		= $sumigsplit->{_Step}.' vfile='.$sumigsplit->{_vfile};

	} else { 
		print("sumigsplit, vfile, missing vfile,\n");
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
