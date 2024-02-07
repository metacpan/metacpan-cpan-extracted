package App::SeismicUnixGui::sunix::well::subackush;

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
 SUBACKUSH - calculate Thomsen anisotropy parameters from 	

 	     well log (vp,vs,rho) data and optionally include	

 	     intrinsic VTI shale layers based on gramma ray log	

 	     via BACKUS averaging				

 subackush < vp_vs_rho.su >stdout [options]			

 subackush < vp_vs_rho_gr.su  gr=1 >stdout [options]		



 Required parameters:						

 none								



 Optional parameter:						

 navg=101	number of depth samples in Backus avg window 	



 	Intrinsic anisotropy of shale layers can be included ...

 gr=0		no gamma ray log input for shale 		

		=1 input is vp_vs_rho_gr			

 grs=100	pure shale gamma ray value (API units)		

 grc=10	0hale gamma ray value (API units)		

 smode=1	include shale anis params prop to shale volume 	

		=0 include shale anis for pure shale only	

 se=0.209	shale epsilon (Thomsen parameter)		

 sd=0.033	shale delta (Thomsen parameter)			

 sg=0.203	shale gamma (Thomsen parameter)			



 Notes:							

 1. Input are (vp,vs,rho) traces in metric units		

 2. Output are  						

    tracl	=(1,2,3,4,5,6)					

    quantity	=(vp0,vs0,<rho>,epsilon,delta,gamma) 		

    units	=(m/s,m/s,kg/m^3,nd,nd,nd) nd=dimensionless	

    tracl	=(7,8)						

    quantity	=(Vsh,shaleEps) Vsh=shale volume fraction	

    units	=(nd,nd) 					

 3. (epsilon,delta,etc.) can be isolated by tracl header field 

 4. (vp0,vs0) are backus averaged vertical wavespeeds		

 5. <rho> is backus averaged density, etc.			



 Example:							

 las2su < logs.las nskip=34 nlog=4 > logs.su 			

 suwind < logs.su  key=tracl min=2 max=3 | suop op=s2vm > v.su	

 suwind < logs.su  key=tracl min=4 max=4 | suop op=d2m > d.su	

 fcat v.su d.su > vp_vs_rho.su					

 subackus < vp_vs_rho.su > vp0_vs0_rho_eps_delta_gamma.su	

 In this example we start with a well las file containing 	

 34 header lines and 4 log tracks (depth,p_son,s_son,den).	

 This is converted to su format by las2su.  Then we pull off	

 the sonic logs and convert them to velocity in metric units.	

 Then the density log is pulled off and converted to metric.	

 All three metric curves are bundled into one su file which 	

 is the input to subackus. 					", 



 Related programs: subackus, sulprime				





 Credits:



	UHouston: Chris Liner 

              I gratefully acknowledge Saudi Aramco for permission

              to release this code developed while I worked for the 

              EXPEC-ARC research division.



 References:

 Anisotropy parameters: Thomsen, 2002, DISC Notes (SEG)

 Backus Method: Berryman, Grechka, and Berge, 1997, SEP94

 Shale params: Wang, 2002, Geophysics, p. 1427	



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

