package App::SeismicUnixGui::sunix::model::suimp3d;

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
SUIMP3D - generate inplane shot records for a point 	

          scatterer embedded in three dimensions using	

          the Born integral equation			",							



suimp3d [optional parameters] >stdout 			



Optional parameters					

	nshot=1		number of shots			

	nrec=1		number of receivers		

	c=5000		speed				

	dt=.004		sampling rate			

	nt=256		number of samples		

	x0=1000		point scatterer location	

	y0=0		point scatterer location	

	z0=1000		point scatterer location	

   dir=0		do not include direct arrival	

	            =1 include direct arrival	

	sxmin=0		first shot location		

	symin=0		first shot location		

	szmin=0		first shot location		

	gxmin=0		first receiver location		

	gymin=0		first receiver location		

	gzmin=0		first receiver location		

	dsx=100		x-step in shot location		

	dsy=0	 	y-step in shot location		

	dsz=0	 	z-step in shot location		

	dgx=100		x-step in receiver location	

	dgy=0		y-step in receiver location	

	dgz=0		z-step in receiver location	



 Example:                                              

       suimp3d nrec=32 | sufilter | supswigp | ...     





 Credits:

	CWP: Norm Bleistein, Jack K. Cohen

  UHouston: Chris Liner 2010 (added direct arrival option)





 

 Theory: Use the 3D Born integral equation (e.g., Geophysics,

 v51, n8, p1554(7)). Use 3-D delta function for alpha.



 Note: Setting a 3D offset in a single offset field beats the

       hell out of us.  We did _something_.



 Trace header fields set: ns, dt, tracl, tracr, fldr, tracf,

                          sx, sy, selev, gx, gy, gelev, offset



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

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $suimp3d			= {
	_c					=> '',
	_dgx					=> '',
	_dgy					=> '',
	_dgz					=> '',
	_dir					=> '',
	_dsx					=> '',
	_dsy					=> '',
	_dsz					=> '',
	_dt					=> '',
	_gxmin					=> '',
	_gymin					=> '',
	_gzmin					=> '',
	_nrec					=> '',
	_nshot					=> '',
	_nt					=> '',
	_sxmin					=> '',
	_symin					=> '',
	_szmin					=> '',
	_x0					=> '',
	_y0					=> '',
	_z0					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suimp3d->{_Step}     = 'suimp3d'.$suimp3d->{_Step};
	return ( $suimp3d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suimp3d->{_note}     = 'suimp3d'.$suimp3d->{_note};
	return ( $suimp3d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suimp3d->{_c}			= '';
		$suimp3d->{_dgx}			= '';
		$suimp3d->{_dgy}			= '';
		$suimp3d->{_dgz}			= '';
		$suimp3d->{_dir}			= '';
		$suimp3d->{_dsx}			= '';
		$suimp3d->{_dsy}			= '';
		$suimp3d->{_dsz}			= '';
		$suimp3d->{_dt}			= '';
		$suimp3d->{_gxmin}			= '';
		$suimp3d->{_gymin}			= '';
		$suimp3d->{_gzmin}			= '';
		$suimp3d->{_nrec}			= '';
		$suimp3d->{_nshot}			= '';
		$suimp3d->{_nt}			= '';
		$suimp3d->{_sxmin}			= '';
		$suimp3d->{_symin}			= '';
		$suimp3d->{_szmin}			= '';
		$suimp3d->{_x0}			= '';
		$suimp3d->{_y0}			= '';
		$suimp3d->{_z0}			= '';
		$suimp3d->{_Step}			= '';
		$suimp3d->{_note}			= '';
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$suimp3d->{_c}		= $c;
		$suimp3d->{_note}		= $suimp3d->{_note}.' c='.$suimp3d->{_c};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' c='.$suimp3d->{_c};

	} else { 
		print("suimp3d, c, missing c,\n");
	 }
 }


=head2 sub dgx 


=cut

 sub dgx {

	my ( $self,$dgx )		= @_;
	if ( $dgx ne $empty_string ) {

		$suimp3d->{_dgx}		= $dgx;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dgx='.$suimp3d->{_dgx};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dgx='.$suimp3d->{_dgx};

	} else { 
		print("suimp3d, dgx, missing dgx,\n");
	 }
 }


=head2 sub dgy 


=cut

 sub dgy {

	my ( $self,$dgy )		= @_;
	if ( $dgy ne $empty_string ) {

		$suimp3d->{_dgy}		= $dgy;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dgy='.$suimp3d->{_dgy};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dgy='.$suimp3d->{_dgy};

	} else { 
		print("suimp3d, dgy, missing dgy,\n");
	 }
 }


=head2 sub dgz 


=cut

 sub dgz {

	my ( $self,$dgz )		= @_;
	if ( $dgz ne $empty_string ) {

		$suimp3d->{_dgz}		= $dgz;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dgz='.$suimp3d->{_dgz};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dgz='.$suimp3d->{_dgz};

	} else { 
		print("suimp3d, dgz, missing dgz,\n");
	 }
 }


=head2 sub dir 


=cut

 sub dir {

	my ( $self,$dir )		= @_;
	if ( $dir ne $empty_string ) {

		$suimp3d->{_dir}		= $dir;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dir='.$suimp3d->{_dir};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dir='.$suimp3d->{_dir};

	} else { 
		print("suimp3d, dir, missing dir,\n");
	 }
 }


=head2 sub dsx 


=cut

 sub dsx {

	my ( $self,$dsx )		= @_;
	if ( $dsx ne $empty_string ) {

		$suimp3d->{_dsx}		= $dsx;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dsx='.$suimp3d->{_dsx};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dsx='.$suimp3d->{_dsx};

	} else { 
		print("suimp3d, dsx, missing dsx,\n");
	 }
 }


=head2 sub dsy 


=cut

 sub dsy {

	my ( $self,$dsy )		= @_;
	if ( $dsy ne $empty_string ) {

		$suimp3d->{_dsy}		= $dsy;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dsy='.$suimp3d->{_dsy};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dsy='.$suimp3d->{_dsy};

	} else { 
		print("suimp3d, dsy, missing dsy,\n");
	 }
 }


=head2 sub dsz 


=cut

 sub dsz {

	my ( $self,$dsz )		= @_;
	if ( $dsz ne $empty_string ) {

		$suimp3d->{_dsz}		= $dsz;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dsz='.$suimp3d->{_dsz};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dsz='.$suimp3d->{_dsz};

	} else { 
		print("suimp3d, dsz, missing dsz,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suimp3d->{_dt}		= $dt;
		$suimp3d->{_note}		= $suimp3d->{_note}.' dt='.$suimp3d->{_dt};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' dt='.$suimp3d->{_dt};

	} else { 
		print("suimp3d, dt, missing dt,\n");
	 }
 }


=head2 sub gxmin 


=cut

 sub gxmin {

	my ( $self,$gxmin )		= @_;
	if ( $gxmin ne $empty_string ) {

		$suimp3d->{_gxmin}		= $gxmin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' gxmin='.$suimp3d->{_gxmin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' gxmin='.$suimp3d->{_gxmin};

	} else { 
		print("suimp3d, gxmin, missing gxmin,\n");
	 }
 }


=head2 sub gymin 


=cut

 sub gymin {

	my ( $self,$gymin )		= @_;
	if ( $gymin ne $empty_string ) {

		$suimp3d->{_gymin}		= $gymin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' gymin='.$suimp3d->{_gymin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' gymin='.$suimp3d->{_gymin};

	} else { 
		print("suimp3d, gymin, missing gymin,\n");
	 }
 }


=head2 sub gzmin 


=cut

 sub gzmin {

	my ( $self,$gzmin )		= @_;
	if ( $gzmin ne $empty_string ) {

		$suimp3d->{_gzmin}		= $gzmin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' gzmin='.$suimp3d->{_gzmin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' gzmin='.$suimp3d->{_gzmin};

	} else { 
		print("suimp3d, gzmin, missing gzmin,\n");
	 }
 }


=head2 sub nrec 


=cut

 sub nrec {

	my ( $self,$nrec )		= @_;
	if ( $nrec ne $empty_string ) {

		$suimp3d->{_nrec}		= $nrec;
		$suimp3d->{_note}		= $suimp3d->{_note}.' nrec='.$suimp3d->{_nrec};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' nrec='.$suimp3d->{_nrec};

	} else { 
		print("suimp3d, nrec, missing nrec,\n");
	 }
 }


=head2 sub nshot 


=cut

 sub nshot {

	my ( $self,$nshot )		= @_;
	if ( $nshot ne $empty_string ) {

		$suimp3d->{_nshot}		= $nshot;
		$suimp3d->{_note}		= $suimp3d->{_note}.' nshot='.$suimp3d->{_nshot};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' nshot='.$suimp3d->{_nshot};

	} else { 
		print("suimp3d, nshot, missing nshot,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suimp3d->{_nt}		= $nt;
		$suimp3d->{_note}		= $suimp3d->{_note}.' nt='.$suimp3d->{_nt};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' nt='.$suimp3d->{_nt};

	} else { 
		print("suimp3d, nt, missing nt,\n");
	 }
 }


=head2 sub sxmin 


=cut

 sub sxmin {

	my ( $self,$sxmin )		= @_;
	if ( $sxmin ne $empty_string ) {

		$suimp3d->{_sxmin}		= $sxmin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' sxmin='.$suimp3d->{_sxmin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' sxmin='.$suimp3d->{_sxmin};

	} else { 
		print("suimp3d, sxmin, missing sxmin,\n");
	 }
 }


=head2 sub symin 


=cut

 sub symin {

	my ( $self,$symin )		= @_;
	if ( $symin ne $empty_string ) {

		$suimp3d->{_symin}		= $symin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' symin='.$suimp3d->{_symin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' symin='.$suimp3d->{_symin};

	} else { 
		print("suimp3d, symin, missing symin,\n");
	 }
 }


=head2 sub szmin 


=cut

 sub szmin {

	my ( $self,$szmin )		= @_;
	if ( $szmin ne $empty_string ) {

		$suimp3d->{_szmin}		= $szmin;
		$suimp3d->{_note}		= $suimp3d->{_note}.' szmin='.$suimp3d->{_szmin};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' szmin='.$suimp3d->{_szmin};

	} else { 
		print("suimp3d, szmin, missing szmin,\n");
	 }
 }


=head2 sub x0 


=cut

 sub x0 {

	my ( $self,$x0 )		= @_;
	if ( $x0 ne $empty_string ) {

		$suimp3d->{_x0}		= $x0;
		$suimp3d->{_note}		= $suimp3d->{_note}.' x0='.$suimp3d->{_x0};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' x0='.$suimp3d->{_x0};

	} else { 
		print("suimp3d, x0, missing x0,\n");
	 }
 }


=head2 sub y0 


=cut

 sub y0 {

	my ( $self,$y0 )		= @_;
	if ( $y0 ne $empty_string ) {

		$suimp3d->{_y0}		= $y0;
		$suimp3d->{_note}		= $suimp3d->{_note}.' y0='.$suimp3d->{_y0};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' y0='.$suimp3d->{_y0};

	} else { 
		print("suimp3d, y0, missing y0,\n");
	 }
 }


=head2 sub z0 


=cut

 sub z0 {

	my ( $self,$z0 )		= @_;
	if ( $z0 ne $empty_string ) {

		$suimp3d->{_z0}		= $z0;
		$suimp3d->{_note}		= $suimp3d->{_note}.' z0='.$suimp3d->{_z0};
		$suimp3d->{_Step}		= $suimp3d->{_Step}.' z0='.$suimp3d->{_z0};

	} else { 
		print("suimp3d, z0, missing z0,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 20;

    return($max_index);
}
 
 
1;
