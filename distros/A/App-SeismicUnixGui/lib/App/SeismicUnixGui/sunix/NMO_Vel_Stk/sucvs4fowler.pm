package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sucvs4fowler;

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
 SUCVS4FOWLER --compute constant velocity stacks for input to Fowler codes



 Required Parameter:							

 ncdps=		number of input cdp gathers			

 Optional Parameters:							

 vminstack=1500.	minimum velocity panel in m/s to output		

 nvstack=180		number of stacking velocity panels to compute	

			( Let offmax be the maximum offset, fmax be	

			the maximum freq to preserve, and tmute be	

			the starting mute time in sec on offmax, then	

			the recommended value for nvstack would be	

			nvstack = 4 +(offmax*offmax*fmax)/(0.6*vmin*vmin*tmute)

			---you may want to make do with less---)		

 lmute=24		length of mute taper in ms			

 nonhyp=1		1 if do mute at 2*offset/vhyp to avoid		

			non-hyperbolic moveout, 0 otherwise		

 vhyp=2500.		velocity to use for non-hyperbolic moveout mute	

 lbtaper=0		length of bottom taper in ms			

 lstaper=0		length of side taper in traces			

 dtout=1.5*dt		output sample rate in s,			

			note: typically fmax=salias*0.5/dtout		

 mxfold=120		maximum number of offsets/input cmp		

 salias=0.8		fraction of output frequencies to force within sloth

			antialias limit.  This controls muting by offset of

			the input data prior to computing the cv stacks	

			for values of choose=1 or choose=2.		

 Required trace header words on input are ns, dt, cdp, offset.		







 Author:  (Visitor to CSM from Mobil): John E. Anderson, Spring 1994

 

	References:



	Fowler, P., 1988, Ph.D. Thesis, Stanford University.

	Anderson, J.E., Alkhalifah, T., and Tsvankin, I., 1994, Fowler

		DMO and time migration for transversely isotropic media,

		1994 CWP project review







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

