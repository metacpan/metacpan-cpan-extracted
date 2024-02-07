package App::SeismicUnixGui::sunix::par::cshotplot;

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
 CSHOTPLOT - convert CSHOT data to files for CWP graphers		



 cshotplot <cshot1plot [optional parameter file]			



 Required parameters:							

 	none 								



 Optional parameter:							

 	outpar=/dev/tty		output parameter file, contains:	

					number of plots (n2=)		

					points in each plot (n1=)	

					colors for plots (linecolor=)	



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

my $cshotplot			= {
	_linecolor					=> '',
	_n1					=> '',
	_n2					=> '',
	_outpar					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$cshotplot->{_Step}     = 'cshotplot'.$cshotplot->{_Step};
	return ( $cshotplot->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$cshotplot->{_note}     = 'cshotplot'.$cshotplot->{_note};
	return ( $cshotplot->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$cshotplot->{_linecolor}			= '';
		$cshotplot->{_n1}			= '';
		$cshotplot->{_n2}			= '';
		$cshotplot->{_outpar}			= '';
		$cshotplot->{_Step}			= '';
		$cshotplot->{_note}			= '';
 }


=head2 sub linecolor 


=cut

 sub linecolor {

	my ( $self,$linecolor )		= @_;
	if ( $linecolor ne $empty_string ) {

		$cshotplot->{_linecolor}		= $linecolor;
		$cshotplot->{_note}		= $cshotplot->{_note}.' linecolor='.$cshotplot->{_linecolor};
		$cshotplot->{_Step}		= $cshotplot->{_Step}.' linecolor='.$cshotplot->{_linecolor};

	} else { 
		print("cshotplot, linecolor, missing linecolor,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$cshotplot->{_n1}		= $n1;
		$cshotplot->{_note}		= $cshotplot->{_note}.' n1='.$cshotplot->{_n1};
		$cshotplot->{_Step}		= $cshotplot->{_Step}.' n1='.$cshotplot->{_n1};

	} else { 
		print("cshotplot, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$cshotplot->{_n2}		= $n2;
		$cshotplot->{_note}		= $cshotplot->{_note}.' n2='.$cshotplot->{_n2};
		$cshotplot->{_Step}		= $cshotplot->{_Step}.' n2='.$cshotplot->{_n2};

	} else { 
		print("cshotplot, n2, missing n2,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$cshotplot->{_outpar}		= $outpar;
		$cshotplot->{_note}		= $cshotplot->{_note}.' outpar='.$cshotplot->{_outpar};
		$cshotplot->{_Step}		= $cshotplot->{_Step}.' outpar='.$cshotplot->{_outpar};

	} else { 
		print("cshotplot, outpar, missing outpar,\n");
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
