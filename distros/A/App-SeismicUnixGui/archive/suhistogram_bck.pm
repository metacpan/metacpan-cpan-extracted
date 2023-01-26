package suhistogram;

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
 SUHISTOGRAM - create histogram of input amplitudes		



    suhistogram <in.su >out.dat				



 Required parameters:						

 min=		minimum bin 					

 max=		maximum bin 					

 bins=		number of bins					



 Optional parameters						

 trend=0	=0 1-D histogram				

	   =1 2-D histogram picks on cumulate			

	   =2 2-D histogram in trace format			



 clip=     threshold value to drop outliers			



 dt=	sample rate in feet or milliseconds.  Defaults  to	

    	tr.dt*1e-3					  	

 datum=  header key to get datum shift if desired (e.g. to	

	 hang from water bottom)			    	



 Notes:							

 trend=0 produces a two column ASCII output for use w/ gnuplot.

 Extreme values are counted in the end bins.			



 trend=1 produces a 6 column ASCII output for use w/ gnuplot   

 The columns are time/depth and picks on the cumulate		

 at 2.28%, 15.87%, 50%, 84.13% & 97.720f the total points    

 corresponding to the median and +- 1 or 2 standard deviations 

 for a Gaussian distribution.					



 trend=2 produces an SU trace panel w/ one trace per bin that  

 can be displayed w/ suximage, etc.				



 Example for plotting with xgraph:				

 suhistogram < data.su min=MIN max=MAX bins=BINS |		

 a2b n1=2 | xgraph n=BINS nplot=1			 	





 Author: Reginald H. Beardsley  2006   rhb@acm.org

 

=head2 User's notes (Juan Lorenzo)


=cut



=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use App::SeismicUnixGui::misc::L_SU_global_constants;

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use App::SeismicUnixGui::configs::big_streams::Project_config;


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

my $suhistogram			= {
	_bins					=> '',
	_clip					=> '',
	_datum					=> '',
	_dt					=> '',
	_max					=> '',
	_min					=> '',
	_n1					=> '',
	_trend					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suhistogram->{_Step}     = 'suhistogram'.$suhistogram->{_Step};
	return ( $suhistogram->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suhistogram->{_note}     = 'suhistogram'.$suhistogram->{_note};
	return ( $suhistogram->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suhistogram->{_bins}			= '';
		$suhistogram->{_clip}			= '';
		$suhistogram->{_datum}			= '';
		$suhistogram->{_dt}			= '';
		$suhistogram->{_max}			= '';
		$suhistogram->{_min}			= '';
		$suhistogram->{_n1}			= '';
		$suhistogram->{_trend}			= '';
		$suhistogram->{_Step}			= '';
		$suhistogram->{_note}			= '';
 }


=head2 sub bins 


=cut

 sub bins {

	my ( $self,$bins )		= @_;
	if ( $bins ne $empty_string ) {

		$suhistogram->{_bins}		= $bins;
		$suhistogram->{_note}		= $suhistogram->{_note}.' bins='.$suhistogram->{_bins};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' bins='.$suhistogram->{_bins};

	} else { 
		print("suhistogram, bins, missing bins,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$suhistogram->{_clip}		= $clip;
		$suhistogram->{_note}		= $suhistogram->{_note}.' clip='.$suhistogram->{_clip};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' clip='.$suhistogram->{_clip};

	} else { 
		print("suhistogram, clip, missing clip,\n");
	 }
 }


=head2 sub datum 


=cut

 sub datum {

	my ( $self,$datum )		= @_;
	if ( $datum ne $empty_string ) {

		$suhistogram->{_datum}		= $datum;
		$suhistogram->{_note}		= $suhistogram->{_note}.' datum='.$suhistogram->{_datum};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' datum='.$suhistogram->{_datum};

	} else { 
		print("suhistogram, datum, missing datum,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suhistogram->{_dt}		= $dt;
		$suhistogram->{_note}		= $suhistogram->{_note}.' dt='.$suhistogram->{_dt};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' dt='.$suhistogram->{_dt};

	} else { 
		print("suhistogram, dt, missing dt,\n");
	 }
 }


=head2 sub max 


=cut

 sub max {

	my ( $self,$max )		= @_;
	if ( $max ne $empty_string ) {

		$suhistogram->{_max}		= $max;
		$suhistogram->{_note}		= $suhistogram->{_note}.' max='.$suhistogram->{_max};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' max='.$suhistogram->{_max};

	} else { 
		print("suhistogram, max, missing max,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$suhistogram->{_min}		= $min;
		$suhistogram->{_note}		= $suhistogram->{_note}.' min='.$suhistogram->{_min};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' min='.$suhistogram->{_min};

	} else { 
		print("suhistogram, min, missing min,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$suhistogram->{_n1}		= $n1;
		$suhistogram->{_note}		= $suhistogram->{_note}.' n1='.$suhistogram->{_n1};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' n1='.$suhistogram->{_n1};

	} else { 
		print("suhistogram, n1, missing n1,\n");
	 }
 }


=head2 sub trend 


=cut

 sub trend {

	my ( $self,$trend )		= @_;
	if ( $trend ne $empty_string ) {

		$suhistogram->{_trend}		= $trend;
		$suhistogram->{_note}		= $suhistogram->{_note}.' trend='.$suhistogram->{_trend};
		$suhistogram->{_Step}		= $suhistogram->{_Step}.' trend='.$suhistogram->{_trend};

	} else { 
		print("suhistogram, trend, missing trend,\n");
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
