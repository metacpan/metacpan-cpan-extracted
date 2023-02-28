package App::SeismicUnixGui::sunix::migration::sudatumfd;

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
 SUDATUMFD - 2D zero-offset Finite Difference acoustic wave-equation	

		 DATUMing    						



 sudatumfd <stdin > stdout [optional parameters]			



 Required parameters:						   	



 nt=	   number of time samples on each trace	       			

 nx=	   number of receivers per shot gather				

 nsx=	  number of shot gathers				    	

 nz=	   number of downward continuation depth steps			

 dz=	   depth sampling interval (in meters)				

 mx=	   number of horizontal samples in the velocity model		

 mz=	   number of vertical samples in the velocity model		

 vfile1=       velocity file used for thin-lens term	    		

 vfile2=       velocity file used for diffraction term			

 dx=           horizontal sampling interval (in meters)                



 Optional parameters:						   	



 dt=.004       time sampling interval (in seconds)			

 buff=5	number of zero traces added to each side of each   	

	     shot gather as a pad			       		

 tap_len=5     taper length (in number of traces)			

 x_0=0.0       x coordinate of leftmost position in velocity model     



 Notes:								

 The algorithm is a 45-degree implicit-finite-difference scheme based  

 on the one-way wave equation.  It works on poststack (zero-offset)    

 data only.  The two velocity files, vfile1 and vfile2, are binary     

 files containing floats with the format v[ix][iz].  There are two     

 potentially different velocity files for the thin-lens and            

 diffraction terms to allow for the use of a zero-velocity layer       

 which allows for datuming from an irregular surface.                  



 Source and receiver locations must be set in the header values in     

 order for the datuming to work properly.  The leftmost position of    

 of the velocity models given in vfile1 and vfile2 must also be given. 







 

 Author:  Chris Robinson, 10/16/00, CWP, Colorado School of Mines





 References:

  Beasley, C., and Lynn, W., 1992, The zero-velocity layer: migration

    from irregular surfaces: Geophysics, 57, 1435-1443.



  Claerbout, J. F., 1985, Imaging the earth's interior:  Blackwell

    Scientific Publications.







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

