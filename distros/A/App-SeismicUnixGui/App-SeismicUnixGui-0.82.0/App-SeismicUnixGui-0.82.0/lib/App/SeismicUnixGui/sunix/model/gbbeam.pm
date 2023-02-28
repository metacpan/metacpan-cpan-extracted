package App::SeismicUnixGui::sunix::model::gbbeam;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 GBBEAM - Gaussian beam synthetic seismograms for a sloth model 	



 gbbeam <rayends >syntraces xg= zg= [optional parameters]		



 Required Parameters:							

 xg=              x coordinates of receiver surface			

 zg=              z coordinates of receiver surface			



 Optional Parameters:							

 ng=101           number of receivers (uniform distributed along surface)

 krecord=1        integer index of receiver surface (see notes below)	

 ang=0.0          array of angles corresponding to amplitudes in amp	

 amp=1.0          array of amplitudes corresponding to angles in ang	

 bw=0             beamwidth at peak frequency				

 nt=251           number of time samples				

 dt=0.004         time sampling interval				

 ft=0.0           first time sample					

 reftrans=0       =1 complex refl/transm. coefficients considered	

 prim             =1, only single-reflected rays are considered	",     

                  =0, only direct hits are considered			

 atten=0          =1 add noncausal attenuation				

                  =2 add causal attenuation				

 lscale=          if defined restricts range of extrapolation		

 aperture=        maximum angle of receiver aperture			

 fpeak=0.1/dt     peak frequency of ricker wavelet			

 infofile         ASCII-file to store useful information		

 NOTES:								

 Only rays that terminate with index krecord will contribute to the	

 synthetic seismograms at the receiver (xg,zg) locations.  The		

 receiver locations are determined by cubic spline interpolation	

 of the specified (xg,zg) coordinates.					







 AUTHOR:  Dave Hale, Colorado School of Mines, 02/09/91

 MODIFIED:  Andreas Rueger, Colorado School of Mines, 08/18/93

	Modifications include: 2.5-D amplitudes, computation of reflection/

			transmission losses, attenuation,

			timewindow, lscale, aperture, beam width, etc.



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

