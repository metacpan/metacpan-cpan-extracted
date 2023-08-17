package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sutaupnmo;

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
 SUTAUPNMO - NMO for an arbitrary velocity function of tau and CDP	



  sutaupnmo <stdin >stdout [optional parameters]			



 Optional Parameters:							

 tnmo=0,...		NMO times corresponding to velocities in vnmo	

 vnmo=1500,...		NMO velocities corresponding to times in tnmo	

 cdp=			CDPs for which vnmo & tnmo are specified (see Notes) 

 smute=1.5		samples with NMO stretch exceeding smute are zeroed  

 lmute=25		length (in samples) of linear ramp for stretch mute  

 sscale=1		=1 to divide output samples by NMO stretch factor    



 Notes:								



 For constant-velocity NMO, specify only one vnmo=constant and omit tnmo.



 For NMO with a velocity function of tau only, specify the arrays	

	   vnmo=v1,v2,... tnmo=t1,t2,...				

 where v1 is the velocity at tau t1, v2 is the velocity at tau t2, ...    

 The taus specified in the tnmo array must be monotonically increasing.    

 Linear interpolation and constant extrapolation of the specified velocities

 is used to compute the velocities at taus not specified.		



 For NMO with a velocity function of tau and CDP, specify the array	

	   cdp=cdp1,cdp2,...						

 and, for each CDP specified, specify the vnmo and tnmo arrays as described 

 above. The first (vnmo,tnmo) pair corresponds to the first cdp, and so on. 

 Linear interpolation and constant extrapolation of velocity^2 is used	 

 to compute velocities at CDPs not specified.				



 Moveout is defined by							



  tau^2 + tau^2.p^2.vel^2						



 Note: In general, the user should set the cdp parameter.  The default is   

	to use tr.cdp from the first trace and assume only one cdp.	 

 Caveat:								

 Taunmo should handle triplication					



 NMO interpolation error is less than 1 0.000000or frequencies less than 600f   

 the Nyquist frequency.						



 Exact inverse NMO is not implemented, nor has anisotropy		

 Example implementation:						

   sutaup dx=25 option=2 pmin=0 pmax=0.0007025 < cmpgather.su |	

   supef minlag=0.2 maxlag=0.8 |					

   sutaupnmo tnmo=0.5,2,4 vnmo=1500,2000,3200 smute=1.5 |		

   sumute key=tracr mode=1 ntaper=20 xmute=1,30,40,50,85,15  		

				 tmute=7.8,7.8,4.5,3.5,2.0,0.35 |	

   sustack key=cdp | ... [...]						





 Credits:

	 Durham, Richard Hobbs modified from SUNMO credited below

	SEP: Shuki Ronen, Chuck Sword

	CWP: Shuki Ronen, Jack K. Cohen , Dave Hale



 Technical Reference:

	van der Baan papers in geophysics (2002 & 2004)



 Trace header fields accessed: ns, dt, delrt, offset, cdp, sy



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

