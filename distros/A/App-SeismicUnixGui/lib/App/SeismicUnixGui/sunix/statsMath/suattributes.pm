package App::SeismicUnixGui::sunix::statsMath::suattributes;

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
 SUATTRIBUTES - instantaneous trace ATTRIBUTES 			



 suattributes <stdin >stdout mode=amp					



 Required parameters:							

 	none								



 Optional parameter:							

 	mode=amp	output flag 					

 	       		=amp envelope traces				

 	       		=phase phase traces				

 	       		=freq frequency traces				

			=bandwith Instantaneous bandwidth		

			=normamp Normalized Phase (Cosine Phase)	

 	       		=fdenv 1st envelope traces derivative		

 	       		=sdenv 2nd envelope traces derivative		

 	       		=q Ins. Q Factor				

 ... unwrapping related options ....					

	unwrap=		default unwrap=0 for mode=phase			

 			default unwrap=1 for freq, uphase, freqw, Q	

 			dphase_min=PI/unwrap				

       trend=0		=1 remove the linear trend of the inst. phase	

 	zeromean=0	=1 assume instantaneous phase is zero mean	



			=freqw Frequency Weighted Envelope		

			=thin  Thin-Bed (inst. freq - average freq)	

	wint=		windowing for freqw				

			windowing for thin				

			default=1 					

 			o--------o--------o				

 			data-1	data	data+1				



 Notes:								

 This program performs complex trace attribute analysis. The first three

 attributes, amp,phase,freq are the classical Taner, Kohler, and	

 Sheriff, 1979.							



 The unwrapping algorithm is the "simple" unwrapping algorithm that	

 searches for jumps in phase.						



 The quantity dphase_min is the minimum change in the phase angle taken

 to be the result of phase wrapping, rather than natural phase	 

 variation in the data. Setting unwrap=0 turns off phase-unwrapping	

 alltogether. Choosing  unwrap > 1 makes the unwrapping function more	

 sensitive to instantaneous phase changes.				

 Setting unwrap > 1 may be necessary to resolve higher frequencies in	

 data (or sample data more finely).					



 Examples:								

 suvibro f1=10 f2=50 t1=0 t2=0 tv=1 | suattributes2 mode=amp | ...	

 suvibro f1=10 f2=50 t1=0 t2=0 tv=1 | suattributes2 mode=phase | ...	

 suvibro f1=10 f2=50 t1=0 t2=0 tv=1 | suattributes2 mode=freq | ...	

 suplane | suattributes mode=... | supswigb |...       		





 Credits:

	CWP: Jack K. Cohen

      CWP: John Stockwell (added freq and unwrap features)

	UGM (Geophysics Students): Agung Wiyono

	   email:aakanjas@gmail.com (others) added more attributes

					



 Algorithm:

	c(t) = hilbert_tranform_kernel(t) convolved with data(t)  



  amp(t) = sqrt( c.re^2(t) + c.im^2(t))

  phase(t) = arctan( c.im(t)/c.re(t))

  freq(t) = d(phase)/dt



 Reference: Taner, M. T., Koehler, A. F., and  Sheriff R. E.

 "Complex seismic trace analysis", Geophysics,  vol.44, p. 1041-1063, 1979



 Trace header fields accessed: ns, trid

 Trace header fields modified: d1, trid





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

