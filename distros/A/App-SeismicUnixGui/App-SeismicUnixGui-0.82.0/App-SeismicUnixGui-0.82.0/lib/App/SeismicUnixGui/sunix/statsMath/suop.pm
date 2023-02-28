package App::SeismicUnixGui::sunix::statsMath::suop;

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
 SUOP - do unary arithmetic operation on segys 		



 suop <stdin >stdout op=abs					



 Required parameters:						

	none							



 Optional parameter:						

	op=abs		operation flag				

			abs   : absolute value			

			avg   : remove average value		

			ssqrt : signed square root		

			sqr   : square				

			ssqr  : signed square			

			sgn   : signum function			

			exp   : exponentiate			

			sexp  : signed exponentiate		

			slog  : signed natural log		

			slog2 : signed log base 2		

			slog10: signed common log		

			cos   : cosine				

			sin   : sine				

			tan   : tangent				

			cosh  : hyperbolic cosine		

			sinh  : hyperbolic sine			

			tanh  : hyperbolic tangent		

			cnorm : norm complex samples by modulus ", 

			norm  : divide trace by Max. Value	

			db    : 20 * slog10 (data)		

			neg   : negate value			

			posonly : pass only positive values	

			negonly : pass only negative values	

                       sum   : running sum trace integration   

                       diff  : running diff trace differentiation

                       refl  : (v[i+1] - v[i])/(v[i+1] + v[i]) 

			mod2pi : modulo 2 pi			

			inv   : inverse				

			rmsamp : rms amplitude			

                       s2v   : sonic to velocity (ft/s) conversion     

                       s2vm  : sonic to velocity (m/s) conversion     

                       d2m   : density (g/cc) to metric (kg/m^3) conversion 

                       drv2  : 2nd order vertical derivative 

                       drv4  : 4th order vertical derivative 

                       integ : top-down integration            

                       spike : local extrema to spikes         

                       saf   : spike and fill to next spike    

                       freq  : local dominant freqeuncy        

                       lnza  : preserve least non-zero amps    

                       --------- window operations ----------- 

                       mean  : arithmetic mean                 

                       despike  : despiking based on median filter

                       std   : standard deviation              

                       var   : variance                        

       nw=21           number of time samples in window        

                       --------------------------------------- 

			nop   : no operation			



 Note:	Binary ops are provided by suop2.			

 Operations inv, slog, slog2, and slog10 are "punctuated",	", 

 meaning that if, the input contains 0 values,			

 0 values are returned.					",	



 For file operations on non-SU format binary files use:  farith



 Credits:



 CWP: Shuki Ronen, Jack K Cohen (c. 1987)

  Toralf Foerster: norm and db operations, 10/95.

  Additions by Reg Beardsley, Chris Liner, and others.



 Notes:

	If efficiency becomes important consider inverting main loop

      and repeating operation code within the branches of the switch.



	Note on db option.  The following are equivalent:

	... | sufft | suamp | suop op=norm | suop op=slog10 |\

		sugain scale=20| suxgraph style=normal



	... | sufft | suamp | suop op=db | suxgraph style=normal



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

my $suop			= {
	_nw					=> '',
	_op					=> '',
	_scale					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suop->{_Step}     = 'suop'.$suop->{_Step};
	return ( $suop->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suop->{_note}     = 'suop'.$suop->{_note};
	return ( $suop->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suop->{_nw}			= '';
		$suop->{_op}			= '';
		$suop->{_scale}			= '';
		$suop->{_Step}			= '';
		$suop->{_note}			= '';
 }


=head2 sub nw 


=cut

 sub nw {

	my ( $self,$nw )		= @_;
	if ( $nw ne $empty_string ) {

		$suop->{_nw}		= $nw;
		$suop->{_note}		= $suop->{_note}.' nw='.$suop->{_nw};
		$suop->{_Step}		= $suop->{_Step}.' nw='.$suop->{_nw};

	} else { 
		print("suop, nw, missing nw,\n");
	 }
 }


=head2 sub op 


=cut

 sub op {

	my ( $self,$op )		= @_;
	if ( $op ne $empty_string ) {

		$suop->{_op}		= $op;
		$suop->{_note}		= $suop->{_note}.' op='.$suop->{_op};
		$suop->{_Step}		= $suop->{_Step}.' op='.$suop->{_op};

	} else { 
		print("suop, op, missing op,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$suop->{_scale}		= $scale;
		$suop->{_note}		= $suop->{_note}.' scale='.$suop->{_scale};
		$suop->{_Step}		= $suop->{_Step}.' scale='.$suop->{_scale};

	} else { 
		print("suop, scale, missing scale,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 2;

    return($max_index);
}
 
 
1;
