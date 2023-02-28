package App::SeismicUnixGui::sunix::header::swapbhed;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SWAPBHED - SWAP the BYTES in a SEGY Binary tape HEaDer file		

opt=null

 swapbhed < binary_in > binary out					







 Required parameter:							

 	none								

 Optional parameters:							

	none 								





 Credits:



	CWP: John Stockwell  13 May 2011



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

my $swapbhed			= {
	_opt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$swapbhed->{_Step}     = 'swapbhed'.$swapbhed->{_Step};
	return ( $swapbhed->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$swapbhed->{_note}     = 'swapbhed'.$swapbhed->{_note};
	return ( $swapbhed->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$swapbhed->{_opt}			= '';
		$swapbhed->{_Step}			= '';
		$swapbhed->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
#	if ( $opt ne $empty_string ) {
#
#		$swapbhed->{_opt}		= $opt;
#		$swapbhed->{_note}		= $swapbhed->{_note}.' opt='.$swapbhed->{_opt};
#		$swapbhed->{_Step}		= $swapbhed->{_Step}.' opt='.$swapbhed->{_opt};
#
#	} else { 
#		print("swapbhed, opt, missing opt,\n");
#	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 0;

    return($max_index);
}
 
 
1;
