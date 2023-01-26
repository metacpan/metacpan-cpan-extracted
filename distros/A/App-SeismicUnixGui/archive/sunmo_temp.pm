package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sunmo_temp;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

 Version: 0.0.1
          0.0.2 July 15, 2015 (JML)
 		  0.0.3 Jan 14, 2020 (DLL)
 		  0.0.4 Feb 06, 2020 (DLL)

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUNMO - NMO for an arbitrary velocity function of time and CDP	     



  sunmo <stdin >stdout [optional parameters]				     



 Optional Parameters:							     

 tnmo=0,...		NMO times corresponding to velocities in vnmo	     

 vnmo=1500,...		NMO velocities corresponding to times in tnmo	     

 cdp=			CDPs for which vnmo & tnmo are specified (see Notes) 

 smute=1.5		samples with NMO stretch exceeding smute are zeroed  

 lmute=25		length (in samples) of linear ramp for stretch mute  

 sscale=1		=1 to divide output samples by NMO stretch factor    

 invert=0		=1 to perform (approximate) inverse NMO		     

 upward=0		=1 to scan upward to find first sample to kill	     

 voutfile=		if set, interplolated velocity function v[cdp][t] is 

			output to named file.			     	     

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



 The format of the output interpolated velocity file is unformatted C floats

 with vout[cdp][t], with time as the fast dimension and may be used as an   

 input velocity file for further processing.				     



 Note that this version of sunmo does not attempt to deal with	anisotropy.  

 The version of sunmo with experimental anisotropy support is "sunmo_a





 Credits:

	SEP: Shuki Ronen, Chuck Sword

	CWP: Shuki Ronen, Jack, Dave Hale, Bjoern Rommel

      Modified: 08/08/98 - Carlos E. Theodoro - option for lateral offset

      Modified: 07/11/02 - Sang-yong Suh -

	  added "upward" option to handle decreasing velocity function.

      CWP: Sept 2010: John Stockwell

	  1. replaced Carlos Theodoro's fix 

	  2. added  the instruction in the selfdoc to use suazimuth to set 

	      offset so that it accounts for lateral offset. 

        3. removed  Bjoren Rommel's anisotropy stuff. sunmo_a is the 

           version with the anisotropy parameters left in.

        4. note that scalel does not scale the offset field in

           the segy standard.

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

 Juan Lorenzo July 15 2015
 introduced "par" subroutine
 
 V0.0.3 Jan 14 2020 automatic use of scalel

=cut

use Moose;
our $VERSION = '0.0.3';


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

