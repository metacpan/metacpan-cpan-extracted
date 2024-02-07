package App::SeismicUnixGui::sunix::header::susehw;

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
 SUSEHW - Set the value the Header Word denoting trace number within	

	     an Ensemble defined by the value of another header word	



     susehw <stdin >stdout [options]					



 Required Parameters:							

	none								



 Optional Parameters:							

 key1=cdp	Key header word defining the ensemble			

 key2=cdpt	Key header word defining the count within the ensemble	

 a=1		starting value of the count in the ensemble		

 b=1		increment or decrement within the ensemble		



 Notes:								

 This code was written because suresstat requires cdpt to be set.	

 The computation is 							

 	val(key2) = a + b*i						



 The input data must first be sorted into constant key1 gathers.	

 Example: setting the cdpt field					", 

        susetehw < cdpgathers.su a=1 b=1 key1=cdp key2=cdpt > new.su	





 Credits:

  CWP: John Stockwell (Feb 2008) in answer to a question by Warren Franz

        based on various codes, including susplit, susshw, suchw



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

my $susehw			= {
	_a					=> '',
	_b					=> '',
	_key1					=> '',
	_key2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$susehw->{_Step}     = 'susehw'.$susehw->{_Step};
	return ( $susehw->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$susehw->{_note}     = 'susehw'.$susehw->{_note};
	return ( $susehw->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$susehw->{_a}			= '';
		$susehw->{_b}			= '';
		$susehw->{_key1}			= '';
		$susehw->{_key2}			= '';
		$susehw->{_Step}			= '';
		$susehw->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$susehw->{_a}		= $a;
		$susehw->{_note}		= $susehw->{_note}.' a='.$susehw->{_a};
		$susehw->{_Step}		= $susehw->{_Step}.' a='.$susehw->{_a};

	} else { 
		print("susehw, a, missing a,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$susehw->{_b}		= $b;
		$susehw->{_note}		= $susehw->{_note}.' b='.$susehw->{_b};
		$susehw->{_Step}		= $susehw->{_Step}.' b='.$susehw->{_b};

	} else { 
		print("susehw, b, missing b,\n");
	 }
 }


=head2 sub key1 


=cut

 sub key1 {

	my ( $self,$key1 )		= @_;
	if ( $key1 ne $empty_string ) {

		$susehw->{_key1}		= $key1;
		$susehw->{_note}		= $susehw->{_note}.' key1='.$susehw->{_key1};
		$susehw->{_Step}		= $susehw->{_Step}.' key1='.$susehw->{_key1};

	} else { 
		print("susehw, key1, missing key1,\n");
	 }
 }


=head2 sub key2 


=cut

 sub key2 {

	my ( $self,$key2 )		= @_;
	if ( $key2 ne $empty_string ) {

		$susehw->{_key2}		= $key2;
		$susehw->{_note}		= $susehw->{_note}.' key2='.$susehw->{_key2};
		$susehw->{_Step}		= $susehw->{_Step}.' key2='.$susehw->{_key2};

	} else { 
		print("susehw, key2, missing key2,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 3;

    return($max_index);
}
 
 
1;