my $sudatumfd			= {
	_buff					=> '',
	_dt					=> '',
	_dx					=> '',
	_dz					=> '',
	_mx					=> '',
	_mz					=> '',
	_nsx					=> '',
	_nt					=> '',
	_nx					=> '',
	_nz					=> '',
	_tap_len					=> '',
	_vfile1					=> '',
	_vfile2					=> '',
	_x_0					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudatumfd->{_Step}     = 'sudatumfd'.$sudatumfd->{_Step};
	return ( $sudatumfd->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudatumfd->{_note}     = 'sudatumfd'.$sudatumfd->{_note};
	return ( $sudatumfd->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudatumfd->{_buff}			= '';
		$sudatumfd->{_dt}			= '';
		$sudatumfd->{_dx}			= '';
		$sudatumfd->{_dz}			= '';
		$sudatumfd->{_mx}			= '';
		$sudatumfd->{_mz}			= '';
		$sudatumfd->{_nsx}			= '';
		$sudatumfd->{_nt}			= '';
		$sudatumfd->{_nx}			= '';
		$sudatumfd->{_nz}			= '';
		$sudatumfd->{_tap_len}			= '';
		$sudatumfd->{_vfile1}			= '';
		$sudatumfd->{_vfile2}			= '';
		$sudatumfd->{_x_0}			= '';
		$sudatumfd->{_Step}			= '';
		$sudatumfd->{_note}			= '';
 }


=head2 sub buff 


=cut

 sub buff {

	my ( $self,$buff )		= @_;
	if ( $buff ne $empty_string ) {

		$sudatumfd->{_buff}		= $buff;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' buff='.$sudatumfd->{_buff};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' buff='.$sudatumfd->{_buff};

	} else { 
		print("sudatumfd, buff, missing buff,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sudatumfd->{_dt}		= $dt;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' dt='.$sudatumfd->{_dt};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' dt='.$sudatumfd->{_dt};

	} else { 
		print("sudatumfd, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sudatumfd->{_dx}		= $dx;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' dx='.$sudatumfd->{_dx};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' dx='.$sudatumfd->{_dx};

	} else { 
		print("sudatumfd, dx, missing dx,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sudatumfd->{_dz}		= $dz;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' dz='.$sudatumfd->{_dz};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' dz='.$sudatumfd->{_dz};

	} else { 
		print("sudatumfd, dz, missing dz,\n");
	 }
 }


=head2 sub mx 


=cut

 sub mx {

	my ( $self,$mx )		= @_;
	if ( $mx ne $empty_string ) {

		$sudatumfd->{_mx}		= $mx;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' mx='.$sudatumfd->{_mx};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' mx='.$sudatumfd->{_mx};

	} else { 
		print("sudatumfd, mx, missing mx,\n");
	 }
 }


=head2 sub mz 


=cut

 sub mz {

	my ( $self,$mz )		= @_;
	if ( $mz ne $empty_string ) {

		$sudatumfd->{_mz}		= $mz;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' mz='.$sudatumfd->{_mz};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' mz='.$sudatumfd->{_mz};

	} else { 
		print("sudatumfd, mz, missing mz,\n");
	 }
 }


=head2 sub nsx 


=cut

 sub nsx {

	my ( $self,$nsx )		= @_;
	if ( $nsx ne $empty_string ) {

		$sudatumfd->{_nsx}		= $nsx;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' nsx='.$sudatumfd->{_nsx};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' nsx='.$sudatumfd->{_nsx};

	} else { 
		print("sudatumfd, nsx, missing nsx,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sudatumfd->{_nt}		= $nt;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' nt='.$sudatumfd->{_nt};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' nt='.$sudatumfd->{_nt};

	} else { 
		print("sudatumfd, nt, missing nt,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$sudatumfd->{_nx}		= $nx;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' nx='.$sudatumfd->{_nx};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' nx='.$sudatumfd->{_nx};

	} else { 
		print("sudatumfd, nx, missing nx,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$sudatumfd->{_nz}		= $nz;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' nz='.$sudatumfd->{_nz};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' nz='.$sudatumfd->{_nz};

	} else { 
		print("sudatumfd, nz, missing nz,\n");
	 }
 }


=head2 sub tap_len 


=cut

 sub tap_len {

	my ( $self,$tap_len )		= @_;
	if ( $tap_len ne $empty_string ) {

		$sudatumfd->{_tap_len}		= $tap_len;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' tap_len='.$sudatumfd->{_tap_len};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' tap_len='.$sudatumfd->{_tap_len};

	} else { 
		print("sudatumfd, tap_len, missing tap_len,\n");
	 }
 }


=head2 sub vfile1 


=cut

 sub vfile1 {

	my ( $self,$vfile1 )		= @_;
	if ( $vfile1 ne $empty_string ) {

		$sudatumfd->{_vfile1}		= $vfile1;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' vfile1='.$sudatumfd->{_vfile1};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' vfile1='.$sudatumfd->{_vfile1};

	} else { 
		print("sudatumfd, vfile1, missing vfile1,\n");
	 }
 }


=head2 sub vfile2 


=cut

 sub vfile2 {

	my ( $self,$vfile2 )		= @_;
	if ( $vfile2 ne $empty_string ) {

		$sudatumfd->{_vfile2}		= $vfile2;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' vfile2='.$sudatumfd->{_vfile2};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' vfile2='.$sudatumfd->{_vfile2};

	} else { 
		print("sudatumfd, vfile2, missing vfile2,\n");
	 }
 }


=head2 sub x_0 


=cut

 sub x_0 {

	my ( $self,$x_0 )		= @_;
	if ( $x_0 ne $empty_string ) {

		$sudatumfd->{_x_0}		= $x_0;
		$sudatumfd->{_note}		= $sudatumfd->{_note}.' x_0='.$sudatumfd->{_x_0};
		$sudatumfd->{_Step}		= $sudatumfd->{_Step}.' x_0='.$sudatumfd->{_x_0};

	} else { 
		print("sudatumfd, x_0, missing x_0,\n");
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
