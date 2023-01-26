package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suztot;

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
 SUZTOT - resample from depth to time					



 suztot <stdin >stdout [optional parms]				



 Optional Parameters:							

 nt=1+(nz-1)*2.0*dz/(vmax*dt)    number of time samples in output	

 dt=2*dz/vmin		time sampling interval (defaults avoids aliasing)

 ft=2*fz/v(fz)		first time sample				

 z=0.0,...		depths corresponding to interval velocities in v

 v=1500.0,...		interval velocities corresponding to depths in v

 vfile=		binary (non-ascii) file containing velocities v(z)

 verbose=0		>0 to print depth sampling information		



 Notes:								

 Default value of nt set to avoid aliasing				

 The z and v arrays specify an interval velocity function of depth.	



 Note that z and v are given  as arrays of floats separated by commas,  

 for example:								

 z=0.0,100,200,... v=1500.0,1720.0,1833.5,... with the number of z values

 equaling the number of v values. The velocities are linearly interpolated

 to produce a piecewise linear v(z) profile. This fact must be taken into

 account when attempting to use this program as the inverse of suttoz.	



 Linear interpolation and constant extrapolation is used to determine	

 interval velocities at times not specified.  Values specified in z	

 must increase monotonically.						



 Alternatively, interval velocities may be stored in a binary file	

 containing one velocity for every time sample.  If vfile is specified,

 then the z and v arrays are ignored.					



 see the selfdoc of   suttoz  for time to depth conversion		

 Trace header fields accessed:  ns, dt, and delrt			

 Trace header fields modified:  trid, ns, d1, and f1			





 Credits:

	CWP: John Stockwell, 2005, 

            based on suttoz.c written by Dave Hale c. 1992





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

my $suztot			= {
	_dt					=> '',
	_ft					=> '',
	_nt					=> '',
	_v					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_z					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suztot->{_Step}     = 'suztot'.$suztot->{_Step};
	return ( $suztot->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suztot->{_note}     = 'suztot'.$suztot->{_note};
	return ( $suztot->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suztot->{_dt}			= '';
		$suztot->{_ft}			= '';
		$suztot->{_nt}			= '';
		$suztot->{_v}			= '';
		$suztot->{_verbose}			= '';
		$suztot->{_vfile}			= '';
		$suztot->{_z}			= '';
		$suztot->{_Step}			= '';
		$suztot->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suztot->{_dt}		= $dt;
		$suztot->{_note}		= $suztot->{_note}.' dt='.$suztot->{_dt};
		$suztot->{_Step}		= $suztot->{_Step}.' dt='.$suztot->{_dt};

	} else { 
		print("suztot, dt, missing dt,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$suztot->{_ft}		= $ft;
		$suztot->{_note}		= $suztot->{_note}.' ft='.$suztot->{_ft};
		$suztot->{_Step}		= $suztot->{_Step}.' ft='.$suztot->{_ft};

	} else { 
		print("suztot, ft, missing ft,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$suztot->{_nt}		= $nt;
		$suztot->{_note}		= $suztot->{_note}.' nt='.$suztot->{_nt};
		$suztot->{_Step}		= $suztot->{_Step}.' nt='.$suztot->{_nt};

	} else { 
		print("suztot, nt, missing nt,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$suztot->{_v}		= $v;
		$suztot->{_note}		= $suztot->{_note}.' v='.$suztot->{_v};
		$suztot->{_Step}		= $suztot->{_Step}.' v='.$suztot->{_v};

	} else { 
		print("suztot, v, missing v,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suztot->{_verbose}		= $verbose;
		$suztot->{_note}		= $suztot->{_note}.' verbose='.$suztot->{_verbose};
		$suztot->{_Step}		= $suztot->{_Step}.' verbose='.$suztot->{_verbose};

	} else { 
		print("suztot, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$suztot->{_vfile}		= $vfile;
		$suztot->{_note}		= $suztot->{_note}.' vfile='.$suztot->{_vfile};
		$suztot->{_Step}		= $suztot->{_Step}.' vfile='.$suztot->{_vfile};

	} else { 
		print("suztot, vfile, missing vfile,\n");
	 }
 }


=head2 sub z 


=cut

 sub z {

	my ( $self,$z )		= @_;
	if ( $z ne $empty_string ) {

		$suztot->{_z}		= $z;
		$suztot->{_note}		= $suztot->{_note}.' z='.$suztot->{_z};
		$suztot->{_Step}		= $suztot->{_Step}.' z='.$suztot->{_z};

	} else { 
		print("suztot, z, missing z,\n");
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
