package App::SeismicUnixGui::configs::big_streams::Synseis_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: Synseis_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: 
       Jan 31 2018
       
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.
     
     derives from Synseis_config.pm
     

=cut

=head2 LOCAL VARIABLES FOR THIS PROJECT 

 Values taken from the simple,local
 file: Synseis.config 
 LOCAL VARIABLES FOR THIS PROJECT
 
     base_file_name						= 'zrhov'
     time_sampling_interval_s  			= 0.001
     depth_sampling_interval_m          = .2; # meters
 	 water_depth_m 						=  0;
 	 Ricker_endtime 					=  0.15
 	 Ricker_frequency					=  20
 	 plot_density_max					= 2
 	 plot_density_min					= 1
 	 plot_depth_min_m					= 0
 	 plot_depth_max_m					= 200  
 	 plot_time_min_s					= 0
 	 plot_time_max_s					= 2	
 	 plot_velocity_min					= 1500
 	 plot_velocity_max					= 2500
 	 plot_reflection_coefficient_min	= -.1
 	 plot_reflection_coefficient_max	= 0.1
 	 plot_ss_amplitude_max				= .3
 	 plot_ss_amplitude_min				= -.3
=cut 

use Moose;
our $VERSION = '1.0.0';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $L_SU_global_constants  = L_SU_global_constants->new();
my $control                = control->new();
my $config_superflows      = config_superflows->new();
my $superflow_config_names = $L_SU_global_constants->superflow_config_names_aref();

#WARNING---- watch out for missing underscore!!
# set the correct index manually for this superflow
# print("1. Synseis_config, alias_superflow_config_name : $$alias_superflow_config_name[4].config\n");

=head2 Synseis hash


=cut

my $Synseis = {
    _prog_name            => '',
    _names_aref           => '',
    _values_aref          => '',
    _superflows_first_idx => '',
    _superflows_length    => '',
};

# set the superflow name: 8 is for Synseis
# print("Synseis_config, prog_name : @{$superflow_config_names}[8]\n");
# Warning: set using a scalar reference

sub get_values {

    my ($self) = @_;

    $Synseis->{_prog_name} = \@{$superflow_config_names}[8];

    $config_superflows->set_program_name( $Synseis->{_prog_name} );

    # parameter names from superflow configuration file
    # $Synseis->{_names_aref}  = $config_superflows->get_names();
    # print("Synseis_config,prog=@{$Synseis->{_names_aref}}\n");

    # parameter values from superflow configuration file
    $Synseis->{_values_aref} = $config_superflows->get_values();

    # print("Synseis_config,values=@{$Synseis->{_values_aref}}\n");

# $Synseis->{_check_buttons_settings_aref}  	= $config_superflows->get_check_buttons_settings();
# print("Synseis_config,chkb=@{$Synseis->{_check_buttons_settings_aref}}\n");

    $Synseis->{_superflows_first_idx} = $config_superflows->first_idx();
    $Synseis->{_superflows_length}    = $config_superflows->length();

    my $base_file_name                  = @{ $Synseis->{_values_aref} }[0];
    my $time_sampling_interval_s        = @{ $Synseis->{_values_aref} }[1];
    my $depth_sampling_interval_m       = @{ $Synseis->{_values_aref} }[2];
    my $water_depth_m                   = @{ $Synseis->{_values_aref} }[3];
    my $Ricker_endtime                  = @{ $Synseis->{_values_aref} }[4];
    my $Ricker_frequency                = @{ $Synseis->{_values_aref} }[5];
    my $plot_density_min                = @{ $Synseis->{_values_aref} }[6];
    my $plot_density_max                = @{ $Synseis->{_values_aref} }[7];
    my $plot_depth_min_m                = @{ $Synseis->{_values_aref} }[8];
    my $plot_depth_max_m                = @{ $Synseis->{_values_aref} }[9];
    my $plot_time_min_s                 = @{ $Synseis->{_values_aref} }[10];
    my $plot_time_max_s                 = @{ $Synseis->{_values_aref} }[11];
    my $plot_velocity_min               = @{ $Synseis->{_values_aref} }[12];
    my $plot_velocity_max               = @{ $Synseis->{_values_aref} }[13];
    my $plot_reflection_coefficient_min = @{ $Synseis->{_values_aref} }[14];
    my $plot_reflection_coefficient_max = @{ $Synseis->{_values_aref} }[15];
    my $plot_ss_amplitude_min           = @{ $Synseis->{_values_aref} }[16];
    my $plot_ss_amplitude_max           = @{ $Synseis->{_values_aref} }[17];

# print(" 1. Synseis_config, get_values, base_file_name is $base_file_name\n\n");
    $base_file_name = $control->su_data_name( \$base_file_name );

    # private hash variable
    my $CFG_h = {
        Synseis => {
            1 => {
                base_file_name            => $base_file_name,
                time_sampling_interval_s  => $time_sampling_interval_s,
                depth_sampling_interval_m => $depth_sampling_interval_m,
                water_depth_m             => $water_depth_m,
                Ricker_endtime            => $Ricker_endtime,
                Ricker_frequency          => $Ricker_frequency,
                plot_density_min          => $plot_density_min,
                plot_density_max          => $plot_density_max,
                plot_depth_min_m          => $plot_depth_min_m,
                plot_depth_max_m          => $plot_depth_max_m,
                plot_time_min_s           => $plot_time_min_s,
                plot_time_max_s           => $plot_time_max_s,
                plot_velocity_min         => $plot_velocity_min,
                plot_velocity_max         => $plot_velocity_max,
                plot_reflection_coefficient_min =>
                  $plot_reflection_coefficient_min,
                plot_reflection_coefficient_max =>
                  $plot_reflection_coefficient_max,
                plot_ss_amplitude_min => $plot_ss_amplitude_min,
                plot_ss_amplitude_max => $plot_ss_amplitude_max,
            },
        },
    };

    return ( $CFG_h, $Synseis->{_values_aref} );    # hash and arrary referenc
}    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # index=17
    my $max_index = 17;

    return ($max_index);
}

1;

