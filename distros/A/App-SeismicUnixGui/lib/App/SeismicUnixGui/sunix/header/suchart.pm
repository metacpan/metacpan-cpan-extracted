package App::SeismicUnixGui::sunix::header::suchart;

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
 SUCHART - prepare data for x vs. y plot			



 suchart <stdin >stdout key1=sx key2=gx			



 Required parameters:						

 	none							



 Optional parameters:						

 	key1=sx  	abscissa 				

 	key2=gx		ordinate				

	outpar=null	name of parameter file			



 The output is the (x, y) pairs of binary floats		



 Examples:							

 suchart < sudata outpar=pfile >plot_data			

 psgraph <plot_data par=pfile title="CMG" \\			

	linewidth=0 marksize=2 mark=8 | ...			

 rm plot_data 							



 suchart < sudata | psgraph n=1024 d1=.004 \\			

	linewidth=0 marksize=2 mark=8 | ...			



 fold chart: 							

 suchart < stacked_data key1=cdp key2=nhs |			

            psgraph n=NUMBER_OF_TRACES d1=.004 \\		

	linewidth=0 marksize=2 mark=8 > chart.ps		







 Credits:

	SEP: Einar Kjartansson

	CWP: Jack K. Cohen



 Notes:

	The vtof routine from valpkge converts values to floats.



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

my $suchart			= {
	_key1					=> '',
	_key2					=> '',
	_linewidth					=> '',
	_n					=> '',
	_outpar					=> '',
	_par					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suchart->{_Step}     = 'suchart'.$suchart->{_Step};
	return ( $suchart->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suchart->{_note}     = 'suchart'.$suchart->{_note};
	return ( $suchart->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suchart->{_key1}			= '';
		$suchart->{_key2}			= '';
		$suchart->{_linewidth}			= '';
		$suchart->{_n}			= '';
		$suchart->{_outpar}			= '';
		$suchart->{_par}			= '';
		$suchart->{_Step}			= '';
		$suchart->{_note}			= '';
 }


=head2 sub key1 


=cut

 sub key1 {

	my ( $self,$key1 )		= @_;
	if ( $key1 ne $empty_string ) {

		$suchart->{_key1}		= $key1;
		$suchart->{_note}		= $suchart->{_note}.' key1='.$suchart->{_key1};
		$suchart->{_Step}		= $suchart->{_Step}.' key1='.$suchart->{_key1};

	} else { 
		print("suchart, key1, missing key1,\n");
	 }
 }


=head2 sub key2 


=cut

 sub key2 {

	my ( $self,$key2 )		= @_;
	if ( $key2 ne $empty_string ) {

		$suchart->{_key2}		= $key2;
		$suchart->{_note}		= $suchart->{_note}.' key2='.$suchart->{_key2};
		$suchart->{_Step}		= $suchart->{_Step}.' key2='.$suchart->{_key2};

	} else { 
		print("suchart, key2, missing key2,\n");
	 }
 }


=head2 sub linewidth 


=cut

 sub linewidth {

	my ( $self,$linewidth )		= @_;
	if ( $linewidth ne $empty_string ) {

		$suchart->{_linewidth}		= $linewidth;
		$suchart->{_note}		= $suchart->{_note}.' linewidth='.$suchart->{_linewidth};
		$suchart->{_Step}		= $suchart->{_Step}.' linewidth='.$suchart->{_linewidth};

	} else { 
		print("suchart, linewidth, missing linewidth,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$suchart->{_n}		= $n;
		$suchart->{_note}		= $suchart->{_note}.' n='.$suchart->{_n};
		$suchart->{_Step}		= $suchart->{_Step}.' n='.$suchart->{_n};

	} else { 
		print("suchart, n, missing n,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$suchart->{_outpar}		= $outpar;
		$suchart->{_note}		= $suchart->{_note}.' outpar='.$suchart->{_outpar};
		$suchart->{_Step}		= $suchart->{_Step}.' outpar='.$suchart->{_outpar};

	} else { 
		print("suchart, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$suchart->{_par}		= $par;
		$suchart->{_note}		= $suchart->{_note}.' par='.$suchart->{_par};
		$suchart->{_Step}		= $suchart->{_Step}.' par='.$suchart->{_par};

	} else { 
		print("suchart, par, missing par,\n");
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
