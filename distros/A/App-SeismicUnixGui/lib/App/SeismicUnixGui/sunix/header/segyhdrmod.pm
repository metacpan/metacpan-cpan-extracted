package App::SeismicUnixGui::sunix::header::segyhdrmod;

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
 SEGYHDRMOD - replace the text header on a SEGY file		



   segyhdrmod text=file data=file				



   Required parameters:					



   text=      name of file containing new 3200 byte text header

   data=      name of file containing SEGY data set		



 Notes:							

 This program simply does a replacement of the content of the first

 3200 bytes of the SEGY file with the contents of the file specified

 by the text= parameter. If the text header in the SEGY standard

 ebcdic format, the user will need to supply an ebcdic format file

 as the text=  as input file. A text file may be converted from

 ascii to ebcdic via:						

   dd if=ascii_filename of=ebcdic_filename conv=ebcdic ibs=3200 count=1

 or from ebcdic to ascii via:					

   dd if=ebcdic_filename of=ascii_filename ibs=3200 conv=ascii count=1







====================================================================*\



   sgyhdrmod - replace the text header on a SEGY data file in place



   This program only reads and writes 3200 bytes



   Reginald H. Beardsley                            rhb@acm.org



\*====================================================================*/

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

my $segyhdrmod			= {
	_data					=> '',
	_if					=> '',
	_text					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$segyhdrmod->{_Step}     = 'segyhdrmod'.$segyhdrmod->{_Step};
	return ( $segyhdrmod->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segyhdrmod->{_note}     = 'segyhdrmod'.$segyhdrmod->{_note};
	return ( $segyhdrmod->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segyhdrmod->{_data}			= '';
		$segyhdrmod->{_if}			= '';
		$segyhdrmod->{_text}			= '';
		$segyhdrmod->{_Step}			= '';
		$segyhdrmod->{_note}			= '';
 }


=head2 sub data 


=cut

 sub data {

	my ( $self,$data )		= @_;
	if ( $data ne $empty_string ) {

		$segyhdrmod->{_data}		= $data;
		$segyhdrmod->{_note}		= $segyhdrmod->{_note}.' data='.$segyhdrmod->{_data};
		$segyhdrmod->{_Step}		= $segyhdrmod->{_Step}.' data='.$segyhdrmod->{_data};

	} else { 
		print("segyhdrmod, data, missing data,\n");
	 }
 }


=head2 sub if 


=cut

 sub if {

	my ( $self,$if )		= @_;
	if ( $if ne $empty_string ) {

		$segyhdrmod->{_if}		= $if;
		$segyhdrmod->{_note}		= $segyhdrmod->{_note}.' if='.$segyhdrmod->{_if};
		$segyhdrmod->{_Step}		= $segyhdrmod->{_Step}.' if='.$segyhdrmod->{_if};

	} else { 
		print("segyhdrmod, if, missing if,\n");
	 }
 }


=head2 sub text 


=cut

 sub text {

	my ( $self,$text )		= @_;
	if ( $text ne $empty_string ) {

		$segyhdrmod->{_text}		= $text;
		$segyhdrmod->{_note}		= $segyhdrmod->{_note}.' text='.$segyhdrmod->{_text};
		$segyhdrmod->{_Step}		= $segyhdrmod->{_Step}.' text='.$segyhdrmod->{_text};

	} else { 
		print("segyhdrmod, text, missing text,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 1;

    return($max_index);
}
 
 
1;
