package App::SeismicUnixGui::sunix::data::supack1;

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
 SUPACK1 - pack segy trace data into chars			



 supack1 <segy_file >packed_file 	gpow=0.5 		



 Required parameters:						

	none							



 Optional parameter: 						

	gpow=0.5	exponent used to compress the dynamic	

			range of the traces			





 Credits:

	CWP: Jack K. Cohen, Shuki Ronen, Brian Sumner



 Caveats:

	This program is for single site use.  Use segywrite to make

	a portable tape.



	We are storing the local header words, ungpow and unscale,

	required by suunpack1 as floats.  Although not essential

	(compare the handling of such fields as dt), it allows us

	to demonstrate the convenience of using the natural data type.

	In any case, the data itself is non-portable floats in general,

	so we aren't giving up any intrinsic portability.

	

 Notes:

	ungpow and unscale are defined in segy.h

	trid = CHARPACK is defined in su.h and segy.h



 Trace header fields accessed: ns

 Trace header fields modified: ungpow, unscale, trid



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

my $supack1			= {
	_gpow					=> '',
	_trid					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supack1->{_Step}     = 'supack1'.$supack1->{_Step};
	return ( $supack1->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supack1->{_note}     = 'supack1'.$supack1->{_note};
	return ( $supack1->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supack1->{_gpow}			= '';
		$supack1->{_trid}			= '';
		$supack1->{_Step}			= '';
		$supack1->{_note}			= '';
 }


=head2 sub gpow 


=cut

 sub gpow {

	my ( $self,$gpow )		= @_;
	if ( $gpow ne $empty_string ) {

		$supack1->{_gpow}		= $gpow;
		$supack1->{_note}		= $supack1->{_note}.' gpow='.$supack1->{_gpow};
		$supack1->{_Step}		= $supack1->{_Step}.' gpow='.$supack1->{_gpow};

	} else { 
		print("supack1, gpow, missing gpow,\n");
	 }
 }


=head2 sub trid 


=cut

 sub trid {

	my ( $self,$trid )		= @_;
	if ( $trid ne $empty_string ) {

		$supack1->{_trid}		= $trid;
		$supack1->{_note}		= $supack1->{_note}.' trid='.$supack1->{_trid};
		$supack1->{_Step}		= $supack1->{_Step}.' trid='.$supack1->{_trid};

	} else { 
		print("supack1, trid, missing trid,\n");
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
