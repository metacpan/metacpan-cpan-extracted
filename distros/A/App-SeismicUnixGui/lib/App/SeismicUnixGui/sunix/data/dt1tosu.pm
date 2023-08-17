package App::SeismicUnixGui::sunix::data::dt1tosu;

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
 DT1TOSU - Convert ground-penetrating radar data in the	

	Sensors & Software X.DT1 GPR format to SU format.	



 dt1tosu < gpr_data_in_dt1_format  > stdout			



 Optional parameters:						

 ns=from header	number of samples per trace		

 dt=.8		time sample interval (see below)		

 swap=endian	endian is auto-determined =1 (big endian) swap	

		=0 don't swap bytes (little endian machines)	

 verbose=0	silent						

		=1 S & S header values from first trace		

			sent to outpar				

		=2 S & S header values from all traces		

			sent to outpar				

 outpar=/dev/tty	output parameter file			

 list=0	silent						

		=1 list explaining labels used in verbose	

		     is printed to stderr			



 Caution: An incorrect ns field will munge subsequent processing.



 Notes:							

 For compatiblity with SEGY header, apparent dt is set to	

 .8 ms (800 microsecs).  Actual dt is .8 nanosecs.		

 Using TRUE DISTANCES, this scales velocity			

 and frequency by a factor of 1 million.			

	Example: v_air = 9.83X10^8 ft/s	 (real)			

		 v_air = 983 ft/s	(apparent for su)	

	Example: fnyquist = 625 MHz	(real)			

		fnyquist = 625 Hz	(apparent for su)	



 IBM RS6000, NeXT, SUN are examples of big endian machines	

 PC's and DEC are examples of little endian machines		



 Caveat:							

 This program has not been tested on DEC, some modification of the

 byte swapping routines may be required.			





 Credits:

	CWP: John Stockwell, Jan 1994   Based on a code "sugpr" by

	UTULSA: Chris Liner & Bill Underwood  (Dec93)

 modifications permit S & S dt1 header information to be transferred

 directly to SU header



 March 2012: CWP John Stockwell  updated for the revised

 S&S DT1, which they still call "DT1" though it is different.



 Trace header fields set: ns, tracl, tracr, dt, delrt, trid,

			    hour, minute, second



 Reference: Sensors & Software pulseEKKO and Noggin^plus Data File

	     Formats

 Publication of:

 Sensors & Software: suburface imaging solutions

 1091 Brevik Place

 Mississauga, ON L4W 3R7 Canada

 Sensors & Software In

 Tel: (905) 624-8909

 Fax (905) 624-9365

 E-mail: sales@sensoft.ca

 Website: www.sensoft.ca


=head2 User's Notes (Juan Lorenzo)

Untested


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

my $dt1tosu			= {
	_dt					=> '',
	_fnyquist					=> '',
	_list					=> '',
	_ns					=> '',
	_outpar					=> '',
	_swap					=> '',
	_v_air					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$dt1tosu->{_Step}     = 'dt1tosu'.$dt1tosu->{_Step};
	return ( $dt1tosu->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$dt1tosu->{_note}     = 'dt1tosu'.$dt1tosu->{_note};
	return ( $dt1tosu->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$dt1tosu->{_dt}			= '';
		$dt1tosu->{_fnyquist}			= '';
		$dt1tosu->{_list}			= '';
		$dt1tosu->{_ns}			= '';
		$dt1tosu->{_outpar}			= '';
		$dt1tosu->{_swap}			= '';
		$dt1tosu->{_v_air}			= '';
		$dt1tosu->{_verbose}			= '';
		$dt1tosu->{_Step}			= '';
		$dt1tosu->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$dt1tosu->{_dt}		= $dt;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' dt='.$dt1tosu->{_dt};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' dt='.$dt1tosu->{_dt};

	} else { 
		print("dt1tosu, dt, missing dt,\n");
	 }
 }


=head2 sub fnyquist 


=cut

 sub fnyquist {

	my ( $self,$fnyquist )		= @_;
	if ( $fnyquist ne $empty_string ) {

		$dt1tosu->{_fnyquist}		= $fnyquist;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' fnyquist='.$dt1tosu->{_fnyquist};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' fnyquist='.$dt1tosu->{_fnyquist};

	} else { 
		print("dt1tosu, fnyquist, missing fnyquist,\n");
	 }
 }


=head2 sub list 


=cut

 sub list {

	my ( $self,$list )		= @_;
	if ( $list ne $empty_string ) {

		$dt1tosu->{_list}		= $list;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' list='.$dt1tosu->{_list};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' list='.$dt1tosu->{_list};

	} else { 
		print("dt1tosu, list, missing list,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$dt1tosu->{_ns}		= $ns;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' ns='.$dt1tosu->{_ns};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' ns='.$dt1tosu->{_ns};

	} else { 
		print("dt1tosu, ns, missing ns,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$dt1tosu->{_outpar}		= $outpar;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' outpar='.$dt1tosu->{_outpar};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' outpar='.$dt1tosu->{_outpar};

	} else { 
		print("dt1tosu, outpar, missing outpar,\n");
	 }
 }


=head2 sub swap 


=cut

 sub swap {

	my ( $self,$swap )		= @_;
	if ( $swap ne $empty_string ) {

		$dt1tosu->{_swap}		= $swap;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' swap='.$dt1tosu->{_swap};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' swap='.$dt1tosu->{_swap};

	} else { 
		print("dt1tosu, swap, missing swap,\n");
	 }
 }


=head2 sub v_air 


=cut

 sub v_air {

	my ( $self,$v_air )		= @_;
	if ( $v_air ne $empty_string ) {

		$dt1tosu->{_v_air}		= $v_air;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' v_air='.$dt1tosu->{_v_air};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' v_air='.$dt1tosu->{_v_air};

	} else { 
		print("dt1tosu, v_air, missing v_air,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$dt1tosu->{_verbose}		= $verbose;
		$dt1tosu->{_note}		= $dt1tosu->{_note}.' verbose='.$dt1tosu->{_verbose};
		$dt1tosu->{_Step}		= $dt1tosu->{_Step}.' verbose='.$dt1tosu->{_verbose};

	} else { 
		print("dt1tosu, verbose, missing verbose,\n");
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
