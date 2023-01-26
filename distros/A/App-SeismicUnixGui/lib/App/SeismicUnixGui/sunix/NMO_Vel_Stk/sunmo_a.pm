package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sunmo_a;

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
 SUNMO_a - NMO for an arbitrary velocity function of time and CDP with	     

		experimental Anisotropy options				     

  sunmo <stdin >stdout [optional parameters]				     



 Optional Parameters:							     

 tnmo=0,...		NMO times corresponding to velocities in vnmo	     

 vnmo=1500,..		NMO velocities corresponding to times in tnmo	     

 anis1=0		two anisotropy coefficients making up quartic term   

 anis2=0		in traveltime curve, corresponding to times in tnmo  

 cdp=			CDPs for which vnmo & tnmo are specified (see Notes) 

 smute=1.5		samples with NMO stretch exceeding smute are zeroed  

 lmute=25		length (in samples) of linear ramp for stretch mute  

 sscale=1		=1 to divide output samples by NMO stretch factor    

 invert=0		=1 to perform (approximate) inverse NMO		     

 upward=0		=1 to scan upward to find first sample to kill	



 Notes:								     

 For constant-velocity NMO, specify only one vnmo=constant and omit tnmo.   



 NMO interpolation error is less than 1 0.000000or frequencies less than 600f   

 the Nyquist frequency.						     



 Exact inverse NMO is impossible, particularly for early times at large     

 offsets and for frequencies near Nyquist with large interpolation errors.  



 The "offset" header field must be set.				     

 Use suazimuth to set offset header field when sx,sy,gx,gy are all	     

 nonzero. 							   	     



 For NMO with a velocity function of time only, specify the arrays	     

	   vnmo=v1,v2,... tnmo=t1,t2,...				     

 where v1 is the velocity at time t1, v2 is the velocity at time t2, ...    

 The times specified in the tnmo array must be monotonically increasing.    

 Linear interpolation and constant extrapolation of the specified velocities

 is used to compute the velocities at times not specified.		     

 The same holds for the anisotropy coefficients as a function of time only. 



 For NMO with a velocity function of time and CDP, specify the array	     

	   cdp=cdp1,cdp2,...						     

 and, for each CDP specified, specify the vnmo and tnmo arrays as described 

 above. The first (vnmo,tnmo) pair corresponds to the first cdp, and so on. 

 Linear interpolation and constant extrapolation of 1/velocity^2 is used    

 to compute velocities at CDPs not specified.				     



 Anisotropy option:							     

 Caveat, this is an experimental option,				     



 The anisotropy coefficients anis1, anis2 permit non-hyperbolicity due	     

 to layering, mode conversion, or anisotropy. Default is isotropic NMO.     



 The same holds for the anisotropy coefficients as a function of time and   

 CDP.									     



 Moveout is defined by							     



   1		 anis1							     

  --- x^2 + ------------- x^4.						     

  v^2	     1 + anis2 x^2						     



 Note: In general, the user should set the cdp parameter.  The default is   

	to use tr.cdp from the first trace and assume only one cdp.	  

 Caveat:								     

 Nmo cannot handle negative moveout as in triplication caused by	     

 anisotropy. But negative moveout happens necessarily for negative anis1 at 

 sufficiently large offsets. Then the error-negative moveout- is printed.   

 Check anis1. An error (anis2 too small) is also printed if the	     

 denominator of the quartic term becomes negative. Check anis2. These errors

 are prompted even if they occur in traces which would not survive the	     

 NMO-stretch threshold. Chop off enough far-offset traces (e.g. with suwind)

 if anis1, anis2 are fine for near-offset traces.			     





 Credits:

	SEP: Shuki, Chuck Sword

	CWP: Shuki, Jack, Dave Hale, Bjoern Rommel

      Modified: 08/08/98 - Carlos E. Theodoro - option for lateral offset

      Modified: 07/11/02 - Sang-yong Suh -

	  added "upward" option to handle decreasing velocity function.

      CWP: Sept 2010: John Stockwell

	  replaced Carlos Theodoro's fix

	  and added the instruction in the selfdoc to use suazimuth to set 

	    offset so that it accounts for lateral offset

      note that by the segy standard "scalel" does not scale the offset

      field

 Technical Reference:

	The Common Depth Point Stack

	William A. Schneider

	Proc. IEEE, v. 72, n. 10, p. 1238-1254

	1984



 Trace header fields accessed: ns, dt, delrt, offset, cdp, scalel



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

