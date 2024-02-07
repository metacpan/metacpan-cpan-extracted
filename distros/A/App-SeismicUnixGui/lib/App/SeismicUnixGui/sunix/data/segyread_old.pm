package App::SeismicUnixGui::sunix::data::segyread;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SEGYREAD - read an SEG-Y tape						
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SEGYREAD - read an SEG-Y tape						

   segyread > stdout tape=						

   or									

   SEG-Y data stream ... | segyread tape=-  > stdout			

 Required parameter:							
 tape=		input tape device or seg-y filename (see notes)		

 Optional parameters:							
 buff=1	for buffered device (9-track reel tape drive)		
		=0 possibly useful for 8mm EXABYTE drives		
 verbose=0	silent operation					
		=1 ; echo every 'vblock' traces				
 vblock=50	echo every 'vblock' traces under verbose option		
 hfile=header	file to store ebcdic block (as ascii)			
 bfile=binary	file to store binary block				
 xfile=xhdrs	file to store extended text block			
 over=0	quit if bhed format not equal 1, 2, 3, 5, or 8		
		= 1 ; override and attempt conversion			
 format=bh.format	if over=1 try to convert assuming format value  
 conv=1	convert data to native format				
			= 0 ; assume data is in native format		
 ebcdic=1	perform ebcdic to ascii conversion on 3200 byte textural
               header. =0 do not perform conversion			
 ns=bh.hns	number of samples (use if bhed ns wrong)		
 trcwt=1	apply trace weighting factor (bytes 169-170)		
		=0, do not apply.  (Default is 0 for formats 1 and 5)	
 trmin=1		first trace to read				
 trmax=INT_MAX	last trace to read					
 endian=(autodetected) =1 for big-endian,  =0 for little-endian byte order
 swapbhed=endian	swap binary reel header?			
 swaphdrs=endian	swap trace headers?				
 swapdata=endian	swap data?					
 errmax=0	allowable number of consecutive tape IO errors		
 remap=...,...	remap key(s) 						
 byte=...,...	formats to use for header remapping 			

 Notes:								
 Traditionally tape=/dev/rmt0.	 However, in the modern world tape device
 names are much less uniform.  The magic name can often be deduced by	
 "ls /dev".  Likely man pages with the names of the tape devices are:
 "mt", "sd" "st".  Also try "man -k scsi", " man mt", etc.	
 Sometimes "mt status" will tell the device name.			

 For a SEG-Y diskfile use tape=filename.				

 The xfile argument will only be used if the file contains extended	
 text headers.								

 Remark: a SEG-Y file is not the same as an su file. A SEG-Y file	
 consists of three parts: an ebcdic header, a binary reel header, and	
 the traces.  The traces are (usually) in 32 bit IBM floating point	
 format.  An SU file consists only of the trace portion written in the 
 native binary floats.							

 Formats supported:							
 1: IBM floating point, 4 byte (32 bits)				
 2: two's complement integer, 4 byte (32 bits)				
 3: two's complement integer, 2 byte (16 bits)				
 5: IEEE floating point, 4 byte (32 bits)				
 8: two's complement integer, 1 byte (8 bits)				

 tape=-   read from standard input. Caveat, under Solaris, you will	
 need to use the buff=1 option, as well.				

 Header remap:								
 The value of header word remap is mapped from the values of byte	

 Map a float at location 221 to sample spacing d1:			
	segyread <data >outdata remap=d1 byte=221f			

 Map a long at location 225 to source location sx:			
	segyread <data >outdata remap=sx byte=225l			

 Map a short at location 229 to gain constant igc:			
	segyread <data >outdata remap=igc byte=229s			

 Or all combined: 							
	segyread <data >outdata remap=d1,sx,igc byte=221f,225l,229s	

 Segy header words are accessed as Xt where X denotes the byte number	
 starting at 1 in correspondance with the SEGY standard (1975)		
 Known types include:	f	float (4 bytes)				
 			l	long int (4 bytes)			
 			s	short int (2 bytes)			
 			b	byte (1 bytes)				

	  type:	  sudoc segyread   for further information		



 Note:
      If you have a tape with multiple sequences of ebcdic header,
	binary header,traces, use the device that
	invokes the no-rewind option and issue multiple segyread
	commands (making an appropriate shell script if you
	want to save all the headers).	Consider using >> if
	you want a single trace file in the end.  Similar
	considerations apply for multiple reels of tapes,
	but use the standard rewind on end of file.

 Note: For buff=1 (default) tape is accessed with 'read', for buff=0
	tape is accessed with fread. We suggest that you try buff=1
	even with EXABYTE tapes.
 Caveat: may be slow on an 8mm streaming (EXABYTE) tapedrive
 Warning: segyread or segywrite to 8mm tape is fragile. Allow sufficient
	time between successive reads and writes.
 Warning: may return the error message "efclose: fclose failed"
	intermittently when segyreading/segywriting to 8mm (EXABYTE) tape
	even if actual segyread/segywrite is successful. However, this
	error message may be returned if your tape drive has a fixed
	block size set.
 Caution: When reading or writing SEG-Y tapes, the tape
	drive should be set to be able to read variable block length
	tape files.


 Credits:
	SEP: Einar Kjartansson
	CWP: Jack K. Cohen, Brian Sumner, Chris Liner
	   : John Stockwell (added 8mm tape stuff)
 conv parameter added by:
	Tony Kocurko
	Department of Earth Sciences
	Memorial University of Newfoundland
	St. John's, Newfoundland
 read from stdin via tape=-  added by	Tony Kocurko
 bhed format = 2,3 conversion by:
	Remco Romijn (Applied Geophysics, TU Delft)
	J.W. de Bruijn (Applied Geophysics, TU Delft)
 bhed format = 8 conversion by: John Stockwell
 header remap feature added by:
 	Matthias Imhof, Virginia Tech
