package App::SeismicUnixGui::sunix::migration::sugazmig;

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
 SUGAZMIGQ - SU version of Jeno GAZDAG's phase-shift migration 	

	     for zero-offset data, with attenuation Q.			



 sugazmig <infile >outfile vfile= [optional parameters]		



 Optional Parameters:							

 dt=from header(dt) or	.004	time sampling interval			

 dx=from header(d2) or 1.0	midpoint sampling interval		

 ft=0.0			first time sample			

 ntau=nt(from data)	number of migrated time samples			

 dtau=dt(from header)	migrated time sampling interval			

 ftau=ft		first migrated time sample			

 tmig=0.0		times corresponding to interval velocities in vmig

 vmig=1500.0	interval velocities corresponding to times in tmig	

 vfile=		name of file containing velocities		

 Q=1e6			quality factor					

 ceil=1e6		gain ceiling beyond which migration ceases	



 verbose=0	verbose = 1 echoes information				



 tmpdir= 	 if non-empty, use the value as a directory path	

		 prefix for storing temporary files; else if the	

	         the CWP_TMPDIR environment variable is set use		

	         its value for the path; else use tmpfile()		



 Note: ray bending effects not accounted for in this version.		



 The tmig and vmig arrays specify an interval velocity function of time.

 Linear interpolation and constant extrapolation is used to determine	

 interval velocities at times not specified.  Values specified in tmig	

 must increase monotonically.						



 Alternatively, interval velocities may be stored in a binary file	

 containing one velocity for every time sample in the data that is to be

 migrated.  If vfile is specified, then the tmig and vmig arrays are ignored.



 Caveat: Adding Q is a first attempt to address GPR issues.		



 

 Credits: 

  Constant Q attenuation correction by Chuck Oden 5 May 2004

  CWP John Stockwell 12 Oct 1992

 	Based on a constant v version by Dave Hale.



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

