package App::SeismicUnixGui::sunix::migration::sumigtk;

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
 SUMIGTK - MIGration via T-K domain method for common-midpoint stacked data



 sumigtk <stdin >stdout dxcdp= [optional parms]			



 Required Parameters:							

 dxcdp                   distance between successive cdps		



 Optional Parameters:							

 fmax=Nyquist            maximum frequency				

 tmig=0.0                times corresponding to interval velocities in vmig

 vmig=1500.0             interval velocities corresponding to times in tmig

 vfile=                  binary (non-ascii) file containing velocities v(t)

 nxpad=0                 number of cdps to pad with zeros before FFT	

 ltaper=0                length of linear taper for left and right edges", 

 verbose=0               =1 for diagnostic print			



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



 The migration is a reverse time migration in the (t,k) domain. In the	

 first step, the data g(t,x) are Fourier transformed x->k into the	",	

 the time-wavenumber domain g(t,k).					



 Then looping over wavenumbers, the data are then reverse-time		

 finite-difference migrated, wavenumber by wavenumber.  The resulting	

 migrated data m(tau,k), now in the tau (migrated time) and k domain,	

 are inverse fourier transformed back into m(tau,xout) and written out.",	





 Credits:

	CWP: Dave Hale



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

my $sumigtk			= {
	_dxcdp					=> '',
	_fmax					=> '',
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

	$sumigtk->{_Step}     = 'sumigtk'.$sumigtk->{_Step};
	return ( $sumigtk->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumigtk->{_note}     = 'sumigtk'.$sumigtk->{_note};
	return ( $sumigtk->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumigtk->{_dxcdp}			= '';
		$sumigtk->{_fmax}			= '';
		$sumigtk->{_ltaper}			= '';
		$sumigtk->{_nxpad}			= '';
		$sumigtk->{_tmig}			= '';
		$sumigtk->{_tmpdir}			= '';
		$sumigtk->{_verbose}			= '';
		$sumigtk->{_vfile}			= '';
		$sumigtk->{_vmig}			= '';
		$sumigtk->{_Step}			= '';
		$sumigtk->{_note}			= '';
 }


=head2 sub dxcdp 


=cut

 sub dxcdp {

	my ( $self,$dxcdp )		= @_;
	if ( $dxcdp ne $empty_string ) {

		$sumigtk->{_dxcdp}		= $dxcdp;
		$sumigtk->{_note}		= $sumigtk->{_note}.' dxcdp='.$sumigtk->{_dxcdp};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' dxcdp='.$sumigtk->{_dxcdp};

	} else { 
		print("sumigtk, dxcdp, missing dxcdp,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sumigtk->{_fmax}		= $fmax;
		$sumigtk->{_note}		= $sumigtk->{_note}.' fmax='.$sumigtk->{_fmax};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' fmax='.$sumigtk->{_fmax};

	} else { 
		print("sumigtk, fmax, missing fmax,\n");
	 }
 }


=head2 sub ltaper 


=cut

 sub ltaper {

	my ( $self,$ltaper )		= @_;
	if ( $ltaper ne $empty_string ) {

		$sumigtk->{_ltaper}		= $ltaper;
		$sumigtk->{_note}		= $sumigtk->{_note}.' ltaper='.$sumigtk->{_ltaper};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' ltaper='.$sumigtk->{_ltaper};

	} else { 
		print("sumigtk, ltaper, missing ltaper,\n");
	 }
 }


=head2 sub nxpad 


=cut

 sub nxpad {

	my ( $self,$nxpad )		= @_;
	if ( $nxpad ne $empty_string ) {

		$sumigtk->{_nxpad}		= $nxpad;
		$sumigtk->{_note}		= $sumigtk->{_note}.' nxpad='.$sumigtk->{_nxpad};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' nxpad='.$sumigtk->{_nxpad};

	} else { 
		print("sumigtk, nxpad, missing nxpad,\n");
	 }
 }


=head2 sub tmig 


=cut

 sub tmig {

	my ( $self,$tmig )		= @_;
	if ( $tmig ne $empty_string ) {

		$sumigtk->{_tmig}		= $tmig;
		$sumigtk->{_note}		= $sumigtk->{_note}.' tmig='.$sumigtk->{_tmig};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' tmig='.$sumigtk->{_tmig};

	} else { 
		print("sumigtk, tmig, missing tmig,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumigtk->{_tmpdir}		= $tmpdir;
		$sumigtk->{_note}		= $sumigtk->{_note}.' tmpdir='.$sumigtk->{_tmpdir};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' tmpdir='.$sumigtk->{_tmpdir};

	} else { 
		print("sumigtk, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumigtk->{_verbose}		= $verbose;
		$sumigtk->{_note}		= $sumigtk->{_note}.' verbose='.$sumigtk->{_verbose};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' verbose='.$sumigtk->{_verbose};

	} else { 
		print("sumigtk, verbose, missing verbose,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sumigtk->{_vfile}		= $vfile;
		$sumigtk->{_note}		= $sumigtk->{_note}.' vfile='.$sumigtk->{_vfile};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' vfile='.$sumigtk->{_vfile};

	} else { 
		print("sumigtk, vfile, missing vfile,\n");
	 }
 }


=head2 sub vmig 


=cut

 sub vmig {

	my ( $self,$vmig )		= @_;
	if ( $vmig ne $empty_string ) {

		$sumigtk->{_vmig}		= $vmig;
		$sumigtk->{_note}		= $sumigtk->{_note}.' vmig='.$sumigtk->{_vmig};
		$sumigtk->{_Step}		= $sumigtk->{_Step}.' vmig='.$sumigtk->{_vmig};

	} else { 
		print("sumigtk, vmig, missing vmig,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
