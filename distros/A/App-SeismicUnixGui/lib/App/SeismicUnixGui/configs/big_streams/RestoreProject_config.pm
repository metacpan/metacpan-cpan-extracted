package App::SeismicUnixGui::configs::big_streams::RestoreProject_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: RestoreProject_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 23 2024 

	
 DESCRIPTION Configuration file set to elicit
      project name via reading RestoreProject.config file

 USED FOR 

 Version 1  Based on Sucat_config.pm
     
=cut

=head2 LOCAL VARIABLES FOR THIS PROJECT 
 
=cut

use Moose;
our $VERSION = '1.0.1';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get               = L_SU_global_constants->new();
my $config_superflows = config_superflows->new();
my $control           = control->new();
my $Project           = Project_config->new();

my $inbound_directory      = $Project->DATA_SEISMIC_SU(); #defaulted
my $outbound_directory     = $Project->DATA_SEISMIC_SU(); #defaulted
my $superflow_config_names = $get->superflow_config_names_aref();

# WARNING---- watch out for missing underscore!!
# print("1. RestoreProject_config,superflow_config_name : $$superflow_config_names[14]\n");

=head2 private hash

=cut

my $RestoreProject_config = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 14 is for RestoreProject

sub get_values {
    my ($self) = @_;

    # Warning: set using a scalar reference
    $RestoreProject_config->{_prog_name} = \@{$superflow_config_names}[14];

#    print("RestoreProject_config, prog_name : @{$superflow_config_names}[14]\n");

    $config_superflows->set_program_name( $RestoreProject_config->{_prog_name} );

    # parameter values from superflow configuration file
    $RestoreProject_config->{_values_aref} = $config_superflows->get_values();

#    print("RestoreProject_config,values=@{$RestoreProject_config->{_values_aref}}\n");

    my $directory_name = @{ $RestoreProject_config->{_values_aref} }[0];
    
    
=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut
   
    my $CFG = {
        RestoreProject => {
            1 => {
                directory_name => $directory_name,
            }
        }
    };    # end of CFG hash

    return ( $CFG, $RestoreProject_config->{_values_aref} );  # hash and arrary reference

};    # end of sub get_values


=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    my $max_index = 0;

    return ($max_index);
}

1;
