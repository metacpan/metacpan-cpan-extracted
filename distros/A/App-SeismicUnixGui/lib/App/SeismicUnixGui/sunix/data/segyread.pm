package App::SeismicUnixGui::sunix::data::segyread;

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

 endian=1	set =0 for little-endian machines(PC's,DEC,etc.)	

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

 JML V0.0.2, 9.1.25

 Normally, segyread acts on only one file at a time
 
 In V0.0.2 wraps an extension to process an arbitrary
 list of trace numbers. The automatic iteration includes
 two additional parameters: list and su_base_file_name
 
 The parameter "list" is the name of a text file.
 The file is automatically bound to the SEIMICS_DATA_TXT 
 directory path.
 
 "list" is the name of a file containing a numeric list
 of trace numbers of type "key" that are to be deleted:
 
 An example list
 file contains values, one per line.
    1 
    3 
    5

  "list" = a file name (in directory path: DATA_SEISMICS_TXT)
  
  su_base_file_name =   e.g., 1001, which by defaults lies
  in directory path: DATA_SEISMIC_SU.
  A bare file name: '1001' will automatically be given an suffix
  The file name on the disk will be '1001.su'
  
  Within code, the imported "list" includes path and name;
  hence its name: _inbound_list. User enters a list name in 
  GUI using the mouse <MB3>.

=cut

=head2 User's notes (Juan Lorenzo)
untested

=cut


use Moose;
our $VERSION = '0.0.2';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $manage_files_by2    = manage_files_by2->new();
my $DATA_SEISMIC_SEGY	= $Project->DATA_SEISMIC_SEGY();
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

my $segyread			= {
	_bfile					=> '',
	_buff					=> '',
	_byte					=> '',
	_conv					=> '',
	_ebcdic					=> '',
	_endian					=> '',
	_errmax					=> '',
	_format					=> '',
	_hfile					=> '',
	_inbound_list		    => '',
	_ns					    => '',
	_over					=> '',
	_remap					=> '',
	_tape					=> '',
	_trcwt					=> '',
	_trmax					=> '',
	_trmin					=> '',
	_vblock					=> '',
	_verbose				=> '',
	_xfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut
sub  Step {
 	
	my ($self) = @_;
	
	# simple check
	if ( length $segyread->{_inbound_list} ) {
		my $file_num;
		my @Step;
		my $step;
		
		my ($inbound_aref)  = _get_inbound4base_file_names();
		my ($outbound_aref) = _get_outbound4base_file_names();
		my @inbound         = @$inbound_aref;
		my @outbound        = @$outbound_aref;		
		my $num_of_files    = scalar @outbound;

		# print("Step,inbound: @inbound\n");
		# print("Step,inbound: @outbound\n");

		my $last_idx        = $num_of_files - 1;

		# All cases when num_files >=1
		# for first file
		$step     = " segyread $segyread->{_Step} tape=$inbound[0] > $outbound[0] ";

		if ( $last_idx >= 2 ) {

			# CASE: >= 3 operations
			for ( my $i = 1 ; $i < $last_idx ; $i++ ) {
				
				$step =
				  $step . "&  segyread $segyread->{_Step} tape=$inbound[$i] > $outbound[$i] ";

			}

			# for last file
			$segyread->{_Step} =
			  $step . "&  segyread $segyread->{_Step} tape=$inbound[$last_idx] > $outbound[$last_idx]";

		}
		elsif ( $last_idx == 1 ) {

			# for last file
			$segyread->{_Step} =
			  $step . "&  segyread $segyread->{_Step} tape=$inbound[$last_idx] > $outbound[$last_idx] ";

		}
		elsif ( $last_idx == 0 ) {

			$segyread->{_Step} = " $step";

		}
		else {
			print("segyread,Step,unexpected case\n");
			return();
		}

		return ($segyread->{_Step});
		
	}
	elsif ( not length $segyread->{_inbound_list} ) {
			
	$segyread->{_Step}     = 'segyread'.$segyread->{_Step};
	return ( $segyread->{_Step} );
	}
	else {
		print("segyread, Step, incorrect parameters\n");
	}
 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segyread->{_note}     = 'segyread'.$segyread->{_note};
	return ( $segyread->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segyread->{_bfile}			= '';
		$segyread->{_buff}			= '';
		$segyread->{_byte}			= '';
		$segyread->{_conv}			= '';
		$segyread->{_ebcdic}		= '';
		$segyread->{_endian}		= '';
		$segyread->{_errmax}		= '';
		$segyread->{_format}        = '';
		$segyread->{_hfile}			= '';
		$segyread->{_inbound_list}  = '';
		$segyread->{_ns}			= '';
		$segyread->{_over}			= '';
		$segyread->{_remap}			= '';
		$segyread->{_tape}			= '';
		$segyread->{_trcwt}			= '';
		$segyread->{_trmax}			= '';
		$segyread->{_trmin}			= '';
		$segyread->{_vblock}		= '';
		$segyread->{_verbose}		= '';
		$segyread->{_xfile}			= '';
		$segyread->{_Step}			= '';
		$segyread->{_note}			= '';
 }

=head2 sub _get_inbound4base_file_names

=cut

sub _get_inbound4base_file_names {
	my ($self) = @_;

    my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( defined $array_ref && @$array_ref ) {

		my @base_file_name = @$array_ref;
		my @inbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$inbound[$i] = $DATA_SEISMIC_SEGY . '/' . $base_file_name[$i].$suffix_segy;
		}
		return ( \@inbound );

	}
	else {
		print("segyread,_get_inbound4base_file_names, missing file names\n");
		return ();
	}

}

=head2 sub _get_outbound4base_file_names

=cut

sub _get_outbound4base_file_names {
	my ($self) = @_;

	my ( $array_ref, $num_files ) = $manage_files_by2->get_base_file_name_aref();

	if ( length $array_ref ) {

		my @base_file_name = @$array_ref;
		my @outbound;

		for ( my $i = 0 ; $i < $num_files ; $i++ ) {

			$outbound[$i] = $DATA_SEISMIC_SU . '/' . $base_file_name[$i].$suffix_su;

		}
		return ( \@outbound );

	}
	else {
		print("segyread,_get_outbound4basefile_names, missing file names\n");
		return ();
	}

}

=head2 sub bfile 


=cut

 sub bfile {

	my ( $self,$bfile )		= @_;
	if ( $bfile ne $empty_string ) {

		$segyread->{_bfile}		= $bfile;
		$segyread->{_note}		= $segyread->{_note}.' bfile='.$segyread->{_bfile};
		$segyread->{_Step}		= $segyread->{_Step}.' bfile='.$segyread->{_bfile};

	} else { 
		print("segyread, bfile, missing bfile,\n");
	 }
 }


=head2 sub buff 


=cut

 sub buff {

	my ( $self,$buff )		= @_;
	if ( $buff ne $empty_string ) {

		$segyread->{_buff}		= $buff;
		$segyread->{_note}		= $segyread->{_note}.' buff='.$segyread->{_buff};
		$segyread->{_Step}		= $segyread->{_Step}.' buff='.$segyread->{_buff};

	} else { 
		print("segyread, buff, missing buff,\n");
	 }
 }


=head2 sub byte 


=cut

 sub byte {

	my ( $self,$byte )		= @_;
	if ( $byte ne $empty_string ) {

		$segyread->{_byte}		= $byte;
		$segyread->{_note}		= $segyread->{_note}.' byte='.$segyread->{_byte};
		$segyread->{_Step}		= $segyread->{_Step}.' byte='.$segyread->{_byte};

	} else { 
		print("segyread, byte, missing byte,\n");
	 }
 }


=head2 sub conv 


=cut

 sub conv {

	my ( $self,$conv )		= @_;
	if ( $conv ne $empty_string ) {

		$segyread->{_conv}		= $conv;
		$segyread->{_note}		= $segyread->{_note}.' conv='.$segyread->{_conv};
		$segyread->{_Step}		= $segyread->{_Step}.' conv='.$segyread->{_conv};

	} else { 
		print("segyread, conv, missing conv,\n");
	 }
 }


=head2 sub ebcdic 


=cut

 sub ebcdic {

	my ( $self,$ebcdic )		= @_;
	if ( $ebcdic ne $empty_string ) {

		$segyread->{_ebcdic}		= $ebcdic;
		$segyread->{_note}		= $segyread->{_note}.' ebcdic='.$segyread->{_ebcdic};
		$segyread->{_Step}		= $segyread->{_Step}.' ebcdic='.$segyread->{_ebcdic};

	} else { 
		print("segyread, ebcdic, missing ebcdic,\n");
	 }
 }


=head2 sub endian 


=cut

 sub endian {

	my ( $self,$endian )		= @_;
	if ( $endian ne $empty_string ) {

		$segyread->{_endian}		= $endian;
		$segyread->{_note}		= $segyread->{_note}.' endian='.$segyread->{_endian};
		$segyread->{_Step}		= $segyread->{_Step}.' endian='.$segyread->{_endian};

	} else { 
		print("segyread, endian, missing endian,\n");
	 }
 }


=head2 sub errmax 


=cut

 sub errmax {

	my ( $self,$errmax )		= @_;
	if ( $errmax ne $empty_string ) {

		$segyread->{_errmax}		= $errmax;
		$segyread->{_note}		= $segyread->{_note}.' errmax='.$segyread->{_errmax};
		$segyread->{_Step}		= $segyread->{_Step}.' errmax='.$segyread->{_errmax};

	} else { 
		print("segyread, errmax, missing errmax,\n");
	 }
 }
 
=head2 sub file 


=cut

 sub file {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

        $tape =~ s/\\//g; 
        
		$segyread->{_tape}		= $tape;
		$segyread->{_note}		= $segyread->{_note}.' tape='.'"'.$segyread->{_tape}.'"';
		$segyread->{_Step}		= $segyread->{_Step}.' tape='.'"'.$segyread->{_tape}.'"';

	} else { 
		print("segyread, file, missing tape,\n");
	 }
 }
 


=head2 sub format 


=cut

 sub format {

	my ( $self,$format )		= @_;
	if ( $format ne $empty_string ) {

		$segyread->{_format}		= $format;
		$segyread->{_note}		= $segyread->{_note}.' format='.$segyread->{_format};
		$segyread->{_Step}		= $segyread->{_Step}.' format='.$segyread->{_format};

	} else { 
		print("segyread, format, missing format,\n");
	 }
 }


=head2 sub hfile 


=cut

 sub hfile {

	my ( $self,$hfile )		= @_;
	if ( $hfile ne $empty_string ) {

		$segyread->{_hfile}		= $hfile;
		$segyread->{_note}		= $segyread->{_note}.' hfile='.$segyread->{_hfile};
		$segyread->{_Step}		= $segyread->{_Step}.' hfile='.$segyread->{_hfile};

	} else { 
		print("segyread, hfile, missing hfile,\n");
	 }
 }

=head2 sub list

 list array

=cut

sub list {
	my ( $self, $list ) = @_;

	if ( length $list ) {

		# clear memory
		$manage_files_by2->clear(); 
		
		$segyread->{_inbound_list} = $list;
		
		$manage_files_by2->set_inbound_list($list);
		

	}
	else {
		print("segyread, list, missing list,\n");
	}
	return ();
}

=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$segyread->{_ns}		= $ns;
		$segyread->{_note}		= $segyread->{_note}.' ns='.$segyread->{_ns};
		$segyread->{_Step}		= $segyread->{_Step}.' ns='.$segyread->{_ns};

	} else { 
		print("segyread, ns, missing ns,\n");
	 }
 }


