package App::SeismicUnixGui::sunix::filter::supolar;

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
 SUPOLAR - POLarization analysis of three-component data               



 supolar <stdin [optional parameters]                                  



 Required parameters:                                                  

    none                                                               



 Optional parameters:                                                  

    dt=(from header)  time sampling intervall in seconds               

    wl=0.1            correlation window length in seconds             

    win=boxcar        correlation window shape, choose "boxcar",     

                      "hanning", "bartlett", or "welsh

    file=polar        base of output file name(s)                      

    rl=1              1 = rectilinearity evaluating 2 eigenvalues,     

                      2, 3 = rectilinearity evaluating 3 eigenvalues   

    rlq=1.0           contrast parameter for rectilinearity            

    dir=1             1 = 3 components of direction of polarization    

                          (the only three-component output file)       

    tau=0             1 = global polarization parameter                

    ellip=0           1 = principal, subprincipal, and transverse      

                          ellipticities e21, e31, and e32              

    pln=0             1 = planarity measure                            

    f1=0              1 = flatness or oblateness coefficient           

    l1=0              1 = linearity coefficient                        

    amp=0             1 = amplitude parameters: instantaneous,         

                          quadratic, and eigenresultant ir, qr, and er 

    theta=0           1, 2, 3 = incidence angle of principal axis      

    phi=0             1, 2, 3 = horizontal azimuth of principal axis   

    angle=rad         unit of angles theta and phi, choose "rad",    

                      "deg", or "gon

    all=0             1, 2, 3 = set all output flags to that value     

    verbose=0         1 = echo additional information                  





 Notes:                                                                

    Three adjacent traces are considered as one three-component        

    dataset.                                                           

    Correct calculation of angles theta and phi requires the first of  

    these traces to be the vertical component, followed by the two     

    horizontal components (e.g. Z, N, E, or Z, inline, crossline).     

    Significant signal energy on Z is necessary to resolve the 180 deg 

    ambiguity of phi (options phi=2,3 only).                           



    Each calculated polarization attribute is written into its own     

    SU file. These files get the same base name (set with "file=")   

    and the parameter flag as an extension (e.g. polar.rl).            



    In case of a tapered correlation window, the window length wl may  

    have to be increased compared to the boxcar case, because of their 

    smaller effective widths (Bartlett, Hanning: 1/2, Welsh: 1/3).     



 Range of values:                                                      

    parameter     option  interval                                     

    rl            1, 2    0.0 ... 1.0   (1.0: linear polarization)     

    rl            3      -1.0 ... 1.0                                  

    tau, l1       1       0.0 ... 1.0   (1.0: linear polarization)     

    pln, f1       1       0.0 ... 1.0   (1.0: planar polarization)     

    e21, e31, e32 1       0.0 ... 1.0   (0.0: linear polarization)     

    theta         1      -pi/2... pi/2  rad                            

    theta         2, 3    0.0 ... pi/2  rad                            

    phi           1      -pi/2... pi/2  rad                            

    phi           2      -pi  ... pi    rad   (see notes above)        

    phi           3       0.0 ... 2 pi  rad   (see notes above)        







 

 Author: Nils Maercklin, 

         GeoForschungsZentrum (GFZ) Potsdam, Germany, 1998-2001.

         E-mail: nils@gfz-potsdam.de

 



 References:

    Jurkevics, A., 1988: Polarization analysis of three-component

       array data. Bulletin of the Seismological Society of America, 

       vol. 78, no. 5.

    Kanasewich, E. R., 1981: Time Sequence Analysis in Geophysics.

       The University of Alberta Press.

    Kanasewich, E. R., 1990: Seismic Noise Attenuation.

       Handbook of Geophysical Exploration, Pergamon Press, Oxford.

    Meyer, J. H. 1988: First Comparative Results of Integral and

       Instantaneous Polarization Attributes for Multicomponent Seismic

       Data. Institut Francais du Petrole.

    Press, W. H., Teukolsky, S. A., Vetterling, W. T., and Flannery, B. P.

       1996: Numerical Recipes in C - The Art of Scientific Computing.

       Cambridge University Press, Cambridge.

    Samson, J. C., 1973: Description of the Polarisation States of Vector

       Processes: Application to ULF Electromagnetic Fields.

       Geophysical Journal vol. 34, p. 403-419.

    Sheriff, R. E., 1991: Encyclopedic Dictionary of Exploration

       Geophysics. 3rd ed., Society of Exploration Geophysicists, Tulsa.



 Trace header fields accessed: ns, dt

 Trace header fields modified: none

