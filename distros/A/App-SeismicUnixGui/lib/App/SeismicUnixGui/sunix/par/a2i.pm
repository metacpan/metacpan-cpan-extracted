package App::SeismicUnixGui::sunix::par::a2i;

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
 A2I - convert Ascii to binary Integers			



 a2i <stdin >stdout outpar=/dev/tty 				



 Required parameters:						

 	none							



 Optional parameters:						

 	n1=2		integers per line in input file		



 	outpar=/dev/tty	output parameter file, contains the	

			number of lines (n=)			



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

my $a2i			= {
	_n					=> '',
	_n1					=> '',
	_outpar					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$a2i->{_Step}     = 'a2i'.$a2i->{_Step};
	return ( $a2i->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$a2i->{_note}     = 'a2i'.$a2i->{_note};
	return ( $a2i->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$a2i->{_n}			= '';
		$a2i->{_n1}			= '';
		$a2i->{_outpar}			= '';
		$a2i->{_Step}			= '';
		$a2i->{_note}			= '';
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$a2i->{_n}		= $n;
		$a2i->{_note}		= $a2i->{_note}.' n='.$a2i->{_n};
		$a2i->{_Step}		= $a2i->{_Step}.' n='.$a2i->{_n};

	} else { 
		print("a2i, n, missing n,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$a2i->{_n1}		= $n1;
		$a2i->{_note}		= $a2i->{_note}.' n1='.$a2i->{_n1};
		$a2i->{_Step}		= $a2i->{_Step}.' n1='.$a2i->{_n1};

	} else { 
		print("a2i, n1, missing n1,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$a2i->{_outpar}		= $outpar;
		$a2i->{_note}		= $a2i->{_note}.' outpar='.$a2i->{_outpar};
		$a2i->{_Step}		= $a2i->{_Step}.' outpar='.$a2i->{_outpar};

	} else { 
		print("a2i, outpar, missing outpar,\n");
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
