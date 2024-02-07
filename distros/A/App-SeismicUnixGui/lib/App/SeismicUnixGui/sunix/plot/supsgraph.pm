package App::SeismicUnixGui::sunix::plot::supsgraph;

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
 SUPSGRAPH - PostScript GRAPH plot of a segy data set			



 supsgraph <stdin [optional parameters] >				



 Optional parameters: 							

 style=seismic		seismic is default here, =normal is alternate	

			(see psgraph selfdoc for style definitions)	



 nplot is the number of traces (ntr is an acceptable alias for nplot) 	



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



 See the psgraph selfdoc for the remaining parameters.			



 On NeXT:     supsgraph < infile [optional parameters]  | open      	



 Credits:



	CWP: Dave Hale and Zhiming Li (pswigp, etc.)

	   Jack Cohen and John Stockwell (supswigp, etc.)



 Notes:

	When the number of traces isn't known, we need to count

	the traces for pswigp.  You can make this value "known"

	either by getparring nplot or by having the ntr field set

	in the trace header.  A getparred value takes precedence

	over the value in the trace header.



	When we must compute ntr, we don't allocate a 2-d array,

	but just content ourselves with copying trace by trace from

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

my $supsgraph			= {
	_d1					=> '',
	_d2					=> '',
	_f1					=> '',
	_f2					=> '',
	_style					=> '',
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

	$supsgraph->{_Step}     = 'supsgraph'.$supsgraph->{_Step};
	return ( $supsgraph->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supsgraph->{_note}     = 'supsgraph'.$supsgraph->{_note};
	return ( $supsgraph->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supsgraph->{_d1}			= '';
		$supsgraph->{_d2}			= '';
		$supsgraph->{_f1}			= '';
		$supsgraph->{_f2}			= '';
		$supsgraph->{_style}			= '';
		$supsgraph->{_tmpdir}			= '';
		$supsgraph->{_verbose}			= '';
		$supsgraph->{_Step}			= '';
		$supsgraph->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$supsgraph->{_d1}		= $d1;
		$supsgraph->{_note}		= $supsgraph->{_note}.' d1='.$supsgraph->{_d1};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' d1='.$supsgraph->{_d1};

	} else { 
		print("supsgraph, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$supsgraph->{_d2}		= $d2;
		$supsgraph->{_note}		= $supsgraph->{_note}.' d2='.$supsgraph->{_d2};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' d2='.$supsgraph->{_d2};

	} else { 
		print("supsgraph, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$supsgraph->{_f1}		= $f1;
		$supsgraph->{_note}		= $supsgraph->{_note}.' f1='.$supsgraph->{_f1};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' f1='.$supsgraph->{_f1};

	} else { 
		print("supsgraph, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$supsgraph->{_f2}		= $f2;
		$supsgraph->{_note}		= $supsgraph->{_note}.' f2='.$supsgraph->{_f2};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' f2='.$supsgraph->{_f2};

	} else { 
		print("supsgraph, f2, missing f2,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$supsgraph->{_style}		= $style;
		$supsgraph->{_note}		= $supsgraph->{_note}.' style='.$supsgraph->{_style};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' style='.$supsgraph->{_style};

	} else { 
		print("supsgraph, style, missing style,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$supsgraph->{_tmpdir}		= $tmpdir;
		$supsgraph->{_note}		= $supsgraph->{_note}.' tmpdir='.$supsgraph->{_tmpdir};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' tmpdir='.$supsgraph->{_tmpdir};

	} else { 
		print("supsgraph, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supsgraph->{_verbose}		= $verbose;
		$supsgraph->{_note}		= $supsgraph->{_note}.' verbose='.$supsgraph->{_verbose};
		$supsgraph->{_Step}		= $supsgraph->{_Step}.' verbose='.$supsgraph->{_verbose};

	} else { 
		print("supsgraph, verbose, missing verbose,\n");
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
