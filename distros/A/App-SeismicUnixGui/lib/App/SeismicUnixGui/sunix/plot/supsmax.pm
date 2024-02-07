package App::SeismicUnixGui::sunix::plot::supsmax;

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
 SUPSMAX - PostScript of the MAX, min, or absolute max value on each trace

 	   of a SEGY (SU) data	set					



   supsmax <stdin >postscript file [optional parameters]		



 Optional parameters: 							

 mode=max		max value					

 			=min min value					

 			=abs absolute max value				



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

 the processing time or use d2= f2= to over-ride the header values if	

 not.									



 See the sumax selfdoc for additional parameter.			

 See the psgraph selfdoc for the remaining parameters.			





 Credits:



	CWP: John Stockwell, based on Jack Cohen's SU JACKet 



 Notes:

	When the number of traces isn't known, we need to count

	the traces for psgraph.  You can make this value "known"

	either by getparring n2 or by having the ntr field set

	in the trace header.  A getparred value takes precedence

	over the value in the trace header.



	When we do have to count the traces, we use the "tmpfile"

	routine because on many machines it is implemented

	as a memory area instead of a disk file.



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

my $supsmax			= {
	_d1					=> '',
	_d2					=> '',
	_f1					=> '',
	_f2					=> '',
	_mode					=> '',
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

	$supsmax->{_Step}     = 'supsmax'.$supsmax->{_Step};
	return ( $supsmax->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supsmax->{_note}     = 'supsmax'.$supsmax->{_note};
	return ( $supsmax->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supsmax->{_d1}			= '';
		$supsmax->{_d2}			= '';
		$supsmax->{_f1}			= '';
		$supsmax->{_f2}			= '';
		$supsmax->{_mode}			= '';
		$supsmax->{_n2}			= '';
		$supsmax->{_tmpdir}			= '';
		$supsmax->{_verbose}			= '';
		$supsmax->{_Step}			= '';
		$supsmax->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$supsmax->{_d1}		= $d1;
		$supsmax->{_note}		= $supsmax->{_note}.' d1='.$supsmax->{_d1};
		$supsmax->{_Step}		= $supsmax->{_Step}.' d1='.$supsmax->{_d1};

	} else { 
		print("supsmax, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$supsmax->{_d2}		= $d2;
		$supsmax->{_note}		= $supsmax->{_note}.' d2='.$supsmax->{_d2};
		$supsmax->{_Step}		= $supsmax->{_Step}.' d2='.$supsmax->{_d2};

	} else { 
		print("supsmax, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$supsmax->{_f1}		= $f1;
		$supsmax->{_note}		= $supsmax->{_note}.' f1='.$supsmax->{_f1};
		$supsmax->{_Step}		= $supsmax->{_Step}.' f1='.$supsmax->{_f1};

	} else { 
		print("supsmax, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$supsmax->{_f2}		= $f2;
		$supsmax->{_note}		= $supsmax->{_note}.' f2='.$supsmax->{_f2};
		$supsmax->{_Step}		= $supsmax->{_Step}.' f2='.$supsmax->{_f2};

	} else { 
		print("supsmax, f2, missing f2,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$supsmax->{_mode}		= $mode;
		$supsmax->{_note}		= $supsmax->{_note}.' mode='.$supsmax->{_mode};
		$supsmax->{_Step}		= $supsmax->{_Step}.' mode='.$supsmax->{_mode};

	} else { 
		print("supsmax, mode, missing mode,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$supsmax->{_n2}		= $n2;
		$supsmax->{_note}		= $supsmax->{_note}.' n2='.$supsmax->{_n2};
		$supsmax->{_Step}		= $supsmax->{_Step}.' n2='.$supsmax->{_n2};

	} else { 
		print("supsmax, n2, missing n2,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$supsmax->{_tmpdir}		= $tmpdir;
		$supsmax->{_note}		= $supsmax->{_note}.' tmpdir='.$supsmax->{_tmpdir};
		$supsmax->{_Step}		= $supsmax->{_Step}.' tmpdir='.$supsmax->{_tmpdir};

	} else { 
		print("supsmax, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supsmax->{_verbose}		= $verbose;
		$supsmax->{_note}		= $supsmax->{_note}.' verbose='.$supsmax->{_verbose};
		$supsmax->{_Step}		= $supsmax->{_Step}.' verbose='.$supsmax->{_verbose};

	} else { 
		print("supsmax, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
