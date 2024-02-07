package App::SeismicUnixGui::sunix::data::suswapbytes;

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
 SUSWAPBYTES - SWAP the BYTES in SU data to convert data from big endian

               to little endian byte order, and vice versa		



 suswapbytes < stdin [optional parameter] > sdtout			



 	format=0		foreign to native			

 				=1 native to foreign			

	swaphdr=1		swap the header byte order		

 				=0 do not change the header byte order	

	swapdata=1		swap the data byte order		

 				=0 do not change the data byte order	

 	ns=from header		if ns not set in header, must be set by hand

 Notes:								

  The 'native'	endian is the endian (byte order) of the machine you are

  running this program on. The 'foreign' endian is the opposite byte order.



 Examples of big endian machines are: IBM RS6000, SUN, NeXT		

 Examples of little endian machines are: PCs, DEC			



 Caveat: this code has not been tested on DEC				





 Credits: 

	CWP: adapted for SU by John Stockwell 

		based on a code supplied by:

	Institute fur Geophysik, Hamburg: Jens Hartmann (June 1993)



 Trace header fields accessed: ns



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

my $suswapbytes			= {
	_format					=> '',
	_ns					=> '',
	_swapdata					=> '',
	_swaphdr					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suswapbytes->{_Step}     = 'suswapbytes'.$suswapbytes->{_Step};
	return ( $suswapbytes->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suswapbytes->{_note}     = 'suswapbytes'.$suswapbytes->{_note};
	return ( $suswapbytes->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suswapbytes->{_format}			= '';
		$suswapbytes->{_ns}			= '';
		$suswapbytes->{_swapdata}			= '';
		$suswapbytes->{_swaphdr}			= '';
		$suswapbytes->{_Step}			= '';
		$suswapbytes->{_note}			= '';
 }


=head2 sub format 


=cut

 sub format {

	my ( $self,$format )		= @_;
	if ( $format ne $empty_string ) {

		$suswapbytes->{_format}		= $format;
		$suswapbytes->{_note}		= $suswapbytes->{_note}.' format='.$suswapbytes->{_format};
		$suswapbytes->{_Step}		= $suswapbytes->{_Step}.' format='.$suswapbytes->{_format};

	} else { 
		print("suswapbytes, format, missing format,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$suswapbytes->{_ns}		= $ns;
		$suswapbytes->{_note}		= $suswapbytes->{_note}.' ns='.$suswapbytes->{_ns};
		$suswapbytes->{_Step}		= $suswapbytes->{_Step}.' ns='.$suswapbytes->{_ns};

	} else { 
		print("suswapbytes, ns, missing ns,\n");
	 }
 }


=head2 sub swapdata 


=cut

 sub swapdata {

	my ( $self,$swapdata )		= @_;
	if ( $swapdata ne $empty_string ) {

		$suswapbytes->{_swapdata}		= $swapdata;
		$suswapbytes->{_note}		= $suswapbytes->{_note}.' swapdata='.$suswapbytes->{_swapdata};
		$suswapbytes->{_Step}		= $suswapbytes->{_Step}.' swapdata='.$suswapbytes->{_swapdata};

	} else { 
		print("suswapbytes, swapdata, missing swapdata,\n");
	 }
 }


=head2 sub swaphdr 


=cut

 sub swaphdr {

	my ( $self,$swaphdr )		= @_;
	if ( $swaphdr ne $empty_string ) {

		$suswapbytes->{_swaphdr}		= $swaphdr;
		$suswapbytes->{_note}		= $suswapbytes->{_note}.' swaphdr='.$suswapbytes->{_swaphdr};
		$suswapbytes->{_Step}		= $suswapbytes->{_Step}.' swaphdr='.$suswapbytes->{_swaphdr};

	} else { 
		print("suswapbytes, swaphdr, missing swaphdr,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 3;

    return($max_index);
}
 
 
1;
