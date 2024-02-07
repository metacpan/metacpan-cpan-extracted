package App::SeismicUnixGui::sunix::migration::sumigpsti;

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
 SUMIGPSTI - MIGration by Phase Shift for TI media with turning rays	



 sumigpsti <stdin >stdout [optional parms]				



 Required Parameters:							

 	None								



 Optional Parameters:							

 dt=from header(dt) or .004	time sampling interval			

 dx=from header(d2) or 1.0	distance between sucessive cdp's	

 ffil=

 0,0,0.5/dt,0.5/dt  trapezoidal window of frequencies to migrate	

 tmig=0.0	times corresponding to interval velocities in vmig	

 vnmig=1500.0	interval NMO velocities corresponding to times in tmig	

 vmig=1500.0	interval velocities corresponding to times in tmig	

 etamig=0.0	interval eta values corresponding to times in tmig	

 vnfile=	binary (non-ascii) file containing NMO velocities vn(t)	

 vfile=	binary (non-ascii) file containing velocities v(t)	

 etafile=	binary (non-ascii) file containing eta values eta(t)	

 nxpad=0	number of cdps to pad with zeros before FFT		

 ltaper=0	length of linear taper for left and right edges		", 

 verbose=0	=1 for diagnostic print					



 Notes:								

 Input traces must be sorted by either increasing or decreasing cdp.	



 The tmig, vnmig, vmig and etamig arrays specify an interval values	

 function of time. Linear interpolation and constant extrapolation is	

 used to determine interval velocities at times not specified.  Values	

 specified in tmig must increase monotonically.			

 Alternatively, interval velocities may be stored in a binary file	

 containing one velocity for every time sample.  If vnfile is specified,

 then the tmig and vnmig arrays are ignored.				



 The time of first sample is assumed to be zero, regardless of the value

 of the trace header field delrt.					



 Trace header fields accessed:  ns and dt				





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

my $sumigpsti			= {
	_dt					=> '',
	_dx					=> '',
	_etafile					=> '',
	_etamig					=> '',
	_ltaper					=> '',
	_nxpad					=> '',
	_tmig					=> '',
	_verbose					=> '',
	_vfile					=> '',
	_vmig					=> '',
	_vnfile					=> '',
	_vnmig					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sumigpsti->{_Step}     = 'sumigpsti'.$sumigpsti->{_Step};
	return ( $sumigpsti->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigpsti->{_note}     = 'sumigpsti'.$sumigpsti->{_note};
	return ( $sumigpsti->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigpsti->{_dt}			= '';
		$sumigpsti->{_dx}			= '';
		$sumigpsti->{_etafile}			= '';
		$sumigpsti->{_etamig}			= '';
		$sumigpsti->{_ltaper}			= '';
		$sumigpsti->{_nxpad}			= '';
		$sumigpsti->{_tmig}			= '';
		$sumigpsti->{_verbose}			= '';
		$sumigpsti->{_vfile}			= '';
		$sumigpsti->{_vmig}			= '';
		$sumigpsti->{_vnfile}			= '';
		$sumigpsti->{_vnmig}			= '';
		$sumigpsti->{_Step}			= '';
		$sumigpsti->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumigpsti->{_dt}		= $dt;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' dt='.$sumigpsti->{_dt};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' dt='.$sumigpsti->{_dt};

	} else { 
		print("sumigpsti, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigpsti->{_dx}		= $dx;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' dx='.$sumigpsti->{_dx};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' dx='.$sumigpsti->{_dx};

	} else { 
		print("sumigpsti, dx, missing dx,\n");
	 }
 }


=head2 sub etafile 


=cut

 sub etafile {

	my ( $self,$etafile )		= @_;
	if ( $etafile ne $empty_string ) {

		$sumigpsti->{_etafile}		= $etafile;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' etafile='.$sumigpsti->{_etafile};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' etafile='.$sumigpsti->{_etafile};

	} else { 
		print("sumigpsti, etafile, missing etafile,\n");
	 }
 }


=head2 sub etamig 


=cut

 sub etamig {

	my ( $self,$etamig )		= @_;
	if ( $etamig ne $empty_string ) {

		$sumigpsti->{_etamig}		= $etamig;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' etamig='.$sumigpsti->{_etamig};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' etamig='.$sumigpsti->{_etamig};

	} else { 
		print("sumigpsti, etamig, missing etamig,\n");
	 }
 }


=head2 sub ltaper 


=cut

 sub ltaper {

	my ( $self,$ltaper )		= @_;
	if ( $ltaper ne $empty_string ) {

		$sumigpsti->{_ltaper}		= $ltaper;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' ltaper='.$sumigpsti->{_ltaper};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' ltaper='.$sumigpsti->{_ltaper};

	} else { 
		print("sumigpsti, ltaper, missing ltaper,\n");
	 }
 }


=head2 sub nxpad 


=cut

 sub nxpad {

	my ( $self,$nxpad )		= @_;
	if ( $nxpad ne $empty_string ) {

		$sumigpsti->{_nxpad}		= $nxpad;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' nxpad='.$sumigpsti->{_nxpad};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' nxpad='.$sumigpsti->{_nxpad};

	} else { 
		print("sumigpsti, nxpad, missing nxpad,\n");
	 }
 }


=head2 sub tmig 


=cut

 sub tmig {

	my ( $self,$tmig )		= @_;
	if ( $tmig ne $empty_string ) {

		$sumigpsti->{_tmig}		= $tmig;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' tmig='.$sumigpsti->{_tmig};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' tmig='.$sumigpsti->{_tmig};

	} else { 
		print("sumigpsti, tmig, missing tmig,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigpsti->{_verbose}		= $verbose;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' verbose='.$sumigpsti->{_verbose};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' verbose='.$sumigpsti->{_verbose};

	} else { 
		print("sumigpsti, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigpsti->{_vfile}		= $vfile;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' vfile='.$sumigpsti->{_vfile};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' vfile='.$sumigpsti->{_vfile};

	} else { 
		print("sumigpsti, vfile, missing vfile,\n");
	 }
 }


=head2 sub vmig 


=cut

 sub vmig {

	my ( $self,$vmig )		= @_;
	if ( $vmig ne $empty_string ) {

		$sumigpsti->{_vmig}		= $vmig;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' vmig='.$sumigpsti->{_vmig};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' vmig='.$sumigpsti->{_vmig};

	} else { 
		print("sumigpsti, vmig, missing vmig,\n");
	 }
 }


=head2 sub vnfile 


=cut

 sub vnfile {

	my ( $self,$vnfile )		= @_;
	if ( $vnfile ne $empty_string ) {

		$sumigpsti->{_vnfile}		= $vnfile;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' vnfile='.$sumigpsti->{_vnfile};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' vnfile='.$sumigpsti->{_vnfile};

	} else { 
		print("sumigpsti, vnfile, missing vnfile,\n");
	 }
 }


=head2 sub vnmig 


=cut

 sub vnmig {

	my ( $self,$vnmig )		= @_;
	if ( $vnmig ne $empty_string ) {

		$sumigpsti->{_vnmig}		= $vnmig;
		$sumigpsti->{_note}		= $sumigpsti->{_note}.' vnmig='.$sumigpsti->{_vnmig};
		$sumigpsti->{_Step}		= $sumigpsti->{_Step}.' vnmig='.$sumigpsti->{_vnmig};

	} else { 
		print("sumigpsti, vnmig, missing vnmig,\n");
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
