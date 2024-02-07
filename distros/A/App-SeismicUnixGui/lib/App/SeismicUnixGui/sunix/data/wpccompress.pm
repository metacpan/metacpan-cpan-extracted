package App::SeismicUnixGui::sunix::data::wpccompress;

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
 WPCCOMPRESS --- COMPRESS a 2D section using Wavelet Packets		



 wpccompress < stdin n1= n2= [optional parameters ] > stdout          	



 Required Parameters:                                                  

 n1=                    number of samples in the 1st dimension		

 n2=                    number of samples in the 2nd dimenstion	



 Optional Parameters:                                                  

 error=0.01              relative RMS allowed in compress		", 



 Notes:                                                                

  This program is used to compress a 2D section. It compresses in both	

  directions, vertically and horizontally.				



  The parameter error is used control the allowable compression error,	

  and thus the compression ratio. The larger the error, the more 	

  the more compression you can get. The amount of error depends on 	

  the type of data and the application of the compression. From my 	

  experience, error=0.01 is a safe choice even when the compressed data 	

  are used for further processing. For some other applications, it 	

  may be set higher to achieve larger compression.			



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

my $wpccompress			= {
	_error					=> '',
	_n1					=> '',
	_n2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$wpccompress->{_Step}     = 'wpccompress'.$wpccompress->{_Step};
	return ( $wpccompress->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$wpccompress->{_note}     = 'wpccompress'.$wpccompress->{_note};
	return ( $wpccompress->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$wpccompress->{_error}			= '';
		$wpccompress->{_n1}			= '';
		$wpccompress->{_n2}			= '';
		$wpccompress->{_Step}			= '';
		$wpccompress->{_note}			= '';
 }


=head2 sub error 


=cut

 sub error {

	my ( $self,$error )		= @_;
	if ( $error ne $empty_string ) {

		$wpccompress->{_error}		= $error;
		$wpccompress->{_note}		= $wpccompress->{_note}.' error='.$wpccompress->{_error};
		$wpccompress->{_Step}		= $wpccompress->{_Step}.' error='.$wpccompress->{_error};

	} else { 
		print("wpccompress, error, missing error,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$wpccompress->{_n1}		= $n1;
		$wpccompress->{_note}		= $wpccompress->{_note}.' n1='.$wpccompress->{_n1};
		$wpccompress->{_Step}		= $wpccompress->{_Step}.' n1='.$wpccompress->{_n1};

	} else { 
		print("wpccompress, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$wpccompress->{_n2}		= $n2;
		$wpccompress->{_note}		= $wpccompress->{_note}.' n2='.$wpccompress->{_n2};
		$wpccompress->{_Step}		= $wpccompress->{_Step}.' n2='.$wpccompress->{_n2};

	} else { 
		print("wpccompress, n2, missing n2,\n");
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
