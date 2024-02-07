package App::SeismicUnixGui::sunix::filter::sueipofi;

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
 SUEIPOFI - EIgenimage (SVD) based POlarization FIlter for             

            three-component data                                       



 sueipofi <stdin >stdout [optional parameters]                         



 Required parameters:                                                  

    none                                                               



 Optional parameters:                                                  

    dt=(from header)  time sampling intervall in seconds               

    wl=0.1            SVD time window length in seconds                

    pwr=1.0           exponent of filter weights                       

    interp=cubic      interpolation between initially calculated       

                      weights, choose "cubic" or "linear

    verbose=0         1 = echo additional information                  



    file=polar        base name for additional output file(s) of       

                      filter weights (see flags below)                 

    rl1=0             1 = rectilinearity along first principal axis    

    rl2=0             1 = rectilinearity along second principal axis   

    pln=0             1 = planarity                                    





 Notes:                                                                

    Three adjacent traces are considered as one three-component        

    dataset.                                                           



    The filter is the sum of the first two eigenimages of the singular 

    value decomposition (SVD) of the signal matrix (time window).      

    Weighting functions depending on linearity and planarity of the    

    signal are applied, additionally. To avoid edge effects, these are 

    interpolated linearily or via cubic splines between initially      

    calculated values of non-overlapping time windows.                 

    The algorithm is based on the assumption that the particle motion  

    trajectory is essentially 2D (elliptical polarization).            



 Caveat:                                                               

    Cubic spline interpolation may result in filter weights exceeding  

    the set of values of initial weights. Weights outside the valid    

    interval [0.0, 1.0] are clipped.                                   





 

 Author: Nils Maercklin, 

         GeoForschungsZentrum (GFZ) Potsdam, Germany, 2001.

         E-mail: nils@gfz-potsdam.de





 References:

    Franco, R. de, and Musacchio, G., 2000: Polarization Filter with

       Singular Value Decomposition, submitted to Geophysics and

       published electronically in Geophysics online (www.geo-online.org).

    Jurkevics, A., 1988: Polarization analysis of three-comomponent

       array data, Bulletin of the Seismological Society of America, 

       vol. 78, no. 5.

    Press, W. H., Teukolsky, S. A., Vetterling, W. T., and Flannery, B. P.

       1996: Numerical Recipes in C - The Art of Scientific Computing,

       Cambridge University Press, Cambridge.



 Trace header fields accessed: ns, dt

 Trace header fields modified: none



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

my $sueipofi			= {
	_dt					=> '',
	_file					=> '',
	_interp					=> '',
	_pln					=> '',
	_pwr					=> '',
	_rl1					=> '',
	_rl2					=> '',
	_verbose					=> '',
	_wl					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sueipofi->{_Step}     = 'sueipofi'.$sueipofi->{_Step};
	return ( $sueipofi->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sueipofi->{_note}     = 'sueipofi'.$sueipofi->{_note};
	return ( $sueipofi->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sueipofi->{_dt}			= '';
		$sueipofi->{_file}			= '';
		$sueipofi->{_interp}			= '';
		$sueipofi->{_pln}			= '';
		$sueipofi->{_pwr}			= '';
		$sueipofi->{_rl1}			= '';
		$sueipofi->{_rl2}			= '';
		$sueipofi->{_verbose}			= '';
		$sueipofi->{_wl}			= '';
		$sueipofi->{_Step}			= '';
		$sueipofi->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sueipofi->{_dt}		= $dt;
		$sueipofi->{_note}		= $sueipofi->{_note}.' dt='.$sueipofi->{_dt};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' dt='.$sueipofi->{_dt};

	} else { 
		print("sueipofi, dt, missing dt,\n");
	 }
 }


=head2 sub file 


=cut

 sub file {

	my ( $self,$file )		= @_;
	if ( $file ne $empty_string ) {

		$sueipofi->{_file}		= $file;
		$sueipofi->{_note}		= $sueipofi->{_note}.' file='.$sueipofi->{_file};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' file='.$sueipofi->{_file};

	} else { 
		print("sueipofi, file, missing file,\n");
	 }
 }


=head2 sub interp 


=cut

 sub interp {

	my ( $self,$interp )		= @_;
	if ( $interp ne $empty_string ) {

		$sueipofi->{_interp}		= $interp;
		$sueipofi->{_note}		= $sueipofi->{_note}.' interp='.$sueipofi->{_interp};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' interp='.$sueipofi->{_interp};

	} else { 
		print("sueipofi, interp, missing interp,\n");
	 }
 }


=head2 sub pln 


=cut

 sub pln {

	my ( $self,$pln )		= @_;
	if ( $pln ne $empty_string ) {

		$sueipofi->{_pln}		= $pln;
		$sueipofi->{_note}		= $sueipofi->{_note}.' pln='.$sueipofi->{_pln};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' pln='.$sueipofi->{_pln};

	} else { 
		print("sueipofi, pln, missing pln,\n");
	 }
 }


=head2 sub pwr 


=cut

 sub pwr {

	my ( $self,$pwr )		= @_;
	if ( $pwr ne $empty_string ) {

		$sueipofi->{_pwr}		= $pwr;
		$sueipofi->{_note}		= $sueipofi->{_note}.' pwr='.$sueipofi->{_pwr};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' pwr='.$sueipofi->{_pwr};

	} else { 
		print("sueipofi, pwr, missing pwr,\n");
	 }
 }


=head2 sub rl1 


=cut

 sub rl1 {

	my ( $self,$rl1 )		= @_;
	if ( $rl1 ne $empty_string ) {

		$sueipofi->{_rl1}		= $rl1;
		$sueipofi->{_note}		= $sueipofi->{_note}.' rl1='.$sueipofi->{_rl1};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' rl1='.$sueipofi->{_rl1};

	} else { 
		print("sueipofi, rl1, missing rl1,\n");
	 }
 }


=head2 sub rl2 


=cut

 sub rl2 {

	my ( $self,$rl2 )		= @_;
	if ( $rl2 ne $empty_string ) {

		$sueipofi->{_rl2}		= $rl2;
		$sueipofi->{_note}		= $sueipofi->{_note}.' rl2='.$sueipofi->{_rl2};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' rl2='.$sueipofi->{_rl2};

	} else { 
		print("sueipofi, rl2, missing rl2,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sueipofi->{_verbose}		= $verbose;
		$sueipofi->{_note}		= $sueipofi->{_note}.' verbose='.$sueipofi->{_verbose};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' verbose='.$sueipofi->{_verbose};

	} else { 
		print("sueipofi, verbose, missing verbose,\n");
	 }
 }


=head2 sub wl 


=cut

 sub wl {

	my ( $self,$wl )		= @_;
	if ( $wl ne $empty_string ) {

		$sueipofi->{_wl}		= $wl;
		$sueipofi->{_note}		= $sueipofi->{_note}.' wl='.$sueipofi->{_wl};
		$sueipofi->{_Step}		= $sueipofi->{_Step}.' wl='.$sueipofi->{_wl};

	} else { 
		print("sueipofi, wl, missing wl,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
