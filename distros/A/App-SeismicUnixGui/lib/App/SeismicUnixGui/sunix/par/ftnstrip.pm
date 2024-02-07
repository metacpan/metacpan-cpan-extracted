package App::SeismicUnixGui::sunix::par::ftnstrip;

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
 FTNSTRIP - convert a file of binary data plus record delimiters created

      via Fortran to a file containing only binary values (as created via C)



 ftnstrip <ftn_data >c_data 	

 

 opt=null



 Required parameter:							

 	none								

 Optional parameters:							

	none 			



 Caveat: this code assumes the conventional Fortran format of header	

         and trailer integer containing the number of byte in the	

         record.  This is overwhelmingly common, but not universal.	





 Credits:

	CWP: Jack K. Cohen



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

my $ftnstrip			= {
	_opt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$ftnstrip->{_Step}     = 'ftnstrip'.$ftnstrip->{_Step};
	return ( $ftnstrip->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$ftnstrip->{_note}     = 'ftnstrip'.$ftnstrip->{_note};
	return ( $ftnstrip->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$ftnstrip->{_opt}			= '';
		$ftnstrip->{_Step}			= '';
		$ftnstrip->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
#	if ( $opt ne $empty_string ) {
#
#		$ftnstrip->{_opt}		= $opt;
#		$ftnstrip->{_note}		= $ftnstrip->{_note}.' opt='.$ftnstrip->{_opt};
#		$ftnstrip->{_Step}		= $ftnstrip->{_Step}.' opt='.$ftnstrip->{_opt};
#
#	} else { 
#		print("ftnstrip, opt, missing opt,\n");
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
