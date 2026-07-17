package App::SeismicUnixGui::sunix::transform::suhilb;

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
 SUHILB - Hilbert transform					



 suhilb <stdin >sdout 						



 Note: the transform is computed in the direct (time) domain   



 Optional parameters: none



 Required parameters: none



                   opt=null



 Credits:

	CWP: Jack Cohen   

      CWP: John Stockwell, modified to use Dave Hale's hilbert() subroutine



 Trace header fields accessed: ns, trid



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

my $suhilb			= {
	_opt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suhilb->{_Step}     = 'suhilb'.$suhilb->{_Step};
	return ( $suhilb->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suhilb->{_note}     = 'suhilb'.$suhilb->{_note};
	return ( $suhilb->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suhilb->{_opt}			= '';
		$suhilb->{_Step}			= '';
		$suhilb->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
	if ( $opt ne $empty_string ) {

		$suhilb->{_opt}		= $opt;
		$suhilb->{_note}		= $suhilb->{_note}.' opt='.$suhilb->{_opt};
		$suhilb->{_Step}		= $suhilb->{_Step}.' opt='.$suhilb->{_opt};

	} else { 
		print("suhilb, opt, missing opt,\n");
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
