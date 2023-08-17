package App::SeismicUnixGui::configs::big_streams::iTopMute_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: iTop_Mute_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: July 27 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR 
      Upper-level variable
      definitions in iTop_Mute3 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
 Version 1  Based on linux command "cat"
 Version 2 based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)
     
   
 Needs: Simple (ASCII) local configuration 
      file is iTop_Mute3.config

  Package control:
     filename is file, without a suffix!
     In some cases, numbers must be
     separated by commasi-- needed by 
     Seismic Unix

=cut

=head2 text file 
 contains all the configuration variables in
 perl script

     base_file_name  		= 30Hz_All_geom_geom;
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
our $VERSION = '1.0.3';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
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

my $iTopMute_config = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 5 is for TopMute-to-TopMute
sub get_values {

    my ($self) = @_;

    # Warning: set using a scalar reference
    $iTopMute_config->{_prog_name} = \@{$superflow_config_names}[5];

# print("iBBottomMute_config_config, prog_name : @{$superflow_config_names}[5]\n");

    $config_superflows->set_program_name( $iTopMute_config->{_prog_name} );

    # parameter values from superflow configuration file
    $iTopMute_config->{_values_aref} = $config_superflows->get_values();

 # print("iTopMute_config_config,values=@{$iTopMute_config->{_values_aref}}\n");

    my $base_file_name = @{ $iTopMute_config->{_values_aref} }[0];
    my $gather_header  = @{ $iTopMute_config->{_values_aref} }[1];
    my $offset_type    = @{ $iTopMute_config->{_values_aref} }[2];
    my $first_gather   = @{ $iTopMute_config->{_values_aref} }[3];
    my $gather_inc     = @{ $iTopMute_config->{_values_aref} }[4];
    my $last_gather    = @{ $iTopMute_config->{_values_aref} }[5];
    my $freq           = @{ $iTopMute_config->{_values_aref} }[6];
    my $gather_type    = @{ $iTopMute_config->{_values_aref} }[7];
    my $min_amplitude  = @{ $iTopMute_config->{_values_aref} }[8];
    my $max_amplitude  = @{ $iTopMute_config->{_values_aref} }[9];

    $base_file_name = $control->su_data_name( \$base_file_name );

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

    my $CFG = {
        sumute => {
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
            },
        },
        sugain         => { 1 => { freq => $freq }, },
        base_file_name => $base_file_name,
    };    # end of CFG hash

    return ( $CFG, $iTopMute_config->{_values_aref} )
      ;    # hash and arrary reference
};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=9
    my $max_index = 9;

    return ($max_index);
}

1;