=head2 User's notes (Juan Lorenzo)
Untested

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

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $supolar = {
	_output_amplitude              => '',
	_amp                           => '',
	_angle_units                    => '',
	_angle                          => '',
	_azimuth_principal_axes         => '',
	_phi                            => '',
	_base_file_name_out                 => '',
	_file                           => '',
	_correlation_window_width_s     => '',
	_wl                             => '',
	_correlation_window_type        => '',
	_win                            => '',
	_default_values                 => '',
	_all                            => '',
	_flatness                       => '',
	_f1                             => '',
	_global_parameter               => '',
	_tau                            => '',
	_incidence_angle_principal_axis => '',
	_theta                          => '',
	_linearity                      => '',
	_l1                             => '',
	_note                           => '',
	_components_polarization        => '',
	_dir                            => '',
	_planarity                      => '',
	_pln                            => '',
	_rectilinearity                 => '',
	_rl                             => '',
	_rectilinearity_contrast        => '',
	_rlq                            => '',
	_Step                           => '',
	_verbose                        => '',
	_output_ellipticities           => '',
	_ellip                          => ''
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name
=cut

sub Step {

	$supolar->{_Step} = 'supolar' . $supolar->{_Step};
	return ( $supolar->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$supolar->{_note} = 'supolar' . $supolar->{_note};
	return ( $supolar->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $supolar->{_output_amplitude}               = '';
    $supolar->{_amp}                            = '';
    $supolar->{_angle_units}                    = '';
    $supolar->{_angle}                          = '';
    $supolar->{_azimuth_principal_axes}         = '';
    $supolar->{_phi}                            = '';
    $supolar->{_base_file_name_out}                 = '';
    $supolar->{_file}                           = '';
    $supolar->{_correlation_window_type}        = '';
    $supolar->{_win}                            = '';
    $supolar->{_correlation_window_width_s}     = '';
    $supolar->{_wl}                             = '';
    $supolar->{_default_values}                 = '';
    $supolar->{_all}                            = '';
    $supolar->{_flatness}                       = '';
    $supolar->{_f1}                             = '';
    $supolar->{_global_parameter}               = '';
    $supolar->{_tau}                            = '';
    $supolar->{_incidence_angle_principal_axis} = '';
    $supolar->{_theta}                          = '';
    $supolar->{_linearity}                      = '';
    $supolar->{_l1}                             = '';
    $supolar->{_note}                           = '';
    $supolar->{_components_polarization}        = '';
    $supolar->{_dir}                            = '';
    $supolar->{_planarity}                      = '';
    $supolar->{_pln}                            = '';
    $supolar->{_rectilinearity}                 = '';
    $supolar->{_rl}                             = '';
    $supolar->{_rectilinearity_contrast}        = '';
    $supolar->{_rlq}                            = '';
    $supolar->{_verbose}                        = '';
    $supolar->{_output_ellipticities}           = '';
    $supolar->{_ellip}                          = '';
    $supolar->{_Step}                           = '';

}


=head2 sub all 


=cut

sub all {

	my ( $self, $all ) = @_;
	if ( $all ne $empty_string ) {

		$supolar->{_all}  = $all;
		$supolar->{_note} = $supolar->{_note} . ' all=' . $supolar->{_all};
		$supolar->{_Step} = $supolar->{_Step} . ' all=' . $supolar->{_all};

	} else {
		print("supolar, all, missing all,\n");
	}
}

=head2 sub angle_units

=cut 

sub angle_units {
    my ($supolar, $angle_units )   = @_;
    $supolar->{_angle_units} = $angle_units if defined($angle_units);
    $supolar->{_note}        = $supolar->{_note}.' angle='.$supolar->{_angle_units};
    $supolar->{_Step}        = $supolar->{_Step}.' angle='.$supolar->{_angle_units};
}

=head2 sub azimuth_principal_axes

=cut 

sub azimuth_principal_axes {
    my ($supolar, $azimuth_principal_axes )   = @_;
    $supolar->{_azimuth_principal_axes}       = $azimuth_principal_axes if defined($azimuth_principal_axes);
    $supolar->{_note}                         = $supolar->{_note}.' phi='.$supolar->{_azimuth_principal_axes};
    $supolar->{_Step}                         = $supolar->{_Step}.' phi='.$supolar->{_azimuth_principal_axes};
}

=head2 sub base_file_name_out

=cut 

sub base_file_name_out {
    my ($supolar, $base_file_name_out )     = @_;
    $supolar->{_base_file_name_out}         = $base_file_name_out if defined($base_file_name_out);
    $supolar->{_note}                   = $supolar->{_note}.' file='.$supolar->{_base_file_name_out};
    $supolar->{_Step}                   = $supolar->{_Step}.' file='.$supolar->{_base_file_name_out};
}


=head2 sub components_polarization

=cut

sub components_polarization{
    my ($supolar,$components_polarization)        = @_;
    $supolar->{_components_polarization}          = $components_polarization if defined($components_polarization);
    $supolar->{_note}             = $supolar->{_note}.' dir='.$supolar->{_components_polarization};
    $supolar->{_Step}             = $supolar->{_Step}.' dir='.$supolar->{_components_polarization};

}


=head2 sub correlation_window_type 

=cut

sub correlation_window_type {
    my ($supolar, $correlation_window_type )    = @_;
    $supolar->{_correlation_window_type}        = $correlation_window_type if defined($correlation_window_type);
    $supolar->{_note}                           = $supolar->{_note}.' win='.$supolar->{_correlation_window_type};
    $supolar->{_Step}                           = $supolar->{_Step}.' win='.$supolar->{_correlation_window_type};
}


=head2 sub correlation_window_length_s

=cut
sub correlation_window_length_s {
    my ($supolar, $correlation_window_length_s)         = @_;
    $supolar->{_correlation_window_length_s}    = $correlation_window_length_s if defined($correlation_window_length_s);
    $supolar->{_note}                   = $supolar->{_note}.' wl='.$supolar->{_correlation_window_length_s};
    $supolar->{_Step}                   = $supolar->{_Step}.' wl='.$supolar->{_correlation_window_length_s};
}

=head2 sub amp 


=cut

sub amp {

	my ( $self, $amp ) = @_;
	if ( $amp ne $empty_string ) {

		$supolar->{_amp}  = $amp;
		$supolar->{_note} = $supolar->{_note} . ' amp=' . $supolar->{_amp};
		$supolar->{_Step} = $supolar->{_Step} . ' amp=' . $supolar->{_amp};

	} else {
		print("supolar, amp, missing amp,\n");
	}
}

=head2 sub angle 


=cut

sub angle {

	my ( $self, $angle ) = @_;
	if ( $angle ne $empty_string ) {

		$supolar->{_angle} = $angle;
		$supolar->{_note}  = $supolar->{_note} . ' angle=' . $supolar->{_angle};
		$supolar->{_Step}  = $supolar->{_Step} . ' angle=' . $supolar->{_angle};

	} else {
		print("supolar, angle, missing angle,\n");
	}
}
sub default_values {
    my ($supolar, $default_values )     = @_;
    $supolar->{_default_values}         = $default_values if defined($default_values);
    $supolar->{_Step}                   = $supolar->{_Step}.' all='.$supolar->{_default_values};
}


=head2 sub dir 


=cut

sub dir {

	my ( $self, $dir ) = @_;
	if ( $dir ne $empty_string ) {

		$supolar->{_dir}  = $dir;
		$supolar->{_note} = $supolar->{_note} . ' dir=' . $supolar->{_dir};
		$supolar->{_Step} = $supolar->{_Step} . ' dir=' . $supolar->{_dir};

	} else {
		print("supolar, dir, missing dir,\n");
	}
}

=head2 sub dt 


=cut

sub dt {

	my ( $self, $dt ) = @_;
	if ( $dt ne $empty_string ) {

		$supolar->{_dt}   = $dt;
		$supolar->{_note} = $supolar->{_note} . ' dt=' . $supolar->{_dt};
		$supolar->{_Step} = $supolar->{_Step} . ' dt=' . $supolar->{_dt};

	} else {
		print("supolar, dt, missing dt,\n");
	}
}

=head2 sub ellip 


=cut

sub ellip {

	my ( $self, $ellip ) = @_;
	if ( $ellip ne $empty_string ) {

		$supolar->{_ellip} = $ellip;
		$supolar->{_note}  = $supolar->{_note} . ' ellip=' . $supolar->{_ellip};
		$supolar->{_Step}  = $supolar->{_Step} . ' ellip=' . $supolar->{_ellip};

	} else {
		print("supolar, ellip, missing ellip,\n");
	}
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$supolar->{_f1}   = $f1;
		$supolar->{_note} = $supolar->{_note} . ' f1=' . $supolar->{_f1};
		$supolar->{_Step} = $supolar->{_Step} . ' f1=' . $supolar->{_f1};

	} else {
		print("supolar, f1, missing f1,\n");
	}
}

=head2 sub flatness 

=cut

sub flatness {
    my ($supolar, $flatness)    = @_;
    $supolar->{_flatness}       = $flatness if defined($flatness);
    $supolar->{_note}           = $supolar->{_note}.' f1='.$supolar->{_flatness};
    $supolar->{_Step}           = $supolar->{_Step}.' f1='.$supolar->{_flatnes};
}

=head2 sub file 


=cut

sub file {

	my ( $self, $file ) = @_;
	if ( $file ne $empty_string ) {

		$supolar->{_file} = $file;
		$supolar->{_note} = $supolar->{_note} . ' file=' . $supolar->{_file};
		$supolar->{_Step} = $supolar->{_Step} . ' file=' . $supolar->{_file};

	} else {
		print("supolar, file, missing file,\n");
	}
}
sub global_parameter {
    my ($supolar, $global_parameter)    = @_;
    $supolar->{_global_paramter}        = $global_parameter if defined($global_parameter);
    $supolar->{_note}                   = $supolar->{_note}.' tau='.$supolar->{_global_parameter};
    $supolar->{_Step}                   = $supolar->{_Step}.' tau='.$supolar->{_global_parameter};
}


sub incidence_angle_principal_axis {
    my ($supolar, $incidence_angle_principal_axis )   = @_;
    $supolar->{_incidence_angle_principal_axis}       = $incidence_angle_principal_axis if defined($incidence_angle_principal_axis);
    $supolar->{_note}                                 = $supolar->{_note}.' theta='.$supolar->{_incidence_angle_principal_axis};
    $supolar->{_Step}                                 = $supolar->{_Step}.' theta='.$supolar->{_incidence_angle_principal_axis};
}

sub linearity{
    my ($supolar,$linearity)      = @_;
    $supolar->{_linearity}        = $linearity if defined($linearity);
     $supolar->{_note}            = $supolar->{_note}.' l1='.$supolar->{_linearity};
    $supolar->{_Step}             = $supolar->{_Step}.' l1='.$supolar->{_linearity};

}

=head2 sub l1 


=cut

sub l1 {

	my ( $self, $l1 ) = @_;
	if ( $l1 ne $empty_string ) {

		$supolar->{_l1}   = $l1;
		$supolar->{_note} = $supolar->{_note} . ' l1=' . $supolar->{_l1};
		$supolar->{_Step} = $supolar->{_Step} . ' l1=' . $supolar->{_l1};

	} else {
		print("supolar, l1, missing l1,\n");
	}
}


sub output_amplitude {
    my ($supolar, $output_amplitude ) = @_;
    $supolar->{_output_amplitude}        = $output_amplitude if defined($output_amplitude);
    $supolar->{_note}             = $supolar->{_note}.' amp='.$supolar->{_output_amplitude};
    $supolar->{_Step}                    = $supolar->{_Step}.' amp='.$supolar->{_output_amplitude};
}


=head2 sub phi 


=cut

sub phi {

	my ( $self, $phi ) = @_;
	if ( $phi ne $empty_string ) {

		$supolar->{_phi}  = $phi;
		$supolar->{_note} = $supolar->{_note} . ' phi=' . $supolar->{_phi};
		$supolar->{_Step} = $supolar->{_Step} . ' phi=' . $supolar->{_phi};

	} else {
		print("supolar, phi, missing phi,\n");
	}
}

sub planarity{
    my ($supolar, $planarity)     = @_;
    $supolar->{_planarity}        = $planarity if defined($planarity);
     $supolar->{_note}            = $supolar->{_note}.' pln='.$supolar->{_planarity};
    $supolar->{_Step}             = $supolar->{_Step}.' pln='.$supolar->{_planarity};
}

=head2 sub pln 


=cut

sub pln {

	my ( $self, $pln ) = @_;
	if ( $pln ne $empty_string ) {

		$supolar->{_pln}  = $pln;
		$supolar->{_note} = $supolar->{_note} . ' pln=' . $supolar->{_pln};
		$supolar->{_Step} = $supolar->{_Step} . ' pln=' . $supolar->{_pln};

	} else {
		print("supolar, pln, missing pln,\n");
	}
}
sub rectilinearity{
    my ($supolar,$rectilinearity) = @_;
    $supolar->{_rectilinearity}   = $rectilinearity if defined($rectilinearity);
     $supolar->{_note}            = $supolar->{_note}.' rl='.$supolar->{_rectilinearity};
    $supolar->{_Step}             = $supolar->{_Step}.' rl='.$supolar->{_rectilinearity};

}

sub rectilinearity_contrast{
    my ($supolar,$rectilinearity_contrast) = @_;
    $supolar->{_rectilinearity_contrast}   = $rectilinearity_contrast if defined($rectilinearity_contrast);
     $supolar->{_note}            = $supolar->{_note}.' rlq='.$supolar->{_rectilinearity_contrast};
    $supolar->{_Step}             = $supolar->{_Step}.' rlq='.$supolar->{_rectilinearity_contrast};

}

=head2 sub rl 


=cut

sub rl {

	my ( $self, $rl ) = @_;
	if ( $rl ne $empty_string ) {

		$supolar->{_rl}   = $rl;
		$supolar->{_note} = $supolar->{_note} . ' rl=' . $supolar->{_rl};
		$supolar->{_Step} = $supolar->{_Step} . ' rl=' . $supolar->{_rl};

	} else {
		print("supolar, rl, missing rl,\n");
	}
}

=head2 sub rlq 


=cut

sub rlq {

	my ( $self, $rlq ) = @_;
	if ( $rlq ne $empty_string ) {

		$supolar->{_rlq}  = $rlq;
		$supolar->{_note} = $supolar->{_note} . ' rlq=' . $supolar->{_rlq};
		$supolar->{_Step} = $supolar->{_Step} . ' rlq=' . $supolar->{_rlq};

	} else {
		print("supolar, rlq, missing rlq,\n");
	}
}

=head2 sub tau 


=cut

sub tau {

	my ( $self, $tau ) = @_;
	if ( $tau ne $empty_string ) {

		$supolar->{_tau}  = $tau;
		$supolar->{_note} = $supolar->{_note} . ' tau=' . $supolar->{_tau};
		$supolar->{_Step} = $supolar->{_Step} . ' tau=' . $supolar->{_tau};

	} else {
		print("supolar, tau, missing tau,\n");
	}
}

=head2 sub theta 


=cut

sub theta {

	my ( $self, $theta ) = @_;
	if ( $theta ne $empty_string ) {

		$supolar->{_theta} = $theta;
		$supolar->{_note}  = $supolar->{_note} . ' theta=' . $supolar->{_theta};
		$supolar->{_Step}  = $supolar->{_Step} . ' theta=' . $supolar->{_theta};

	} else {
		print("supolar, theta, missing theta,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$supolar->{_verbose} = $verbose;
		$supolar->{_note}    = $supolar->{_note} . ' verbose=' . $supolar->{_verbose};
		$supolar->{_Step}    = $supolar->{_Step} . ' verbose=' . $supolar->{_verbose};

	} else {
		print("supolar, verbose, missing verbose,\n");
	}
}

sub output_ellipticities{
    my ($supolar,$output_ellipticities) = @_;
    $supolar->{_output_ellipticities}   = $output_ellipticities if defined($output_ellipticities);
     $supolar->{_note}            = $supolar->{_note}.' ellip='.$supolar->{_output_ellipticities};
    $supolar->{_Step}             = $supolar->{_Step}.' ellip='.$supolar->{_output_ellipticities};

}


=head2 sub win 


=cut

sub win {

	my ( $self, $win ) = @_;
	if ( $win ne $empty_string ) {

		$supolar->{_win}  = $win;
		$supolar->{_note} = $supolar->{_note} . ' win=' . $supolar->{_win};
		$supolar->{_Step} = $supolar->{_Step} . ' win=' . $supolar->{_win};

	} else {
		print("supolar, win, missing win,\n");
	}
}

=head2 sub wl 


=cut

sub wl {

	my ( $self, $wl ) = @_;
	if ( $wl ne $empty_string ) {

		$supolar->{_wl}   = $wl;
		$supolar->{_note} = $supolar->{_note} . ' wl=' . $supolar->{_wl};
		$supolar->{_Step} = $supolar->{_Step} . ' wl=' . $supolar->{_wl};

	} else {
		print("supolar, wl, missing wl,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 17;

	return ($max_index);
}

1;
