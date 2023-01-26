package App::SeismicUnixGui::sunix::model::susyncz;

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
 SUSYNCZ - SYNthetic seismograms for piecewise constant V(Z) function	

	   True amplitude (primaries only) modeling for 2.5D		



  susyncz > outfile [parameters]					



 Required parameters:							

 none									



 Optional Parameters:							

 ninf=4        number of interfaces (not including upper surface)	

 dip=5*i       dips of interfaces in degrees (i=1,2,3,4)		

 zint=100*i    z-intercepts of interfaces at x=0 (i=1,2,3,4)		

 v=1500+ 500*i velocities below surface & interfaces (i=0,1,2,3,4)	

 rho=1,1,1,1,1 densities below surface & interfaces (i=0,1,2,3,4)	

 nline=1	number of (identical) lines				

 ntr=32        number of traces					

 dx=10         trace interval						

 tdelay=0      delay in recording time after source initiation		

 dt=0.004      time interval						

 nt=128        number of time samples					



 Notes:								

 The original purpose of this code was to create some nontrivial	

 data for Brian Sumner's CZ suite.					



 The program produces zero-offset data over dipping reflectors.	



 In the original fortran code, some arrays had the index		

 interval 1:ninf, as a natural way to index over the subsurface	

 reflectors.  This indexing was preserved in this C translation.	

 Consequently, some arrays in the code do not use the 0 "slot".	



 Example:								

	susyncz | sufilter | sugain tpow=1 | display_program		



 Trace header fields set: tracl, ns, dt, delrt, ntr, sx, gx		





 Credits:

 	CWP: Brian Sumner, 1983, 1985, Fortran design and code 

      CWP: Stockwell & Cohen, 1995, translation to C 







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

