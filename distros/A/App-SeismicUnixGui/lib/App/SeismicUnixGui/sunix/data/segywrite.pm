package App::SeismicUnixGui::sunix::data::segywrite;

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
 SEGYWRITE - write an SEG-Y tape					



 segywrite <stdin tape=						



 Required parameters:							

	tape=		tape device to use (see sudoc segyread)		



 Optional parameter:							

 verbose=0	silent operation				

		=1 ; echo every 'vblock' traces			

 vblock=50	echo every 'vblock' traces under verbose option 

 buff=1		for buffered device (9-track reel tape drive)	

		=0 possibly useful for 8mm EXABYTE drive	

 conv=1		=0 don't convert to IBM format			

 ebcdic=1	convert text header to ebcdic, =0 leave as ascii	

 hfile=header	ebcdic card image header file			

 bfile=binary	binary header file				

 trmin=1 first trace to write					

 trmax=INT_MAX  last trace to write			       

 endian=(autodetected)	=1 for big-endian and =0 for little-endian byte order

 errmax=0	allowable number of consecutive tape IO errors	

 format=		override value of format in binary header file	



 Note: The header files may be created with  'segyhdrs'.		





 Note: For buff=1 (default) tape is accessed with 'write', for buff=0	

	tape is accessed with fwrite. Try the default setting of buff=1 

	for all tape types.						

 Caveat: may be slow on an 8mm streaming (EXABYTE) tapedrive		

 Warning: segyread or segywrite to 8mm tape is fragile. Allow time	

	   between successive reads and writes.				

 Precaution: make sure tapedrive is set to read/write variable blocksize

	   tapefiles.							



 For more information, type:	sudoc <segywrite>			







 Warning: may return the error message "efclose: fclose failed"

	 intermittently when segyreading/segywriting to 8mm EXABYTE tape,

	 even if actual segyread/segywrite is successful. However, this

	 may indicate that your tape drive has been set to a fixed block

	 size. Tape drives should be set to variable block size before reading

	 or writing tapes in the SEG-Y format.



 Credits:

	SEP: Einar Kjartansson

	CWP: Jack, Brian, Chris

	   : John Stockwell (added EXABYTE functionality)

 Notes:

	Brian's subroutine, float_to_ibm, for converting IEEE floating

	point to IBM floating point is NOT portable and must be

	altered for non-IEEE machines.	See the subroutine notes below.



	On machines where shorts are not 2 bytes and/or ints are not 

	4 bytes, routines to convert SEGY 16 bit and 32 bit integers 

	will be required.



	The program, segyhdrs, can be used to make the ascii and binary

	files required by this code.





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

