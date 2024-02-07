package App::SeismicUnixGui::sunix::header::sucliphead;

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
 SUCLIPHEAD - Clip header values					



 sucliphead <stdin >stdout [optional parameters]			



 Required parameters:							

	none								



 Optional parameters:							

	key=cdp,...			header key word(s) to clip	

	min=0,...			minimum value to clip		

	max=ULONG_MAX,ULONG_MAX,...	maximum value to clip		







 Credits:

	Geocon: Garry Perratt





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

my $sucliphead			= {
	_key					=> '',
	_max					=> '',
	_min					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucliphead->{_Step}     = 'sucliphead'.$sucliphead->{_Step};
	return ( $sucliphead->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucliphead->{_note}     = 'sucliphead'.$sucliphead->{_note};
	return ( $sucliphead->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucliphead->{_key}			= '';
		$sucliphead->{_max}			= '';
		$sucliphead->{_min}			= '';
		$sucliphead->{_Step}			= '';
		$sucliphead->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sucliphead->{_key}		= $key;
		$sucliphead->{_note}		= $sucliphead->{_note}.' key='.$sucliphead->{_key};
		$sucliphead->{_Step}		= $sucliphead->{_Step}.' key='.$sucliphead->{_key};

	} else { 
		print("sucliphead, key, missing key,\n");
	 }
 }


=head2 sub max 


=cut

 sub max {

	my ( $self,$max )		= @_;
	if ( $max ne $empty_string ) {

		$sucliphead->{_max}		= $max;
		$sucliphead->{_note}		= $sucliphead->{_note}.' max='.$sucliphead->{_max};
		$sucliphead->{_Step}		= $sucliphead->{_Step}.' max='.$sucliphead->{_max};

	} else { 
		print("sucliphead, max, missing max,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$sucliphead->{_min}		= $min;
		$sucliphead->{_note}		= $sucliphead->{_note}.' min='.$sucliphead->{_min};
		$sucliphead->{_Step}		= $sucliphead->{_Step}.' min='.$sucliphead->{_min};

	} else { 
		print("sucliphead, min, missing min,\n");
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