--------------------------
 Additional Notes:
	Brian's subroutine, ibm_to_float, which converts IBM floating
	point to IEEE floating point is NOT portable and must be
	altered for non-IEEE machines.	See the subroutine notes below.

	A direct read by dd would suck up the entire tape; hence the
	dancing around with buffers and files.


=head2 CHANGES and their DATES

10.06.21 V0.0.2
    forcing correct suffix deprecated and is now handled in segyread_spec.pm

=cut

use Moose;
our $VERSION = '0.0.2';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

my $Project = Project_config->new();
my $get     = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $segyread = {
	_bfile    => '',
	_buff     => '',
	_byte     => '',
	_conv     => '',
	_ebcdic   => '',
	_endian   => '',
	_errmax   => '',
	_format   => '',
	_hfile    => '',
	_ns       => '',
	_over     => '',
	_remap    => '',
	_swapbhed => '',
	_swapdata => '',
	_swaphdrs => '',
	_tape     => '',
	_trcwt    => '',
	_trmax    => '',
	_trmin    => '',
	_vblock   => '',
	_verbose  => '',
	_xfile    => '',
	_Step     => '',
	_note     => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$segyread->{_Step} = 'segyread' . $segyread->{_Step};
	return ( $segyread->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$segyread->{_note} = 'segyread' . $segyread->{_note};
	return ( $segyread->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$segyread->{_bfile}    = '';
	$segyread->{_buff}     = '';
	$segyread->{_byte}     = '';
	$segyread->{_conv}     = '';
	$segyread->{_ebcdic}   = '';
	$segyread->{_endian}   = '';
	$segyread->{_errmax}   = '';
	$segyread->{_format}   = '';
	$segyread->{_hfile}    = '';
	$segyread->{_ns}       = '';
	$segyread->{_over}     = '';
	$segyread->{_remap}    = '';
	$segyread->{_swapbhed} = '';
	$segyread->{_swapdata} = '';
	$segyread->{_swaphdrs} = '';
	$segyread->{_tape}     = '';
	$segyread->{_trcwt}    = '';
	$segyread->{_trmax}    = '';
	$segyread->{_trmin}    = '';
	$segyread->{_vblock}   = '';
	$segyread->{_verbose}  = '';
	$segyread->{_xfile}    = '';
	$segyread->{_Step}     = '';
	$segyread->{_note}     = '';
}

=head2 sub bfile 


=cut

sub bfile {

	my ( $self, $bfile ) = @_;
	if ( $bfile ne $empty_string ) {

		use File::Basename;
		my ($DATA_SEISMIC_BIN) = $Project->DATA_SEISMIC_BIN();

		$segyread->{_bfile} = $bfile;

		my $new_file_name = basename($bfile);

		$segyread->{_bfile} =
		  $DATA_SEISMIC_BIN . '/' . "'" . $new_file_name . "'";

		$segyread->{_note} =
		  $segyread->{_note} . ' bfile=' . $segyread->{_bfile};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' bfile=' . $segyread->{_bfile};

	}
	else {
		print("segyread, bfile, missing bfile,\n");
	}
}

=head2 sub buff 


=cut

sub buff {

	my ( $self, $buff ) = @_;
	if ( $buff ne $empty_string ) {

		$segyread->{_buff} = $buff;
		$segyread->{_note} =
		  $segyread->{_note} . ' buff=' . $segyread->{_buff};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' buff=' . $segyread->{_buff};

	}
	else {
		print("segyread, buff, missing buff,\n");
	}
}

=head2 sub byte 


=cut

sub byte {

	my ( $self, $byte ) = @_;
	if ( $byte ne $empty_string ) {

		$segyread->{_byte} = $byte;
		$segyread->{_note} =
		  $segyread->{_note} . ' byte=' . $segyread->{_byte};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' byte=' . $segyread->{_byte};

	}
	else {
		print("segyread, byte, missing byte,\n");
	}
}

=head2 sub conv 


=cut

sub conv {

	my ( $self, $conv ) = @_;
	if ( $conv ne $empty_string ) {

		$segyread->{_conv} = $conv;
		$segyread->{_note} =
		  $segyread->{_note} . ' conv=' . $segyread->{_conv};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' conv=' . $segyread->{_conv};

	}
	else {
		print("segyread, conv, missing conv,\n");
	}
}

=head2 sub ebcdic 


=cut

sub ebcdic {

	my ( $self, $ebcdic ) = @_;
	if ( $ebcdic ne $empty_string ) {

		$segyread->{_ebcdic} = $ebcdic;
		$segyread->{_note} =
		  $segyread->{_note} . ' ebcdic=' . $segyread->{_ebcdic};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' ebcdic=' . $segyread->{_ebcdic};

	}
	else {
		print("segyread, ebcdic, missing ebcdic,\n");
	}
}

=head2 sub endian 


=cut

sub endian {

	my ( $self, $endian ) = @_;
	if ( $endian ne $empty_string ) {

		$segyread->{_endian} = $endian;
		$segyread->{_note} =
		  $segyread->{_note} . ' endian=' . $segyread->{_endian};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' endian=' . $segyread->{_endian};

	}
	else {
		print("segyread, endian, missing endian,\n");
	}
}

=head2 sub errmax 


=cut

sub errmax {

	my ( $self, $errmax ) = @_;
	if ( $errmax ne $empty_string ) {

		$segyread->{_errmax} = $errmax;
		$segyread->{_note} =
		  $segyread->{_note} . ' errmax=' . $segyread->{_errmax};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' errmax=' . $segyread->{_errmax};

	}
	else {
		print("segyread, errmax, missing errmax,\n");
	}
}

=head2 sub file

	nowadays is usually a segyfile on disk
	same as tape
    forcing correct suffix deprecated 10.06.21
    parse filepaths and keep only the file name

=cut

sub file {

	my ( $self, $file ) = @_;
	if ( $file ne $empty_string ) {

		use File::Basename;
		my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();

		# forcing correct suffix deprecated 10.06.21
		my $new_file_name = basename($file);
		$segyread->{_tape} =
		  $DATA_SEISMIC_SEGY . '/' . "'" . $new_file_name . "'";

		$segyread->{_note} =
		  $segyread->{_note} . ' tape=' . $segyread->{_tape};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' tape=' . $segyread->{_tape};

	}
	else {
		print("segyread, tape, missing tape,\n");
	}
}

=head2 sub format 


=cut

sub format {

	my ( $self, $format ) = @_;
	if ( $format ne $empty_string ) {

		$segyread->{_format} = $format;
		$segyread->{_note} =
		  $segyread->{_note} . ' format=' . $segyread->{_format};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' format=' . $segyread->{_format};

	}
	else {
		print("segyread, format, missing format,\n");
	}
}

=head2 sub hfile 


=cut

sub hfile {

	my ( $self, $hfile ) = @_;
	
	if ( $hfile ne $empty_string ) {

		use File::Basename;
		my ($DATA_SEISMIC_TXT) = $Project->DATA_SEISMIC_TXT();

		my $new_file_name = basename($hfile);
		
		$segyread->{_hfile} =
		  $DATA_SEISMIC_TXT . '/' . "'" . $new_file_name . "'";

		$segyread->{_note} =
		  $segyread->{_note} . ' hfile=' . $segyread->{_hfile};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' hfile=' . $segyread->{_hfile};

	}
	else {
		print("segyread, hfile, missing hfile,\n");
	}
}

=head2 sub ns 


=cut

sub ns {

	my ( $self, $ns ) = @_;
	if ( $ns ne $empty_string ) {

		$segyread->{_ns}   = $ns;
		$segyread->{_note} = $segyread->{_note} . ' ns=' . $segyread->{_ns};
		$segyread->{_Step} = $segyread->{_Step} . ' ns=' . $segyread->{_ns};

	}
	else {
		print("segyread, ns, missing ns,\n");
	}
}

=head2 sub over 


=cut

sub over {

	my ( $self, $over ) = @_;
	if ( $over ne $empty_string ) {

		$segyread->{_over} = $over;
		$segyread->{_note} =
		  $segyread->{_note} . ' over=' . $segyread->{_over};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' over=' . $segyread->{_over};

	}
	else {
		print("segyread, over, missing over,\n");
	}
}

=head2 sub remap 


=cut

sub remap {

	my ( $self, $remap ) = @_;
	if ( $remap ne $empty_string ) {

		$segyread->{_remap} = $remap;
		$segyread->{_note} =
		  $segyread->{_note} . ' remap=' . $segyread->{_remap};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' remap=' . $segyread->{_remap};

	}
	else {
		print("segyread, remap, missing remap,\n");
	}
}

=head2 sub swapbhed 


=cut

sub swapbhed {

	my ( $self, $swapbhed ) = @_;
	if ( $swapbhed ne $empty_string ) {

		$segyread->{_swapbhed} = $swapbhed;
		$segyread->{_note} =
		  $segyread->{_note} . ' swapbhed=' . $segyread->{_swapbhed};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' swapbhed=' . $segyread->{_swapbhed};

	}
	else {
		print("segyread, swapbhed, missing swapbhed,\n");
	}
}

=head2 sub swapdata 


=cut

sub swapdata {

	my ( $self, $swapdata ) = @_;
	if ( $swapdata ne $empty_string ) {

		$segyread->{_swapdata} = $swapdata;
		$segyread->{_note} =
		  $segyread->{_note} . ' swapdata=' . $segyread->{_swapdata};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' swapdata=' . $segyread->{_swapdata};

	}
	else {
		print("segyread, swapdata, missing swapdata,\n");
	}
}

=head2 sub swaphdrs 


=cut

sub swaphdrs {

	my ( $self, $swaphdrs ) = @_;
	if ( $swaphdrs ne $empty_string ) {

		$segyread->{_swaphdrs} = $swaphdrs;
		$segyread->{_note} =
		  $segyread->{_note} . ' swaphdrs=' . $segyread->{_swaphdrs};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' swaphdrs=' . $segyread->{_swaphdrs};

	}
	else {
		print("segyread, swaphdrs, missing swaphdrs,\n");
	}
}

=head2 sub tape 

	nowadays is usually a segyfile on disk

=cut

sub tape {

	my ( $self, $tape ) = @_;
	if ( $tape ne $empty_string ) {

		use File::Basename;
		my ($DATA_SEISMIC_SEGY) = $Project->DATA_SEISMIC_SEGY();

		# forcing correct suffix deprecated 10.06.21
		my $new_file_name = basename($tape);
		$segyread->{_tape} =
		  $DATA_SEISMIC_SEGY . '/' . "'" . $new_file_name . "'";

		$segyread->{_note} =
		  $segyread->{_note} . ' tape=' . $segyread->{_tape};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' tape=' . $segyread->{_tape};

	}
	else {
		print("segyread, tape, missing tape,\n");
	}
}

=head2 sub trcwt 


=cut

sub trcwt {

	my ( $self, $trcwt ) = @_;
	if ( $trcwt ne $empty_string ) {

		$segyread->{_trcwt} = $trcwt;
		$segyread->{_note} =
		  $segyread->{_note} . ' trcwt=' . $segyread->{_trcwt};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' trcwt=' . $segyread->{_trcwt};

	}
	else {
		print("segyread, trcwt, missing trcwt,\n");
	}
}

=head2 sub trmax 


=cut

sub trmax {

	my ( $self, $trmax ) = @_;
	if ( $trmax ne $empty_string ) {

		$segyread->{_trmax} = $trmax;
		$segyread->{_note} =
		  $segyread->{_note} . ' trmax=' . $segyread->{_trmax};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' trmax=' . $segyread->{_trmax};

	}
	else {
		print("segyread, trmax, missing trmax,\n");
	}
}

=head2 sub trmin 


=cut

sub trmin {

	my ( $self, $trmin ) = @_;
	if ( $trmin ne $empty_string ) {

		$segyread->{_trmin} = $trmin;
		$segyread->{_note} =
		  $segyread->{_note} . ' trmin=' . $segyread->{_trmin};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' trmin=' . $segyread->{_trmin};

	}
	else {
		print("segyread, trmin, missing trmin,\n");
	}
}

=head2 sub vblock 


=cut

sub vblock {

	my ( $self, $vblock ) = @_;
	if ( $vblock ne $empty_string ) {

		$segyread->{_vblock} = $vblock;
		$segyread->{_note} =
		  $segyread->{_note} . ' vblock=' . $segyread->{_vblock};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' vblock=' . $segyread->{_vblock};

	}
	else {
		print("segyread, vblock, missing vblock,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$segyread->{_verbose} = $verbose;
		$segyread->{_note} =
		  $segyread->{_note} . ' verbose=' . $segyread->{_verbose};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' verbose=' . $segyread->{_verbose};

	}
	else {
		print("segyread, verbose, missing verbose,\n");
	}
}

=head2 sub xfile 


=cut

sub xfile {

	my ( $self, $xfile ) = @_;
	if ( $xfile ne $empty_string ) {

		$segyread->{_xfile} = $xfile;
		$segyread->{_note} =
		  $segyread->{_note} . ' xfile=' . $segyread->{_xfile};
		$segyread->{_Step} =
		  $segyread->{_Step} . ' xfile=' . $segyread->{_xfile};

	}
	else {
		print("segyread, xfile, missing xfile,\n");
	}
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 21;

	return ($max_index);
}

1;