my $sutaupnmo			= {
	_cdp					=> '',
	_dx					=> '',
	_key					=> '',
	_lmute					=> '',
	_minlag					=> '',
	_smute					=> '',
	_sscale					=> '',
	_tmute					=> '',
	_tnmo					=> '',
	_vnmo					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sutaupnmo->{_Step}     = 'sutaupnmo'.$sutaupnmo->{_Step};
	return ( $sutaupnmo->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sutaupnmo->{_note}     = 'sutaupnmo'.$sutaupnmo->{_note};
	return ( $sutaupnmo->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sutaupnmo->{_cdp}			= '';
		$sutaupnmo->{_dx}			= '';
		$sutaupnmo->{_key}			= '';
		$sutaupnmo->{_lmute}			= '';
		$sutaupnmo->{_minlag}			= '';
		$sutaupnmo->{_smute}			= '';
		$sutaupnmo->{_sscale}			= '';
		$sutaupnmo->{_tmute}			= '';
		$sutaupnmo->{_tnmo}			= '';
		$sutaupnmo->{_vnmo}			= '';
		$sutaupnmo->{_Step}			= '';
		$sutaupnmo->{_note}			= '';
 }


=head2 sub cdp 


=cut

 sub cdp {

	my ( $self,$cdp )		= @_;
	if ( $cdp ne $empty_string ) {

		$sutaupnmo->{_cdp}		= $cdp;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' cdp='.$sutaupnmo->{_cdp};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' cdp='.$sutaupnmo->{_cdp};

	} else { 
		print("sutaupnmo, cdp, missing cdp,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sutaupnmo->{_dx}		= $dx;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' dx='.$sutaupnmo->{_dx};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' dx='.$sutaupnmo->{_dx};

	} else { 
		print("sutaupnmo, dx, missing dx,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sutaupnmo->{_key}		= $key;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' key='.$sutaupnmo->{_key};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' key='.$sutaupnmo->{_key};

	} else { 
		print("sutaupnmo, key, missing key,\n");
	 }
 }


=head2 sub lmute 


=cut

 sub lmute {

	my ( $self,$lmute )		= @_;
	if ( $lmute ne $empty_string ) {

		$sutaupnmo->{_lmute}		= $lmute;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' lmute='.$sutaupnmo->{_lmute};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' lmute='.$sutaupnmo->{_lmute};

	} else { 
		print("sutaupnmo, lmute, missing lmute,\n");
	 }
 }


=head2 sub minlag 


=cut

 sub minlag {

	my ( $self,$minlag )		= @_;
	if ( $minlag ne $empty_string ) {

		$sutaupnmo->{_minlag}		= $minlag;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' minlag='.$sutaupnmo->{_minlag};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' minlag='.$sutaupnmo->{_minlag};

	} else { 
		print("sutaupnmo, minlag, missing minlag,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$sutaupnmo->{_smute}		= $smute;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' smute='.$sutaupnmo->{_smute};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' smute='.$sutaupnmo->{_smute};

	} else { 
		print("sutaupnmo, smute, missing smute,\n");
	 }
 }


=head2 sub sscale 


=cut

 sub sscale {

	my ( $self,$sscale )		= @_;
	if ( $sscale ne $empty_string ) {

		$sutaupnmo->{_sscale}		= $sscale;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' sscale='.$sutaupnmo->{_sscale};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' sscale='.$sutaupnmo->{_sscale};

	} else { 
		print("sutaupnmo, sscale, missing sscale,\n");
	 }
 }


=head2 sub tmute 


=cut

 sub tmute {

	my ( $self,$tmute )		= @_;
	if ( $tmute ne $empty_string ) {

		$sutaupnmo->{_tmute}		= $tmute;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' tmute='.$sutaupnmo->{_tmute};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' tmute='.$sutaupnmo->{_tmute};

	} else { 
		print("sutaupnmo, tmute, missing tmute,\n");
	 }
 }


=head2 sub tnmo 


=cut

 sub tnmo {

	my ( $self,$tnmo )		= @_;
	if ( $tnmo ne $empty_string ) {

		$sutaupnmo->{_tnmo}		= $tnmo;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' tnmo='.$sutaupnmo->{_tnmo};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' tnmo='.$sutaupnmo->{_tnmo};

	} else { 
		print("sutaupnmo, tnmo, missing tnmo,\n");
	 }
 }


=head2 sub vnmo 


=cut

 sub vnmo {

	my ( $self,$vnmo )		= @_;
	if ( $vnmo ne $empty_string ) {

		$sutaupnmo->{_vnmo}		= $vnmo;
		$sutaupnmo->{_note}		= $sutaupnmo->{_note}.' vnmo='.$sutaupnmo->{_vnmo};
		$sutaupnmo->{_Step}		= $sutaupnmo->{_Step}.' vnmo='.$sutaupnmo->{_vnmo};

	} else { 
		print("sutaupnmo, vnmo, missing vnmo,\n");
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