my $sunmo_a			= {
	_anis1					=> '',
	_anis2					=> '',
	_cdp					=> '',
	_invert					=> '',
	_lmute					=> '',
	_smute					=> '',
	_sscale					=> '',
	_tnmo					=> '',
	_upward					=> '',
	_vnmo					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sunmo_a->{_Step}     = 'sunmo_a'.$sunmo_a->{_Step};
	return ( $sunmo_a->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sunmo_a->{_note}     = 'sunmo_a'.$sunmo_a->{_note};
	return ( $sunmo_a->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sunmo_a->{_anis1}			= '';
		$sunmo_a->{_anis2}			= '';
		$sunmo_a->{_cdp}			= '';
		$sunmo_a->{_invert}			= '';
		$sunmo_a->{_lmute}			= '';
		$sunmo_a->{_smute}			= '';
		$sunmo_a->{_sscale}			= '';
		$sunmo_a->{_tnmo}			= '';
		$sunmo_a->{_upward}			= '';
		$sunmo_a->{_vnmo}			= '';
		$sunmo_a->{_Step}			= '';
		$sunmo_a->{_note}			= '';
 }


=head2 sub anis1 


=cut

 sub anis1 {

	my ( $self,$anis1 )		= @_;
	if ( $anis1 ne $empty_string ) {

		$sunmo_a->{_anis1}		= $anis1;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' anis1='.$sunmo_a->{_anis1};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' anis1='.$sunmo_a->{_anis1};

	} else { 
		print("sunmo_a, anis1, missing anis1,\n");
	 }
 }


=head2 sub anis2 


=cut

 sub anis2 {

	my ( $self,$anis2 )		= @_;
	if ( $anis2 ne $empty_string ) {

		$sunmo_a->{_anis2}		= $anis2;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' anis2='.$sunmo_a->{_anis2};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' anis2='.$sunmo_a->{_anis2};

	} else { 
		print("sunmo_a, anis2, missing anis2,\n");
	 }
 }


=head2 sub cdp 


=cut

 sub cdp {

	my ( $self,$cdp )		= @_;
	if ( $cdp ne $empty_string ) {

		$sunmo_a->{_cdp}		= $cdp;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' cdp='.$sunmo_a->{_cdp};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' cdp='.$sunmo_a->{_cdp};

	} else { 
		print("sunmo_a, cdp, missing cdp,\n");
	 }
 }


=head2 sub invert 


=cut

 sub invert {

	my ( $self,$invert )		= @_;
	if ( $invert ne $empty_string ) {

		$sunmo_a->{_invert}		= $invert;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' invert='.$sunmo_a->{_invert};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' invert='.$sunmo_a->{_invert};

	} else { 
		print("sunmo_a, invert, missing invert,\n");
	 }
 }


=head2 sub lmute 


=cut

 sub lmute {

	my ( $self,$lmute )		= @_;
	if ( $lmute ne $empty_string ) {

		$sunmo_a->{_lmute}		= $lmute;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' lmute='.$sunmo_a->{_lmute};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' lmute='.$sunmo_a->{_lmute};

	} else { 
		print("sunmo_a, lmute, missing lmute,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$sunmo_a->{_smute}		= $smute;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' smute='.$sunmo_a->{_smute};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' smute='.$sunmo_a->{_smute};

	} else { 
		print("sunmo_a, smute, missing smute,\n");
	 }
 }


=head2 sub sscale 


=cut

 sub sscale {

	my ( $self,$sscale )		= @_;
	if ( $sscale ne $empty_string ) {

		$sunmo_a->{_sscale}		= $sscale;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' sscale='.$sunmo_a->{_sscale};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' sscale='.$sunmo_a->{_sscale};

	} else { 
		print("sunmo_a, sscale, missing sscale,\n");
	 }
 }


=head2 sub tnmo 


=cut

 sub tnmo {

	my ( $self,$tnmo )		= @_;
	if ( $tnmo ne $empty_string ) {

		$sunmo_a->{_tnmo}		= $tnmo;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' tnmo='.$sunmo_a->{_tnmo};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' tnmo='.$sunmo_a->{_tnmo};

	} else { 
		print("sunmo_a, tnmo, missing tnmo,\n");
	 }
 }


=head2 sub upward 


=cut

 sub upward {

	my ( $self,$upward )		= @_;
	if ( $upward ne $empty_string ) {

		$sunmo_a->{_upward}		= $upward;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' upward='.$sunmo_a->{_upward};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' upward='.$sunmo_a->{_upward};

	} else { 
		print("sunmo_a, upward, missing upward,\n");
	 }
 }


=head2 sub vnmo 


=cut

 sub vnmo {

	my ( $self,$vnmo )		= @_;
	if ( $vnmo ne $empty_string ) {

		$sunmo_a->{_vnmo}		= $vnmo;
		$sunmo_a->{_note}		= $sunmo_a->{_note}.' vnmo='.$sunmo_a->{_vnmo};
		$sunmo_a->{_Step}		= $sunmo_a->{_Step}.' vnmo='.$sunmo_a->{_vnmo};

	} else { 
		print("sunmo_a, vnmo, missing vnmo,\n");
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
