package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suttoz;

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
 SUTTOZ - resample from time to depth					



 suttoz <stdin >stdout [optional parms]				



 Optional Parameters:							

 nz=1+(nt-1)*dt*vmax/(2.0*dz)   number of depth samples in output	

 dz=vmin*dt/2		depth sampling interval (defaults avoids aliasing)

 fz=v(ft)*ft/2		first depth sample				

 t=0.0,...		times corresponding to interval velocities in v

 v=1500.0,...		interval velocities corresponding to times in v

 vfile=		  binary (non-ascii) file containing velocities v(t)

 verbose=0		>0 to print depth sampling information		



 Notes:								

 Default value of nz set to avoid aliasing				

 The t and v arrays specify an interval velocity function of time.	



 Note that t and v are given  as arrays of floats separated by commas,  

 for example:								

 t=0.0,0.01,.2,... v=1500.0,1720.0,1833.5,... with the number of t values

 equaling the number of v values. The velocities are linearly interpolated

 to make a continuous, piecewise linear v(t) profile.			



 Linear interpolation and constant extrapolation is used to determine	

 interval velocities at times not specified.  Values specified in t	

 must increase monotonically.						



 Alternatively, interval velocities may be stored in a binary file	

 containing one velocity for every time sample.  If vfile is specified,

 then the t and v arrays are ignored.					



 see selfdoc of suztot  for depth to time conversion			



 Trace header fields accessed:  ns, dt, and delrt			

 Trace header fields modified:  trid, ns, d1, and f1			





 Credits:

	CWP: Dave Hale c. 1992





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

my $suttoz			= {
	_dz					=> '',
	_fz					=> '',
	_nz					=> '',
	_t					=> '',
	_v					=> '',
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

	$suttoz->{_Step}     = 'suttoz'.$suttoz->{_Step};
	return ( $suttoz->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suttoz->{_note}     = 'suttoz'.$suttoz->{_note};
	return ( $suttoz->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suttoz->{_dz}			= '';
		$suttoz->{_fz}			= '';
		$suttoz->{_nz}			= '';
		$suttoz->{_t}			= '';
		$suttoz->{_v}			= '';
		$suttoz->{_verbose}			= '';
		$suttoz->{_vfile}			= '';
		$suttoz->{_Step}			= '';
		$suttoz->{_note}			= '';
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$suttoz->{_dz}		= $dz;
		$suttoz->{_note}		= $suttoz->{_note}.' dz='.$suttoz->{_dz};
		$suttoz->{_Step}		= $suttoz->{_Step}.' dz='.$suttoz->{_dz};

	} else { 
		print("suttoz, dz, missing dz,\n");
	 }
 }


=head2 sub fz 


=cut

 sub fz {

	my ( $self,$fz )		= @_;
	if ( $fz ne $empty_string ) {

		$suttoz->{_fz}		= $fz;
		$suttoz->{_note}		= $suttoz->{_note}.' fz='.$suttoz->{_fz};
		$suttoz->{_Step}		= $suttoz->{_Step}.' fz='.$suttoz->{_fz};

	} else { 
		print("suttoz, fz, missing fz,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$suttoz->{_nz}		= $nz;
		$suttoz->{_note}		= $suttoz->{_note}.' nz='.$suttoz->{_nz};
		$suttoz->{_Step}		= $suttoz->{_Step}.' nz='.$suttoz->{_nz};

	} else { 
		print("suttoz, nz, missing nz,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$suttoz->{_t}		= $t;
		$suttoz->{_note}		= $suttoz->{_note}.' t='.$suttoz->{_t};
		$suttoz->{_Step}		= $suttoz->{_Step}.' t='.$suttoz->{_t};

	} else { 
		print("suttoz, t, missing t,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$suttoz->{_v}		= $v;
		$suttoz->{_note}		= $suttoz->{_note}.' v='.$suttoz->{_v};
		$suttoz->{_Step}		= $suttoz->{_Step}.' v='.$suttoz->{_v};

	} else { 
		print("suttoz, v, missing v,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suttoz->{_verbose}		= $verbose;
		$suttoz->{_note}		= $suttoz->{_note}.' verbose='.$suttoz->{_verbose};
		$suttoz->{_Step}		= $suttoz->{_Step}.' verbose='.$suttoz->{_verbose};

	} else { 
		print("suttoz, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suttoz->{_vfile}		= $vfile;
		$suttoz->{_note}		= $suttoz->{_note}.' vfile='.$suttoz->{_vfile};
		$suttoz->{_Step}		= $suttoz->{_Step}.' vfile='.$suttoz->{_vfile};

	} else { 
		print("suttoz, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
