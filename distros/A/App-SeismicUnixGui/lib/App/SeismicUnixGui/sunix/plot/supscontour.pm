package App::SeismicUnixGui::sunix::plot::supscontour;

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
 SUPSCONTOUR - PostScript CONTOUR plot of a segy data set		



 supscontour <stdin [optional parameters] > ...			



 Optional parameters:						 	



 n2=tr.ntr or number of traces in the data set (ntr is an alias for n2)



 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension	

   =.004 for seismic 		(if not set)				

   =1.0 for nonseismic		(if not set)				



 d2=tr.d2			sampling interval in the slow dimension	

   =1.0 			(if not set)				



 f1=tr.f1 or tr.delrt/10^3 or 0.0  first sample in the fast dimension	



 f2=tr.f2 or tr.tracr or tr.tracl  first sample in the slow dimension	

   =1.0 for seismic		    (if not set)			

   =d2 for nonseismic		    (if not set)			



 verbose=0              =1 to print some useful information		



 tmpdir=	 	if non-empty, use the value as a directory path	

		 	prefix for storing temporary files; else if the	

	         	the CWP_TMPDIR environment variable is set use	

	         	its value for the path; else use tmpfile()	



 Note that for seismic time domain data, the "fast dimension" is	

 time and the "slow dimension" is usually trace number or range.	

 Also note that "foreign" data tapes may have something unexpected	

 in the d2,f2 fields, use segyclean to clear these if you can afford	

 the processing time or use d2= f2= to override the header values if	

 not.									



 See the pscontour selfdoc for the remaining parameters.		



 On NeXT:	supscontour < infile [optional parameters]  | open	



 Trace header fields accessed: ns, ntr, tracr, tracl, delrt, trid,     

	dt, d1, d2, f1, f2						



 Credits:



	CWP: Dave Hale and Zhiming Li (pscontour, etc.)

	   Jack Cohen and John Stockwell (supscontour, etc.)

      Delphi: Alexander Koek, added support for irregularly spaced traces

      Aarhus University: Morten W. Pedersen copied everything from the xwigb

                         source and just replaced all occurencies of the word



 Notes:

	When the number of traces isn't known, we need to count

	the traces for pscontour.  You can make this value "known"

	either by getparring n2 or by having the ntr field set

	in the trace header.  A getparred value takes precedence

	over the value in the trace header.



	When we do have to count the traces, we use the "tmpfile"

	routine because on many machines it is implemented

	as a memory area instead of a disk file.



	If your system does make a disk file, consider altering

	the code to remove the file on interrupt.  This could be

	done either by trapping the interrupt with "signal"

	or by using the "tmpnam" routine followed by an immediate

	"remove" (aka "unlink" in old unix).



	When we must compute ntr, we don't allocate a 2-d array,

	but just content ourselves with copying trace by trace from

	the data "file" to the pipe into the plotting program.

	Although we could use tr.data, we allocate a trace buffer

	for code clarity.



=head2 User's notes (Juan Lorenzo)

untested
V0.0.2 2.9.23 pipe out not allowed. Only redirect out is allowed.

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.2';


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

my $supscontour			= {
	_d1					=> '',
	_d2					=> '',
	_f1					=> '',
	_f2					=> '',
	_n2					=> '',
	_tmpdir					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supscontour->{_Step}     = 'supscontour'.$supscontour->{_Step};
	return ( $supscontour->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supscontour->{_note}     = 'supscontour'.$supscontour->{_note};
	return ( $supscontour->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supscontour->{_d1}			= '';
		$supscontour->{_d2}			= '';
		$supscontour->{_f1}			= '';
		$supscontour->{_f2}			= '';
		$supscontour->{_n2}			= '';
		$supscontour->{_tmpdir}			= '';
		$supscontour->{_verbose}			= '';
		$supscontour->{_Step}			= '';
		$supscontour->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$supscontour->{_d1}		= $d1;
		$supscontour->{_note}		= $supscontour->{_note}.' d1='.$supscontour->{_d1};
		$supscontour->{_Step}		= $supscontour->{_Step}.' d1='.$supscontour->{_d1};

	} else { 
		print("supscontour, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$supscontour->{_d2}		= $d2;
		$supscontour->{_note}		= $supscontour->{_note}.' d2='.$supscontour->{_d2};
		$supscontour->{_Step}		= $supscontour->{_Step}.' d2='.$supscontour->{_d2};

	} else { 
		print("supscontour, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$supscontour->{_f1}		= $f1;
		$supscontour->{_note}		= $supscontour->{_note}.' f1='.$supscontour->{_f1};
		$supscontour->{_Step}		= $supscontour->{_Step}.' f1='.$supscontour->{_f1};

	} else { 
		print("supscontour, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$supscontour->{_f2}		= $f2;
		$supscontour->{_note}		= $supscontour->{_note}.' f2='.$supscontour->{_f2};
		$supscontour->{_Step}		= $supscontour->{_Step}.' f2='.$supscontour->{_f2};

	} else { 
		print("supscontour, f2, missing f2,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$supscontour->{_n2}		= $n2;
		$supscontour->{_note}		= $supscontour->{_note}.' n2='.$supscontour->{_n2};
		$supscontour->{_Step}		= $supscontour->{_Step}.' n2='.$supscontour->{_n2};

	} else { 
		print("supscontour, n2, missing n2,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$supscontour->{_tmpdir}		= $tmpdir;
		$supscontour->{_note}		= $supscontour->{_note}.' tmpdir='.$supscontour->{_tmpdir};
		$supscontour->{_Step}		= $supscontour->{_Step}.' tmpdir='.$supscontour->{_tmpdir};

	} else { 
		print("supscontour, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supscontour->{_verbose}		= $verbose;
		$supscontour->{_note}		= $supscontour->{_note}.' verbose='.$supscontour->{_verbose};
		$supscontour->{_Step}		= $supscontour->{_Step}.' verbose='.$supscontour->{_verbose};

	} else { 
		print("supscontour, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
