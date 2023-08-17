package App::SeismicUnixGui::configs::big_streams::iVA_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iVA_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: Aug 18 2016 
       July 19 2017
       Jan 7 2017
       Jan 13 2020
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR IVA (interactive velocity analysis)

 Derives from iVA_config.pl
 
 Version 2 based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)

    package control replaces commas in strings
    needed by Seismic Unix
    
  July 19 2017 - added tmax_s parameter to configuration file
  January 7, 2017 - remove outside dependency on Config-Simple
  
  Jan 13 2020: data_scale removed from gui; max_index=11
     

=cut

=head2 LOCAL VARIABLES FOR THIS PROJECT 

 Values taken from the simple,local
 file: iVA.config called
 LOCAL VARIABLES FOR THIS PROJECT
     base_file_name  				= 'All_cmp'
     cdp_first   				= 15
     cdp_inc    				= 1
     cdp_last    				= 100
     tmax_s             		= .2
     dt_s    					= .004
     freq    		    		= '0,3,100,200'
     number_of_velocities   	= 300
     first_velocity   	        = 3
     velocity_increment   		= 10
     min_semblance    	        = .0
     max_semblance    	        = .75
 
=cut 

use Moose;
our $VERSION = '1.0.1';
use aliased 'App::SeismicUnixGui::misc::config_superflows';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get                    = L_SU_global_constants->new();
my $control                = control->new();
my $config_superflows      = config_superflows->new();
my $superflow_config_names = $get->superflow_config_names_aref();

#WARNING---- watch out for missing underscore!!
# set the correct index manually for this superflow
# print("1. iVA_config, alias_superflow_config_name : $$alias_superflow_config_name[4].config\n");

=head2 private hash


=cut

my $iVA = {
    _prog_name   => '',
    _names_aref  => '',
    _values_aref => '',

    #_check_buttons_settings_aref		=> '',
    #_check_buttons_settings_aref		=> '',
    _superflows_first_idx => '',
    _superflows_length    => '',
};

# set the superflow name: 4 is for iVA
# print("iVA_config, prog_name : @{$superflow_config_names}[4]\n");
# Warning: set using a scalar reference

sub get_values {
	my ($self)  = @_;
    $iVA->{_prog_name} = \@{$superflow_config_names}[4];

    $config_superflows->set_program_name( $iVA->{_prog_name} );

    # parameter names from superflow configuration file
    $iVA->{_names_aref}  = $config_superflows->get_names();
    # print("iVA_config,prog=@{$iVA->{_names_aref}}\n");

    # parameter values from superflow configuration file
    $iVA->{_values_aref} = $config_superflows->get_values();

    # print("iVA_config,values=@{$iVA->{_values_aref}}\n");

# $iVA->{_check_buttons_settings_aref}  	= $config_superflows->get_check_buttons_settings();
# print("iVA_config,chkb=@{$iVA->{_check_buttons_settings_aref}}\n");

    $iVA->{_superflows_first_idx} = $config_superflows->first_idx();
    $iVA->{_superflows_length}    = $config_superflows->length();

    my $base_file_name       = @{ $iVA->{_values_aref} }[0];
    my $cdp_first            = @{ $iVA->{_values_aref} }[1];
    my $cdp_inc              = @{ $iVA->{_values_aref} }[2];
    my $cdp_last             = @{ $iVA->{_values_aref} }[3];
    my $dt_s                 = @{ $iVA->{_values_aref} }[4];
    my $tmax_s               = @{ $iVA->{_values_aref} }[5];
    my $freq                 = @{ $iVA->{_values_aref} }[6];
    my $number_of_velocities = @{ $iVA->{_values_aref} }[7];
    my $first_velocity       = @{ $iVA->{_values_aref} }[8];
    my $velocity_increment   = @{ $iVA->{_values_aref} }[9];
    my $min_semblance        = @{ $iVA->{_values_aref} }[10];
    my $max_semblance        = @{ $iVA->{_values_aref} }[11];
	my $anis1        		 = @{ $iVA->{_values_aref} }[12];
	my $anis2        		 = @{ $iVA->{_values_aref} }[13];
	my $dtratio        		 = @{ $iVA->{_values_aref} }[14];
	my $nsmooth        		 = @{ $iVA->{_values_aref} }[15];
	my $pwr       		     = @{ $iVA->{_values_aref} }[16];
	my $smute        		 = @{ $iVA->{_values_aref} }[17];

    # check on formats
    $freq = $control->commas( \$freq );    # needed?

    # print(" 1. iVA_config for iVA, base_file_name is $base_file_name\n\n");
    $base_file_name = $control->su_data_name( \$base_file_name );

    # print(" 2. VA_config, for iVA, base_file_name is $base_file_name \n\n");

    # private hash variable
    my $CFG_h = {
        iva => {
            1 => {
                base_file_name       => $base_file_name,
                cdp_first            => $cdp_first,
                cdp_inc              => $cdp_inc,
                cdp_last             => $cdp_last,
                dt_s                 => $dt_s,
                tmax_s               => $tmax_s,
                freq                 => $freq,
                number_of_velocities => $number_of_velocities,
                first_velocity       => $first_velocity,
                velocity_increment   => $velocity_increment,
                min_semblance        => $min_semblance,
                max_semblance        => $max_semblance,
  				anis1        		 => $anis1,
  				anis2        		 => $anis2,
  				dtratio        		 => $dtratio,
  				nsmooth        		 => $nsmooth,
  				pwr       		     => $pwr,
  				smute        		 => $smute,        
            }
        }
    };

    return ( $CFG_h, $iVA->{_values_aref} );    # hash and arrary reference
}    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    my $max_index = 17;

    return ($max_index);
}

1;

