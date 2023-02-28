package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sudmotx;

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
 SUDMOTX - DMO via T-X domain (Kirchhoff) method for common-offset gathers



 sudmotx <stdin >stdout cdpmin= cdpmax= dxcdp= noffmix= [optional parms]



 Required Parameters:							

 cdpmin=                  minimum cdp (integer number) for which to apply DMO

 cdpmax=                  maximum cdp (integer number) for which to apply DMO

 dxcdp=                   distance between successive cdps		

 noffmix=                 number of offsets to mix (see notes)		



 Optional Parameters:							

 offmax=3000.0           maximum offset				

 tmute=2.0               mute time at maximum offset offmax		

 vrms=1500.0             RMS velocity at mute time tmute		

 verbose=0               =1 for diagnostic print			

 tmpdir=	if non-empty, use the value as a directory path	prefix	

		for storing temporary files; else if the CWP_TMPDIR	

		environment variable is set use	its value for the path;	

		else use tmpfile()					





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



 The defaults for offmax and vrms are appropriate only for metric units.

 If distances are measured in feet, then these parameters should be	

 specified explicitly.							



 offmax, tmute, and vrms need not be specified precisely.		

 If these values are unknown, then one should overestimate offmax	

 and underestimate tmute and vrms.					



 No muting is actually performed.  The tmute parameter is used only to	

 determine parameters required to perform DMO.				



 Credits:

	CWP: Dave Hale



 Technical Reference:

      A non-aliased integral method for dip-moveout

      Dave Hale

      submitted to Geophysics, June, 1990



 Trace header fields accessed:  ns, dt, delrt, offset, cdp.



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

my $sudmotx			= {
	_cdpmax					=> '',
	_cdpmin					=> '',
	_dxcdp					=> '',
	_noffmix					=> '',
	_offmax					=> '',
	_tmpdir					=> '',
	_tmute					=> '',
	_verbose					=> '',
	_vrms					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudmotx->{_Step}     = 'sudmotx'.$sudmotx->{_Step};
	return ( $sudmotx->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudmotx->{_note}     = 'sudmotx'.$sudmotx->{_note};
	return ( $sudmotx->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudmotx->{_cdpmax}			= '';
		$sudmotx->{_cdpmin}			= '';
		$sudmotx->{_dxcdp}			= '';
		$sudmotx->{_noffmix}			= '';
		$sudmotx->{_offmax}			= '';
		$sudmotx->{_tmpdir}			= '';
		$sudmotx->{_tmute}			= '';
		$sudmotx->{_verbose}			= '';
		$sudmotx->{_vrms}			= '';
		$sudmotx->{_Step}			= '';
		$sudmotx->{_note}			= '';
 }


=head2 sub cdpmax 


=cut

 sub cdpmax {

	my ( $self,$cdpmax )		= @_;
	if ( $cdpmax ne $empty_string ) {

		$sudmotx->{_cdpmax}		= $cdpmax;
		$sudmotx->{_note}		= $sudmotx->{_note}.' cdpmax='.$sudmotx->{_cdpmax};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' cdpmax='.$sudmotx->{_cdpmax};

	} else { 
		print("sudmotx, cdpmax, missing cdpmax,\n");
	 }
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sudmotx->{_cdpmin}		= $cdpmin;
		$sudmotx->{_note}		= $sudmotx->{_note}.' cdpmin='.$sudmotx->{_cdpmin};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' cdpmin='.$sudmotx->{_cdpmin};

	} else { 
		print("sudmotx, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub dxcdp 


=cut

 sub dxcdp {

	my ( $self,$dxcdp )		= @_;
	if ( $dxcdp ne $empty_string ) {

		$sudmotx->{_dxcdp}		= $dxcdp;
		$sudmotx->{_note}		= $sudmotx->{_note}.' dxcdp='.$sudmotx->{_dxcdp};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' dxcdp='.$sudmotx->{_dxcdp};

	} else { 
		print("sudmotx, dxcdp, missing dxcdp,\n");
	 }
 }


=head2 sub noffmix 


=cut

 sub noffmix {

	my ( $self,$noffmix )		= @_;
	if ( $noffmix ne $empty_string ) {

		$sudmotx->{_noffmix}		= $noffmix;
		$sudmotx->{_note}		= $sudmotx->{_note}.' noffmix='.$sudmotx->{_noffmix};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' noffmix='.$sudmotx->{_noffmix};

	} else { 
		print("sudmotx, noffmix, missing noffmix,\n");
	 }
 }


=head2 sub offmax 


=cut

 sub offmax {

	my ( $self,$offmax )		= @_;
	if ( $offmax ne $empty_string ) {

		$sudmotx->{_offmax}		= $offmax;
		$sudmotx->{_note}		= $sudmotx->{_note}.' offmax='.$sudmotx->{_offmax};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' offmax='.$sudmotx->{_offmax};

	} else { 
		print("sudmotx, offmax, missing offmax,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sudmotx->{_tmpdir}		= $tmpdir;
		$sudmotx->{_note}		= $sudmotx->{_note}.' tmpdir='.$sudmotx->{_tmpdir};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' tmpdir='.$sudmotx->{_tmpdir};

	} else { 
		print("sudmotx, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub tmute 


=cut

 sub tmute {

	my ( $self,$tmute )		= @_;
	if ( $tmute ne $empty_string ) {

		$sudmotx->{_tmute}		= $tmute;
		$sudmotx->{_note}		= $sudmotx->{_note}.' tmute='.$sudmotx->{_tmute};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' tmute='.$sudmotx->{_tmute};

	} else { 
		print("sudmotx, tmute, missing tmute,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudmotx->{_verbose}		= $verbose;
		$sudmotx->{_note}		= $sudmotx->{_note}.' verbose='.$sudmotx->{_verbose};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' verbose='.$sudmotx->{_verbose};

	} else { 
		print("sudmotx, verbose, missing verbose,\n");
	 }
 }


=head2 sub vrms 


=cut

 sub vrms {

	my ( $self,$vrms )		= @_;
	if ( $vrms ne $empty_string ) {

		$sudmotx->{_vrms}		= $vrms;
		$sudmotx->{_note}		= $sudmotx->{_note}.' vrms='.$sudmotx->{_vrms};
		$sudmotx->{_Step}		= $sudmotx->{_Step}.' vrms='.$sudmotx->{_vrms};

	} else { 
		print("sudmotx, vrms, missing vrms,\n");
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