my $suattributes			= {
	_default					=> '',
	_dphase_min					=> '',
	_f1					=> '',
	_mode					=> '',
	_trend					=> '',
	_unwrap					=> '',
	_wint					=> '',
	_zeromean					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suattributes->{_Step}     = 'suattributes'.$suattributes->{_Step};
	return ( $suattributes->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suattributes->{_note}     = 'suattributes'.$suattributes->{_note};
	return ( $suattributes->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suattributes->{_default}			= '';
		$suattributes->{_dphase_min}			= '';
		$suattributes->{_f1}			= '';
		$suattributes->{_mode}			= '';
		$suattributes->{_trend}			= '';
		$suattributes->{_unwrap}			= '';
		$suattributes->{_wint}			= '';
		$suattributes->{_zeromean}			= '';
		$suattributes->{_Step}			= '';
		$suattributes->{_note}			= '';
 }


=head2 sub default 


=cut

 sub default {

	my ( $self,$default )		= @_;
	if ( $default ne $empty_string ) {

		$suattributes->{_default}		= $default;
		$suattributes->{_note}		= $suattributes->{_note}.' default='.$suattributes->{_default};
		$suattributes->{_Step}		= $suattributes->{_Step}.' default='.$suattributes->{_default};

	} else { 
		print("suattributes, default, missing default,\n");
	 }
 }


=head2 sub dphase_min 


=cut

 sub dphase_min {

	my ( $self,$dphase_min )		= @_;
	if ( $dphase_min ne $empty_string ) {

		$suattributes->{_dphase_min}		= $dphase_min;
		$suattributes->{_note}		= $suattributes->{_note}.' dphase_min='.$suattributes->{_dphase_min};
		$suattributes->{_Step}		= $suattributes->{_Step}.' dphase_min='.$suattributes->{_dphase_min};

	} else { 
		print("suattributes, dphase_min, missing dphase_min,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$suattributes->{_f1}		= $f1;
		$suattributes->{_note}		= $suattributes->{_note}.' f1='.$suattributes->{_f1};
		$suattributes->{_Step}		= $suattributes->{_Step}.' f1='.$suattributes->{_f1};

	} else { 
		print("suattributes, f1, missing f1,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$suattributes->{_mode}		= $mode;
		$suattributes->{_note}		= $suattributes->{_note}.' mode='.$suattributes->{_mode};
		$suattributes->{_Step}		= $suattributes->{_Step}.' mode='.$suattributes->{_mode};

	} else { 
		print("suattributes, mode, missing mode,\n");
	 }
 }


=head2 sub trend 


=cut

 sub trend {

	my ( $self,$trend )		= @_;
	if ( $trend ne $empty_string ) {

		$suattributes->{_trend}		= $trend;
		$suattributes->{_note}		= $suattributes->{_note}.' trend='.$suattributes->{_trend};
		$suattributes->{_Step}		= $suattributes->{_Step}.' trend='.$suattributes->{_trend};

	} else { 
		print("suattributes, trend, missing trend,\n");
	 }
 }


=head2 sub unwrap 


=cut

 sub unwrap {

	my ( $self,$unwrap )		= @_;
	if ( $unwrap ne $empty_string ) {

		$suattributes->{_unwrap}		= $unwrap;
		$suattributes->{_note}		= $suattributes->{_note}.' unwrap='.$suattributes->{_unwrap};
		$suattributes->{_Step}		= $suattributes->{_Step}.' unwrap='.$suattributes->{_unwrap};

	} else { 
		print("suattributes, unwrap, missing unwrap,\n");
	 }
 }


=head2 sub wint 


=cut

 sub wint {

	my ( $self,$wint )		= @_;
	if ( $wint ne $empty_string ) {

		$suattributes->{_wint}		= $wint;
		$suattributes->{_note}		= $suattributes->{_note}.' wint='.$suattributes->{_wint};
		$suattributes->{_Step}		= $suattributes->{_Step}.' wint='.$suattributes->{_wint};

	} else { 
		print("suattributes, wint, missing wint,\n");
	 }
 }


=head2 sub zeromean 


=cut

 sub zeromean {

	my ( $self,$zeromean )		= @_;
	if ( $zeromean ne $empty_string ) {

		$suattributes->{_zeromean}		= $zeromean;
		$suattributes->{_note}		= $suattributes->{_note}.' zeromean='.$suattributes->{_zeromean};
		$suattributes->{_Step}		= $suattributes->{_Step}.' zeromean='.$suattributes->{_zeromean};

	} else { 
		print("suattributes, zeromean, missing zeromean,\n");
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
