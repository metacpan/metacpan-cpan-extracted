package App::SeismicUnixGui::sunix::data::wpc1uncomp2;

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
 WPC1UNCOMP2 --- UNCOMPRESS a 2D seismic section, which has been	

  			compressed using Wavelet Packets		



 wpc1uncomp2 < stdin > stdout               				



 Required Parameters:                                                  

 none                                                                  



 Optional Parameters:                                                  

 opt=null                                                             



 Notes:                                                                

  No parameter is required for this program. All the information for	

  uncompression has been encoded in the header of the compressed data.	



 Caveats:								

  For the current implementation, the compressed data themselves are	

  NOT portable, i.e., the data compressed on one platform might not be	

  recognizable on another.						



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

my $wpc1uncomp2			= {
	_opt					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$wpc1uncomp2->{_Step}     = 'wpc1uncomp2'.$wpc1uncomp2->{_Step};
	return ( $wpc1uncomp2->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$wpc1uncomp2->{_note}     = 'wpc1uncomp2'.$wpc1uncomp2->{_note};
	return ( $wpc1uncomp2->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$wpc1uncomp2->{_opt}			= '';
		$wpc1uncomp2->{_Step}			= '';
		$wpc1uncomp2->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
#	if ( $opt ne $empty_string ) {
#
#		$wpc1uncomp2->{_opt}		= $opt;
#		$wpc1uncomp2->{_note}		= $wpc1uncomp2->{_note}.' opt='.$wpc1uncomp2->{_opt};
#		$wpc1uncomp2->{_Step}		= $wpc1uncomp2->{_Step}.' opt='.$wpc1uncomp2->{_opt};
#
#	} else { 
#		print("wpc1uncomp2, opt, missing opt,\n");
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
