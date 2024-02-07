package App::SeismicUnixGui::sunix::filter::sumedian;

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
 SUMEDIAN - MEDIAN filter about a user-defined polygonal curve with	

	   the distance along the curve specified by key header word 	



 sumedian <stdin >stdout xshift= tshift= [optional parameters]		



 Required parameters:							

 xshift=               array of position values as specified by	

                       the `key' parameter				

 tshift=               array of corresponding time values (sec)	

  ... or input via files:						

 nshift=               number of x,t values defining median times	

 xfile=                file containing position values as specified by	

                       the `key' parameter				

 tfile=                file containing corresponding time values (sec)	



 Optional parameters:							

 key=tracl             Key header word specifying trace number 	

                       =offset  use trace offset instead		



 mix=.6,1,1,1,.6       array of weights for mix (weighted moving average)

 median=0              =0  for mix					

                       =1  for median filter				

 nmed=5                odd no. of traces to median filter		

 sign=-1               =-1  for upward shift				

                       =+1  for downward shift				

 subtract=1            =1  subtract filtered data from input		

                       =0  don't subtract				

 verbose=0             =1  echoes information				



 tmpdir= 	 if non-empty, use the value as a directory path	

		 prefix for storing temporary files; else if the	

	         the CWP_TMPDIR environment variable is set use		

	         its value for the path; else use tmpfile()		



 Notes: 								

 ------								

 Median filtering is a process for suppressing a particular moveout on 

 seismic sections. Its advantage over traditional dip filtering is that

 events with arbitrary moveout may be suppressed. Median filtering is	

 commonly used in up/down wavefield separation of VSP data.		



 The process generally consists of 3 steps:				

 1. A copy of the data panel is shifted such that the polygon in x,t	

    specifying moveout is flattened to horizontal. The x,t pairs are 	

    specified either by the vector xshift,tshift or by the values in	

    the datafiles xfile,tfile.	For fractional shift, the shifted data	

    is interpolated.							

 2. Then a mix (weighted moving average) is performed over the shifted	

    panel to emphasize events with the specified moveout and suppress	

    events with other moveouts.					

 3. The panel is then shifted back (and interpolated) to its original	

    moveout, and subtracted from the original data. Thus all events	

    with the user-specified moveout are removed.			



 For VSP data the following modifications are provided:		

 1. The moveout polygon in x,t is usually the first break times for	

    each trace. The parameter sign allows for downward shift in order	

    align upgoing events.						

 2. Alternative to a mix, a median filter can be applied by setting	

    the parameter median=1 and nmed= to the number of traces filtered.	

 3. By setting subtract=0 the filtered panel is only shifted back but	

    not subtracted from the original data.				



 The values of tshift are linearly interpolated for traces falling	

 between given xshift values. The tshift interpolant is extrapolated	

 to the left by the smallest time sample on the trace and to the right	

 by the last value given in the tshift array. 				



 The files tfile and xfile are files of binary (C-style) floats.	



 The number of values defined by mix=val1,val2,... determines the	

 number of traces to be averaged, the values determine the weights.	



 Caveat:								

 The median filter may perform poorly on the edges of a section.	

 Choosing larger beginning and ending mix values may help, but may	

 also introduce additional artifacts.					



 Examples:								







 Credits:



 CWP: John Stockwell, based in part on sumute, sureduce, sumix

 CENPET: Werner M. Heigl - fixed various errors, added VSP functionality



 U of Durham, UK: Richard Hobbs - fixed the program so it applies the

                                   median filter

 ideas for improvement:

	a versatile median filter needs to do:

	shift traces by fractional amounts -> needs sinc interpolation

	positive and negative shifts similar to SUSTATIC

	make subtraction of filtered events a user choice

	provide a median stack as well as a weighted average stack

 Trace header fields accessed: ns, dt, delrt, key=keyword





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