=head2 sub over 


=cut

 sub over {

	my ( $self,$over )		= @_;
	if ( $over ne $empty_string ) {

		$segyread->{_over}		= $over;
		$segyread->{_note}		= $segyread->{_note}.' over='.$segyread->{_over};
		$segyread->{_Step}		= $segyread->{_Step}.' over='.$segyread->{_over};

	} else { 
		print("segyread, over, missing over,\n");
	 }
 }


=head2 sub remap 


=cut

 sub remap {

	my ( $self,$remap )		= @_;
	if ( $remap ne $empty_string ) {

		$segyread->{_remap}		= $remap;
		$segyread->{_note}		= $segyread->{_note}.' remap='.$segyread->{_remap};
		$segyread->{_Step}		= $segyread->{_Step}.' remap='.$segyread->{_remap};

	} else { 
		print("segyread, remap, missing remap,\n");
	 }
 }


=head2 sub tape 


=cut

 sub tape {

	my ( $self,$tape )		= @_;
	if ( $tape ne $empty_string ) {

		$segyread->{_tape}		= $tape;
		$segyread->{_note}		= $segyread->{_note}.' tape='.'"'.$segyread->{_tape}.'"';
		$segyread->{_Step}		= $segyread->{_Step}.' tape='.'"'.$segyread->{_tape}.'"';

	} else { 
		print("segyread, tape, missing tape,\n");
	 }
 }


