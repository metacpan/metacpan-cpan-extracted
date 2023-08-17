package App::SeismicUnixGui::sunix::filter::suphase;

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
 SUPHASE - PHASE manipulation by linear transformation			



  suphase  <stdin >sdout      						



 Required parameters:							

 none									

 Optional parameters:							

 a=90			constant phase shift              		

 b=180/PI              linear phase shift				

 c=0.0			phase = a +b*(old_phase)+c*f;			



 Notes: 								

 A program that allows the user to experiment with changes in the phase

 spectrum of a signal.							



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

my $suphase			= {
	_a					=> '',
	_b					=> '',
	_c					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suphase->{_Step}     = 'suphase'.$suphase->{_Step};
	return ( $suphase->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suphase->{_note}     = 'suphase'.$suphase->{_note};
	return ( $suphase->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suphase->{_a}			= '';
		$suphase->{_b}			= '';
		$suphase->{_c}			= '';
		$suphase->{_Step}			= '';
		$suphase->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$suphase->{_a}		= $a;
		$suphase->{_note}		= $suphase->{_note}.' a='.$suphase->{_a};
		$suphase->{_Step}		= $suphase->{_Step}.' a='.$suphase->{_a};

	} else { 
		print("suphase, a, missing a,\n");
	 }
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$suphase->{_b}		= $b;
		$suphase->{_note}		= $suphase->{_note}.' b='.$suphase->{_b};
		$suphase->{_Step}		= $suphase->{_Step}.' b='.$suphase->{_b};

	} else { 
		print("suphase, b, missing b,\n");
	 }
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$suphase->{_c}		= $c;
		$suphase->{_note}		= $suphase->{_note}.' c='.$suphase->{_c};
		$suphase->{_Step}		= $suphase->{_Step}.' c='.$suphase->{_c};

	} else { 
		print("suphase, c, missing c,\n");
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
