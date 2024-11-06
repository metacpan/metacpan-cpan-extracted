package App::SeismicUnixGui::sunix::header::suresstat;

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
 SURESSTAT - Surface consistent source and receiver statics calculation



   suresstat <stdin [optional parameters]				



 Required parameters: 							

 ssol=		output file source statics				

 rsol=		output file receiver statics				

 ntraces=	number of traces in input data set (must be correct!)	



 Optional parameters:							

 ntpick=50 	maximum static shift (samples)         			

 niter=5 	number of iterations					

 nshot=240 	largest shot number (fldr=1 to nshot)			

 nr=335 	largest receiver number (tracf=1 to nr)			

 nc=574 	maximum number of cmp's (for array allocation)		

 sfold=96 	maximum shot gather fold				

 rfold=96 	maximum receiver gather fold				

 cfold=48 	maximum cmp gather fold					

 sub=0 	subtract super trace 1 from super trace 2 (=1)		

 		sub=0 strongly biases static to a value of 0		

 mode=0 	use global maximum in cross-correllation window		

		=1 choose the peak perc=percent smaller than the global max.

 perc=10. 	percent of global max (used only for mode=1)		

 verbose=0 	print diagnostic output (verbose=1)                     



 Notes:								

 Estimates surface-consistent source and receiver statics, meaning that

 there is one static correction value estimated for each shot and receiver

 position.								



 The method employed here is based on the method of Ronen and Claerbout:

 Geophysics 50, 2759-2767 (1985).					



 The output files are binary files containing the source and receiver	

 statics, as a function of shot number (trace header fldr) and      	

 receiver station number (trace header tracf). 			



 The code builds a supertrace1 and supertrace2, which are subsequently	

 cross-correllated. The program then picks the time lag associated with

 the largest peak in the cross-correllation according to two possible	

 criteria set by the parameter "mode". If mode=0, the maximum of the	

 cross-correllation window is chosen. If mode=1, the program will pick 

 a peak which is up to perc=percent smaller than the global maximum, but

 closer to zero lag than the global maximum.	(Choosing mode=0 is	

 recommended.)								



 The geometry can be irregular: the program simply computes a static 	

 correction for each shot record (fldr=1 to fldr=nshot), with any missing 

 shots being assigned a static of 0.  A static correction for each    	

 receiver station (tracf=1 to tracf=nr) is calculated, with missing    

 receivers again assigned a static of 0.                               ", 



 The ntracesces parameter must be equal to the number of prestack traces.

 The ntpick parameter sets the maximum allowable shift desired (in	

   samples NOT time).							

 The niter parameter sets the number of iterations desired.		

 The nshot parameter must be equal to the maximum fldr number in	

     the data. Note that this number might be different from the actual

     number of shot records in the data (i.e., the maximum ep number).	

     For getting the correct maximum fldr number, you may use the surange

     command.								

 The nr parameter must be equal to the largest number of receivers	

     per shot in the whole data.					

 The nc parameter must be equal to the number of prestack traces in	

     the data.								

 The sfold parameter must be equal to the nr parameter.		

 The rfold parameter must be equal to the maximum ep number.		

 The cfold parameter must be equal to the maximum CDP fold,		

     which is equal to the maximum number under the cdpt entry in the	

     output of the surange command.					



 To apply the static corrections, use sustatic with hdrs=3		



 Reference:



  Ronen, J. and Claerbout, J., 1985, Surface-consistent residual statics

      estimation  by stack-power maximization: Geophysics, vol. 50,

      2759-2767.



 Credits:

	CWP: Timo Tjan, 4 October 1994



      rewritten by Thomas Pratt, USGS, Feb. 2000.



 Trace header fields accessed: ns, dt, tracf, fldr, cdp



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