my $sugazmig			= {
	_Q					=> '',
	_ceil					=> '',
	_dt					=> '',
	_dtau					=> '',
	_dx					=> '',
	_ft					=> '',
	_ftau					=> '',
	_ntau					=> '',
	_tmig					=> '',
	_tmpdir					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_vmig					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sugazmig->{_Step}     = 'sugazmig'.$sugazmig->{_Step};
	return ( $sugazmig->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sugazmig->{_note}     = 'sugazmig'.$sugazmig->{_note};
	return ( $sugazmig->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sugazmig->{_Q}			= '';
		$sugazmig->{_ceil}			= '';
		$sugazmig->{_dt}			= '';
		$sugazmig->{_dtau}			= '';
		$sugazmig->{_dx}			= '';
		$sugazmig->{_ft}			= '';
		$sugazmig->{_ftau}			= '';
		$sugazmig->{_ntau}			= '';
		$sugazmig->{_tmig}			= '';
		$sugazmig->{_tmpdir}			= '';
		$sugazmig->{_verbose}			= '';
		$sugazmig->{_vfile}			= '';
		$sugazmig->{_vmig}			= '';
		$sugazmig->{_Step}			= '';
		$sugazmig->{_note}			= '';
 }


=head2 sub Q 


=cut

 sub Q {

	my ( $self,$Q )		= @_;
	if ( $Q ne $empty_string ) {

		$sugazmig->{_Q}		= $Q;
		$sugazmig->{_note}		= $sugazmig->{_note}.' Q='.$sugazmig->{_Q};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' Q='.$sugazmig->{_Q};

	} else { 
		print("sugazmig, Q, missing Q,\n");
	 }
 }


=head2 sub ceil 


=cut

 sub ceil {

	my ( $self,$ceil )		= @_;
	if ( $ceil ne $empty_string ) {

		$sugazmig->{_ceil}		= $ceil;
		$sugazmig->{_note}		= $sugazmig->{_note}.' ceil='.$sugazmig->{_ceil};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' ceil='.$sugazmig->{_ceil};

	} else { 
		print("sugazmig, ceil, missing ceil,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sugazmig->{_dt}		= $dt;
		$sugazmig->{_note}		= $sugazmig->{_note}.' dt='.$sugazmig->{_dt};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' dt='.$sugazmig->{_dt};

	} else { 
		print("sugazmig, dt, missing dt,\n");
	 }
 }


=head2 sub dtau 


=cut

 sub dtau {

	my ( $self,$dtau )		= @_;
	if ( $dtau ne $empty_string ) {

		$sugazmig->{_dtau}		= $dtau;
		$sugazmig->{_note}		= $sugazmig->{_note}.' dtau='.$sugazmig->{_dtau};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' dtau='.$sugazmig->{_dtau};

	} else { 
		print("sugazmig, dtau, missing dtau,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sugazmig->{_dx}		= $dx;
		$sugazmig->{_note}		= $sugazmig->{_note}.' dx='.$sugazmig->{_dx};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' dx='.$sugazmig->{_dx};

	} else { 
		print("sugazmig, dx, missing dx,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$sugazmig->{_ft}		= $ft;
		$sugazmig->{_note}		= $sugazmig->{_note}.' ft='.$sugazmig->{_ft};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' ft='.$sugazmig->{_ft};

	} else { 
		print("sugazmig, ft, missing ft,\n");
	 }
 }


=head2 sub ftau 


=cut

 sub ftau {

	my ( $self,$ftau )		= @_;
	if ( $ftau ne $empty_string ) {

		$sugazmig->{_ftau}		= $ftau;
		$sugazmig->{_note}		= $sugazmig->{_note}.' ftau='.$sugazmig->{_ftau};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' ftau='.$sugazmig->{_ftau};

	} else { 
		print("sugazmig, ftau, missing ftau,\n");
	 }
 }


=head2 sub ntau 


=cut

 sub ntau {

	my ( $self,$ntau )		= @_;
	if ( $ntau ne $empty_string ) {

		$sugazmig->{_ntau}		= $ntau;
		$sugazmig->{_note}		= $sugazmig->{_note}.' ntau='.$sugazmig->{_ntau};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' ntau='.$sugazmig->{_ntau};

	} else { 
		print("sugazmig, ntau, missing ntau,\n");
	 }
 }


=head2 sub tmig 


=cut

 sub tmig {

	my ( $self,$tmig )		= @_;
	if ( $tmig ne $empty_string ) {

		$sugazmig->{_tmig}		= $tmig;
		$sugazmig->{_note}		= $sugazmig->{_note}.' tmig='.$sugazmig->{_tmig};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' tmig='.$sugazmig->{_tmig};

	} else { 
		print("sugazmig, tmig, missing tmig,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sugazmig->{_tmpdir}		= $tmpdir;
		$sugazmig->{_note}		= $sugazmig->{_note}.' tmpdir='.$sugazmig->{_tmpdir};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' tmpdir='.$sugazmig->{_tmpdir};

	} else { 
		print("sugazmig, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sugazmig->{_verbose}		= $verbose;
		$sugazmig->{_note}		= $sugazmig->{_note}.' verbose='.$sugazmig->{_verbose};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' verbose='.$sugazmig->{_verbose};

	} else { 
		print("sugazmig, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sugazmig->{_vfile}		= $vfile;
		$sugazmig->{_note}		= $sugazmig->{_note}.' vfile='.$sugazmig->{_vfile};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' vfile='.$sugazmig->{_vfile};

	} else { 
		print("sugazmig, vfile, missing vfile,\n");
	 }
 }


=head2 sub vmig 


=cut

 sub vmig {

	my ( $self,$vmig )		= @_;
	if ( $vmig ne $empty_string ) {

		$sugazmig->{_vmig}		= $vmig;
		$sugazmig->{_note}		= $sugazmig->{_note}.' vmig='.$sugazmig->{_vmig};
		$sugazmig->{_Step}		= $sugazmig->{_Step}.' vmig='.$sugazmig->{_vmig};

	} else { 
		print("sugazmig, vmig, missing vmig,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
