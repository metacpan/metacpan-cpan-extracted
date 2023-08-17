package App::SeismicUnixGui::sunix::model::suimp2d;

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
 SUIMP2D - generate shot records for a line scatterer	

           embedded in three dimensions using the Born	

	    integral equation				",							



 suimp2d [optional parameters] >stdout			



 Optional parameters					

	nshot=1		number of shots			

	nrec=1		number of receivers		

	c=5000		speed				

	dt=.004		sampling rate			

	nt=256		number of samples		

	x0=1000		point scatterer location	

	z0=1000		point scatterer location	

	sxmin=0		first shot location		

	szmin=0		first shot location		

	gxmin=0		first receiver location		

	gzmin=0		first receiver location		

	dsx=100		x-step in shot location		

	dsz=0	 	z-step in shot location		

	dgx=100		x-step in receiver location	

	dgz=0		z-step in receiver location	



 Example:						

	suimp2d nrec=32 | sufilter | supswigp | ...	





 Credits:

	CWP: Norm Bleistein, Jack K. Cohen





 Theory: Use the 3D Born integral equation (e.g., Geophysics,

 v51, n8, p1554(7)). Use 2-D delta function for alpha and do

 remaining y-integral by stationary phase.



 Note: Setting a 2D offset in a single offset field beats the

       hell out of us.  We did _something_.



 Trace header fields set: ns, dt, tracl, tracr, fldr, sx, selev,

                          gx, gelev, offset



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