my $suresstat			= {
	_cfold					=> '',
	_fldr					=> '',
	_hdrs					=> '',
	_mode					=> '',
	_nc					=> '',
	_niter					=> '',
	_nr					=> '',
	_nshot					=> '',
	_ntpick					=> '',
	_ntraces					=> '',
	_perc					=> '',
	_rfold					=> '',
	_rsol					=> '',
	_sfold					=> '',
	_ssol					=> '',
	_sub					=> '',
	_tracf					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suresstat->{_Step}     = 'suresstat'.$suresstat->{_Step};
	return ( $suresstat->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suresstat->{_note}     = 'suresstat'.$suresstat->{_note};
	return ( $suresstat->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suresstat->{_cfold}			= '';
		$suresstat->{_fldr}			= '';
		$suresstat->{_hdrs}			= '';
		$suresstat->{_mode}			= '';
		$suresstat->{_nc}			= '';
		$suresstat->{_niter}			= '';
		$suresstat->{_nr}			= '';
		$suresstat->{_nshot}			= '';
		$suresstat->{_ntpick}			= '';
		$suresstat->{_ntraces}			= '';
		$suresstat->{_perc}			= '';
		$suresstat->{_rfold}			= '';
		$suresstat->{_rsol}			= '';
		$suresstat->{_sfold}			= '';
		$suresstat->{_ssol}			= '';
		$suresstat->{_sub}			= '';
		$suresstat->{_tracf}			= '';
		$suresstat->{_verbose}			= '';
		$suresstat->{_Step}			= '';
		$suresstat->{_note}			= '';
 }


=head2 sub cfold 


=cut

 sub cfold {

	my ( $self,$cfold )		= @_;
	if ( $cfold ne $empty_string ) {

		$suresstat->{_cfold}		= $cfold;
		$suresstat->{_note}		= $suresstat->{_note}.' cfold='.$suresstat->{_cfold};
		$suresstat->{_Step}		= $suresstat->{_Step}.' cfold='.$suresstat->{_cfold};

	} else { 
		print("suresstat, cfold, missing cfold,\n");
	 }
 }


=head2 sub fldr 


=cut

 sub fldr {

	my ( $self,$fldr )		= @_;
	if ( $fldr ne $empty_string ) {

		$suresstat->{_fldr}		= $fldr;
		$suresstat->{_note}		= $suresstat->{_note}.' fldr='.$suresstat->{_fldr};
		$suresstat->{_Step}		= $suresstat->{_Step}.' fldr='.$suresstat->{_fldr};

	} else { 
		print("suresstat, fldr, missing fldr,\n");
	 }
 }


=head2 sub hdrs 


=cut

 sub hdrs {

	my ( $self,$hdrs )		= @_;
	if ( $hdrs ne $empty_string ) {

		$suresstat->{_hdrs}		= $hdrs;
		$suresstat->{_note}		= $suresstat->{_note}.' hdrs='.$suresstat->{_hdrs};
		$suresstat->{_Step}		= $suresstat->{_Step}.' hdrs='.$suresstat->{_hdrs};

	} else { 
		print("suresstat, hdrs, missing hdrs,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$suresstat->{_mode}		= $mode;
		$suresstat->{_note}		= $suresstat->{_note}.' mode='.$suresstat->{_mode};
		$suresstat->{_Step}		= $suresstat->{_Step}.' mode='.$suresstat->{_mode};

	} else { 
		print("suresstat, mode, missing mode,\n");
	 }
 }


=head2 sub nc 


=cut

 sub nc {

	my ( $self,$nc )		= @_;
	if ( $nc ne $empty_string ) {

		$suresstat->{_nc}		= $nc;
		$suresstat->{_note}		= $suresstat->{_note}.' nc='.$suresstat->{_nc};
		$suresstat->{_Step}		= $suresstat->{_Step}.' nc='.$suresstat->{_nc};

	} else { 
		print("suresstat, nc, missing nc,\n");
	 }
 }


=head2 sub niter 


=cut

 sub niter {

	my ( $self,$niter )		= @_;
	if ( $niter ne $empty_string ) {

		$suresstat->{_niter}		= $niter;
		$suresstat->{_note}		= $suresstat->{_note}.' niter='.$suresstat->{_niter};
		$suresstat->{_Step}		= $suresstat->{_Step}.' niter='.$suresstat->{_niter};

	} else { 
		print("suresstat, niter, missing niter,\n");
	 }
 }


=head2 sub nr 


=cut

 sub nr {

	my ( $self,$nr )		= @_;
	if ( $nr ne $empty_string ) {

		$suresstat->{_nr}		= $nr;
		$suresstat->{_note}		= $suresstat->{_note}.' nr='.$suresstat->{_nr};
		$suresstat->{_Step}		= $suresstat->{_Step}.' nr='.$suresstat->{_nr};

	} else { 
		print("suresstat, nr, missing nr,\n");
	 }
 }


=head2 sub nshot 


=cut

 sub nshot {

	my ( $self,$nshot )		= @_;
	if ( $nshot ne $empty_string ) {

		$suresstat->{_nshot}		= $nshot;
		$suresstat->{_note}		= $suresstat->{_note}.' nshot='.$suresstat->{_nshot};
		$suresstat->{_Step}		= $suresstat->{_Step}.' nshot='.$suresstat->{_nshot};

	} else { 
		print("suresstat, nshot, missing nshot,\n");
	 }
 }


=head2 sub ntpick 


=cut

 sub ntpick {

	my ( $self,$ntpick )		= @_;
	if ( $ntpick ne $empty_string ) {

		$suresstat->{_ntpick}		= $ntpick;
		$suresstat->{_note}		= $suresstat->{_note}.' ntpick='.$suresstat->{_ntpick};
		$suresstat->{_Step}		= $suresstat->{_Step}.' ntpick='.$suresstat->{_ntpick};

	} else { 
		print("suresstat, ntpick, missing ntpick,\n");
	 }
 }


=head2 sub ntraces 


=cut

 sub ntraces {

	my ( $self,$ntraces )		= @_;
	if ( $ntraces ne $empty_string ) {

		$suresstat->{_ntraces}		= $ntraces;
		$suresstat->{_note}		= $suresstat->{_note}.' ntraces='.$suresstat->{_ntraces};
		$suresstat->{_Step}		= $suresstat->{_Step}.' ntraces='.$suresstat->{_ntraces};

	} else { 
		print("suresstat, ntraces, missing ntraces,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$suresstat->{_perc}		= $perc;
		$suresstat->{_note}		= $suresstat->{_note}.' perc='.$suresstat->{_perc};
		$suresstat->{_Step}		= $suresstat->{_Step}.' perc='.$suresstat->{_perc};

	} else { 
		print("suresstat, perc, missing perc,\n");
	 }
 }


=head2 sub rfold 


=cut

 sub rfold {

	my ( $self,$rfold )		= @_;
	if ( $rfold ne $empty_string ) {

		$suresstat->{_rfold}		= $rfold;
		$suresstat->{_note}		= $suresstat->{_note}.' rfold='.$suresstat->{_rfold};
		$suresstat->{_Step}		= $suresstat->{_Step}.' rfold='.$suresstat->{_rfold};

	} else { 
		print("suresstat, rfold, missing rfold,\n");
	 }
 }


=head2 sub rsol 


=cut

 sub rsol {

	my ( $self,$rsol )		= @_;
	if ( $rsol ne $empty_string ) {

		$suresstat->{_rsol}		= $rsol;
		$suresstat->{_note}		= $suresstat->{_note}.' rsol='.$suresstat->{_rsol};
		$suresstat->{_Step}		= $suresstat->{_Step}.' rsol='.$suresstat->{_rsol};

	} else { 
		print("suresstat, rsol, missing rsol,\n");
	 }
 }


=head2 sub sfold 


=cut

 sub sfold {

	my ( $self,$sfold )		= @_;
	if ( $sfold ne $empty_string ) {

		$suresstat->{_sfold}		= $sfold;
		$suresstat->{_note}		= $suresstat->{_note}.' sfold='.$suresstat->{_sfold};
		$suresstat->{_Step}		= $suresstat->{_Step}.' sfold='.$suresstat->{_sfold};

	} else { 
		print("suresstat, sfold, missing sfold,\n");
	 }
 }


=head2 sub ssol 


=cut

 sub ssol {

	my ( $self,$ssol )		= @_;
	if ( $ssol ne $empty_string ) {

		$suresstat->{_ssol}		= $ssol;
		$suresstat->{_note}		= $suresstat->{_note}.' ssol='.$suresstat->{_ssol};
		$suresstat->{_Step}		= $suresstat->{_Step}.' ssol='.$suresstat->{_ssol};

	} else { 
		print("suresstat, ssol, missing ssol,\n");
	 }
 }


=head2 sub sub 


=cut

 sub sub {

	my ( $self,$sub )		= @_;
	if ( $sub ne $empty_string ) {

		$suresstat->{_sub}		= $sub;
		$suresstat->{_note}		= $suresstat->{_note}.' sub='.$suresstat->{_sub};
		$suresstat->{_Step}		= $suresstat->{_Step}.' sub='.$suresstat->{_sub};

	} else { 
		print("suresstat, sub, missing sub,\n");
	 }
 }


=head2 sub tracf 


=cut

 sub tracf {

	my ( $self,$tracf )		= @_;
	if ( $tracf ne $empty_string ) {

		$suresstat->{_tracf}		= $tracf;
		$suresstat->{_note}		= $suresstat->{_note}.' tracf='.$suresstat->{_tracf};
		$suresstat->{_Step}		= $suresstat->{_Step}.' tracf='.$suresstat->{_tracf};

	} else { 
		print("suresstat, tracf, missing tracf,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suresstat->{_verbose}		= $verbose;
		$suresstat->{_note}		= $suresstat->{_note}.' verbose='.$suresstat->{_verbose};
		$suresstat->{_Step}		= $suresstat->{_Step}.' verbose='.$suresstat->{_verbose};

	} else { 
		print("suresstat, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 17;

    return($max_index);
}
 
 
1;
