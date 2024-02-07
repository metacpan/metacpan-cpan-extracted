package App::SeismicUnixGui::sunix::data::segdread;

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
 SEGDREAD - read an SEG-D tape					



 segdread > stdout tape=						



 Required parameters:						 

	tape=	   input tape device				

 			tape=- to read from stdin			



 Optional parameters:						 

	use_stdio=0	for record devices (9-track reel tape drive)   

			=1 for pipe, disk and fixed-block 8mm drives   

	verbose=0	silent operation				

			= 1 ; echo every 'vblock' traces		

			= 2 ; echo information about blocks	    

	vblock=50	echo every 'vblock' traces under verbose option

	ptmin=1	 first shot to read				

	ptmax=INT_MAX   last shot to read				

	gain=0	  no application of gain			 

	aux=0	   no recovery of auxiliary traces		

	errmax=0	allowable number of consecutive tape IO errors 

	ns=0		override of computed ns to work around SEG-D   

			flaws.  Ignored when use_stdio=0.		

	pivot_year=30   Use current century for 2 digit yrs less than  

			pivot_year, previous century otherwise.	



	 type:   sudoc segdread   for further information		



 Credits:

  for version 1:

    IPRA, Pau, France: Dominique Rousset, rousset@iprrs1.univ-pau.fr

  for version 2.2:

    EOST, Strasbourg, France: Celine Girard

  for versions 2.3:

    EOST, Strasbourg, France: Marc Schaming, mschaming@eost.u-strasbg.fr

  for version 2.4:

    SEP, Stanford University: Stew Levin, stew@sep.stanford.edu

    a) Changed definitions of BCD_FF/BCD_FFFF

    b) Corrected decoding of general_header_1 in info_gh1.

    c) Changed buff=0 to use_stdio=1 to avoid confusion (stdio

	IS buffered I/O). Kept old buff= internally for backwards

	compatibility.

    d) Changed F8015 decoding of negative mantissas to avoid

	1 part in 2^14th decoding error on 2's complement platforms.

    e) Adapted F8015 to F0015 decoding routine. Unused, but now available.

    f) Use AT&T sfio package for tape read.

    g) Handle endian and wordsize dependencies portably (I think).

    g) Allow tape=- command line argument to accept input from stdin.

    h) Compute trace length explicitly from headers so that disk data

	input can work.

    i) Correct tape trace length calculation to account for demux

	trace header extensions.

    j) Fix a couple of typos in comments and selfdoc

    k) Added F8022 for 1 byte quaternary exponent demux.

    l) Added F8024 for 2 byte quaternary exponent demux.

    m) Added F8042 for 1 byte hexadecimal exponent demux.

    n) Added F8044 for 2 byte hexadecimal exponent demux.

    o) Added F8048 for 4 byte hexadecimal exponent demux.

    p) Added F8036 for 2 byte 2's complement integer demux.

    q) Added F8038 for 4 byte 2's complement integer demux.

    r) Added F8058 for 4 byte IEEE float demux.

    s) Added ns= parameter to work around bad SEG-D trace

	length specifications in headers.

  for version 2.5:

    SEP, Stanford University: Stew Levin, stew@sep.stanford.edu

    a) Added pivot_year to disambiguate decoding of 2-digit yrs

    b) Modified decode of 2-byte BCD to avoid endian problems

    c) Modified debug printout to fix endian BCD display problems

    d) Don't let dem_trace_header override ns specified on command line

    e) Removed extra factor of two in decoding of general_header_1.r

    f) Removed conditional disabling of sfio

  for version 2.6:

    SEP, Stanford University: Stew Levin, stew@sep.stanford.edu

    a) tightened test for Sercel 358

    b) modified 8015 conversion to handle Sercel 358/368 misuse of

	two's complement instead of one's complement.



