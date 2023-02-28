package App::SeismicUnixGui::sunix::header::suahw;

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
 SUAHW - Assign Header Word using another header word			



  suahw <stdin >stdout [optional parameters]				



 Required parameters:							

  key1=ep		output key 					

  key2=fldr		input key 					

  a=			array of key1 output values			

  b=			array of key2 input values			

  mode=extrapolate	how to assign a key1-value, when the key2-value	

			is not found in b:				

			=interpolate	interpolate			

			=extrapolate	interpolate and extrapolate	

			=zero		zero key1-values		

			=preserve	preserve key1-values		

			=transfer	transfer key2-values to key1	



 Optional parameters:							

  key3=tracf		input key 					

  c=			array of key3 input values			



 The key1-value is assigned based on the key2-value and the arrays a,b.

 If the header value of key2= equals the n'th element in b=, then the	

 header value key1= is set to the n'th element in a=.			

 The arrays a= and b= must have the same size, and the elements of b=	

 must be in ascending order.						



 The mode-switch decides what to do when a trace header has a key2-value

 that is not an element of the b-array:				

    zero - the key1-value will be set to zero				

    preserve - the key1-value will not be modified			

    transfer - the key2-value will be assigned to key1			

    interpolate - if the key2-value is greater than the n'th element	

	and less than the (n+1)'th element of b=, then the key1-value	

	will be	interpolated accordingly from the n'th and (n+1)'th	

	element of a=. Otherwise, key1 will not be changed.		

    extrapolate - same as interpolate, plus, if the key2-value is	

	smaller/greater than the first/last element of b=, then the	

	key1-value will be set to the first/last element of a=		



 The array c= can be used to prevent the modification of trace headers	

 with certain key3-values. The number of elements in c= is independent	

 of the other arrays.							

 The key1-value will not be modified, if the mode-switch is set to	

    zero, preserve, transfer - and the key3-value is an element of c=	

    interpolate, extrapolate - and the key3-value is outside of c=	

				(smaller than the first or greater than	

				the last element of c=)			



 Examples:								

  Assign shot numbers 1-3 to field file ID 1009,1011,1015 and 0 to the	

  remaining FFID (fldr):						

    suahw <data a=1,2,3 b=1009,1011,1015 mode=zero			



  Use channel numbers (tracf) to assign stations numbers (tracr) for a	

  split spread with a gap:						

    suahw <data key1=tracr a=151,128,124,101 key2=tracf b=1,24,25,48	



  Assign shot-statics:							

    suahw <data key1=sstat key2=ep a=-32,13,-4 b=1,2,3			



  Set trid to 0 for channel 1-24, but only for the record 1016:	

    suahw <data key1=trid key2=tracf key3=fldr a=0,0 b=1,24 c=1016	



 Credits:

	Florian Bleibinhaus, U Salzburg, Austria

	cloned from suchw of Einar Kajartansson, SEP



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

my $suahw			= {
	_a					=> '',
	_b					=> '',
	_c					=> '',
	_key1					=> '',
	_key2					=> '',
	_key3					=> '',
	_mode					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suahw->{_Step}     = 'suahw'.$suahw->{_Step};
	return ( $suahw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suahw->{_note}     = 'suahw'.$suahw->{_note};
	return ( $suahw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suahw->{_a}			= '';
		$suahw->{_b}			= '';
		$suahw->{_c}			= '';
		$suahw->{_key1}			= '';
		$suahw->{_key2}			= '';
		$suahw->{_key3}			= '';
		$suahw->{_mode}			= '';
		$suahw->{_Step}			= '';
		$suahw->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$suahw->{_a}		= $a;
		$suahw->{_note}		= $suahw->{_note}.' a='.$suahw->{_a};
		$suahw->{_Step}		= $suahw->{_Step}.' a='.$suahw->{_a};

	} else { 
		print("suahw, a, missing a,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$suahw->{_b}		= $b;
		$suahw->{_note}		= $suahw->{_note}.' b='.$suahw->{_b};
		$suahw->{_Step}		= $suahw->{_Step}.' b='.$suahw->{_b};

	} else { 
		print("suahw, b, missing b,\n");
	 }
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$suahw->{_c}		= $c;
		$suahw->{_note}		= $suahw->{_note}.' c='.$suahw->{_c};
		$suahw->{_Step}		= $suahw->{_Step}.' c='.$suahw->{_c};

	} else { 
		print("suahw, c, missing c,\n");
	 }
 }


=head2 sub key1 


=cut

 sub key1 {

	my ( $self,$key1 )		= @_;
	if ( $key1 ne $empty_string ) {

		$suahw->{_key1}		= $key1;
		$suahw->{_note}		= $suahw->{_note}.' key1='.$suahw->{_key1};
		$suahw->{_Step}		= $suahw->{_Step}.' key1='.$suahw->{_key1};

	} else { 
		print("suahw, key1, missing key1,\n");
	 }
 }


=head2 sub key2 


=cut

 sub key2 {

	my ( $self,$key2 )		= @_;
	if ( $key2 ne $empty_string ) {

		$suahw->{_key2}		= $key2;
		$suahw->{_note}		= $suahw->{_note}.' key2='.$suahw->{_key2};
		$suahw->{_Step}		= $suahw->{_Step}.' key2='.$suahw->{_key2};

	} else { 
		print("suahw, key2, missing key2,\n");
	 }
 }


=head2 sub key3 


=cut

 sub key3 {

	my ( $self,$key3 )		= @_;
	if ( $key3 ne $empty_string ) {

		$suahw->{_key3}		= $key3;
		$suahw->{_note}		= $suahw->{_note}.' key3='.$suahw->{_key3};
		$suahw->{_Step}		= $suahw->{_Step}.' key3='.$suahw->{_key3};

	} else { 
		print("suahw, key3, missing key3,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$suahw->{_mode}		= $mode;
		$suahw->{_note}		= $suahw->{_note}.' mode='.$suahw->{_mode};
		$suahw->{_Step}		= $suahw->{_Step}.' mode='.$suahw->{_mode};

	} else { 
		print("suahw, mode, missing mode,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