my $segywrite			= {
	_bfile					=> '',
	_buff					=> '',
	_conv					=> '',
	_ebcdic					=> '',
	_endian					=> '',
	_errmax					=> '',
	_format					=> '',
	_hfile					=> '',
	_tape					=> '',
	_trmax					=> '',
	_trmin					=> '',
	_vblock					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$segywrite->{_Step}     = 'segywrite'.$segywrite->{_Step};
	return ( $segywrite->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segywrite->{_note}     = 'segywrite'.$segywrite->{_note};
	return ( $segywrite->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segywrite->{_bfile}			= '';
		$segywrite->{_buff}			= '';
		$segywrite->{_conv}			= '';
		$segywrite->{_ebcdic}			= '';
		$segywrite->{_endian}			= '';
		$segywrite->{_errmax}			= '';
		$segywrite->{_format}			= '';
		$segywrite->{_hfile}			= '';
		$segywrite->{_tape}			= '';
		$segywrite->{_trmax}			= '';
		$segywrite->{_trmin}			= '';
		$segywrite->{_vblock}			= '';
		$segywrite->{_verbose}			= '';
		$segywrite->{_Step}			= '';
		$segywrite->{_note}			= '';
 }


=head2 sub bfile 


=cut

 sub bfile {

	my ( $self,$bfile )		= @_;
	if ( $bfile ne $empty_string ) {

		$segywrite->{_bfile}		= $bfile;
		$segywrite->{_note}		= $segywrite->{_note}.' bfile='.$segywrite->{_bfile};
		$segywrite->{_Step}		= $segywrite->{_Step}.' bfile='.$segywrite->{_bfile};

	} else { 
		print("segywrite, bfile, missing bfile,\n");
	 }
 }


=head2 sub buff 


=cut

 sub buff {

	my ( $self,$buff )		= @_;
	if ( $buff ne $empty_string ) {

		$segywrite->{_buff}		= $buff;
		$segywrite->{_note}		= $segywrite->{_note}.' buff='.$segywrite->{_buff};
		$segywrite->{_Step}		= $segywrite->{_Step}.' buff='.$segywrite->{_buff};

	} else { 
		print("segywrite, buff, missing buff,\n");
	 }
 }


=head2 sub conv 


=cut

 sub conv {

	my ( $self,$conv )		= @_;
	if ( $conv ne $empty_string ) {

		$segywrite->{_conv}		= $conv;
		$segywrite->{_note}		= $segywrite->{_note}.' conv='.$segywrite->{_conv};
		$segywrite->{_Step}		= $segywrite->{_Step}.' conv='.$segywrite->{_conv};

	} else { 
		print("segywrite, conv, missing conv,\n");
	 }
 }


=head2 sub ebcdic 


=cut

 sub ebcdic {

	my ( $self,$ebcdic )		= @_;
	if ( $ebcdic ne $empty_string ) {

		$segywrite->{_ebcdic}		= $ebcdic;
		$segywrite->{_note}		= $segywrite->{_note}.' ebcdic='.$segywrite->{_ebcdic};
		$segywrite->{_Step}		= $segywrite->{_Step}.' ebcdic='.$segywrite->{_ebcdic};

	} else { 
		print("segywrite, ebcdic, missing ebcdic,\n");
	 }
 }


=head2 sub endian 


=cut

 sub endian {

	my ( $self,$endian )		= @_;
	if ( $endian ne $empty_string ) {

		$segywrite->{_endian}		= $endian;
		$segywrite->{_note}		= $segywrite->{_note}.' endian='.$segywrite->{_endian};
		$segywrite->{_Step}		= $segywrite->{_Step}.' endian='.$segywrite->{_endian};

	} else { 
		print("segywrite, endian, missing endian,\n");
	 }
 }


=head2 sub errmax 


=cut

 sub errmax {

	my ( $self,$errmax )		= @_;
	if ( $errmax ne $empty_string ) {

		$segywrite->{_errmax}		= $errmax;
		$segywrite->{_note}		= $segywrite->{_note}.' errmax='.$segywrite->{_errmax};
		$segywrite->{_Step}		= $segywrite->{_Step}.' errmax='.$segywrite->{_errmax};

	} else { 
		print("segywrite, errmax, missing errmax,\n");
	 }
 }
 
=head2 sub file 


=cut

 sub file {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

		$segywrite->{_tape}		= $tape;
		$segywrite->{_note}		= $segywrite->{_note}.' tape='.$segywrite->{_tape};
		$segywrite->{_Step}		= $segywrite->{_Step}.' tape='.$segywrite->{_tape};

	} else { 
		print("segywrite, file, missing file,\n");
	 }
 }


=head2 sub format 


=cut

 sub format {

	my ( $self,$format )		= @_;
	if ( $format ne $empty_string ) {

		$segywrite->{_format}		= $format;
		$segywrite->{_note}		= $segywrite->{_note}.' format='.$segywrite->{_format};
		$segywrite->{_Step}		= $segywrite->{_Step}.' format='.$segywrite->{_format};

	} else { 
		print("segywrite, format, missing format,\n");
	 }
 }


=head2 sub hfile 


=cut

 sub hfile {

	my ( $self,$hfile )		= @_;
	if ( $hfile ne $empty_string ) {

		$segywrite->{_hfile}		= $hfile;
		$segywrite->{_note}		= $segywrite->{_note}.' hfile='.$segywrite->{_hfile};
		$segywrite->{_Step}		= $segywrite->{_Step}.' hfile='.$segywrite->{_hfile};

	} else { 
		print("segywrite, hfile, missing hfile,\n");
	 }
 }


=head2 sub tape 


=cut

 sub tape {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

		$segywrite->{_tape}		= $tape;
		$segywrite->{_note}		= $segywrite->{_note}.' tape='.$segywrite->{_tape};
		$segywrite->{_Step}		= $segywrite->{_Step}.' tape='.$segywrite->{_tape};

	} else { 
		print("segywrite, tape, missing tape,\n");
	 }
 }


=head2 sub trmax 


=cut

 sub trmax {

	my ( $self,$trmax )		= @_;
	if ( $trmax ne $empty_string ) {

		$segywrite->{_trmax}		= $trmax;
		$segywrite->{_note}		= $segywrite->{_note}.' trmax='.$segywrite->{_trmax};
		$segywrite->{_Step}		= $segywrite->{_Step}.' trmax='.$segywrite->{_trmax};

	} else { 
		print("segywrite, trmax, missing trmax,\n");
	 }
 }


=head2 sub trmin 


=cut

 sub trmin {

	my ( $self,$trmin )		= @_;
	if ( $trmin ne $empty_string ) {

		$segywrite->{_trmin}		= $trmin;
		$segywrite->{_note}		= $segywrite->{_note}.' trmin='.$segywrite->{_trmin};
		$segywrite->{_Step}		= $segywrite->{_Step}.' trmin='.$segywrite->{_trmin};

	} else { 
		print("segywrite, trmin, missing trmin,\n");
	 }
 }


=head2 sub vblock 


=cut

 sub vblock {

	my ( $self,$vblock )		= @_;
	if ( $vblock ne $empty_string ) {

		$segywrite->{_vblock}		= $vblock;
		$segywrite->{_note}		= $segywrite->{_note}.' vblock='.$segywrite->{_vblock};
		$segywrite->{_Step}		= $segywrite->{_Step}.' vblock='.$segywrite->{_vblock};

	} else { 
		print("segywrite, vblock, missing vblock,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$segywrite->{_verbose}		= $verbose;
		$segywrite->{_note}		= $segywrite->{_note}.' verbose='.$segywrite->{_verbose};
		$segywrite->{_Step}		= $segywrite->{_Step}.' verbose='.$segywrite->{_verbose};

	} else { 
		print("segywrite, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 12;

    return($max_index);
}
 
 
1;
