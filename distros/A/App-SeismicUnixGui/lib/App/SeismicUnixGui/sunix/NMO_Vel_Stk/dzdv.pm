package App::SeismicUnixGui::sunix::NMO_Vel_Stk::dzdv;

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
 DZDV - determine depth derivative with respect to the velocity	",  

  parameter, dz/dv,  by ratios of migrated data with the primary 	

  amplitude and those with the extra amplitude				



 dzdv <infile afile=afile dfile=dfile>outfile [parameters]		



 Required Parameters:							

 infile=	input of common image gathers with primary amplitude	

 afile=	input of common image gathers with extra amplitude	

 dfile=	output of imaged depths in common image gathers 	

 outfile=	output of dz/dv at the imaged points			

 nx= 	        number of migrated traces 				

 nz=	        number of points in migrated traces 			

 dx=		horizontal spacing of migrated trace 			

 dz=	        vertical spacing of output trace 			

 fx=	        x-coordinate of first migrated trace 			

 fz=	        z-coordinate of first point in migrated trace 		

 off0=         first offset in common image gathers 			

 noff=	        number of offsets in common image gathers  		

 doff=	        offset increment in common image gathers  		

 cip=x1,z1,r1,..., cip=xn,zn,rn         description of input CIGS	

	x	x-value of a common image point				

	z	z-value of a common image point	at zero offset		

	r	r-parameter in a common image gather			



 Optional Parameters:							

 nxw, nzw=0		window widths along x- and z-directions in 	

			which points are contributed in solving dz/dv. 	





 Notes:								

 This program is used as part of the velocity analysis technique developed

 by Zhenyue Liu, CWP:1995.						



 Author: CWP: Zhenyue Liu,  1995

 

 Reference: 

 Liu, Z. 1995, "Migration Velocity Analysis", Ph.D. Thesis, Colorado

      School of Mines, CWP report #168.

 



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

