package App::SeismicUnixGui::sunix::header::surandhw;

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
 surandhw - set header word to random variable 		



 surandhw <stdin >stdout key=tstat a=0 min=0 max=1		



 Required parameters:						

 	none (no op)						



 Optional parameters:						

 	key=tstat	header key word to set			

 	a=0		=1 flag to add original value to final key

 	noise=gauss	noise probability distribution		

 			=flat for uniform; default Gaussian	

 	seed=from_clock	random number seed (integer)		

 	min=0		minimum random number			

 	max=1		maximum radnom number		 	



 NOTES:							

 The value of header word key is computed using the formula:	

 	val(key) = a * val(key) + rand				



 Example:							

  	surandhw <indata key=tstat a=0 min=0 max=10  > outdata	



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

my $surandhw			= {
	_a					=> '',
	_key					=> '',
	_max					=> '',
	_min					=> '',
	_noise					=> '',
	_seed					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$surandhw->{_Step}     = 'surandhw'.$surandhw->{_Step};
	return ( $surandhw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$surandhw->{_note}     = 'surandhw'.$surandhw->{_note};
	return ( $surandhw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$surandhw->{_a}			= '';
		$surandhw->{_key}			= '';
		$surandhw->{_max}			= '';
		$surandhw->{_min}			= '';
		$surandhw->{_noise}			= '';
		$surandhw->{_seed}			= '';
		$surandhw->{_Step}			= '';
		$surandhw->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$surandhw->{_a}		= $a;
		$surandhw->{_note}		= $surandhw->{_note}.' a='.$surandhw->{_a};
		$surandhw->{_Step}		= $surandhw->{_Step}.' a='.$surandhw->{_a};

	} else { 
		print("surandhw, a, missing a,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$surandhw->{_key}		= $key;
		$surandhw->{_note}		= $surandhw->{_note}.' key='.$surandhw->{_key};
		$surandhw->{_Step}		= $surandhw->{_Step}.' key='.$surandhw->{_key};

	} else { 
		print("surandhw, key, missing key,\n");
	 }
 }


=head2 sub max 


=cut

 sub max {

	my ( $self,$max )		= @_;
	if ( $max ne $empty_string ) {

		$surandhw->{_max}		= $max;
		$surandhw->{_note}		= $surandhw->{_note}.' max='.$surandhw->{_max};
		$surandhw->{_Step}		= $surandhw->{_Step}.' max='.$surandhw->{_max};

	} else { 
		print("surandhw, max, missing max,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$surandhw->{_min}		= $min;
		$surandhw->{_note}		= $surandhw->{_note}.' min='.$surandhw->{_min};
		$surandhw->{_Step}		= $surandhw->{_Step}.' min='.$surandhw->{_min};

	} else { 
		print("surandhw, min, missing min,\n");
	 }
 }


=head2 sub noise 


=cut

 sub noise {

	my ( $self,$noise )		= @_;
	if ( $noise ne $empty_string ) {

		$surandhw->{_noise}		= $noise;
		$surandhw->{_note}		= $surandhw->{_note}.' noise='.$surandhw->{_noise};
		$surandhw->{_Step}		= $surandhw->{_Step}.' noise='.$surandhw->{_noise};

	} else { 
		print("surandhw, noise, missing noise,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$surandhw->{_seed}		= $seed;
		$surandhw->{_note}		= $surandhw->{_note}.' seed='.$surandhw->{_seed};
		$surandhw->{_Step}		= $surandhw->{_Step}.' seed='.$surandhw->{_seed};

	} else { 
		print("surandhw, seed, missing seed,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
