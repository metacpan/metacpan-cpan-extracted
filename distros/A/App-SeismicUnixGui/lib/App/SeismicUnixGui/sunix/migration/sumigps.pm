package App::SeismicUnixGui::sunix::migration::sumigps;

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
 SUMIGPS - MIGration by Phase Shift with turning rays			



 sumigps <stdin >stdout [optional parms]				



 Required Parameters:							

 	None								



 Optional Parameters:							

 dt=from header(dt) or .004	time sampling interval			

 dx=from header(d2) or 1.0	distance between sucessive cdp's

 

 ffil=0

 

 0,0,0.5/dt,0.5/dt  trapezoidal window of frequencies to migrate	

 tmig=0.0		times corresponding to interval velocities in vmig

 vmig=1500.0		interval velocities corresponding to times in tmig

 vfile=		binary (non-ascii) file containing velocities v(t)

 nxpad=0		number of cdps to pad with zeros before FFT	

 ltaper=0		length of linear taper for left and right edges", 

 verbose=0		=1 for diagnostic print				





 tmpdir= 	 if non-empty, use the value as a directory path	

		 prefix for storing temporary files; else if the	

	         the CWP_TMPDIR environment variable is set use		

	         its value for the path; else use tmpfile()		



 Notes:								

 Input traces must be sorted by either increasing or decreasing cdp.	



 The tmig and vmig arrays specify an interval velocity function of time.

 Linear interpolation and constant extrapolation is used to determine	

 interval velocities at times not specified.  Values specified in tmig	

 must increase monotonically.						



 Alternatively, interval velocities may be stored in a binary file	

 containing one velocity for every time sample.  If vfile is specified,

 then the tmig and vmig arrays are ignored.				



 The time of first sample is assumed to be zero, regardless of the value

 of the trace header field delrt.					



 Credits:

	CWP: Dave Hale (originally called supsmig.c)



  Trace header fields accessed:  ns, dt, d2



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

my $sumigps			= {
	_dt					=> '',
	_dx					=> '',
	_ffil					=> '',
	_ltaper					=> '',
	_nxpad					=> '',
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

	$sumigps->{_Step}     = 'sumigps'.$sumigps->{_Step};
	return ( $sumigps->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigps->{_note}     = 'sumigps'.$sumigps->{_note};
	return ( $sumigps->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigps->{_dt}			= '';
		$sumigps->{_dx}			= '';
		$sumigps->{_ffil}			= '';
		$sumigps->{_ltaper}			= '';
		$sumigps->{_nxpad}			= '';
		$sumigps->{_tmig}			= '';
		$sumigps->{_tmpdir}			= '';
		$sumigps->{_verbose}			= '';
		$sumigps->{_vfile}			= '';
		$sumigps->{_vmig}			= '';
		$sumigps->{_Step}			= '';
		$sumigps->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sumigps->{_dt}		= $dt;
		$sumigps->{_note}		= $sumigps->{_note}.' dt='.$sumigps->{_dt};
		$sumigps->{_Step}		= $sumigps->{_Step}.' dt='.$sumigps->{_dt};

	} else { 
		print("sumigps, dt, missing dt,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sumigps->{_dx}		= $dx;
		$sumigps->{_note}		= $sumigps->{_note}.' dx='.$sumigps->{_dx};
		$sumigps->{_Step}		= $sumigps->{_Step}.' dx='.$sumigps->{_dx};

	} else { 
		print("sumigps, dx, missing dx,\n");
	 }
 }


=head2 sub ffil 


=cut

 sub ffil {

	my ( $self,$ffil )		= @_;
	if ( $ffil ne $empty_string ) {

		$sumigps->{_ffil}		= $ffil;
		$sumigps->{_note}		= $sumigps->{_note}.' ffil='.$sumigps->{_ffil};
		$sumigps->{_Step}		= $sumigps->{_Step}.' ffil='.$sumigps->{_ffil};

	} else { 
		print("sumigps, ffil, missing ffil,\n");
	 }
 }


=head2 sub ltaper 


=cut

 sub ltaper {

	my ( $self,$ltaper )		= @_;
	if ( $ltaper ne $empty_string ) {

		$sumigps->{_ltaper}		= $ltaper;
		$sumigps->{_note}		= $sumigps->{_note}.' ltaper='.$sumigps->{_ltaper};
		$sumigps->{_Step}		= $sumigps->{_Step}.' ltaper='.$sumigps->{_ltaper};

	} else { 
		print("sumigps, ltaper, missing ltaper,\n");
	 }
 }


=head2 sub nxpad 


=cut

 sub nxpad {

	my ( $self,$nxpad )		= @_;
	if ( $nxpad ne $empty_string ) {

		$sumigps->{_nxpad}		= $nxpad;
		$sumigps->{_note}		= $sumigps->{_note}.' nxpad='.$sumigps->{_nxpad};
		$sumigps->{_Step}		= $sumigps->{_Step}.' nxpad='.$sumigps->{_nxpad};

	} else { 
		print("sumigps, nxpad, missing nxpad,\n");
	 }
 }


=head2 sub tmig 


=cut

 sub tmig {

	my ( $self,$tmig )		= @_;
	if ( $tmig ne $empty_string ) {

		$sumigps->{_tmig}		= $tmig;
		$sumigps->{_note}		= $sumigps->{_note}.' tmig='.$sumigps->{_tmig};
		$sumigps->{_Step}		= $sumigps->{_Step}.' tmig='.$sumigps->{_tmig};

	} else { 
		print("sumigps, tmig, missing tmig,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumigps->{_tmpdir}		= $tmpdir;
		$sumigps->{_note}		= $sumigps->{_note}.' tmpdir='.$sumigps->{_tmpdir};
		$sumigps->{_Step}		= $sumigps->{_Step}.' tmpdir='.$sumigps->{_tmpdir};

	} else { 
		print("sumigps, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigps->{_verbose}		= $verbose;
		$sumigps->{_note}		= $sumigps->{_note}.' verbose='.$sumigps->{_verbose};
		$sumigps->{_Step}		= $sumigps->{_Step}.' verbose='.$sumigps->{_verbose};

	} else { 
		print("sumigps, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigps->{_vfile}		= $vfile;
		$sumigps->{_note}		= $sumigps->{_note}.' vfile='.$sumigps->{_vfile};
		$sumigps->{_Step}		= $sumigps->{_Step}.' vfile='.$sumigps->{_vfile};

	} else { 
		print("sumigps, vfile, missing vfile,\n");
	 }
 }


=head2 sub vmig 


=cut

 sub vmig {

	my ( $self,$vmig )		= @_;
	if ( $vmig ne $empty_string ) {

		$sumigps->{_vmig}		= $vmig;
		$sumigps->{_note}		= $sumigps->{_note}.' vmig='.$sumigps->{_vmig};
		$sumigps->{_Step}		= $sumigps->{_Step}.' vmig='.$sumigps->{_vmig};

	} else { 
		print("sumigps, vmig, missing vmig,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 9;

    return($max_index);
}
 
 
1;
