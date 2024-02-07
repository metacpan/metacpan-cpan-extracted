package App::SeismicUnixGui::sunix::well::subackus;

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
 SUBACKUS - calculate Thomsen anisotropy parameters from 	

 	     well log (vp,vs,rho) data via BACKUS averaging	



 subackus < vp_vs_rho.su >stdout [options]			



 Required parameters:						

 none								



 Optional parameter:						

 navg=201	number of depth samples in Backus avg window 	

 all=0		=1 to output extra parameters 			

		(<vp0>,<vs0>,<rho>,eta,vang,a,f,c,l,A,B,<lam>,<mu>)

 ang=30	angle (deg) for use in vang			



 Notes:							

 1. Input are (vp,vs,rho) traces in metric units		

 2. Output are (epsilon,delta,gamma) dimensionless traces	

    tracl=(1,2,3)=(epsilon,delta,gamma) 			

	(all=1 output optional traces listed below)		

    tracl=(4,5,6,7,8)=(vp0,vs0,<rho>,eta,vang)			

    tracl=(9,10,11,12)=(a,f,c,l)=(c11,c13,c33,c44) backus avg'd

    tracl=(13,14)=(<lam/lamp2mu>^2,4<mu*lampmu/lamp2mu>)=(A,B)	

       used to analyze eps=(a-c)/2c; a=c11=A*x+B;  c=c33=x	

    tracl=(15,16)=(<lambda>,<mu>)				

       for fluid analysis (lambda affected by fluid, mu not)   

    tracl=(17,18,19)=(vp,vs,rho)  orig log values		

    tracl=(20)=(m)=(c66) Backus avg'd 				

    tracl=(21,22,23,24,25)=(a,f,c,l,m)=(c11,c13,c33,c44,c66) orig

 3. (epsilon,delta,etc.) can be isolated by tracl header field 

 4. (vp0,vs0) are backus averaged vertical wavespeeds		

 5. <rho> is backus averaged density, etc.			

 6. eta = (eps - delta) / (1 + 2 delta)			

 7. vang=vp(ang_deg)/vp0  phase velocity ratio			

    The idea being that if vang~vp0 there are small time effects

    (30 deg comes from ~ max ray angle preserved in processing)



 Example:							

 las2su < logs.las nskip=34 nlog=4 > logs.su 			

 suwind < logs.su  key=tracl min=2 max=3 | suop op=s2vm > v.su	

 suwind < logs.su  key=tracl min=4 max=4 | suop op=d2m > d.su	

 fcat v.su d.su > vp_vs_rho.su					

 subackus < vp_vs_rho.su > eps_delta_gamma.su			

 In this example we start with a well las file containing 	

 34 header lines and 4 log tracks (depth,p_son,s_son,den).	

 This is converted to su format by las2su.  Then we pull off	

 the sonic logs and convert them to velocity in metric units.	

 Then the density log is pulled off and converted to metric.	

 All three metric curves are bundled into one su file which 	

 is the input to subackus. 					", 



 Related codes: sulprime subackush				



 Credits:



	UHouston: Chris Liner 

              I gratefully acknowledge Saudi Aramco for permission

              to release this code developed while I worked for the 

              EXPEC-ARC research division.

 References:		

 Anisotropy parameters: Thomsen, 2002, DISC Notes (SEG)

 Backus Method: Berryman, Grechka, and Berge, 1997, SEP94





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

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $subackus			= {
	_all					=> '',
	_ang					=> '',
	_eps					=> '',
	_eta					=> '',
	_key					=> '',
	_navg					=> '',
	_nskip					=> '',
	_tracl					=> '',
	_vang					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$subackus->{_Step}     = 'subackus'.$subackus->{_Step};
	return ( $subackus->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$subackus->{_note}     = 'subackus'.$subackus->{_note};
	return ( $subackus->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$subackus->{_all}			= '';
		$subackus->{_ang}			= '';
		$subackus->{_eps}			= '';
		$subackus->{_eta}			= '';
		$subackus->{_key}			= '';
		$subackus->{_navg}			= '';
		$subackus->{_nskip}			= '';
		$subackus->{_tracl}			= '';
		$subackus->{_vang}			= '';
		$subackus->{_Step}			= '';
		$subackus->{_note}			= '';
 }


=head2 sub all 


=cut

 sub all {

	my ( $self,$all )		= @_;
	if ( $all ne $empty_string ) {

		$subackus->{_all}		= $all;
		$subackus->{_note}		= $subackus->{_note}.' all='.$subackus->{_all};
		$subackus->{_Step}		= $subackus->{_Step}.' all='.$subackus->{_all};

	} else { 
		print("subackus, all, missing all,\n");
	 }
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$subackus->{_ang}		= $ang;
		$subackus->{_note}		= $subackus->{_note}.' ang='.$subackus->{_ang};
		$subackus->{_Step}		= $subackus->{_Step}.' ang='.$subackus->{_ang};

	} else { 
		print("subackus, ang, missing ang,\n");
	 }
 }


=head2 sub eps 


=cut

 sub eps {

	my ( $self,$eps )		= @_;
	if ( $eps ne $empty_string ) {

		$subackus->{_eps}		= $eps;
		$subackus->{_note}		= $subackus->{_note}.' eps='.$subackus->{_eps};
		$subackus->{_Step}		= $subackus->{_Step}.' eps='.$subackus->{_eps};

	} else { 
		print("subackus, eps, missing eps,\n");
	 }
 }


=head2 sub eta 


=cut

 sub eta {

	my ( $self,$eta )		= @_;
	if ( $eta ne $empty_string ) {

		$subackus->{_eta}		= $eta;
		$subackus->{_note}		= $subackus->{_note}.' eta='.$subackus->{_eta};
		$subackus->{_Step}		= $subackus->{_Step}.' eta='.$subackus->{_eta};

	} else { 
		print("subackus, eta, missing eta,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$subackus->{_key}		= $key;
		$subackus->{_note}		= $subackus->{_note}.' key='.$subackus->{_key};
		$subackus->{_Step}		= $subackus->{_Step}.' key='.$subackus->{_key};

	} else { 
		print("subackus, key, missing key,\n");
	 }
 }


=head2 sub navg 


=cut

 sub navg {

	my ( $self,$navg )		= @_;
	if ( $navg ne $empty_string ) {

		$subackus->{_navg}		= $navg;
		$subackus->{_note}		= $subackus->{_note}.' navg='.$subackus->{_navg};
		$subackus->{_Step}		= $subackus->{_Step}.' navg='.$subackus->{_navg};

	} else { 
		print("subackus, navg, missing navg,\n");
	 }
 }


=head2 sub nskip 


=cut

 sub nskip {

	my ( $self,$nskip )		= @_;
	if ( $nskip ne $empty_string ) {

		$subackus->{_nskip}		= $nskip;
		$subackus->{_note}		= $subackus->{_note}.' nskip='.$subackus->{_nskip};
		$subackus->{_Step}		= $subackus->{_Step}.' nskip='.$subackus->{_nskip};

	} else { 
		print("subackus, nskip, missing nskip,\n");
	 }
 }


=head2 sub tracl 


=cut

 sub tracl {

	my ( $self,$tracl )		= @_;
	if ( $tracl ne $empty_string ) {

		$subackus->{_tracl}		= $tracl;
		$subackus->{_note}		= $subackus->{_note}.' tracl='.$subackus->{_tracl};
		$subackus->{_Step}		= $subackus->{_Step}.' tracl='.$subackus->{_tracl};

	} else { 
		print("subackus, tracl, missing tracl,\n");
	 }
 }


=head2 sub vang 


=cut

 sub vang {

	my ( $self,$vang )		= @_;
	if ( $vang ne $empty_string ) {

		$subackus->{_vang}		= $vang;
		$subackus->{_note}		= $subackus->{_note}.' vang='.$subackus->{_vang};
		$subackus->{_Step}		= $subackus->{_Step}.' vang='.$subackus->{_vang};

	} else { 
		print("subackus, vang, missing vang,\n");
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