my $susyncz			= {
	_dip					=> '',
	_dt					=> '',
	_dx					=> '',
	_ninf					=> '',
	_nline					=> '',
	_nt					=> '',
	_ntr					=> '',
	_rho					=> '',
	_tdelay					=> '',
	_tpow					=> '',
	_v					=> '',
	_zint					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susyncz->{_Step}     = 'susyncz'.$susyncz->{_Step};
	return ( $susyncz->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susyncz->{_note}     = 'susyncz'.$susyncz->{_note};
	return ( $susyncz->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susyncz->{_dip}			= '';
		$susyncz->{_dt}			= '';
		$susyncz->{_dx}			= '';
		$susyncz->{_ninf}			= '';
		$susyncz->{_nline}			= '';
		$susyncz->{_nt}			= '';
		$susyncz->{_ntr}			= '';
		$susyncz->{_rho}			= '';
		$susyncz->{_tdelay}			= '';
		$susyncz->{_tpow}			= '';
		$susyncz->{_v}			= '';
		$susyncz->{_zint}			= '';
		$susyncz->{_Step}			= '';
		$susyncz->{_note}			= '';
 }


=head2 sub dip 


=cut

 sub dip {

	my ( $self,$dip )		= @_;
	if ( $dip ne $empty_string ) {

		$susyncz->{_dip}		= $dip;
		$susyncz->{_note}		= $susyncz->{_note}.' dip='.$susyncz->{_dip};
		$susyncz->{_Step}		= $susyncz->{_Step}.' dip='.$susyncz->{_dip};

	} else { 
		print("susyncz, dip, missing dip,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$susyncz->{_dt}		= $dt;
		$susyncz->{_note}		= $susyncz->{_note}.' dt='.$susyncz->{_dt};
		$susyncz->{_Step}		= $susyncz->{_Step}.' dt='.$susyncz->{_dt};

	} else { 
		print("susyncz, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$susyncz->{_dx}		= $dx;
		$susyncz->{_note}		= $susyncz->{_note}.' dx='.$susyncz->{_dx};
		$susyncz->{_Step}		= $susyncz->{_Step}.' dx='.$susyncz->{_dx};

	} else { 
		print("susyncz, dx, missing dx,\n");
	 }
 }


=head2 sub ninf 


=cut

 sub ninf {

	my ( $self,$ninf )		= @_;
	if ( $ninf ne $empty_string ) {

		$susyncz->{_ninf}		= $ninf;
		$susyncz->{_note}		= $susyncz->{_note}.' ninf='.$susyncz->{_ninf};
		$susyncz->{_Step}		= $susyncz->{_Step}.' ninf='.$susyncz->{_ninf};

	} else { 
		print("susyncz, ninf, missing ninf,\n");
	 }
 }


=head2 sub nline 


=cut

 sub nline {

	my ( $self,$nline )		= @_;
	if ( $nline ne $empty_string ) {

		$susyncz->{_nline}		= $nline;
		$susyncz->{_note}		= $susyncz->{_note}.' nline='.$susyncz->{_nline};
		$susyncz->{_Step}		= $susyncz->{_Step}.' nline='.$susyncz->{_nline};

	} else { 
		print("susyncz, nline, missing nline,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$susyncz->{_nt}		= $nt;
		$susyncz->{_note}		= $susyncz->{_note}.' nt='.$susyncz->{_nt};
		$susyncz->{_Step}		= $susyncz->{_Step}.' nt='.$susyncz->{_nt};

	} else { 
		print("susyncz, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$susyncz->{_ntr}		= $ntr;
		$susyncz->{_note}		= $susyncz->{_note}.' ntr='.$susyncz->{_ntr};
		$susyncz->{_Step}		= $susyncz->{_Step}.' ntr='.$susyncz->{_ntr};

	} else { 
		print("susyncz, ntr, missing ntr,\n");
	 }
 }


=head2 sub rho 


=cut

 sub rho {

	my ( $self,$rho )		= @_;
	if ( $rho ne $empty_string ) {

		$susyncz->{_rho}		= $rho;
		$susyncz->{_note}		= $susyncz->{_note}.' rho='.$susyncz->{_rho};
		$susyncz->{_Step}		= $susyncz->{_Step}.' rho='.$susyncz->{_rho};

	} else { 
		print("susyncz, rho, missing rho,\n");
	 }
 }


=head2 sub tdelay 


=cut

 sub tdelay {

	my ( $self,$tdelay )		= @_;
	if ( $tdelay ne $empty_string ) {

		$susyncz->{_tdelay}		= $tdelay;
		$susyncz->{_note}		= $susyncz->{_note}.' tdelay='.$susyncz->{_tdelay};
		$susyncz->{_Step}		= $susyncz->{_Step}.' tdelay='.$susyncz->{_tdelay};

	} else { 
		print("susyncz, tdelay, missing tdelay,\n");
	 }
 }


=head2 sub tpow 


=cut

 sub tpow {

	my ( $self,$tpow )		= @_;
	if ( $tpow ne $empty_string ) {

		$susyncz->{_tpow}		= $tpow;
		$susyncz->{_note}		= $susyncz->{_note}.' tpow='.$susyncz->{_tpow};
		$susyncz->{_Step}		= $susyncz->{_Step}.' tpow='.$susyncz->{_tpow};

	} else { 
		print("susyncz, tpow, missing tpow,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$susyncz->{_v}		= $v;
		$susyncz->{_note}		= $susyncz->{_note}.' v='.$susyncz->{_v};
		$susyncz->{_Step}		= $susyncz->{_Step}.' v='.$susyncz->{_v};

	} else { 
		print("susyncz, v, missing v,\n");
	 }
 }


=head2 sub zint 


=cut

 sub zint {

	my ( $self,$zint )		= @_;
	if ( $zint ne $empty_string ) {

		$susyncz->{_zint}		= $zint;
		$susyncz->{_note}		= $susyncz->{_note}.' zint='.$susyncz->{_zint};
		$susyncz->{_Step}		= $susyncz->{_Step}.' zint='.$susyncz->{_zint};

	} else { 
		print("susyncz, zint, missing zint,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 11;

    return($max_index);
}
 
 
1;
