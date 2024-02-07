package App::SeismicUnixGui::sunix::shapeNcut::supad;

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
 SUPAD - Pad zero traces						



  supad <stdin >stdout min= max= [optional parameters]			



 Required parameters:							

  min=			trace key start					

  max=			trace key end					



 Optional parameters:							

  key1=ep		panel key 					

  key2=tracf		trace key 					

  key3=trid		flag key					

  val3=2		value assigned to padded traces			

  d=1			trace key spacing				



 Notes:								

  In contrast to most SU codes, supad recognizes panels, or ensembles.	

  If the input consists of several panels, each panel will be padded	

  individually.							

  key1 and key2 are the primary and secondary sort key of the data set.

  The sort order of key1 does not matter at all.			

  The sort order of key2 must be monotonous - if key2 is descending,	

	supply a negative value for the spacing d.			

  Traces with a key2-value outside the min/max range will be lost. 	

  Traces with a key2-value that is not a multiple of the spacing from	

	the min-value (the max-value, if the spacing is negative) will	

	not be lost. Instead, they will shift the series of key2-values.

  By default the dead trace flag will be raised for the padded traces.	

  This should make it easy to remove the zero traces later on, if need be.



 Examples:								

	suplane | supad min=1 max=40 key1=offset key2=tracr | ...	

	... appends eight empty traces.					



	suplane | supad min=1 max=32 key1=offset key2=tracr d=0.5 | ...	

	... inserts a zero trace after each trace (even though the	

	header tracr is integer and cannot properly store the floats)	



	suplane | supad min=1 max=32 | ...				

	... produces an error because the panel and trace key are all 0.





 Credits:

	Florian Bleibinhaus, U Salzburg, Austria



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

my $supad			= {
	_d					=> '',
	_key1					=> '',
	_key2					=> '',
	_key3					=> '',
	_max					=> '',
	_min					=> '',
	_val3					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supad->{_Step}     = 'supad'.$supad->{_Step};
	return ( $supad->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supad->{_note}     = 'supad'.$supad->{_note};
	return ( $supad->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supad->{_d}			= '';
		$supad->{_key1}			= '';
		$supad->{_key2}			= '';
		$supad->{_key3}			= '';
		$supad->{_max}			= '';
		$supad->{_min}			= '';
		$supad->{_val3}			= '';
		$supad->{_Step}			= '';
		$supad->{_note}			= '';
 }


=head2 sub d 


=cut

 sub d {

	my ( $self,$d )		= @_;
	if ( $d ne $empty_string ) {

		$supad->{_d}		= $d;
		$supad->{_note}		= $supad->{_note}.' d='.$supad->{_d};
		$supad->{_Step}		= $supad->{_Step}.' d='.$supad->{_d};

	} else { 
		print("supad, d, missing d,\n");
	 }
 }


=head2 sub key1 


=cut

 sub key1 {

	my ( $self,$key1 )		= @_;
	if ( $key1 ne $empty_string ) {

		$supad->{_key1}		= $key1;
		$supad->{_note}		= $supad->{_note}.' key1='.$supad->{_key1};
		$supad->{_Step}		= $supad->{_Step}.' key1='.$supad->{_key1};

	} else { 
		print("supad, key1, missing key1,\n");
	 }
 }


=head2 sub key2 


=cut

 sub key2 {

	my ( $self,$key2 )		= @_;
	if ( $key2 ne $empty_string ) {

		$supad->{_key2}		= $key2;
		$supad->{_note}		= $supad->{_note}.' key2='.$supad->{_key2};
		$supad->{_Step}		= $supad->{_Step}.' key2='.$supad->{_key2};

	} else { 
		print("supad, key2, missing key2,\n");
	 }
 }


=head2 sub key3 


=cut

 sub key3 {

	my ( $self,$key3 )		= @_;
	if ( $key3 ne $empty_string ) {

		$supad->{_key3}		= $key3;
		$supad->{_note}		= $supad->{_note}.' key3='.$supad->{_key3};
		$supad->{_Step}		= $supad->{_Step}.' key3='.$supad->{_key3};

	} else { 
		print("supad, key3, missing key3,\n");
	 }
 }


=head2 sub max 


=cut

 sub max {

	my ( $self,$max )		= @_;
	if ( $max ne $empty_string ) {

		$supad->{_max}		= $max;
		$supad->{_note}		= $supad->{_note}.' max='.$supad->{_max};
		$supad->{_Step}		= $supad->{_Step}.' max='.$supad->{_max};

	} else { 
		print("supad, max, missing max,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$supad->{_min}		= $min;
		$supad->{_note}		= $supad->{_note}.' min='.$supad->{_min};
		$supad->{_Step}		= $supad->{_Step}.' min='.$supad->{_min};

	} else { 
		print("supad, min, missing min,\n");
	 }
 }


=head2 sub val3 


=cut

 sub val3 {

	my ( $self,$val3 )		= @_;
	if ( $val3 ne $empty_string ) {

		$supad->{_val3}		= $val3;
		$supad->{_note}		= $supad->{_note}.' val3='.$supad->{_val3};
		$supad->{_Step}		= $supad->{_Step}.' val3='.$supad->{_val3};

	} else { 
		print("supad, val3, missing val3,\n");
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
