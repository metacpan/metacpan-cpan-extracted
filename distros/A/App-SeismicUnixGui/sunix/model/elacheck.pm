package App::SeismicUnixGui::sunix::model::elacheck;

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
 ELACHECK - get elastic coefficients of model  	   		



 elacheck file= (required modelfile)					



 ____ interactive program _____________                                









 AUTHOR:: Andreas Rueger, Colorado School of Mines, 01/20/94

 get stiffness information for anisotropic model (interactive)





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

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $elacheck			= {
	_file					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$elacheck->{_Step}     = 'elacheck'.$elacheck->{_Step};
	return ( $elacheck->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$elacheck->{_note}     = 'elacheck'.$elacheck->{_note};
	return ( $elacheck->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$elacheck->{_file}			= '';
		$elacheck->{_Step}			= '';
		$elacheck->{_note}			= '';
 }


=head2 sub file 


=cut

 sub file {

	my ( $self,$file )		= @_;
	if ( $file ne $empty_string ) {

		$elacheck->{_file}		= $file;
		$elacheck->{_note}		= $elacheck->{_note}.' file='.$elacheck->{_file};
		$elacheck->{_Step}		= $elacheck->{_Step}.' file='.$elacheck->{_file};

	} else { 
		print("elacheck, file, missing file,\n");
	 }
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