my $dzdv			= {
	_afile					=> '',
	_cip					=> '',
	_dfile					=> '',
	_doff					=> '',
	_dx					=> '',
	_dz					=> '',
	_fx					=> '',
	_fz					=> '',
	_infile					=> '',
	_noff					=> '',
	_nx					=> '',
	_nz					=> '',
	_nzw					=> '',
	_off0					=> '',
	_outfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$dzdv->{_Step}     = 'dzdv'.$dzdv->{_Step};
	return ( $dzdv->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$dzdv->{_note}     = 'dzdv'.$dzdv->{_note};
	return ( $dzdv->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$dzdv->{_afile}			= '';
		$dzdv->{_cip}			= '';
		$dzdv->{_dfile}			= '';
		$dzdv->{_doff}			= '';
		$dzdv->{_dx}			= '';
		$dzdv->{_dz}			= '';
		$dzdv->{_fx}			= '';
		$dzdv->{_fz}			= '';
		$dzdv->{_infile}			= '';
		$dzdv->{_noff}			= '';
		$dzdv->{_nx}			= '';
		$dzdv->{_nz}			= '';
		$dzdv->{_nzw}			= '';
		$dzdv->{_off0}			= '';
		$dzdv->{_outfile}			= '';
		$dzdv->{_Step}			= '';
		$dzdv->{_note}			= '';
 }


=head2 sub afile 


=cut

 sub afile {

	my ( $self,$afile )		= @_;
	if ( $afile ne $empty_string ) {

		$dzdv->{_afile}		= $afile;
		$dzdv->{_note}		= $dzdv->{_note}.' afile='.$dzdv->{_afile};
		$dzdv->{_Step}		= $dzdv->{_Step}.' afile='.$dzdv->{_afile};

	} else { 
		print("dzdv, afile, missing afile,\n");
	 }
 }


=head2 sub cip 


=cut

 sub cip {

	my ( $self,$cip )		= @_;
	if ( $cip ne $empty_string ) {

		$dzdv->{_cip}		= $cip;
		$dzdv->{_note}		= $dzdv->{_note}.' cip='.$dzdv->{_cip};
		$dzdv->{_Step}		= $dzdv->{_Step}.' cip='.$dzdv->{_cip};

	} else { 
		print("dzdv, cip, missing cip,\n");
	 }
 }


=head2 sub dfile 


=cut

 sub dfile {

	my ( $self,$dfile )		= @_;
	if ( $dfile ne $empty_string ) {

		$dzdv->{_dfile}		= $dfile;
		$dzdv->{_note}		= $dzdv->{_note}.' dfile='.$dzdv->{_dfile};
		$dzdv->{_Step}		= $dzdv->{_Step}.' dfile='.$dzdv->{_dfile};

	} else { 
		print("dzdv, dfile, missing dfile,\n");
	 }
 }


=head2 sub doff 


=cut

 sub doff {

	my ( $self,$doff )		= @_;
	if ( $doff ne $empty_string ) {

		$dzdv->{_doff}		= $doff;
		$dzdv->{_note}		= $dzdv->{_note}.' doff='.$dzdv->{_doff};
		$dzdv->{_Step}		= $dzdv->{_Step}.' doff='.$dzdv->{_doff};

	} else { 
		print("dzdv, doff, missing doff,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$dzdv->{_dx}		= $dx;
		$dzdv->{_note}		= $dzdv->{_note}.' dx='.$dzdv->{_dx};
		$dzdv->{_Step}		= $dzdv->{_Step}.' dx='.$dzdv->{_dx};

	} else { 
		print("dzdv, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$dzdv->{_dz}		= $dz;
		$dzdv->{_note}		= $dzdv->{_note}.' dz='.$dzdv->{_dz};
		$dzdv->{_Step}		= $dzdv->{_Step}.' dz='.$dzdv->{_dz};

	} else { 
		print("dzdv, dz, missing dz,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$dzdv->{_fx}		= $fx;
		$dzdv->{_note}		= $dzdv->{_note}.' fx='.$dzdv->{_fx};
		$dzdv->{_Step}		= $dzdv->{_Step}.' fx='.$dzdv->{_fx};

	} else { 
		print("dzdv, fx, missing fx,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$dzdv->{_fz}		= $fz;
		$dzdv->{_note}		= $dzdv->{_note}.' fz='.$dzdv->{_fz};
		$dzdv->{_Step}		= $dzdv->{_Step}.' fz='.$dzdv->{_fz};

	} else { 
		print("dzdv, fz, missing fz,\n");
	 }
 }


=head2 sub infile 


=cut

 sub infile {

	my ( $self,$infile )		= @_;
	if ( $infile ne $empty_string ) {

		$dzdv->{_infile}		= $infile;
		$dzdv->{_note}		= $dzdv->{_note}.' infile='.$dzdv->{_infile};
		$dzdv->{_Step}		= $dzdv->{_Step}.' infile='.$dzdv->{_infile};

	} else { 
		print("dzdv, infile, missing infile,\n");
	 }
 }


=head2 sub noff 


=cut

 sub noff {

	my ( $self,$noff )		= @_;
	if ( $noff ne $empty_string ) {

		$dzdv->{_noff}		= $noff;
		$dzdv->{_note}		= $dzdv->{_note}.' noff='.$dzdv->{_noff};
		$dzdv->{_Step}		= $dzdv->{_Step}.' noff='.$dzdv->{_noff};

	} else { 
		print("dzdv, noff, missing noff,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$dzdv->{_nx}		= $nx;
		$dzdv->{_note}		= $dzdv->{_note}.' nx='.$dzdv->{_nx};
		$dzdv->{_Step}		= $dzdv->{_Step}.' nx='.$dzdv->{_nx};

	} else { 
		print("dzdv, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$dzdv->{_nz}		= $nz;
		$dzdv->{_note}		= $dzdv->{_note}.' nz='.$dzdv->{_nz};
		$dzdv->{_Step}		= $dzdv->{_Step}.' nz='.$dzdv->{_nz};

	} else { 
		print("dzdv, nz, missing nz,\n");
	 }
 }


=head2 sub nzw 


=cut

 sub nzw {

	my ( $self,$nzw )		= @_;
	if ( $nzw ne $empty_string ) {

		$dzdv->{_nzw}		= $nzw;
		$dzdv->{_note}		= $dzdv->{_note}.' nzw='.$dzdv->{_nzw};
		$dzdv->{_Step}		= $dzdv->{_Step}.' nzw='.$dzdv->{_nzw};

	} else { 
		print("dzdv, nzw, missing nzw,\n");
	 }
 }


=head2 sub off0 


=cut

 sub off0 {

	my ( $self,$off0 )		= @_;
	if ( $off0 ne $empty_string ) {

		$dzdv->{_off0}		= $off0;
		$dzdv->{_note}		= $dzdv->{_note}.' off0='.$dzdv->{_off0};
		$dzdv->{_Step}		= $dzdv->{_Step}.' off0='.$dzdv->{_off0};

	} else { 
		print("dzdv, off0, missing off0,\n");
	 }
 }


=head2 sub outfile 


=cut

 sub outfile {

	my ( $self,$outfile )		= @_;
	if ( $outfile ne $empty_string ) {

		$dzdv->{_outfile}		= $outfile;
		$dzdv->{_note}		= $dzdv->{_note}.' outfile='.$dzdv->{_outfile};
		$dzdv->{_Step}		= $dzdv->{_Step}.' outfile='.$dzdv->{_outfile};

	} else { 
		print("dzdv, outfile, missing outfile,\n");
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