my $sucvs4fowler			= {
	_choose					=> '',
	_dtout					=> '',
	_fmax					=> '',
	_lbtaper					=> '',
	_lmute					=> '',
	_lstaper					=> '',
	_mxfold					=> '',
	_ncdps					=> '',
	_nonhyp					=> '',
	_nvstack					=> '',
	_salias					=> '',
	_vhyp					=> '',
	_vminstack					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucvs4fowler->{_Step}     = 'sucvs4fowler'.$sucvs4fowler->{_Step};
	return ( $sucvs4fowler->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucvs4fowler->{_note}     = 'sucvs4fowler'.$sucvs4fowler->{_note};
	return ( $sucvs4fowler->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucvs4fowler->{_choose}			= '';
		$sucvs4fowler->{_dtout}			= '';
		$sucvs4fowler->{_fmax}			= '';
		$sucvs4fowler->{_lbtaper}			= '';
		$sucvs4fowler->{_lmute}			= '';
		$sucvs4fowler->{_lstaper}			= '';
		$sucvs4fowler->{_mxfold}			= '';
		$sucvs4fowler->{_ncdps}			= '';
		$sucvs4fowler->{_nonhyp}			= '';
		$sucvs4fowler->{_nvstack}			= '';
		$sucvs4fowler->{_salias}			= '';
		$sucvs4fowler->{_vhyp}			= '';
		$sucvs4fowler->{_vminstack}			= '';
		$sucvs4fowler->{_Step}			= '';
		$sucvs4fowler->{_note}			= '';
 }


=head2 sub choose 


=cut

 sub choose {

	my ( $self,$choose )		= @_;
	if ( $choose ne $empty_string ) {

		$sucvs4fowler->{_choose}		= $choose;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' choose='.$sucvs4fowler->{_choose};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' choose='.$sucvs4fowler->{_choose};

	} else { 
		print("sucvs4fowler, choose, missing choose,\n");
	 }
 }


=head2 sub dtout 


=cut

 sub dtout {

	my ( $self,$dtout )		= @_;
	if ( $dtout ne $empty_string ) {

		$sucvs4fowler->{_dtout}		= $dtout;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' dtout='.$sucvs4fowler->{_dtout};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' dtout='.$sucvs4fowler->{_dtout};

	} else { 
		print("sucvs4fowler, dtout, missing dtout,\n");
	 }
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sucvs4fowler->{_fmax}		= $fmax;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' fmax='.$sucvs4fowler->{_fmax};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' fmax='.$sucvs4fowler->{_fmax};

	} else { 
		print("sucvs4fowler, fmax, missing fmax,\n");
	 }
 }


=head2 sub lbtaper 


=cut

 sub lbtaper {

	my ( $self,$lbtaper )		= @_;
	if ( $lbtaper ne $empty_string ) {

		$sucvs4fowler->{_lbtaper}		= $lbtaper;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' lbtaper='.$sucvs4fowler->{_lbtaper};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' lbtaper='.$sucvs4fowler->{_lbtaper};

	} else { 
		print("sucvs4fowler, lbtaper, missing lbtaper,\n");
	 }
 }


=head2 sub lmute 


=cut

 sub lmute {

	my ( $self,$lmute )		= @_;
	if ( $lmute ne $empty_string ) {

		$sucvs4fowler->{_lmute}		= $lmute;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' lmute='.$sucvs4fowler->{_lmute};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' lmute='.$sucvs4fowler->{_lmute};

	} else { 
		print("sucvs4fowler, lmute, missing lmute,\n");
	 }
 }


=head2 sub lstaper 


=cut

 sub lstaper {

	my ( $self,$lstaper )		= @_;
	if ( $lstaper ne $empty_string ) {

		$sucvs4fowler->{_lstaper}		= $lstaper;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' lstaper='.$sucvs4fowler->{_lstaper};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' lstaper='.$sucvs4fowler->{_lstaper};

	} else { 
		print("sucvs4fowler, lstaper, missing lstaper,\n");
	 }
 }


=head2 sub mxfold 


=cut

 sub mxfold {

	my ( $self,$mxfold )		= @_;
	if ( $mxfold ne $empty_string ) {

		$sucvs4fowler->{_mxfold}		= $mxfold;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' mxfold='.$sucvs4fowler->{_mxfold};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' mxfold='.$sucvs4fowler->{_mxfold};

	} else { 
		print("sucvs4fowler, mxfold, missing mxfold,\n");
	 }
 }


=head2 sub ncdps 


=cut

 sub ncdps {

	my ( $self,$ncdps )		= @_;
	if ( $ncdps ne $empty_string ) {

		$sucvs4fowler->{_ncdps}		= $ncdps;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' ncdps='.$sucvs4fowler->{_ncdps};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' ncdps='.$sucvs4fowler->{_ncdps};

	} else { 
		print("sucvs4fowler, ncdps, missing ncdps,\n");
	 }
 }


=head2 sub nonhyp 


=cut

 sub nonhyp {

	my ( $self,$nonhyp )		= @_;
	if ( $nonhyp ne $empty_string ) {

		$sucvs4fowler->{_nonhyp}		= $nonhyp;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' nonhyp='.$sucvs4fowler->{_nonhyp};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' nonhyp='.$sucvs4fowler->{_nonhyp};

	} else { 
		print("sucvs4fowler, nonhyp, missing nonhyp,\n");
	 }
 }


=head2 sub nvstack 


=cut

 sub nvstack {

	my ( $self,$nvstack )		= @_;
	if ( $nvstack ne $empty_string ) {

		$sucvs4fowler->{_nvstack}		= $nvstack;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' nvstack='.$sucvs4fowler->{_nvstack};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' nvstack='.$sucvs4fowler->{_nvstack};

	} else { 
		print("sucvs4fowler, nvstack, missing nvstack,\n");
	 }
 }


=head2 sub salias 


=cut

 sub salias {

	my ( $self,$salias )		= @_;
	if ( $salias ne $empty_string ) {

		$sucvs4fowler->{_salias}		= $salias;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' salias='.$sucvs4fowler->{_salias};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' salias='.$sucvs4fowler->{_salias};

	} else { 
		print("sucvs4fowler, salias, missing salias,\n");
	 }
 }


=head2 sub vhyp 


=cut

 sub vhyp {

	my ( $self,$vhyp )		= @_;
	if ( $vhyp ne $empty_string ) {

		$sucvs4fowler->{_vhyp}		= $vhyp;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' vhyp='.$sucvs4fowler->{_vhyp};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' vhyp='.$sucvs4fowler->{_vhyp};

	} else { 
		print("sucvs4fowler, vhyp, missing vhyp,\n");
	 }
 }


=head2 sub vminstack 


=cut

 sub vminstack {

	my ( $self,$vminstack )		= @_;
	if ( $vminstack ne $empty_string ) {

		$sucvs4fowler->{_vminstack}		= $vminstack;
		$sucvs4fowler->{_note}		= $sucvs4fowler->{_note}.' vminstack='.$sucvs4fowler->{_vminstack};
		$sucvs4fowler->{_Step}		= $sucvs4fowler->{_Step}.' vminstack='.$sucvs4fowler->{_vminstack};

	} else { 
		print("sucvs4fowler, vminstack, missing vminstack,\n");
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