my $sumedian			= {
	_key					=> '',
	_median					=> '',
	_mix					=> '',
	_nmed					=> '',
	_nshift					=> '',
	_sign					=> '',
	_subtract					=> '',
	_tfile					=> '',
	_tmpdir					=> '',
	_tshift					=> '',
	_verbose					=> '',
	_xfile					=> '',
	_xshift					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sumedian->{_Step}     = 'sumedian'.$sumedian->{_Step};
	return ( $sumedian->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumedian->{_note}     = 'sumedian'.$sumedian->{_note};
	return ( $sumedian->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumedian->{_key}			= '';
		$sumedian->{_median}			= '';
		$sumedian->{_mix}			= '';
		$sumedian->{_nmed}			= '';
		$sumedian->{_nshift}			= '';
		$sumedian->{_sign}			= '';
		$sumedian->{_subtract}			= '';
		$sumedian->{_tfile}			= '';
		$sumedian->{_tmpdir}			= '';
		$sumedian->{_tshift}			= '';
		$sumedian->{_verbose}			= '';
		$sumedian->{_xfile}			= '';
		$sumedian->{_xshift}			= '';
		$sumedian->{_Step}			= '';
		$sumedian->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sumedian->{_key}		= $key;
		$sumedian->{_note}		= $sumedian->{_note}.' key='.$sumedian->{_key};
		$sumedian->{_Step}		= $sumedian->{_Step}.' key='.$sumedian->{_key};

	} else { 
		print("sumedian, key, missing key,\n");
	 }
 }


=head2 sub median 


=cut

 sub median {

	my ( $self,$median )		= @_;
	if ( $median ne $empty_string ) {

		$sumedian->{_median}		= $median;
		$sumedian->{_note}		= $sumedian->{_note}.' median='.$sumedian->{_median};
		$sumedian->{_Step}		= $sumedian->{_Step}.' median='.$sumedian->{_median};

	} else { 
		print("sumedian, median, missing median,\n");
	 }
 }


=head2 sub mix 


=cut

 sub mix {

	my ( $self,$mix )		= @_;
	if ( $mix ne $empty_string ) {

		$sumedian->{_mix}		= $mix;
		$sumedian->{_note}		= $sumedian->{_note}.' mix='.$sumedian->{_mix};
		$sumedian->{_Step}		= $sumedian->{_Step}.' mix='.$sumedian->{_mix};

	} else { 
		print("sumedian, mix, missing mix,\n");
	 }
 }


=head2 sub nmed 


=cut

 sub nmed {

	my ( $self,$nmed )		= @_;
	if ( $nmed ne $empty_string ) {

		$sumedian->{_nmed}		= $nmed;
		$sumedian->{_note}		= $sumedian->{_note}.' nmed='.$sumedian->{_nmed};
		$sumedian->{_Step}		= $sumedian->{_Step}.' nmed='.$sumedian->{_nmed};

	} else { 
		print("sumedian, nmed, missing nmed,\n");
	 }
 }


=head2 sub nshift 


=cut

 sub nshift {

	my ( $self,$nshift )		= @_;
	if ( $nshift ne $empty_string ) {

		$sumedian->{_nshift}		= $nshift;
		$sumedian->{_note}		= $sumedian->{_note}.' nshift='.$sumedian->{_nshift};
		$sumedian->{_Step}		= $sumedian->{_Step}.' nshift='.$sumedian->{_nshift};

	} else { 
		print("sumedian, nshift, missing nshift,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sumedian->{_sign}		= $sign;
		$sumedian->{_note}		= $sumedian->{_note}.' sign='.$sumedian->{_sign};
		$sumedian->{_Step}		= $sumedian->{_Step}.' sign='.$sumedian->{_sign};

	} else { 
		print("sumedian, sign, missing sign,\n");
	 }
 }


=head2 sub subtract 


=cut

 sub subtract {

	my ( $self,$subtract )		= @_;
	if ( $subtract ne $empty_string ) {

		$sumedian->{_subtract}		= $subtract;
		$sumedian->{_note}		= $sumedian->{_note}.' subtract='.$sumedian->{_subtract};
		$sumedian->{_Step}		= $sumedian->{_Step}.' subtract='.$sumedian->{_subtract};

	} else { 
		print("sumedian, subtract, missing subtract,\n");
	 }
 }


=head2 sub tfile 


=cut

 sub tfile {

	my ( $self,$tfile )		= @_;
	if ( $tfile ne $empty_string ) {

		$sumedian->{_tfile}		= $tfile;
		$sumedian->{_note}		= $sumedian->{_note}.' tfile='.$sumedian->{_tfile};
		$sumedian->{_Step}		= $sumedian->{_Step}.' tfile='.$sumedian->{_tfile};

	} else { 
		print("sumedian, tfile, missing tfile,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sumedian->{_tmpdir}		= $tmpdir;
		$sumedian->{_note}		= $sumedian->{_note}.' tmpdir='.$sumedian->{_tmpdir};
		$sumedian->{_Step}		= $sumedian->{_Step}.' tmpdir='.$sumedian->{_tmpdir};

	} else { 
		print("sumedian, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub tshift 


=cut

 sub tshift {

	my ( $self,$tshift )		= @_;
	if ( $tshift ne $empty_string ) {

		$sumedian->{_tshift}		= $tshift;
		$sumedian->{_note}		= $sumedian->{_note}.' tshift='.$sumedian->{_tshift};
		$sumedian->{_Step}		= $sumedian->{_Step}.' tshift='.$sumedian->{_tshift};

	} else { 
		print("sumedian, tshift, missing tshift,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumedian->{_verbose}		= $verbose;
		$sumedian->{_note}		= $sumedian->{_note}.' verbose='.$sumedian->{_verbose};
		$sumedian->{_Step}		= $sumedian->{_Step}.' verbose='.$sumedian->{_verbose};

	} else { 
		print("sumedian, verbose, missing verbose,\n");
	 }
 }


=head2 sub xfile 


=cut

 sub xfile {

	my ( $self,$xfile )		= @_;
	if ( $xfile ne $empty_string ) {

		$sumedian->{_xfile}		= $xfile;
		$sumedian->{_note}		= $sumedian->{_note}.' xfile='.$sumedian->{_xfile};
		$sumedian->{_Step}		= $sumedian->{_Step}.' xfile='.$sumedian->{_xfile};

	} else { 
		print("sumedian, xfile, missing xfile,\n");
	 }
 }


=head2 sub xshift 


=cut

 sub xshift {

	my ( $self,$xshift )		= @_;
	if ( $xshift ne $empty_string ) {

		$sumedian->{_xshift}		= $xshift;
		$sumedian->{_note}		= $sumedian->{_note}.' xshift='.$sumedian->{_xshift};
		$sumedian->{_Step}		= $sumedian->{_Step}.' xshift='.$sumedian->{_xshift};

	} else { 
		print("sumedian, xshift, missing xshift,\n");
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