my $subackush			= {
	_gr					=> '',
	_grc					=> '',
	_grs					=> '',
	_key					=> '',
	_navg					=> '',
	_nskip					=> '',
	_quantity					=> '',
	_sd					=> '',
	_se					=> '',
	_sg					=> '',
	_smode					=> '',
	_tracl					=> '',
	_units					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$subackush->{_Step}     = 'subackush'.$subackush->{_Step};
	return ( $subackush->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$subackush->{_note}     = 'subackush'.$subackush->{_note};
	return ( $subackush->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$subackush->{_gr}			= '';
		$subackush->{_grc}			= '';
		$subackush->{_grs}			= '';
		$subackush->{_key}			= '';
		$subackush->{_navg}			= '';
		$subackush->{_nskip}			= '';
		$subackush->{_quantity}			= '';
		$subackush->{_sd}			= '';
		$subackush->{_se}			= '';
		$subackush->{_sg}			= '';
		$subackush->{_smode}			= '';
		$subackush->{_tracl}			= '';
		$subackush->{_units}			= '';
		$subackush->{_Step}			= '';
		$subackush->{_note}			= '';
 }


=head2 sub gr 


=cut

 sub gr {

	my ( $self,$gr )		= @_;
	if ( $gr ne $empty_string ) {

		$subackush->{_gr}		= $gr;
		$subackush->{_note}		= $subackush->{_note}.' gr='.$subackush->{_gr};
		$subackush->{_Step}		= $subackush->{_Step}.' gr='.$subackush->{_gr};

	} else { 
		print("subackush, gr, missing gr,\n");
	 }
 }


=head2 sub grc 


=cut

 sub grc {

	my ( $self,$grc )		= @_;
	if ( $grc ne $empty_string ) {

		$subackush->{_grc}		= $grc;
		$subackush->{_note}		= $subackush->{_note}.' grc='.$subackush->{_grc};
		$subackush->{_Step}		= $subackush->{_Step}.' grc='.$subackush->{_grc};

	} else { 
		print("subackush, grc, missing grc,\n");
	 }
 }


=head2 sub grs 


=cut

 sub grs {

	my ( $self,$grs )		= @_;
	if ( $grs ne $empty_string ) {

		$subackush->{_grs}		= $grs;
		$subackush->{_note}		= $subackush->{_note}.' grs='.$subackush->{_grs};
		$subackush->{_Step}		= $subackush->{_Step}.' grs='.$subackush->{_grs};

	} else { 
		print("subackush, grs, missing grs,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$subackush->{_key}		= $key;
		$subackush->{_note}		= $subackush->{_note}.' key='.$subackush->{_key};
		$subackush->{_Step}		= $subackush->{_Step}.' key='.$subackush->{_key};

	} else { 
		print("subackush, key, missing key,\n");
	 }
 }


=head2 sub navg 


=cut

 sub navg {

	my ( $self,$navg )		= @_;
	if ( $navg ne $empty_string ) {

		$subackush->{_navg}		= $navg;
		$subackush->{_note}		= $subackush->{_note}.' navg='.$subackush->{_navg};
		$subackush->{_Step}		= $subackush->{_Step}.' navg='.$subackush->{_navg};

	} else { 
		print("subackush, navg, missing navg,\n");
	 }
 }


=head2 sub nskip 


=cut

 sub nskip {

	my ( $self,$nskip )		= @_;
	if ( $nskip ne $empty_string ) {

		$subackush->{_nskip}		= $nskip;
		$subackush->{_note}		= $subackush->{_note}.' nskip='.$subackush->{_nskip};
		$subackush->{_Step}		= $subackush->{_Step}.' nskip='.$subackush->{_nskip};

	} else { 
		print("subackush, nskip, missing nskip,\n");
	 }
 }


=head2 sub quantity 


=cut

 sub quantity {

	my ( $self,$quantity )		= @_;
	if ( $quantity ne $empty_string ) {

		$subackush->{_quantity}		= $quantity;
		$subackush->{_note}		= $subackush->{_note}.' quantity='.$subackush->{_quantity};
		$subackush->{_Step}		= $subackush->{_Step}.' quantity='.$subackush->{_quantity};

	} else { 
		print("subackush, quantity, missing quantity,\n");
	 }
 }


=head2 sub sd 


=cut

 sub sd {

	my ( $self,$sd )		= @_;
	if ( $sd ne $empty_string ) {

		$subackush->{_sd}		= $sd;
		$subackush->{_note}		= $subackush->{_note}.' sd='.$subackush->{_sd};
		$subackush->{_Step}		= $subackush->{_Step}.' sd='.$subackush->{_sd};

	} else { 
		print("subackush, sd, missing sd,\n");
	 }
 }


=head2 sub se 


=cut

 sub se {

	my ( $self,$se )		= @_;
	if ( $se ne $empty_string ) {

		$subackush->{_se}		= $se;
		$subackush->{_note}		= $subackush->{_note}.' se='.$subackush->{_se};
		$subackush->{_Step}		= $subackush->{_Step}.' se='.$subackush->{_se};

	} else { 
		print("subackush, se, missing se,\n");
	 }
 }


=head2 sub sg 


=cut

 sub sg {

	my ( $self,$sg )		= @_;
	if ( $sg ne $empty_string ) {

		$subackush->{_sg}		= $sg;
		$subackush->{_note}		= $subackush->{_note}.' sg='.$subackush->{_sg};
		$subackush->{_Step}		= $subackush->{_Step}.' sg='.$subackush->{_sg};

	} else { 
		print("subackush, sg, missing sg,\n");
	 }
 }


=head2 sub smode 


=cut

 sub smode {

	my ( $self,$smode )		= @_;
	if ( $smode ne $empty_string ) {

		$subackush->{_smode}		= $smode;
		$subackush->{_note}		= $subackush->{_note}.' smode='.$subackush->{_smode};
		$subackush->{_Step}		= $subackush->{_Step}.' smode='.$subackush->{_smode};

	} else { 
		print("subackush, smode, missing smode,\n");
	 }
 }


=head2 sub tracl 


=cut

 sub tracl {

	my ( $self,$tracl )		= @_;
	if ( $tracl ne $empty_string ) {

		$subackush->{_tracl}		= $tracl;
		$subackush->{_note}		= $subackush->{_note}.' tracl='.$subackush->{_tracl};
		$subackush->{_Step}		= $subackush->{_Step}.' tracl='.$subackush->{_tracl};

	} else { 
		print("subackush, tracl, missing tracl,\n");
	 }
 }


=head2 sub units 


=cut

 sub units {

	my ( $self,$units )		= @_;
	if ( $units ne $empty_string ) {

		$subackush->{_units}		= $units;
		$subackush->{_note}		= $subackush->{_note}.' units='.$subackush->{_units};
		$subackush->{_Step}		= $subackush->{_Step}.' units='.$subackush->{_units};

	} else { 
		print("subackush, units, missing units,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