my $sunmo			= {
	_cdp					=> '',
	_invert					=> '',
	_lmute					=> '',
	_smute					=> '',
	_sscale					=> '',
	_tnmo					=> '',
	_upward					=> '',
	_vnmo					=> '',
	_voutfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sunmo->{_Step}     = 'sunmo'.$sunmo->{_Step};
	return ( $sunmo->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sunmo->{_note}     = 'sunmo'.$sunmo->{_note};
	return ( $sunmo->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sunmo->{_cdp}			= '';
		$sunmo->{_invert}			= '';
		$sunmo->{_lmute}			= '';
		$sunmo->{_smute}			= '';
		$sunmo->{_sscale}			= '';
		$sunmo->{_tnmo}			= '';
		$sunmo->{_upward}			= '';
		$sunmo->{_vnmo}			= '';
		$sunmo->{_voutfile}			= '';
		$sunmo->{_Step}			= '';
		$sunmo->{_note}			= '';
 }


=head2 sub cdp 


=cut

 sub cdp {

	my ( $self,$cdp )		= @_;
	if ( $cdp ne $empty_string ) {

		$sunmo->{_cdp}		= $cdp;
		$sunmo->{_note}		= $sunmo->{_note}.' cdp='.$sunmo->{_cdp};
		$sunmo->{_Step}		= $sunmo->{_Step}.' cdp='.$sunmo->{_cdp};

	} else { 
		print("sunmo, cdp, missing cdp,\n");
	 }
 }


=head2 sub invert 


=cut

 sub invert {

	my ( $self,$invert )		= @_;
	if ( $invert ne $empty_string ) {

		$sunmo->{_invert}		= $invert;
		$sunmo->{_note}		= $sunmo->{_note}.' invert='.$sunmo->{_invert};
		$sunmo->{_Step}		= $sunmo->{_Step}.' invert='.$sunmo->{_invert};

	} else { 
		print("sunmo, invert, missing invert,\n");
	 }
 }


=head2 sub lmute 


=cut

 sub lmute {

	my ( $self,$lmute )		= @_;
	if ( $lmute ne $empty_string ) {

		$sunmo->{_lmute}		= $lmute;
		$sunmo->{_note}		= $sunmo->{_note}.' lmute='.$sunmo->{_lmute};
		$sunmo->{_Step}		= $sunmo->{_Step}.' lmute='.$sunmo->{_lmute};

	} else { 
		print("sunmo, lmute, missing lmute,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$sunmo->{_smute}		= $smute;
		$sunmo->{_note}		= $sunmo->{_note}.' smute='.$sunmo->{_smute};
		$sunmo->{_Step}		= $sunmo->{_Step}.' smute='.$sunmo->{_smute};

	} else { 
		print("sunmo, smute, missing smute,\n");
	 }
 }


=head2 sub sscale 


=cut

 sub sscale {

	my ( $self,$sscale )		= @_;
	if ( $sscale ne $empty_string ) {

		$sunmo->{_sscale}		= $sscale;
		$sunmo->{_note}		= $sunmo->{_note}.' sscale='.$sunmo->{_sscale};
		$sunmo->{_Step}		= $sunmo->{_Step}.' sscale='.$sunmo->{_sscale};

	} else { 
		print("sunmo, sscale, missing sscale,\n");
	 }
 }


=head2 sub tnmo 


=cut

 sub tnmo {

	my ( $self,$tnmo )		= @_;
	if ( $tnmo ne $empty_string ) {

		$sunmo->{_tnmo}		= $tnmo;
		$sunmo->{_note}		= $sunmo->{_note}.' tnmo='.$sunmo->{_tnmo};
		$sunmo->{_Step}		= $sunmo->{_Step}.' tnmo='.$sunmo->{_tnmo};

	} else { 
		print("sunmo, tnmo, missing tnmo,\n");
	 }
 }


=head2 sub upward 


=cut

 sub upward {

	my ( $self,$upward )		= @_;
	if ( $upward ne $empty_string ) {

		$sunmo->{_upward}		= $upward;
		$sunmo->{_note}		= $sunmo->{_note}.' upward='.$sunmo->{_upward};
		$sunmo->{_Step}		= $sunmo->{_Step}.' upward='.$sunmo->{_upward};

	} else { 
		print("sunmo, upward, missing upward,\n");
	 }
 }


=head2 sub vnmo 


=cut

 sub vnmo {

	my ( $self,$vnmo )		= @_;
	if ( $vnmo ne $empty_string ) {

		$sunmo->{_vnmo}		= $vnmo;
		$sunmo->{_note}		= $sunmo->{_note}.' vnmo='.$sunmo->{_vnmo};
		$sunmo->{_Step}		= $sunmo->{_Step}.' vnmo='.$sunmo->{_vnmo};

	} else { 
		print("sunmo, vnmo, missing vnmo,\n");
	 }
 }


=head2 sub voutfile 


=cut

 sub voutfile {

	my ( $self,$voutfile )		= @_;
	if ( $voutfile ne $empty_string ) {

		$sunmo->{_voutfile}		= $voutfile;
		$sunmo->{_note}		= $sunmo->{_note}.' voutfile='.$sunmo->{_voutfile};
		$sunmo->{_Step}		= $sunmo->{_Step}.' voutfile='.$sunmo->{_voutfile};

	} else { 
		print("sunmo, voutfile, missing voutfile,\n");
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