my $gbbeam			= {
	_amp					=> '',
	_ang					=> '',
	_aperture					=> '',
	_atten					=> '',
	_bw					=> '',
	_dt					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_krecord					=> '',
	_lscale					=> '',
	_ng					=> '',
	_nt					=> '',
	_prim					=> '',
	_reftrans					=> '',
	_xg					=> '',
	_zg					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$gbbeam->{_Step}     = 'gbbeam'.$gbbeam->{_Step};
	return ( $gbbeam->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$gbbeam->{_note}     = 'gbbeam'.$gbbeam->{_note};
	return ( $gbbeam->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$gbbeam->{_amp}			= '';
		$gbbeam->{_ang}			= '';
		$gbbeam->{_aperture}			= '';
		$gbbeam->{_atten}			= '';
		$gbbeam->{_bw}			= '';
		$gbbeam->{_dt}			= '';
		$gbbeam->{_fpeak}			= '';
		$gbbeam->{_ft}			= '';
		$gbbeam->{_krecord}			= '';
		$gbbeam->{_lscale}			= '';
		$gbbeam->{_ng}			= '';
		$gbbeam->{_nt}			= '';
		$gbbeam->{_prim}			= '';
		$gbbeam->{_reftrans}			= '';
		$gbbeam->{_xg}			= '';
		$gbbeam->{_zg}			= '';
		$gbbeam->{_Step}			= '';
		$gbbeam->{_note}			= '';
 }


=head2 sub amp 


=cut

 sub amp {

	my ( $self,$amp )		= @_;
	if ( $amp ne $empty_string ) {

		$gbbeam->{_amp}		= $amp;
		$gbbeam->{_note}		= $gbbeam->{_note}.' amp='.$gbbeam->{_amp};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' amp='.$gbbeam->{_amp};

	} else { 
		print("gbbeam, amp, missing amp,\n");
	 }
 }


=head2 sub ang 


=cut

 sub ang {

	my ( $self,$ang )		= @_;
	if ( $ang ne $empty_string ) {

		$gbbeam->{_ang}		= $ang;
		$gbbeam->{_note}		= $gbbeam->{_note}.' ang='.$gbbeam->{_ang};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' ang='.$gbbeam->{_ang};

	} else { 
		print("gbbeam, ang, missing ang,\n");
	 }
 }


=head2 sub aperture 


=cut

 sub aperture {

	my ( $self,$aperture )		= @_;
	if ( $aperture ne $empty_string ) {

		$gbbeam->{_aperture}		= $aperture;
		$gbbeam->{_note}		= $gbbeam->{_note}.' aperture='.$gbbeam->{_aperture};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' aperture='.$gbbeam->{_aperture};

	} else { 
		print("gbbeam, aperture, missing aperture,\n");
	 }
 }


=head2 sub atten 


=cut

 sub atten {

	my ( $self,$atten )		= @_;
	if ( $atten ne $empty_string ) {

		$gbbeam->{_atten}		= $atten;
		$gbbeam->{_note}		= $gbbeam->{_note}.' atten='.$gbbeam->{_atten};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' atten='.$gbbeam->{_atten};

	} else { 
		print("gbbeam, atten, missing atten,\n");
	 }
 }


=head2 sub bw 


=cut

 sub bw {

	my ( $self,$bw )		= @_;
	if ( $bw ne $empty_string ) {

		$gbbeam->{_bw}		= $bw;
		$gbbeam->{_note}		= $gbbeam->{_note}.' bw='.$gbbeam->{_bw};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' bw='.$gbbeam->{_bw};

	} else { 
		print("gbbeam, bw, missing bw,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$gbbeam->{_dt}		= $dt;
		$gbbeam->{_note}		= $gbbeam->{_note}.' dt='.$gbbeam->{_dt};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' dt='.$gbbeam->{_dt};

	} else { 
		print("gbbeam, dt, missing dt,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$gbbeam->{_fpeak}		= $fpeak;
		$gbbeam->{_note}		= $gbbeam->{_note}.' fpeak='.$gbbeam->{_fpeak};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' fpeak='.$gbbeam->{_fpeak};

	} else { 
		print("gbbeam, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$gbbeam->{_ft}		= $ft;
		$gbbeam->{_note}		= $gbbeam->{_note}.' ft='.$gbbeam->{_ft};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' ft='.$gbbeam->{_ft};

	} else { 
		print("gbbeam, ft, missing ft,\n");
	 }
 }


=head2 sub krecord 


=cut

 sub krecord {

	my ( $self,$krecord )		= @_;
	if ( $krecord ne $empty_string ) {

		$gbbeam->{_krecord}		= $krecord;
		$gbbeam->{_note}		= $gbbeam->{_note}.' krecord='.$gbbeam->{_krecord};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' krecord='.$gbbeam->{_krecord};

	} else { 
		print("gbbeam, krecord, missing krecord,\n");
	 }
 }


=head2 sub lscale 


=cut

 sub lscale {

	my ( $self,$lscale )		= @_;
	if ( $lscale ne $empty_string ) {

		$gbbeam->{_lscale}		= $lscale;
		$gbbeam->{_note}		= $gbbeam->{_note}.' lscale='.$gbbeam->{_lscale};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' lscale='.$gbbeam->{_lscale};

	} else { 
		print("gbbeam, lscale, missing lscale,\n");
	 }
 }


=head2 sub ng 


=cut

 sub ng {

	my ( $self,$ng )		= @_;
	if ( $ng ne $empty_string ) {

		$gbbeam->{_ng}		= $ng;
		$gbbeam->{_note}		= $gbbeam->{_note}.' ng='.$gbbeam->{_ng};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' ng='.$gbbeam->{_ng};

	} else { 
		print("gbbeam, ng, missing ng,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$gbbeam->{_nt}		= $nt;
		$gbbeam->{_note}		= $gbbeam->{_note}.' nt='.$gbbeam->{_nt};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' nt='.$gbbeam->{_nt};

	} else { 
		print("gbbeam, nt, missing nt,\n");
	 }
 }


=head2 sub prim 


=cut

 sub prim {

	my ( $self,$prim )		= @_;
	if ( $prim ne $empty_string ) {

		$gbbeam->{_prim}		= $prim;
		$gbbeam->{_note}		= $gbbeam->{_note}.' prim='.$gbbeam->{_prim};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' prim='.$gbbeam->{_prim};

	} else { 
		print("gbbeam, prim, missing prim,\n");
	 }
 }


=head2 sub reftrans 


=cut

 sub reftrans {

	my ( $self,$reftrans )		= @_;
	if ( $reftrans ne $empty_string ) {

		$gbbeam->{_reftrans}		= $reftrans;
		$gbbeam->{_note}		= $gbbeam->{_note}.' reftrans='.$gbbeam->{_reftrans};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' reftrans='.$gbbeam->{_reftrans};

	} else { 
		print("gbbeam, reftrans, missing reftrans,\n");
	 }
 }


=head2 sub xg 


=cut

 sub xg {

	my ( $self,$xg )		= @_;
	if ( $xg ne $empty_string ) {

		$gbbeam->{_xg}		= $xg;
		$gbbeam->{_note}		= $gbbeam->{_note}.' xg='.$gbbeam->{_xg};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' xg='.$gbbeam->{_xg};

	} else { 
		print("gbbeam, xg, missing xg,\n");
	 }
 }


=head2 sub zg 


=cut

 sub zg {

	my ( $self,$zg )		= @_;
	if ( $zg ne $empty_string ) {

		$gbbeam->{_zg}		= $zg;
		$gbbeam->{_note}		= $gbbeam->{_note}.' zg='.$gbbeam->{_zg};
		$gbbeam->{_Step}		= $gbbeam->{_Step}.' zg='.$gbbeam->{_zg};

	} else { 
		print("gbbeam, zg, missing zg,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 15;

    return($max_index);
}
 
 
1;
