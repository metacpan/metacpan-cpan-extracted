package App::SeismicUnixGui::sunix::header::sucountkey;

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
 SUCOUNTKEY - COUNT the number of unique values for a given KEYword.	



 sucountkey < input.su key=[sx,gx,cdp,...]				

 Required parameter:							

 key=			array of SU header keywords being counted	

 Optional parameters:							

 verbose=1		chatty, =0 just print keyword number		

 Example:								

	  suplane | sucountkey key=tracl,tracr,offset			







 Credits: Baoniu Han, bhan@mines.edu, Nov, 2000



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

my $sucountkey			= {
	_key					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucountkey->{_Step}     = 'sucountkey'.$sucountkey->{_Step};
	return ( $sucountkey->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucountkey->{_note}     = 'sucountkey'.$sucountkey->{_note};
	return ( $sucountkey->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucountkey->{_key}			= '';
		$sucountkey->{_verbose}			= '';
		$sucountkey->{_Step}			= '';
		$sucountkey->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sucountkey->{_key}		= $key;
		$sucountkey->{_note}		= $sucountkey->{_note}.' key='.$sucountkey->{_key};
		$sucountkey->{_Step}		= $sucountkey->{_Step}.' key='.$sucountkey->{_key};

	} else { 
		print("sucountkey, key, missing key,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sucountkey->{_verbose}		= $verbose;
		$sucountkey->{_note}		= $sucountkey->{_note}.' verbose='.$sucountkey->{_verbose};
		$sucountkey->{_Step}		= $sucountkey->{_Step}.' verbose='.$sucountkey->{_verbose};

	} else { 
		print("sucountkey, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 1;

    return($max_index);
}
 
 
1;
