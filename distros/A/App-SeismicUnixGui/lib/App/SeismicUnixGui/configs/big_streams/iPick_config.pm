package App::SeismicUnixGui::configs::big_streams::iPick_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: iPick_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 16, 2019
 DESCRIPTION: Reads a seismic unix-formatted file
 outputs a text file of the picks

 USED 

 BASED ON:
 Version 0.01 iTopMute_config.pm
     
   
 Needs: Simple (ASCII) local configuration 
      file is iPick.config

  Package control:

=cut

=head2 EXAMPLE
 
 	contains all the configuration variables in
 	perl script

     base_file_name  	= 30Hz_All_geom_geom;
     gather_header  	= fldr;
     offset_type  		= tracl;
     first_gather   	= 1;
     gather_inc    		= 1;
     last_gather    	= 100;
     freq    		    = '0,3,100,200;
     gather_type    	= fldr;
     min_amplitude    	= .0;
     max_amplitude    	= .75;
 
=cut 

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

my $Project                = Project_config->new();
my $control                = control->new();
my $DATA_SEISMIC_SU        = $Project->DATA_SEISMIC_SU();
my $config_superflows      = config_superflows->new();
my $get                    = L_SU_global_constants->new();
my $superflow_config_names = $get->superflow_config_names_aref();

# WARNING---- watch out for missing underscore!!

=head2  private hash

=cut

my $iPick_config = {
    _prog_name   => '',
    _values_aref => '',
};
# set the superflow name: 11 is for iPick

sub get_values {

    my ($self) = @_;

    # Warning: set using a scalar reference
    $iPick_config->{_prog_name} = \@{$superflow_config_names}[11];

#    print("iPick_config, prog_name : @{$superflow_config_names}[11]\n");

    $config_superflows->set_program_name( $iPick_config->{_prog_name} );

    # parameter values from superflow configuration file
    $iPick_config->{_values_aref} = $config_superflows->get_values();

#    print("iPick_config,values=@{$iPick_config->{_values_aref}}\n");

    my $base_file_name = @{ $iPick_config->{_values_aref} }[0];
    my $gather_header  = @{ $iPick_config->{_values_aref} }[1];
    my $offset_type    = @{ $iPick_config->{_values_aref} }[2];
    my $first_gather   = @{ $iPick_config->{_values_aref} }[3];
    my $gather_inc     = @{ $iPick_config->{_values_aref} }[4];
    my $last_gather    = @{ $iPick_config->{_values_aref} }[5];
    my $freq           = @{ $iPick_config->{_values_aref} }[6];
    my $gather_type    = @{ $iPick_config->{_values_aref} }[7];
    my $min_amplitude  = @{ $iPick_config->{_values_aref} }[8];
    my $max_amplitude  = @{ $iPick_config->{_values_aref} }[9];
    my $min_x1     = @{ $iPick_config->{_values_aref} }[10];
    my $max_x1     = @{ $iPick_config->{_values_aref} }[11];
    my $purpose        = @{ $iPick_config->{_values_aref} }[12];

    $base_file_name = $control->su_data_name( \$base_file_name );

    # print ("iPick_config, min_x1: $min_x1\n");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

    my $CFG = {
        suximage => {
            1 => {
                gather_header => $gather_header,
                offset_type   => $offset_type,
                first_gather  => $first_gather,
                gather_inc    => $gather_inc,
                last_gather   => $last_gather,
                freq          => $freq,
                gather_type   => $gather_type,
                min_amplitude => $min_amplitude,
                max_amplitude => $max_amplitude,
                min_x1    => $min_x1,
                max_x1    => $max_x1,
                purpose       => $purpose,
            },
        },
        sugain         => { 1 => { freq => $freq }, },
        base_file_name => $base_file_name,
    };    # end of CFG hash

    return ( $CFG, $iPick_config->{_values_aref} );  # hash and arrary reference

};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 12;

    return ($max_index);
}

1;