=head2 sub trcwt 


=cut

 sub trcwt {

	my ( $self,$trcwt )		= @_;
	if ( $trcwt ne $empty_string ) {

		$segyread->{_trcwt}		= $trcwt;
		$segyread->{_note}		= $segyread->{_note}.' trcwt='.$segyread->{_trcwt};
		$segyread->{_Step}		= $segyread->{_Step}.' trcwt='.$segyread->{_trcwt};

	} else { 
		print("segyread, trcwt, missing trcwt,\n");
	 }
 }


=head2 sub trmax 


=cut

 sub trmax {

	my ( $self,$trmax )		= @_;
	if ( $trmax ne $empty_string ) {

		$segyread->{_trmax}		= $trmax;
		$segyread->{_note}		= $segyread->{_note}.' trmax='.$segyread->{_trmax};
		$segyread->{_Step}		= $segyread->{_Step}.' trmax='.$segyread->{_trmax};

	} else { 
		print("segyread, trmax, missing trmax,\n");
	 }
 }


=head2 sub trmin 


=cut

 sub trmin {

	my ( $self,$trmin )		= @_;
	if ( $trmin ne $empty_string ) {

		$segyread->{_trmin}		= $trmin;
		$segyread->{_note}		= $segyread->{_note}.' trmin='.$segyread->{_trmin};
		$segyread->{_Step}		= $segyread->{_Step}.' trmin='.$segyread->{_trmin};

	} else { 
		print("segyread, trmin, missing trmin,\n");
	 }
 }


