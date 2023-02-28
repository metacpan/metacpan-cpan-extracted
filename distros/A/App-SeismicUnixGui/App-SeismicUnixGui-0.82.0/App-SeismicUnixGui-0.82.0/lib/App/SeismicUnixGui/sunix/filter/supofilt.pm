package App::SeismicUnixGui::sunix::filter::supofilt;

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
 SUPOFILT - POlarization FILTer for three-component data               



 supofilt <stdin >stdout [optional parameters]                         



 Required parameters:                                                  

    dfile=polar.dir   file containing the 3 components of the          

                      direction of polarization                        

    wfile=polar.rl    file name of weighting polarization parameter    



 Optional parameters:                                                  

    dt=(from header)  time sampling intervall in seconds               

    smooth=1          1 = smooth filter operators, 0 do not            

    sl=0.05           smoothing window length in seconds               

    wpow=1.0          raise weighting function to power wpow           

    dpow=1.0          raise directivity functions to power dpow        

    verbose=0         1 = echo additional information                  





 Notes:                                                                

    Three adjacent traces are considered as one three-component        

    dataset.                                                           



    This program SUPOFILT is an extension to the polarization analysis 

    program supolar. The files wfile and dfile are SU files as written 

    by SUPOLAR.                                                        





 

 Author: Nils Maercklin, 

         GeoForschungsZentrum (GFZ) Potsdam, Germany, 1999-2000.

         E-mail: nils@gfz-potsdam.de

 



 References:

    Benhama, A., Cliet, C. and Dubesset, M., 1986: Study and

       Application of spatial directional filtering in three 

       component recordings.

       Geophysical Prospecting, vol. 36.

    Kanasewich, E. R., 1981: Time Sequence Analysis in Geophysics, 

       The University of Alberta Press.

    Kanasewich, E. R., 1990: Seismic Noise Attenuation, 

       Handbook of Geophysical Exploration, Pergamon Press, Oxford.

 



 Trace header fields accessed: ns, dt



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

my $supofilt			= {
	_dfile					=> '',
	_dpow					=> '',
	_dt					=> '',
	_sl					=> '',
	_smooth					=> '',
	_verbose					=> '',
	_wfile					=> '',
	_wpow					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$supofilt->{_Step}     = 'supofilt'.$supofilt->{_Step};
	return ( $supofilt->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$supofilt->{_note}     = 'supofilt'.$supofilt->{_note};
	return ( $supofilt->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$supofilt->{_dfile}			= '';
		$supofilt->{_dpow}			= '';
		$supofilt->{_dt}			= '';
		$supofilt->{_sl}			= '';
		$supofilt->{_smooth}			= '';
		$supofilt->{_verbose}			= '';
		$supofilt->{_wfile}			= '';
		$supofilt->{_wpow}			= '';
		$supofilt->{_Step}			= '';
		$supofilt->{_note}			= '';
 }


=head2 sub dfile 


=cut

 sub dfile {

	my ( $self,$dfile )		= @_;
	if ( $dfile ne $empty_string ) {

		$supofilt->{_dfile}		= $dfile;
		$supofilt->{_note}		= $supofilt->{_note}.' dfile='.$supofilt->{_dfile};
		$supofilt->{_Step}		= $supofilt->{_Step}.' dfile='.$supofilt->{_dfile};

	} else { 
		print("supofilt, dfile, missing dfile,\n");
	 }
 }


=head2 sub dpow 


=cut

 sub dpow {

	my ( $self,$dpow )		= @_;
	if ( $dpow ne $empty_string ) {

		$supofilt->{_dpow}		= $dpow;
		$supofilt->{_note}		= $supofilt->{_note}.' dpow='.$supofilt->{_dpow};
		$supofilt->{_Step}		= $supofilt->{_Step}.' dpow='.$supofilt->{_dpow};

	} else { 
		print("supofilt, dpow, missing dpow,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$supofilt->{_dt}		= $dt;
		$supofilt->{_note}		= $supofilt->{_note}.' dt='.$supofilt->{_dt};
		$supofilt->{_Step}		= $supofilt->{_Step}.' dt='.$supofilt->{_dt};

	} else { 
		print("supofilt, dt, missing dt,\n");
	 }
 }


=head2 sub sl 


=cut

 sub sl {

	my ( $self,$sl )		= @_;
	if ( $sl ne $empty_string ) {

		$supofilt->{_sl}		= $sl;
		$supofilt->{_note}		= $supofilt->{_note}.' sl='.$supofilt->{_sl};
		$supofilt->{_Step}		= $supofilt->{_Step}.' sl='.$supofilt->{_sl};

	} else { 
		print("supofilt, sl, missing sl,\n");
	 }
 }


=head2 sub smooth 


=cut

 sub smooth {

	my ( $self,$smooth )		= @_;
	if ( $smooth ne $empty_string ) {

		$supofilt->{_smooth}		= $smooth;
		$supofilt->{_note}		= $supofilt->{_note}.' smooth='.$supofilt->{_smooth};
		$supofilt->{_Step}		= $supofilt->{_Step}.' smooth='.$supofilt->{_smooth};

	} else { 
		print("supofilt, smooth, missing smooth,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$supofilt->{_verbose}		= $verbose;
		$supofilt->{_note}		= $supofilt->{_note}.' verbose='.$supofilt->{_verbose};
		$supofilt->{_Step}		= $supofilt->{_Step}.' verbose='.$supofilt->{_verbose};

	} else { 
		print("supofilt, verbose, missing verbose,\n");
	 }
 }


=head2 sub wfile 


=cut

 sub wfile {

	my ( $self,$wfile )		= @_;
	if ( $wfile ne $empty_string ) {

		$supofilt->{_wfile}		= $wfile;
		$supofilt->{_note}		= $supofilt->{_note}.' wfile='.$supofilt->{_wfile};
		$supofilt->{_Step}		= $supofilt->{_Step}.' wfile='.$supofilt->{_wfile};

	} else { 
		print("supofilt, wfile, missing wfile,\n");
	 }
 }


=head2 sub wpow 


=cut

 sub wpow {

	my ( $self,$wpow )		= @_;
	if ( $wpow ne $empty_string ) {

		$supofilt->{_wpow}		= $wpow;
		$supofilt->{_note}		= $supofilt->{_note}.' wpow='.$supofilt->{_wpow};
		$supofilt->{_Step}		= $supofilt->{_Step}.' wpow='.$supofilt->{_wpow};

	} else { 
		print("supofilt, wpow, missing wpow,\n");
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
