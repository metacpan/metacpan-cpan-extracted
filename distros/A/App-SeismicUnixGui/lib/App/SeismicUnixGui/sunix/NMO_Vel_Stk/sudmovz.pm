package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudmovz;

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
 SUDMOVZ - DMO for V(Z) media for common-offset gathers		



 sudmovz <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [...]		



 Required Parameters:							

 cdpmin         minimum cdp (integer number) for which to apply DMO	

 cdpmax         maximum cdp (integer number) for which to apply DMO	

 dxcdp          distance between adjacent cdp bins (m)			

 noffmix        number of offsets to mix (see notes)			



 Optional Parameters:							

 vfile=         binary (non-ascii) file containing interval velocities (m/s)

 tdmo=0.0       times corresponding to interval velocities in vdmo (s)	

 vdmo=1500.0    interval velocities corresponding to times in tdmo (m/s)

 fmax=0.5/dt    maximum frequency in input traces (Hz)			

 smute=1.5      stretch mute used for NMO correction			

 speed=1.0      twist this knob for speed (and aliasing)		

 verbose=0      =1 for diagnostic print				



 Notes:								

 Input traces should be sorted into common-offset gathers.  One common-

 offset gather ends and another begins when the offset field of the trace

 headers changes.							



 The cdp field of the input trace headers must be the cdp bin NUMBER, NOT

 the cdp location expressed in units of meters or feet.		



 The number of offsets to mix (noffmix) should typically equal the ratio of

 the shotpoint spacing to the cdp spacing.  This choice ensures that every

 cdp will be represented in each offset mix.  Traces in each mix will	

 contribute through DMO to other traces in adjacent cdps within that mix.



 vfile should contain the regularly sampled interval velocities as a	

 function of time.  If vfile is not supplied, the interval velocity	

 function is defined by linear interpolation of the values in the tdmo	

 and vdmo arrays.  The times in tdmo must be monotonically increasing.	



 For each offset, the minimum time to process is determined using the	

 smute parameter.  The DMO correction is not computed for samples that	

 have experienced greater stretch during NMO.				



 Trace header fields accessed:  nt, dt, delrt, offset, cdp.		

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

my $sudmovz			= {
	_cdpmin					=> '',
	_fmax					=> '',
	_smute					=> '',
	_speed					=> '',
	_tdmo					=> '',
	_vdmo					=> '',
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

	$sudmovz->{_Step}     = 'sudmovz'.$sudmovz->{_Step};
	return ( $sudmovz->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudmovz->{_note}     = 'sudmovz'.$sudmovz->{_note};
	return ( $sudmovz->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudmovz->{_cdpmin}			= '';
		$sudmovz->{_fmax}			= '';
		$sudmovz->{_smute}			= '';
		$sudmovz->{_speed}			= '';
		$sudmovz->{_tdmo}			= '';
		$sudmovz->{_vdmo}			= '';
		$sudmovz->{_verbose}			= '';
		$sudmovz->{_vfile}			= '';
		$sudmovz->{_Step}			= '';
		$sudmovz->{_note}			= '';
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sudmovz->{_cdpmin}		= $cdpmin;
		$sudmovz->{_note}		= $sudmovz->{_note}.' cdpmin='.$sudmovz->{_cdpmin};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' cdpmin='.$sudmovz->{_cdpmin};

	} else { 
		print("sudmovz, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sudmovz->{_fmax}		= $fmax;
		$sudmovz->{_note}		= $sudmovz->{_note}.' fmax='.$sudmovz->{_fmax};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' fmax='.$sudmovz->{_fmax};

	} else { 
		print("sudmovz, fmax, missing fmax,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$sudmovz->{_smute}		= $smute;
		$sudmovz->{_note}		= $sudmovz->{_note}.' smute='.$sudmovz->{_smute};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' smute='.$sudmovz->{_smute};

	} else { 
		print("sudmovz, smute, missing smute,\n");
	 }
 }


=head2 sub speed 


=cut

 sub speed {

	my ( $self,$speed )		= @_;
	if ( $speed ne $empty_string ) {

		$sudmovz->{_speed}		= $speed;
		$sudmovz->{_note}		= $sudmovz->{_note}.' speed='.$sudmovz->{_speed};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' speed='.$sudmovz->{_speed};

	} else { 
		print("sudmovz, speed, missing speed,\n");
	 }
 }


=head2 sub tdmo 


=cut

 sub tdmo {

	my ( $self,$tdmo )		= @_;
	if ( $tdmo ne $empty_string ) {

		$sudmovz->{_tdmo}		= $tdmo;
		$sudmovz->{_note}		= $sudmovz->{_note}.' tdmo='.$sudmovz->{_tdmo};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' tdmo='.$sudmovz->{_tdmo};

	} else { 
		print("sudmovz, tdmo, missing tdmo,\n");
	 }
 }


=head2 sub vdmo 


=cut

 sub vdmo {

	my ( $self,$vdmo )		= @_;
	if ( $vdmo ne $empty_string ) {

		$sudmovz->{_vdmo}		= $vdmo;
		$sudmovz->{_note}		= $sudmovz->{_note}.' vdmo='.$sudmovz->{_vdmo};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' vdmo='.$sudmovz->{_vdmo};

	} else { 
		print("sudmovz, vdmo, missing vdmo,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudmovz->{_verbose}		= $verbose;
		$sudmovz->{_note}		= $sudmovz->{_note}.' verbose='.$sudmovz->{_verbose};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' verbose='.$sudmovz->{_verbose};

	} else { 
		print("sudmovz, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sudmovz->{_vfile}		= $vfile;
		$sudmovz->{_note}		= $sudmovz->{_note}.' vfile='.$sudmovz->{_vfile};
		$sudmovz->{_Step}		= $sudmovz->{_Step}.' vfile='.$sudmovz->{_vfile};

	} else { 
		print("sudmovz, vfile, missing vfile,\n");
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
