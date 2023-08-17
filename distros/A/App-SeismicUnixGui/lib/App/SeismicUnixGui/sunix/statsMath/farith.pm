package App::SeismicUnixGui::sunix::statsMath::farith;

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
 FARITH - File ARITHmetic -- perform simple arithmetic with binary files



 farith <infile >outfile [optional parameters]				



 Optional Parameters:							

 in=stdin	input file						

 out=stdout	output file						

 in2=	   second input file (required for binary operations)		

		   if it can't be opened as a file, it might be a scalar

 n=size_of_in,  fastest dimension (used only for op=cartprod is set)	

 isig=		 index at which signum function acts (used only for 	

			op=signum)					

 scale=	value to scale in by, used only for op=scale)		

 bias=		value to bias in by, used only for op=bias)		



 op=noop   noop for out = in						

	   neg  for out = -in						

	   abs  for out = abs(in)					

	   scale for out = in *scale					

	   bias for out = in + bias 					

	   exp  for out = exp(in)					

	   sin  for out = sin(in)					

	   cos  for out = cos(in)					

	   log  for out = log(in)					

	   sqrt for out = (signed) sqrt(in)				

	   sqr  for out = in*in						

	   degrad  for out = in*PI/180					

	   raddeg  for out = in*180/PI					

	   pinv  for out = (punctuated) 1 / in   			

	   pinvsqr  for out = (punctuated) 1 /in*in 			

	   pinvsqrt for out = (punctuated signed) 1 /sqrt(in) 		

	   add  for out = in + in2					

	   sub  for out = in - in2					

	   mul  for out = in * in2					

	   div  for out = in / in2					

		cartprod for out = in x in2					

		requires: n=size_of_in, fastest dimension in output	

		signum for out[i] = in[i] for i< isig  and			

				= -in[i] for i>= isig			

		requires: isig=point where signum function acts		

 Seismic operations:							

	   slowp   for  out =  1/in - 1/in2	Slowness perturbation	

	   slothp  for  out =  1/in^2 - 1/in2^2   Sloth perturbation	



 Notes:								

 op=sqrt takes sqrt(x) for x>=0 and -sqrt(ABS(x)) for x<0 (signed sqrt)



 op=pinv takes y=1/x for x!=0,  if x=0 then y=0. (punctuated inverse)	



 The seismic operations assume that in and in2 are wavespeed profiles.	

 "Slowness" is 1/wavespeed and "sloth" is  1/wavespeed^2.		

 Use "suop" and "suop2" to perform unary and binary operations on	

 data in the SU (SEGY trace) format.					



 The options "pinvsq" and "pinvsqrt" are also useful for seismic	

 computations involving converting velocity to sloth and vice versa.	



 The option "cartprod" (cartesian product) requires also that the	

 parameter n=size_of_in be set. This will be the fastest dimension	

 of the rectangular array that is output.				



 The option "signum" causes a flip in sign for all values with index	

 greater than "isig"	(really -1*signum(index)).			



 For file operations on SU format files, please use:  suop, suop2	







   AUTHOR:  Dave Hale, Colorado School of Mines, 07/07/89

	Zhaobo Meng added scale and cartprod, 10/01/96

	Zhaobo Meng added signum, 9 May 1997

	Tony Kocurko added scalar operations, August 1997

      John Stockwell added bias option 4 August 2004



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

my $farith			= {
	_bias					=> '',
	_in					=> '',
	_in2					=> '',
	_isig					=> '',
	_n					=> '',
	_op					=> '',
	_out					=> '',
	_scale					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$farith->{_Step}     = 'farith'.$farith->{_Step};
	return ( $farith->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$farith->{_note}     = 'farith'.$farith->{_note};
	return ( $farith->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$farith->{_bias}			= '';
		$farith->{_in}			= '';
		$farith->{_in2}			= '';
		$farith->{_isig}			= '';
		$farith->{_n}			= '';
		$farith->{_op}			= '';
		$farith->{_out}			= '';
		$farith->{_scale}			= '';
		$farith->{_Step}			= '';
		$farith->{_note}			= '';
 }


=head2 sub bias 


=cut

 sub bias {

	my ( $self,$bias )		= @_;
	if ( $bias ne $empty_string ) {

		$farith->{_bias}		= $bias;
		$farith->{_note}		= $farith->{_note}.' bias='.$farith->{_bias};
		$farith->{_Step}		= $farith->{_Step}.' bias='.$farith->{_bias};

	} else { 
		print("farith, bias, missing bias,\n");
	 }
 }


=head2 sub in 


=cut

 sub in {

	my ( $self,$in )		= @_;
	if ( $in ne $empty_string ) {

		$farith->{_in}		= $in;
		$farith->{_note}		= $farith->{_note}.' in='.$farith->{_in};
		$farith->{_Step}		= $farith->{_Step}.' in='.$farith->{_in};

	} else { 
		print("farith, in, missing in,\n");
	 }
 }


=head2 sub in2 


=cut

 sub in2 {

	my ( $self,$in2 )		= @_;
	if ( $in2 ne $empty_string ) {

		$farith->{_in2}		= $in2;
		$farith->{_note}		= $farith->{_note}.' in2='.$farith->{_in2};
		$farith->{_Step}		= $farith->{_Step}.' in2='.$farith->{_in2};

	} else { 
		print("farith, in2, missing in2,\n");
	 }
 }


=head2 sub isig 


=cut

 sub isig {

	my ( $self,$isig )		= @_;
	if ( $isig ne $empty_string ) {

		$farith->{_isig}		= $isig;
		$farith->{_note}		= $farith->{_note}.' isig='.$farith->{_isig};
		$farith->{_Step}		= $farith->{_Step}.' isig='.$farith->{_isig};

	} else { 
		print("farith, isig, missing isig,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$farith->{_n}		= $n;
		$farith->{_note}		= $farith->{_note}.' n='.$farith->{_n};
		$farith->{_Step}		= $farith->{_Step}.' n='.$farith->{_n};

	} else { 
		print("farith, n, missing n,\n");
	 }
 }


=head2 sub op 


=cut

 sub op {

	my ( $self,$op )		= @_;
	if ( $op ne $empty_string ) {

		$farith->{_op}		= $op;
		$farith->{_note}		= $farith->{_note}.' op='.$farith->{_op};
		$farith->{_Step}		= $farith->{_Step}.' op='.$farith->{_op};

	} else { 
		print("farith, op, missing op,\n");
	 }
 }


=head2 sub out 


=cut

 sub out {

	my ( $self,$out )		= @_;
	if ( $out ne $empty_string ) {

		$farith->{_out}		= $out;
		$farith->{_note}		= $farith->{_note}.' out='.$farith->{_out};
		$farith->{_Step}		= $farith->{_Step}.' out='.$farith->{_out};

	} else { 
		print("farith, out, missing out,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$farith->{_scale}		= $scale;
		$farith->{_note}		= $farith->{_note}.' scale='.$farith->{_scale};
		$farith->{_Step}		= $farith->{_Step}.' scale='.$farith->{_scale};

	} else { 
		print("farith, scale, missing scale,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