my $suimp2d			= {
	_c					=> '',
	_dgx					=> '',
	_dgz					=> '',
	_dsx					=> '',
	_dsz					=> '',
	_dt					=> '',
	_gxmin					=> '',
	_gzmin					=> '',
	_nrec					=> '',
	_nshot					=> '',
	_nt					=> '',
	_sxmin					=> '',
	_szmin					=> '',
	_x0					=> '',
	_z0					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suimp2d->{_Step}     = 'suimp2d'.$suimp2d->{_Step};
	return ( $suimp2d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suimp2d->{_note}     = 'suimp2d'.$suimp2d->{_note};
	return ( $suimp2d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suimp2d->{_c}			= '';
		$suimp2d->{_dgx}			= '';
		$suimp2d->{_dgz}			= '';
		$suimp2d->{_dsx}			= '';
		$suimp2d->{_dsz}			= '';
		$suimp2d->{_dt}			= '';
		$suimp2d->{_gxmin}			= '';
		$suimp2d->{_gzmin}			= '';
		$suimp2d->{_nrec}			= '';
		$suimp2d->{_nshot}			= '';
		$suimp2d->{_nt}			= '';
		$suimp2d->{_sxmin}			= '';
		$suimp2d->{_szmin}			= '';
		$suimp2d->{_x0}			= '';
		$suimp2d->{_z0}			= '';
		$suimp2d->{_Step}			= '';
		$suimp2d->{_note}			= '';
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$suimp2d->{_c}		= $c;
		$suimp2d->{_note}		= $suimp2d->{_note}.' c='.$suimp2d->{_c};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' c='.$suimp2d->{_c};

	} else { 
		print("suimp2d, c, missing c,\n");
	 }
 }


=head2 sub dgx 


=cut

 sub dgx {

	my ( $self,$dgx )		= @_;
	if ( $dgx ne $empty_string ) {

		$suimp2d->{_dgx}		= $dgx;
		$suimp2d->{_note}		= $suimp2d->{_note}.' dgx='.$suimp2d->{_dgx};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' dgx='.$suimp2d->{_dgx};

	} else { 
		print("suimp2d, dgx, missing dgx,\n");
	 }
 }


=head2 sub dgz 


=cut

 sub dgz {

	my ( $self,$dgz )		= @_;
	if ( $dgz ne $empty_string ) {

		$suimp2d->{_dgz}		= $dgz;
		$suimp2d->{_note}		= $suimp2d->{_note}.' dgz='.$suimp2d->{_dgz};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' dgz='.$suimp2d->{_dgz};

	} else { 
		print("suimp2d, dgz, missing dgz,\n");
	 }
 }


=head2 sub dsx 


=cut

 sub dsx {

	my ( $self,$dsx )		= @_;
	if ( $dsx ne $empty_string ) {

		$suimp2d->{_dsx}		= $dsx;
		$suimp2d->{_note}		= $suimp2d->{_note}.' dsx='.$suimp2d->{_dsx};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' dsx='.$suimp2d->{_dsx};

	} else { 
		print("suimp2d, dsx, missing dsx,\n");
	 }
 }


=head2 sub dsz 


=cut

 sub dsz {

	my ( $self,$dsz )		= @_;
	if ( $dsz ne $empty_string ) {

		$suimp2d->{_dsz}		= $dsz;
		$suimp2d->{_note}		= $suimp2d->{_note}.' dsz='.$suimp2d->{_dsz};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' dsz='.$suimp2d->{_dsz};

	} else { 
		print("suimp2d, dsz, missing dsz,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suimp2d->{_dt}		= $dt;
		$suimp2d->{_note}		= $suimp2d->{_note}.' dt='.$suimp2d->{_dt};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' dt='.$suimp2d->{_dt};

	} else { 
		print("suimp2d, dt, missing dt,\n");
	 }
 }


=head2 sub gxmin 


=cut

 sub gxmin {

	my ( $self,$gxmin )		= @_;
	if ( $gxmin ne $empty_string ) {

		$suimp2d->{_gxmin}		= $gxmin;
		$suimp2d->{_note}		= $suimp2d->{_note}.' gxmin='.$suimp2d->{_gxmin};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' gxmin='.$suimp2d->{_gxmin};

	} else { 
		print("suimp2d, gxmin, missing gxmin,\n");
	 }
 }


=head2 sub gzmin 


=cut

 sub gzmin {

	my ( $self,$gzmin )		= @_;
	if ( $gzmin ne $empty_string ) {

		$suimp2d->{_gzmin}		= $gzmin;
		$suimp2d->{_note}		= $suimp2d->{_note}.' gzmin='.$suimp2d->{_gzmin};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' gzmin='.$suimp2d->{_gzmin};

	} else { 
		print("suimp2d, gzmin, missing gzmin,\n");
	 }
 }


=head2 sub nrec 


=cut

 sub nrec {

	my ( $self,$nrec )		= @_;
	if ( $nrec ne $empty_string ) {

		$suimp2d->{_nrec}		= $nrec;
		$suimp2d->{_note}		= $suimp2d->{_note}.' nrec='.$suimp2d->{_nrec};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' nrec='.$suimp2d->{_nrec};

	} else { 
		print("suimp2d, nrec, missing nrec,\n");
	 }
 }


=head2 sub nshot 


=cut

 sub nshot {

	my ( $self,$nshot )		= @_;
	if ( $nshot ne $empty_string ) {

		$suimp2d->{_nshot}		= $nshot;
		$suimp2d->{_note}		= $suimp2d->{_note}.' nshot='.$suimp2d->{_nshot};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' nshot='.$suimp2d->{_nshot};

	} else { 
		print("suimp2d, nshot, missing nshot,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suimp2d->{_nt}		= $nt;
		$suimp2d->{_note}		= $suimp2d->{_note}.' nt='.$suimp2d->{_nt};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' nt='.$suimp2d->{_nt};

	} else { 
		print("suimp2d, nt, missing nt,\n");
	 }
 }


=head2 sub sxmin 


=cut

 sub sxmin {

	my ( $self,$sxmin )		= @_;
	if ( $sxmin ne $empty_string ) {

		$suimp2d->{_sxmin}		= $sxmin;
		$suimp2d->{_note}		= $suimp2d->{_note}.' sxmin='.$suimp2d->{_sxmin};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' sxmin='.$suimp2d->{_sxmin};

	} else { 
		print("suimp2d, sxmin, missing sxmin,\n");
	 }
 }


=head2 sub szmin 


=cut

 sub szmin {

	my ( $self,$szmin )		= @_;
	if ( $szmin ne $empty_string ) {

		$suimp2d->{_szmin}		= $szmin;
		$suimp2d->{_note}		= $suimp2d->{_note}.' szmin='.$suimp2d->{_szmin};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' szmin='.$suimp2d->{_szmin};

	} else { 
		print("suimp2d, szmin, missing szmin,\n");
	 }
 }


=head2 sub x0 


=cut

 sub x0 {

	my ( $self,$x0 )		= @_;
	if ( $x0 ne $empty_string ) {

		$suimp2d->{_x0}		= $x0;
		$suimp2d->{_note}		= $suimp2d->{_note}.' x0='.$suimp2d->{_x0};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' x0='.$suimp2d->{_x0};

	} else { 
		print("suimp2d, x0, missing x0,\n");
	 }
 }


=head2 sub z0 


=cut

 sub z0 {

	my ( $self,$z0 )		= @_;
	if ( $z0 ne $empty_string ) {

		$suimp2d->{_z0}		= $z0;
		$suimp2d->{_note}		= $suimp2d->{_note}.' z0='.$suimp2d->{_z0};
		$suimp2d->{_Step}		= $suimp2d->{_Step}.' z0='.$suimp2d->{_z0};

	} else { 
		print("suimp2d, z0, missing z0,\n");
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
