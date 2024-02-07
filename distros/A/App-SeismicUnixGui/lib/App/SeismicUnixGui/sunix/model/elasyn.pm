package App::SeismicUnixGui::sunix::model::elasyn;

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
 ELASYN - SYNthetic seismograms for triangulated elastic media		



  elasyn <rayends xg= zg= [optional parameters]			



Required Parameters:							

xg=            x coordinates of receiver surface			

zg=            z coordinates of receiver surface			



Optional Parameters:							

compon=0         horizontal and vertical component seismograms         

		  =3 vertical component (positive downwards)		

		  =1 horizontal component				

ng=101           number of receivers (uniform distributed along surface)

krecord=1        integer index of receiver surface (see notes below)	

nt=251           number of time samples				

dt=0.004         time sampling interval				

ft=0.0           first time sample					

inter=0          linear interpolation					

inter=1 (default) cross parabolic interpolation 			

reftrans=0       =1 complex refl/transm. coefficients considered 	

nameref=-1       all rays recorded at interface <krecord> considered 	",     

                 =0, only direct hits are considered  			

                 >0, only rays reflected from interface <nameref>      

lscale=          if defined restricts range of extrapolation		

fpeak=0.1/dt     peak frequency of ricker wavelet 			

infofile         ASCII-file to store useful information 		

xfile=x_compon.bin     bin-file to store x_component traces 		

zfile=z_compon.bin     bin-file to store z_component traces 		



NOTES:									

Only rays that terminate with index krecord will contribute to the	

synthetic seismograms at the receiver (xg,zg) locations.  The		

receiver locations are determined by cubic spline interpolation	

of the specified (xg,zg) coordinates.					



 Warning!!-- This version is not quite complete. There is a bug in the 

 interpolation routines that causes a segmentation violation on the last

 couple  of traces.							







 AUTHORS:  Andreas Rueger, Colorado School of Mines, 02/02/94

            Tariq Alkalifah, Colorado School of Mines, 02/02/94

	     (interpolation routines)

	     

 The program is based on :

	        gbbeam.c, Author: Andreas Rueger, 08/12/93

	       	sdbeam.c, AUTHOR Dave Hale, CSM, 02/26/91





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

