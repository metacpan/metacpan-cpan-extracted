package App::SeismicUnixGui::sunix::plot::supscubecontour;

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
 SUPSCUBECONTOUR - PostScript CUBE plot of a segy data set		



 supscubecontour <stdin [optional parameters] >			



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



 See the pscubecontour selfdoc for the remaining parameters.		



 example:   supscubecontour < infile [optional parameters]  | gv -	



 Credits:



	CWP: Dave Hale and Zhiming Li (pscube)

	     Jack K. Cohen  (suxmovie)

	     John Stockwell (supscubecontour)



 Notes:

	When n2 isn't getparred, we need to count the traces

	for pscube. Although we compute ntr, we don't allocate a 2-d array

	and content ourselves with copying trace by trace from

	the data "file" to the pipe into the plotting program.

	Although we could use tr.data, we allocate a trace buffer

	for code clarity.



=head2 User's notes (Juan Lorenzo)

untested
VERSION = '0.0.2'; 2.9.23 Only redirection is allowed.

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

my $supscubecontour			= {
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

	$supscubecontour->{_Step}     = 'supscubecontour'.$supscubecontour->{_Step};
	return ( $supscubecontour->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supscubecontour->{_note}     = 'supscubecontour'.$supscubecontour->{_note};
	return ( $supscubecontour->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supscubecontour->{_d1}			= '';
		$supscubecontour->{_d2}			= '';
		$supscubecontour->{_f1}			= '';
		$supscubecontour->{_f2}			= '';
		$supscubecontour->{_tmpdir}			= '';
		$supscubecontour->{_verbose}			= '';
		$supscubecontour->{_Step}			= '';
		$supscubecontour->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$supscubecontour->{_d1}		= $d1;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' d1='.$supscubecontour->{_d1};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' d1='.$supscubecontour->{_d1};

	} else { 
		print("supscubecontour, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$supscubecontour->{_d2}		= $d2;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' d2='.$supscubecontour->{_d2};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' d2='.$supscubecontour->{_d2};

	} else { 
		print("supscubecontour, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$supscubecontour->{_f1}		= $f1;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' f1='.$supscubecontour->{_f1};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' f1='.$supscubecontour->{_f1};

	} else { 
		print("supscubecontour, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$supscubecontour->{_f2}		= $f2;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' f2='.$supscubecontour->{_f2};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' f2='.$supscubecontour->{_f2};

	} else { 
		print("supscubecontour, f2, missing f2,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$supscubecontour->{_tmpdir}		= $tmpdir;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' tmpdir='.$supscubecontour->{_tmpdir};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' tmpdir='.$supscubecontour->{_tmpdir};

	} else { 
		print("supscubecontour, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supscubecontour->{_verbose}		= $verbose;
		$supscubecontour->{_note}		= $supscubecontour->{_note}.' verbose='.$supscubecontour->{_verbose};
		$supscubecontour->{_Step}		= $supscubecontour->{_Step}.' verbose='.$supscubecontour->{_verbose};

	} else { 
		print("supscubecontour, verbose, missing verbose,\n");
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
