package App::SeismicUnixGui::sunix::par::float2ibm;

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
 FLOAT2IBM - convert native binary FLOATS to IBM tape FLOATS	



 float2ibm <stdin >stdout 					



 Required parameters:						

 	none							



 Optional parameters:						

 endian=	byte order of your system (autodetected)	

 outpar=/dev/tty output parameter file, contains the		

			number of values (n=)			

		       other choices for outpar are: /dev/tty, 

		       /dev/stderr, or a name of a disk file   



 Notes:							

 endian=1 (big endian) endian=0 (little endian) byte order 	

 You probably will not have to set this, as the byte order of  

 your system is autodetected by the program. 			

 This program is usable for writing SEG Y traces with the headers

 stripped off.							



 Credits:

	CWP: John Stockwell, based on code by Jack K. Cohen



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

my $float2ibm			= {
	_endian					=> '',
	_n					=> '',
	_outpar					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$float2ibm->{_Step}     = 'float2ibm'.$float2ibm->{_Step};
	return ( $float2ibm->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$float2ibm->{_note}     = 'float2ibm'.$float2ibm->{_note};
	return ( $float2ibm->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$float2ibm->{_endian}			= '';
		$float2ibm->{_n}			= '';
		$float2ibm->{_outpar}			= '';
		$float2ibm->{_Step}			= '';
		$float2ibm->{_note}			= '';
 }


=head2 sub endian 


=cut

 sub endian {

	my ( $self,$endian )		= @_;
	if ( $endian ne $empty_string ) {

		$float2ibm->{_endian}		= $endian;
		$float2ibm->{_note}		= $float2ibm->{_note}.' endian='.$float2ibm->{_endian};
		$float2ibm->{_Step}		= $float2ibm->{_Step}.' endian='.$float2ibm->{_endian};

	} else { 
		print("float2ibm, endian, missing endian,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$float2ibm->{_n}		= $n;
		$float2ibm->{_note}		= $float2ibm->{_note}.' n='.$float2ibm->{_n};
		$float2ibm->{_Step}		= $float2ibm->{_Step}.' n='.$float2ibm->{_n};

	} else { 
		print("float2ibm, n, missing n,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$float2ibm->{_outpar}		= $outpar;
		$float2ibm->{_note}		= $float2ibm->{_note}.' outpar='.$float2ibm->{_outpar};
		$float2ibm->{_Step}		= $float2ibm->{_Step}.' outpar='.$float2ibm->{_outpar};

	} else { 
		print("float2ibm, outpar, missing outpar,\n");
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
