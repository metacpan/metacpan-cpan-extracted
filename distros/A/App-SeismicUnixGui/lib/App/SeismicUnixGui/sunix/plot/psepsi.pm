package App::SeismicUnixGui::sunix::plot::psepsi;

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
 PSEPSI - add an EPSI formatted preview bitmap to an EPS file		



 psepsi <epsfile >epsifile		

 

 opt=null				



 Note:									

 This application requires						

 (1) that gs (the Ghostscript interpreter) exist, and			

 (2) that the input EPS file contain a BoundingBox and EndComments.	

 Ghostscript is used to build the preview bitmap, which is then		

 merged with the input EPS file to make the output EPSI file.		



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

use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $psepsi = {
	_opt  => '',
	_Step => '',
	_note => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$psepsi->{_Step} = 'psepsi' . $psepsi->{_Step};
	return ( $psepsi->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$psepsi->{_note} = 'psepsi' . $psepsi->{_note};
	return ( $psepsi->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$psepsi->{_opt}  = '';
	$psepsi->{_Step} = '';
	$psepsi->{_note} = '';
}

=head2 sub opt 


=cut

sub opt {

	my ( $self, $opt ) = @_;
#	if ( $opt ne $empty_string ) {
#
#		$psepsi->{_opt}  = $opt;
#		$psepsi->{_note} = $psepsi->{_note} . ' opt=' . $psepsi->{_opt};
#		$psepsi->{_Step} = $psepsi->{_Step} . ' opt=' . $psepsi->{_opt};
#
#	}
#	else {
#		print("psepsi, opt, missing opt,\n");
#	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 0;

	return ($max_index);
}

1;
