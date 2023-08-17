package App::SeismicUnixGui::sunix::well::sugassman;

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
 SUGASSMAN - Model reflectivity change with rock/fluid properties	



	sugassman [optional parameters] > data.su			



 Optional parameters:							

 nt=500 	number of time samples					

 ntr=200	number of traces					

 dt=0.004 	time sampling interval in seconds			

 mode=0	model isolated gassmann refl coefficient		

		=1 embed gassmann RC in random RC series		

		=2 R0 parameter sensitivity output			

 p=0.15 	parameter sensitivity test range (if mode=2)		

 .... Environment variables ...					

 temp=140 	Temperature in degrees C				

 pres=20 	Pressure in megaPascals					

 .... Caprock variables ....						

 v1=37900 	caprock P-wave speed (m/s)				

 r1=44300 	caprock mass density (g/cc)				

 .... Reservoir fluid variables ....					

 g=0.56	Gas specific gravity 0.56 (methane)-1.8 (condensate)	

 api=50 	Gas specific gravity 10 (heavy)-50 (ultra light)	

 s=35		Brine salinity in ppm/(1000 000				

 so=.7 	Oil saturation (0-1)					

 sg=.2 	Gas saturation (0-1)					

 .... Reservoir rock frame variables ....				

 kmin=37900 	Bulk modulus (MPa) of rock frame mineral(s) [default=quartz]

 mumin=44300 	Shear modulus (MPa) of rock frame mineral(s) [default=quartz]

 rmin=2.67 	Mass density (g/cc) of rock frame mineral(s) [default=quartz]

 phi=.24 	Rock frame porosity (0-1)				

 a=1 		Fitting parameters: Mdry/Mmineral ~ 1/(a + b phi^c)	

 b=15 		... where M is P-wave modulus and defaults are for	

 c=1 		... Glenn sandstone [see Liner (2nd ed, table 26.2)]	

	h=20 			Reservoir thickness (m)			



 Notes:								

 Creates a reflection coefficient series based on Gassmann		

 theory of velocity and density for porous elastic media		



 

 Credits: UHouston: Chris Liner	9/23/2009



 trace header fields set: 



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

my $sugassman			= {
	_a					=> '',
	_api					=> '',
	_b					=> '',
	_c					=> '',
	_dt					=> '',
	_g					=> '',
	_h					=> '',
	_kmin					=> '',
	_mode					=> '',
	_mumin					=> '',
	_nt					=> '',
	_ntr					=> '',
	_p					=> '',
	_phi					=> '',
	_pres					=> '',
	_r1					=> '',
	_rmin					=> '',
	_s					=> '',
	_sg					=> '',
	_so					=> '',
	_temp					=> '',
	_v1					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sugassman->{_Step}     = 'sugassman'.$sugassman->{_Step};
	return ( $sugassman->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sugassman->{_note}     = 'sugassman'.$sugassman->{_note};
	return ( $sugassman->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sugassman->{_a}			= '';
		$sugassman->{_api}			= '';
		$sugassman->{_b}			= '';
		$sugassman->{_c}			= '';
		$sugassman->{_dt}			= '';
		$sugassman->{_g}			= '';
		$sugassman->{_h}			= '';
		$sugassman->{_kmin}			= '';
		$sugassman->{_mode}			= '';
		$sugassman->{_mumin}			= '';
		$sugassman->{_nt}			= '';
		$sugassman->{_ntr}			= '';
		$sugassman->{_p}			= '';
		$sugassman->{_phi}			= '';
		$sugassman->{_pres}			= '';
		$sugassman->{_r1}			= '';
		$sugassman->{_rmin}			= '';
		$sugassman->{_s}			= '';
		$sugassman->{_sg}			= '';
		$sugassman->{_so}			= '';
		$sugassman->{_temp}			= '';
		$sugassman->{_v1}			= '';
		$sugassman->{_Step}			= '';
		$sugassman->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$sugassman->{_a}		= $a;
		$sugassman->{_note}		= $sugassman->{_note}.' a='.$sugassman->{_a};
		$sugassman->{_Step}		= $sugassman->{_Step}.' a='.$sugassman->{_a};

	} else { 
		print("sugassman, a, missing a,\n");
	 }
 }


=head2 sub api 


=cut

 sub api {

	my ( $self,$api )		= @_;
	if ( $api ne $empty_string ) {

		$sugassman->{_api}		= $api;
		$sugassman->{_note}		= $sugassman->{_note}.' api='.$sugassman->{_api};
		$sugassman->{_Step}		= $sugassman->{_Step}.' api='.$sugassman->{_api};

	} else { 
		print("sugassman, api, missing api,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$sugassman->{_b}		= $b;
		$sugassman->{_note}		= $sugassman->{_note}.' b='.$sugassman->{_b};
		$sugassman->{_Step}		= $sugassman->{_Step}.' b='.$sugassman->{_b};

	} else { 
		print("sugassman, b, missing b,\n");
	 }
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$sugassman->{_c}		= $c;
		$sugassman->{_note}		= $sugassman->{_note}.' c='.$sugassman->{_c};
		$sugassman->{_Step}		= $sugassman->{_Step}.' c='.$sugassman->{_c};

	} else { 
		print("sugassman, c, missing c,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sugassman->{_dt}		= $dt;
		$sugassman->{_note}		= $sugassman->{_note}.' dt='.$sugassman->{_dt};
		$sugassman->{_Step}		= $sugassman->{_Step}.' dt='.$sugassman->{_dt};

	} else { 
		print("sugassman, dt, missing dt,\n");
	 }
 }


=head2 sub g 


=cut

 sub g {

	my ( $self,$g )		= @_;
	if ( $g ne $empty_string ) {

		$sugassman->{_g}		= $g;
		$sugassman->{_note}		= $sugassman->{_note}.' g='.$sugassman->{_g};
		$sugassman->{_Step}		= $sugassman->{_Step}.' g='.$sugassman->{_g};

	} else { 
		print("sugassman, g, missing g,\n");
	 }
 }


=head2 sub h 


=cut

 sub h {

	my ( $self,$h )		= @_;
	if ( $h ne $empty_string ) {

		$sugassman->{_h}		= $h;
		$sugassman->{_note}		= $sugassman->{_note}.' h='.$sugassman->{_h};
		$sugassman->{_Step}		= $sugassman->{_Step}.' h='.$sugassman->{_h};

	} else { 
		print("sugassman, h, missing h,\n");
	 }
 }


=head2 sub kmin 


=cut

 sub kmin {

	my ( $self,$kmin )		= @_;
	if ( $kmin ne $empty_string ) {

		$sugassman->{_kmin}		= $kmin;
		$sugassman->{_note}		= $sugassman->{_note}.' kmin='.$sugassman->{_kmin};
		$sugassman->{_Step}		= $sugassman->{_Step}.' kmin='.$sugassman->{_kmin};

	} else { 
		print("sugassman, kmin, missing kmin,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$sugassman->{_mode}		= $mode;
		$sugassman->{_note}		= $sugassman->{_note}.' mode='.$sugassman->{_mode};
		$sugassman->{_Step}		= $sugassman->{_Step}.' mode='.$sugassman->{_mode};

	} else { 
		print("sugassman, mode, missing mode,\n");
	 }
 }


=head2 sub mumin 


=cut

 sub mumin {

	my ( $self,$mumin )		= @_;
	if ( $mumin ne $empty_string ) {

		$sugassman->{_mumin}		= $mumin;
		$sugassman->{_note}		= $sugassman->{_note}.' mumin='.$sugassman->{_mumin};
		$sugassman->{_Step}		= $sugassman->{_Step}.' mumin='.$sugassman->{_mumin};

	} else { 
		print("sugassman, mumin, missing mumin,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sugassman->{_nt}		= $nt;
		$sugassman->{_note}		= $sugassman->{_note}.' nt='.$sugassman->{_nt};
		$sugassman->{_Step}		= $sugassman->{_Step}.' nt='.$sugassman->{_nt};

	} else { 
		print("sugassman, nt, missing nt,\n");
	 }
 }


=head2 sub ntr 


=cut

 sub ntr {

	my ( $self,$ntr )		= @_;
	if ( $ntr ne $empty_string ) {

		$sugassman->{_ntr}		= $ntr;
		$sugassman->{_note}		= $sugassman->{_note}.' ntr='.$sugassman->{_ntr};
		$sugassman->{_Step}		= $sugassman->{_Step}.' ntr='.$sugassman->{_ntr};

	} else { 
		print("sugassman, ntr, missing ntr,\n");
	 }
 }


=head2 sub p 


=cut

 sub p {

	my ( $self,$p )		= @_;
	if ( $p ne $empty_string ) {

		$sugassman->{_p}		= $p;
		$sugassman->{_note}		= $sugassman->{_note}.' p='.$sugassman->{_p};
		$sugassman->{_Step}		= $sugassman->{_Step}.' p='.$sugassman->{_p};

	} else { 
		print("sugassman, p, missing p,\n");
	 }
 }


=head2 sub phi 


=cut

 sub phi {

	my ( $self,$phi )		= @_;
	if ( $phi ne $empty_string ) {

		$sugassman->{_phi}		= $phi;
		$sugassman->{_note}		= $sugassman->{_note}.' phi='.$sugassman->{_phi};
		$sugassman->{_Step}		= $sugassman->{_Step}.' phi='.$sugassman->{_phi};

	} else { 
		print("sugassman, phi, missing phi,\n");
	 }
 }


=head2 sub pres 


=cut

 sub pres {

	my ( $self,$pres )		= @_;
	if ( $pres ne $empty_string ) {

		$sugassman->{_pres}		= $pres;
		$sugassman->{_note}		= $sugassman->{_note}.' pres='.$sugassman->{_pres};
		$sugassman->{_Step}		= $sugassman->{_Step}.' pres='.$sugassman->{_pres};

	} else { 
		print("sugassman, pres, missing pres,\n");
	 }
 }


=head2 sub r1 


=cut

 sub r1 {

	my ( $self,$r1 )		= @_;
	if ( $r1 ne $empty_string ) {

		$sugassman->{_r1}		= $r1;
		$sugassman->{_note}		= $sugassman->{_note}.' r1='.$sugassman->{_r1};
		$sugassman->{_Step}		= $sugassman->{_Step}.' r1='.$sugassman->{_r1};

	} else { 
		print("sugassman, r1, missing r1,\n");
	 }
 }


=head2 sub rmin 


=cut

 sub rmin {

	my ( $self,$rmin )		= @_;
	if ( $rmin ne $empty_string ) {

		$sugassman->{_rmin}		= $rmin;
		$sugassman->{_note}		= $sugassman->{_note}.' rmin='.$sugassman->{_rmin};
		$sugassman->{_Step}		= $sugassman->{_Step}.' rmin='.$sugassman->{_rmin};

	} else { 
		print("sugassman, rmin, missing rmin,\n");
	 }
 }


=head2 sub s 


=cut

 sub s {

	my ( $self,$s )		= @_;
	if ( $s ne $empty_string ) {

		$sugassman->{_s}		= $s;
		$sugassman->{_note}		= $sugassman->{_note}.' s='.$sugassman->{_s};
		$sugassman->{_Step}		= $sugassman->{_Step}.' s='.$sugassman->{_s};

	} else { 
		print("sugassman, s, missing s,\n");
	 }
 }


=head2 sub sg 


=cut

 sub sg {

	my ( $self,$sg )		= @_;
	if ( $sg ne $empty_string ) {

		$sugassman->{_sg}		= $sg;
		$sugassman->{_note}		= $sugassman->{_note}.' sg='.$sugassman->{_sg};
		$sugassman->{_Step}		= $sugassman->{_Step}.' sg='.$sugassman->{_sg};

	} else { 
		print("sugassman, sg, missing sg,\n");
	 }
 }


=head2 sub so 


=cut

 sub so {

	my ( $self,$so )		= @_;
	if ( $so ne $empty_string ) {

		$sugassman->{_so}		= $so;
		$sugassman->{_note}		= $sugassman->{_note}.' so='.$sugassman->{_so};
		$sugassman->{_Step}		= $sugassman->{_Step}.' so='.$sugassman->{_so};

	} else { 
		print("sugassman, so, missing so,\n");
	 }
 }


=head2 sub temp 


=cut

 sub temp {

	my ( $self,$temp )		= @_;
	if ( $temp ne $empty_string ) {

		$sugassman->{_temp}		= $temp;
		$sugassman->{_note}		= $sugassman->{_note}.' temp='.$sugassman->{_temp};
		$sugassman->{_Step}		= $sugassman->{_Step}.' temp='.$sugassman->{_temp};

	} else { 
		print("sugassman, temp, missing temp,\n");
	 }
 }


=head2 sub v1 


=cut

 sub v1 {

	my ( $self,$v1 )		= @_;
	if ( $v1 ne $empty_string ) {

		$sugassman->{_v1}		= $v1;
		$sugassman->{_note}		= $sugassman->{_note}.' v1='.$sugassman->{_v1};
		$sugassman->{_Step}		= $sugassman->{_Step}.' v1='.$sugassman->{_v1};

	} else { 
		print("sugassman, v1, missing v1,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 21;

    return($max_index);
}
 
 
1;