=head2 sub vblock 


=cut

 sub vblock {

	my ( $self,$vblock )		= @_;
	if ( $vblock ne $empty_string ) {

		$segyread->{_vblock}		= $vblock;
		$segyread->{_note}		= $segyread->{_note}.' vblock='.$segyread->{_vblock};
		$segyread->{_Step}		= $segyread->{_Step}.' vblock='.$segyread->{_vblock};

	} else { 
		print("segyread, vblock, missing vblock,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$segyread->{_verbose}		= $verbose;
		$segyread->{_note}		= $segyread->{_note}.' verbose='.$segyread->{_verbose};
		$segyread->{_Step}		= $segyread->{_Step}.' verbose='.$segyread->{_verbose};

	} else { 
		print("segyread, verbose, missing verbose,\n");
	 }
 }


=head2 sub xfile 


=cut

 sub xfile {

	my ( $self,$xfile )		= @_;
	if ( $xfile ne $empty_string ) {

		$segyread->{_xfile}		= $xfile;
		$segyread->{_note}		= $segyread->{_note}.' xfile='.$segyread->{_xfile};
		$segyread->{_Step}		= $segyread->{_Step}.' xfile='.$segyread->{_xfile};

	} else { 
		print("segyread, xfile, missing xfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 19;

    return($max_index);
}
 
 
1;
