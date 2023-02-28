package App::SeismicUnixGui::sunix::plot::supsmovie;

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
 SUPSMOVIE - PostScript MOVIE plot of a segy data set			



 supsmovie <stdin [optional parameters] >				



 Optional parameters: 							



 n2 is the number of traces per frame.  If not getparred then it	

 is the total number of traces in the data set.  			



 n3 is the number of frames.  If not getparred then it			

 is the total number of frames in the data set measured by ntr/n2	



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

 the processing time or use d2= f2= to over-ride the header values if	

 not.									



 See the psmovie selfdoc for the remaining parameters.			



 On NeXT:     supsmovie < infile [optional parameters]  | open	       	



 Credits:



	CWP: Dave Hale and Zhiming Li (psmovie)

	     Jack K. Cohen  (suxmovie)

	     John Stockwell (supsmovie)



 Notes:

	When n2 isn't getparred, we need to count the traces

	for psmovie.  In this case:

	we are using tmpfile because on many machines it is

	implemented as a memory area instead of a disk file.

	Although we compute ntr, we don't allocate a 2-d array

	and content ourselves with copying trace by trace from

	the data "file" to the pipe into the plotting program.

	Although we could use tr.data, we allocate a trace buffer

	for code clarity.



=head2 User's notes (Juan Lorenzo)

untested
VERSION = '0.0.2'; Only redirection is allowed. 2.9.23

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

my $supsmovie			= {
	_d1					=> '',
	_d2					=> '',
	_f1					=> '',
	_f2					=> '',
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

	$supsmovie->{_Step}     = 'supsmovie'.$supsmovie->{_Step};
	return ( $supsmovie->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supsmovie->{_note}     = 'supsmovie'.$supsmovie->{_note};
	return ( $supsmovie->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supsmovie->{_d1}			= '';
		$supsmovie->{_d2}			= '';
		$supsmovie->{_f1}			= '';
		$supsmovie->{_f2}			= '';
		$supsmovie->{_tmpdir}			= '';
		$supsmovie->{_verbose}			= '';
		$supsmovie->{_Step}			= '';
		$supsmovie->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$supsmovie->{_d1}		= $d1;
		$supsmovie->{_note}		= $supsmovie->{_note}.' d1='.$supsmovie->{_d1};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' d1='.$supsmovie->{_d1};

	} else { 
		print("supsmovie, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$supsmovie->{_d2}		= $d2;
		$supsmovie->{_note}		= $supsmovie->{_note}.' d2='.$supsmovie->{_d2};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' d2='.$supsmovie->{_d2};

	} else { 
		print("supsmovie, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$supsmovie->{_f1}		= $f1;
		$supsmovie->{_note}		= $supsmovie->{_note}.' f1='.$supsmovie->{_f1};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' f1='.$supsmovie->{_f1};

	} else { 
		print("supsmovie, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$supsmovie->{_f2}		= $f2;
		$supsmovie->{_note}		= $supsmovie->{_note}.' f2='.$supsmovie->{_f2};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' f2='.$supsmovie->{_f2};

	} else { 
		print("supsmovie, f2, missing f2,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$supsmovie->{_tmpdir}		= $tmpdir;
		$supsmovie->{_note}		= $supsmovie->{_note}.' tmpdir='.$supsmovie->{_tmpdir};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' tmpdir='.$supsmovie->{_tmpdir};

	} else { 
		print("supsmovie, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supsmovie->{_verbose}		= $verbose;
		$supsmovie->{_note}		= $supsmovie->{_note}.' verbose='.$supsmovie->{_verbose};
		$supsmovie->{_Step}		= $supsmovie->{_Step}.' verbose='.$supsmovie->{_verbose};

	} else { 
		print("supsmovie, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