my $elasyn			= {
	_compon					=> '',
	_dt					=> '',
	_fpeak					=> '',
	_ft					=> '',
	_inter					=> '',
	_krecord					=> '',
	_lscale					=> '',
	_nameref					=> '',
	_ng					=> '',
	_nt					=> '',
	_reftrans					=> '',
	_xfile					=> '',
	_xg					=> '',
	_zfile					=> '',
	_zg					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$elasyn->{_Step}     = 'elasyn'.$elasyn->{_Step};
	return ( $elasyn->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$elasyn->{_note}     = 'elasyn'.$elasyn->{_note};
	return ( $elasyn->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$elasyn->{_compon}			= '';
		$elasyn->{_dt}			= '';
		$elasyn->{_fpeak}			= '';
		$elasyn->{_ft}			= '';
		$elasyn->{_inter}			= '';
		$elasyn->{_krecord}			= '';
		$elasyn->{_lscale}			= '';
		$elasyn->{_nameref}			= '';
		$elasyn->{_ng}			= '';
		$elasyn->{_nt}			= '';
		$elasyn->{_reftrans}			= '';
		$elasyn->{_xfile}			= '';
		$elasyn->{_xg}			= '';
		$elasyn->{_zfile}			= '';
		$elasyn->{_zg}			= '';
		$elasyn->{_Step}			= '';
		$elasyn->{_note}			= '';
 }


=head2 sub compon 


=cut

 sub compon {

	my ( $self,$compon )		= @_;
	if ( $compon ne $empty_string ) {

		$elasyn->{_compon}		= $compon;
		$elasyn->{_note}		= $elasyn->{_note}.' compon='.$elasyn->{_compon};
		$elasyn->{_Step}		= $elasyn->{_Step}.' compon='.$elasyn->{_compon};

	} else { 
		print("elasyn, compon, missing compon,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$elasyn->{_dt}		= $dt;
		$elasyn->{_note}		= $elasyn->{_note}.' dt='.$elasyn->{_dt};
		$elasyn->{_Step}		= $elasyn->{_Step}.' dt='.$elasyn->{_dt};

	} else { 
		print("elasyn, dt, missing dt,\n");
	 }
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$elasyn->{_fpeak}		= $fpeak;
		$elasyn->{_note}		= $elasyn->{_note}.' fpeak='.$elasyn->{_fpeak};
		$elasyn->{_Step}		= $elasyn->{_Step}.' fpeak='.$elasyn->{_fpeak};

	} else { 
		print("elasyn, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub ft 


=cut

 sub ft {

	my ( $self,$ft )		= @_;
	if ( $ft ne $empty_string ) {

		$elasyn->{_ft}		= $ft;
		$elasyn->{_note}		= $elasyn->{_note}.' ft='.$elasyn->{_ft};
		$elasyn->{_Step}		= $elasyn->{_Step}.' ft='.$elasyn->{_ft};

	} else { 
		print("elasyn, ft, missing ft,\n");
	 }
 }


=head2 sub inter 


=cut

 sub inter {

	my ( $self,$inter )		= @_;
	if ( $inter ne $empty_string ) {

		$elasyn->{_inter}		= $inter;
		$elasyn->{_note}		= $elasyn->{_note}.' inter='.$elasyn->{_inter};
		$elasyn->{_Step}		= $elasyn->{_Step}.' inter='.$elasyn->{_inter};

	} else { 
		print("elasyn, inter, missing inter,\n");
	 }
 }


=head2 sub krecord 


=cut

 sub krecord {

	my ( $self,$krecord )		= @_;
	if ( $krecord ne $empty_string ) {

		$elasyn->{_krecord}		= $krecord;
		$elasyn->{_note}		= $elasyn->{_note}.' krecord='.$elasyn->{_krecord};
		$elasyn->{_Step}		= $elasyn->{_Step}.' krecord='.$elasyn->{_krecord};

	} else { 
		print("elasyn, krecord, missing krecord,\n");
	 }
 }


=head2 sub lscale 


=cut

 sub lscale {

	my ( $self,$lscale )		= @_;
	if ( $lscale ne $empty_string ) {

		$elasyn->{_lscale}		= $lscale;
		$elasyn->{_note}		= $elasyn->{_note}.' lscale='.$elasyn->{_lscale};
		$elasyn->{_Step}		= $elasyn->{_Step}.' lscale='.$elasyn->{_lscale};

	} else { 
		print("elasyn, lscale, missing lscale,\n");
	 }
 }


=head2 sub nameref 


=cut

 sub nameref {

	my ( $self,$nameref )		= @_;
	if ( $nameref ne $empty_string ) {

		$elasyn->{_nameref}		= $nameref;
		$elasyn->{_note}		= $elasyn->{_note}.' nameref='.$elasyn->{_nameref};
		$elasyn->{_Step}		= $elasyn->{_Step}.' nameref='.$elasyn->{_nameref};

	} else { 
		print("elasyn, nameref, missing nameref,\n");
	 }
 }


=head2 sub ng 


=cut

 sub ng {

	my ( $self,$ng )		= @_;
	if ( $ng ne $empty_string ) {

		$elasyn->{_ng}		= $ng;
		$elasyn->{_note}		= $elasyn->{_note}.' ng='.$elasyn->{_ng};
		$elasyn->{_Step}		= $elasyn->{_Step}.' ng='.$elasyn->{_ng};

	} else { 
		print("elasyn, ng, missing ng,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$elasyn->{_nt}		= $nt;
		$elasyn->{_note}		= $elasyn->{_note}.' nt='.$elasyn->{_nt};
		$elasyn->{_Step}		= $elasyn->{_Step}.' nt='.$elasyn->{_nt};

	} else { 
		print("elasyn, nt, missing nt,\n");
	 }
 }


=head2 sub reftrans 


=cut

 sub reftrans {

	my ( $self,$reftrans )		= @_;
	if ( $reftrans ne $empty_string ) {

		$elasyn->{_reftrans}		= $reftrans;
		$elasyn->{_note}		= $elasyn->{_note}.' reftrans='.$elasyn->{_reftrans};
		$elasyn->{_Step}		= $elasyn->{_Step}.' reftrans='.$elasyn->{_reftrans};

	} else { 
		print("elasyn, reftrans, missing reftrans,\n");
	 }
 }


=head2 sub xfile 


=cut

 sub xfile {

	my ( $self,$xfile )		= @_;
	if ( $xfile ne $empty_string ) {

		$elasyn->{_xfile}		= $xfile;
		$elasyn->{_note}		= $elasyn->{_note}.' xfile='.$elasyn->{_xfile};
		$elasyn->{_Step}		= $elasyn->{_Step}.' xfile='.$elasyn->{_xfile};

	} else { 
		print("elasyn, xfile, missing xfile,\n");
	 }
 }


=head2 sub xg 


=cut

 sub xg {

	my ( $self,$xg )		= @_;
	if ( $xg ne $empty_string ) {

		$elasyn->{_xg}		= $xg;
		$elasyn->{_note}		= $elasyn->{_note}.' xg='.$elasyn->{_xg};
		$elasyn->{_Step}		= $elasyn->{_Step}.' xg='.$elasyn->{_xg};

	} else { 
		print("elasyn, xg, missing xg,\n");
	 }
 }


=head2 sub zfile 


=cut

 sub zfile {

	my ( $self,$zfile )		= @_;
	if ( $zfile ne $empty_string ) {

		$elasyn->{_zfile}		= $zfile;
		$elasyn->{_note}		= $elasyn->{_note}.' zfile='.$elasyn->{_zfile};
		$elasyn->{_Step}		= $elasyn->{_Step}.' zfile='.$elasyn->{_zfile};

	} else { 
		print("elasyn, zfile, missing zfile,\n");
	 }
 }


=head2 sub zg 


=cut

 sub zg {

	my ( $self,$zg )		= @_;
	if ( $zg ne $empty_string ) {

		$elasyn->{_zg}		= $zg;
		$elasyn->{_note}		= $elasyn->{_note}.' zg='.$elasyn->{_zg};
		$elasyn->{_Step}		= $elasyn->{_Step}.' zg='.$elasyn->{_zg};

	} else { 
		print("elasyn, zg, missing zg,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 14;

    return($max_index);
}
 
 
1;
