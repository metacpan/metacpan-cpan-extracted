package App::SeismicUnixGui::sunix::par::bhedtopar;

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
 BHEDTOPAR - convert a Binary tape HEaDer file to PAR file format	



     bhedtopar < stdin outpar=parfile					



 Required parameter:							

 	none								

 Optional parameters:							

	swap=0 			=1 to swap bytes			

 	outpar=/dev/tty		=parfile  name of output param file	



 Notes: 								

 This program dumps the contents of a SEGY binary tape header file, as 

 would be produced by segyread and segyhdrs to a file in "parfile" format.

 A "parfile" is an ASCII file containing entries of the form param=value.

 Here "param" is the keyword for the binary tape header field and	

 "value" is the value of that field. The parfile may be edited as	

 any ASCII file. The edited parfile may then be made into a new binary tape 

 header file via the program    setbhed.				



 See    sudoc  setbhed   for examples					





 Credits:



	CWP: John Stockwell  11 Nov 1994



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

my $bhedtopar			= {
	_outpar					=> '',
	_param					=> '',
	_swap					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$bhedtopar->{_Step}     = 'bhedtopar'.$bhedtopar->{_Step};
	return ( $bhedtopar->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$bhedtopar->{_note}     = 'bhedtopar'.$bhedtopar->{_note};
	return ( $bhedtopar->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$bhedtopar->{_outpar}			= '';
		$bhedtopar->{_param}			= '';
		$bhedtopar->{_swap}			= '';
		$bhedtopar->{_Step}			= '';
		$bhedtopar->{_note}			= '';
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$bhedtopar->{_outpar}		= $outpar;
		$bhedtopar->{_note}		= $bhedtopar->{_note}.' outpar='.$bhedtopar->{_outpar};
		$bhedtopar->{_Step}		= $bhedtopar->{_Step}.' outpar='.$bhedtopar->{_outpar};

	} else { 
		print("bhedtopar, outpar, missing outpar,\n");
	 }
 }


=head2 sub param 


=cut

 sub param {

	my ( $self,$param )		= @_;
	if ( $param ne $empty_string ) {

		$bhedtopar->{_param}		= $param;
		$bhedtopar->{_note}		= $bhedtopar->{_note}.' param='.$bhedtopar->{_param};
		$bhedtopar->{_Step}		= $bhedtopar->{_Step}.' param='.$bhedtopar->{_param};

	} else { 
		print("bhedtopar, param, missing param,\n");
	 }
 }


=head2 sub swap 


=cut

 sub swap {

	my ( $self,$swap )		= @_;
	if ( $swap ne $empty_string ) {

		$bhedtopar->{_swap}		= $swap;
		$bhedtopar->{_note}		= $bhedtopar->{_note}.' swap='.$bhedtopar->{_swap};
		$bhedtopar->{_Step}		= $bhedtopar->{_Step}.' swap='.$bhedtopar->{_swap};

	} else { 
		print("bhedtopar, swap, missing swap,\n");
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