--------------------------------------------------------------------

 SEGDREAD: Version 2.1, 10/10/94

	   Version 2.2, 17/08/95

	   Version 2.3, 04/1997 Thu Apr 10 11:55:45 DFT 1997

	   Version 2.4, 10/03/98 Tue Mar 10 1998

	   Version 2.5, Feb 4, 2001

	   Version 2.6, May 26, 2009

--------------------------------------------------------------------



=head2 User's notes (Juan Lorenzo)
untested

 Example:
 $segdread->clear();
 $segdread->tape($segdread_inbound[1]);
 $segdread->verbose(1);
 $segdread->ptmax(1);
 $segdread->aux(0);
 $segdread->use_stdio(1);
 $segdread[1] = $segdread->Step();

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
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

my $segdread			= {
	_aux					=> '',
	_buff					=> '',
	_errmax					=> '',
	_gain					=> '',
	_ns					=> '',
	_pivot_year					=> '',
	_ptmax					=> '',
	_ptmin					=> '',
	_tape					=> '',
	_use_stdio					=> '',
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

	$segdread->{_Step}     = 'segdread'.$segdread->{_Step};
	return ( $segdread->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$segdread->{_note}     = 'segdread'.$segdread->{_note};
	return ( $segdread->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$segdread->{_aux}			= '';
		$segdread->{_buff}			= '';
		$segdread->{_errmax}			= '';
		$segdread->{_gain}			= '';
		$segdread->{_ns}			= '';
		$segdread->{_pivot_year}			= '';
		$segdread->{_ptmax}			= '';
		$segdread->{_ptmin}			= '';
		$segdread->{_tape}			= '';
		$segdread->{_use_stdio}			= '';
		$segdread->{_vblock}			= '';
		$segdread->{_verbose}			= '';
		$segdread->{_Step}			= '';
		$segdread->{_note}			= '';
 }


=head2 sub aux 


=cut

 sub aux {

	my ( $self,$aux )		= @_;
	if ( $aux ne $empty_string ) {

		$segdread->{_aux}		= $aux;
		$segdread->{_note}		= $segdread->{_note}.' aux='.$segdread->{_aux};
		$segdread->{_Step}		= $segdread->{_Step}.' aux='.$segdread->{_aux};

	} else { 
		print("segdread, aux, missing aux,\n");
	 }
 }


=head2 sub buff 


=cut

 sub buff {

	my ( $self,$buff )		= @_;
	if ( $buff ne $empty_string ) {

		$segdread->{_buff}		= $buff;
		$segdread->{_note}		= $segdread->{_note}.' buff='.$segdread->{_buff};
		$segdread->{_Step}		= $segdread->{_Step}.' buff='.$segdread->{_buff};

	} else { 
		print("segdread, buff, missing buff,\n");
	 }
 }


=head2 sub errmax 


=cut

 sub errmax {

	my ( $self,$errmax )		= @_;
	if ( $errmax ne $empty_string ) {

		$segdread->{_errmax}		= $errmax;
		$segdread->{_note}		= $segdread->{_note}.' errmax='.$segdread->{_errmax};
		$segdread->{_Step}		= $segdread->{_Step}.' errmax='.$segdread->{_errmax};

	} else { 
		print("segdread, errmax, missing errmax,\n");
	 }
 }


=head2 sub gain 


=cut

 sub gain {

	my ( $self,$gain )		= @_;
	if ( $gain ne $empty_string ) {

		$segdread->{_gain}		= $gain;
		$segdread->{_note}		= $segdread->{_note}.' gain='.$segdread->{_gain};
		$segdread->{_Step}		= $segdread->{_Step}.' gain='.$segdread->{_gain};

	} else { 
		print("segdread, gain, missing gain,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$segdread->{_ns}		= $ns;
		$segdread->{_note}		= $segdread->{_note}.' ns='.$segdread->{_ns};
		$segdread->{_Step}		= $segdread->{_Step}.' ns='.$segdread->{_ns};

	} else { 
		print("segdread, ns, missing ns,\n");
	 }
 }


=head2 sub pivot_year 


=cut

 sub pivot_year {

	my ( $self,$pivot_year )		= @_;
	if ( $pivot_year ne $empty_string ) {

		$segdread->{_pivot_year}		= $pivot_year;
		$segdread->{_note}		= $segdread->{_note}.' pivot_year='.$segdread->{_pivot_year};
		$segdread->{_Step}		= $segdread->{_Step}.' pivot_year='.$segdread->{_pivot_year};

	} else { 
		print("segdread, pivot_year, missing pivot_year,\n");
	 }
 }


=head2 sub ptmax 


=cut

 sub ptmax {

	my ( $self,$ptmax )		= @_;
	if ( $ptmax ne $empty_string ) {

		$segdread->{_ptmax}		= $ptmax;
		$segdread->{_note}		= $segdread->{_note}.' ptmax='.$segdread->{_ptmax};
		$segdread->{_Step}		= $segdread->{_Step}.' ptmax='.$segdread->{_ptmax};

	} else { 
		print("segdread, ptmax, missing ptmax,\n");
	 }
 }


=head2 sub ptmin 


=cut

 sub ptmin {

	my ( $self,$ptmin )		= @_;
	if ( $ptmin ne $empty_string ) {

		$segdread->{_ptmin}		= $ptmin;
		$segdread->{_note}		= $segdread->{_note}.' ptmin='.$segdread->{_ptmin};
		$segdread->{_Step}		= $segdread->{_Step}.' ptmin='.$segdread->{_ptmin};

	} else { 
		print("segdread, ptmin, missing ptmin,\n");
	 }
 }


=head2 sub tape 


=cut

 sub tape {

    my ( $self, $tape ) = @_;
    if ( $tape ne $empty_string ) {

        use App::SeismicUnixGui::misc::SeismicUnix qw($suffix_segd);
        use File::Basename;
        my ($DATA_SEISMIC_SEGD) = $Project->DATA_SEISMIC_SEGD();
        my $new_file_name = $tape;

        # force correct suffix
        $new_file_name = basename($tape) . $suffix_segd;

        # print("1. segyread,tape, new_file_name= $new_file_name\n");

        $segdread->{_tape} = $DATA_SEISMIC_SEGD . '/' . $new_file_name;

        $segdread->{_note} =
          $segdread->{_note} . ' tape=' . $segdread->{_tape};
        $segdread->{_Step} =
          $segdread->{_Step} . ' tape=' . $segdread->{_tape};

    }
    else {
        print("segyread, tape, missing tape,\n");
    }
}

=head2 sub use_stdio 


=cut

 sub use_stdio {

	my ( $self,$use_stdio )		= @_;
	if ( $use_stdio ne $empty_string ) {

		$segdread->{_use_stdio}		= $use_stdio;
		$segdread->{_note}		= $segdread->{_note}.' use_stdio='.$segdread->{_use_stdio};
		$segdread->{_Step}		= $segdread->{_Step}.' use_stdio='.$segdread->{_use_stdio};

	} else { 
		print("segdread, use_stdio, missing use_stdio,\n");
	 }
 }


=head2 sub vblock 


=cut

 sub vblock {

	my ( $self,$vblock )		= @_;
	if ( $vblock ne $empty_string ) {

		$segdread->{_vblock}		= $vblock;
		$segdread->{_note}		= $segdread->{_note}.' vblock='.$segdread->{_vblock};
		$segdread->{_Step}		= $segdread->{_Step}.' vblock='.$segdread->{_vblock};

	} else { 
		print("segdread, vblock, missing vblock,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$segdread->{_verbose}		= $verbose;
		$segdread->{_note}		= $segdread->{_note}.' verbose='.$segdread->{_verbose};
		$segdread->{_Step}		= $segdread->{_Step}.' verbose='.$segdread->{_verbose};

	} else { 
		print("segdread, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 11;

    return($max_index);
}
 
 
1;
