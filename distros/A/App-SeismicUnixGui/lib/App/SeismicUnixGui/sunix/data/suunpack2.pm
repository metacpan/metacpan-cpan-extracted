package App::SeismicUnixGui::sunix::data::suunpack2;

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
 SUUNPACK2 - unpack segy trace data from shorts to floats	



    suunpack2 <packed_file >unpacked_file			



 suunpack2 is the approximate inverse of supack2	

 

 opt=null	





 Credits:

	CWP: Jack K. Cohen, Shuki Ronen, Brian Sumner



 Revised:  7/4/95 Stewart A. Levin  Mobil

          Changed decoding to parallel 2 byte encoding of supack2



 Caveats:

	This program is for single site use with supack2.  See the

	supack2 header comments.



 Notes:

	ungpow and unscale are defined in segy.h

	trid = SHORTPACK is defined in su.h and segy.h



 Trace header fields accessed: ns, trid, ungpow, unscale

 Trace header fields modified:     trid, ungpow, unscale



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

my $suunpack2			= {
	_opt					=> '',
	_trid					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suunpack2->{_Step}     = 'suunpack2'.$suunpack2->{_Step};
	return ( $suunpack2->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suunpack2->{_note}     = 'suunpack2'.$suunpack2->{_note};
	return ( $suunpack2->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suunpack2->{_opt}			= '';
		$suunpack2->{_trid}			= '';
		$suunpack2->{_Step}			= '';
		$suunpack2->{_note}			= '';
 }


=head2 sub opt 


=cut

 sub opt {

	my ( $self,$opt )		= @_;
	if ( $opt ne $empty_string ) {

		$suunpack2->{_opt}		= $opt;
		$suunpack2->{_note}		= $suunpack2->{_note}.' opt='.$suunpack2->{_opt};
		$suunpack2->{_Step}		= $suunpack2->{_Step}.' opt='.$suunpack2->{_opt};

	} else { 
		print("suunpack2, opt, missing opt,\n");
	 }
 }


=head2 sub trid 


=cut

 sub trid {

	my ( $self,$trid )		= @_;
	if ( $trid ne $empty_string ) {

		$suunpack2->{_trid}		= $trid;
		$suunpack2->{_note}		= $suunpack2->{_note}.' trid='.$suunpack2->{_trid};
		$suunpack2->{_Step}		= $suunpack2->{_Step}.' trid='.$suunpack2->{_trid};

	} else { 
		print("suunpack2, trid, missing trid,\n");
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
