package App::SeismicUnixGui::sunix::header::sulhead;

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
SULHEAD - Load information from an ascii column file into HEADERS based

	   on the value of the user specified header field		

  sulhead < inflie > outfile cf=Column_file key=..  [ optional parameters]



 Required parameters:							

 cf=Name of column file						

 key=key1,key2,...Number of column entires				

 Optional parameters:							

 mc=1		Column number to use to match rows to traces		



Notes:									

 Caveat: This is not simple trace header setting, but conditional	

 setting.								



 This utility reads the column file and loads the values into the	

 specified header locations. Each column represents one set of header  

 words, one of them (#mc) is used to match the rows to the traces	

 using header tr.key[mc].						



 Example:								

 key=cdp,ep,sx   mc=1	cf=file						

 file contains:							

	1  2  3								

	2  3  4								



 if tr.cdp equals 1 then tr.ep and tr.sx will be set to 2 and 3		

 if tr.cdp equals 2 then tr.ep and tr.sx will be set to 3 and 4		

 if tr.cdp equals other than tr.trid equals 3					



 Caveat: the user has to make it sure that number of entires in key=	

	 is equal the number of columns stored in the file.		



 For simple mass setting of header words, see selfdoc of:  sushw	







 Credits: Balasz Nemeth, Potash Corporation, Saskatoon Saskatchewan

 Given to CWP in 2008 





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

my $sulhead			= {
	_cf					=> '',
	_key					=> '',
	_mc					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sulhead->{_Step}     = 'sulhead'.$sulhead->{_Step};
	return ( $sulhead->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sulhead->{_note}     = 'sulhead'.$sulhead->{_note};
	return ( $sulhead->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sulhead->{_cf}			= '';
		$sulhead->{_key}			= '';
		$sulhead->{_mc}			= '';
		$sulhead->{_Step}			= '';
		$sulhead->{_note}			= '';
 }


=head2 sub cf 


=cut

 sub cf {

	my ( $self,$cf )		= @_;
	if ( $cf ne $empty_string ) {

		$sulhead->{_cf}		= $cf;
		$sulhead->{_note}		= $sulhead->{_note}.' cf='.$sulhead->{_cf};
		$sulhead->{_Step}		= $sulhead->{_Step}.' cf='.$sulhead->{_cf};

	} else { 
		print("sulhead, cf, missing cf,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sulhead->{_key}		= $key;
		$sulhead->{_note}		= $sulhead->{_note}.' key='.$sulhead->{_key};
		$sulhead->{_Step}		= $sulhead->{_Step}.' key='.$sulhead->{_key};

	} else { 
		print("sulhead, key, missing key,\n");
	 }
 }


=head2 sub mc 


=cut

 sub mc {

	my ( $self,$mc )		= @_;
	if ( $mc ne $empty_string ) {

		$sulhead->{_mc}		= $mc;
		$sulhead->{_note}		= $sulhead->{_note}.' mc='.$sulhead->{_mc};
		$sulhead->{_Step}		= $sulhead->{_Step}.' mc='.$sulhead->{_mc};

	} else { 
		print("sulhead, mc, missing mc,\n");
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
