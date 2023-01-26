package App::SeismicUnixGui::configs::big_streams::Sseg2su_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: Sseg2su_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: July 29 2016 
 		April 4, 2018 V 1.0.2
 		
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.
     Takes seg2-formatted data and converts to
     su fomratted data with SIOSEIS (USC)

 USED FOR 
      Upper-level variables
      definitions in Sseg2su
      Seismic data is assumed currently to be in
      dat/seg2 format, as output by Geometerics
      

 BASED ON:
 Version X  Based on linux command "cat"
 Version XX based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)
 Version 1.0.2 derives from Sseg2su_config.pl
     
   
 Needs: Simple (ASCII) local configuration 
      file is Sseg2su.config
      Needs sioseis executable already installed 
      sioseis binary executable must be automatically available
      pn a system path.

=cut

=head2 EXAMPLE configuration file

  A local onfiguration file
  An example Sseg2su.config contains:
  
  $number_of_files	   =  38;
  $first_file_number  	= 1000;
  
  print("number of files is $number_of_files\n");
 
=cut 

use Moose;
our $VERSION = '1.0.2';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

my $get               = L_SU_global_constants->new();
my $config_superflows = config_superflows->new();
my $control           = control->new();
my $Project           = Project_config->new();

my $DATA_SEISMIC_SU        = $Project->DATA_SEISMIC_SU();
my $superflow_config_names = $get->superflow_config_names_aref();

# WARNING---- watch out for missing underscore!!
# print("1. Sseg2su_config,superflow_config_name : $$superflow_config_names[0]\n");

=head2 private hash

=cut

my $Sseg2su_config = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 9 is for Sseg2su

sub get_values {
    my ($self) = @_;

    # Warning: set using a scalar reference
    $Sseg2su_config->{_prog_name} = \@{$superflow_config_names}[9];

    # print("Sseg2su_config, prog_name : @{$superflow_config_names}[9]\n");

    $config_superflows->set_program_name( $Sseg2su_config->{_prog_name} );

    # parameter values from superflow configuration file
    $Sseg2su_config->{_values_aref} = $config_superflows->get_values();

    # print("Sseg2su_config,values=@{$Sseg2su->{_values_aref}}\n");

    my $number_of_files   = @{ $Sseg2su_config->{_values_aref} }[0];
    my $first_file_number = @{ $Sseg2su_config->{_values_aref} }[1];

=head2 LOCAL VARIABLES FOR THIS PROJECT

=cut

    my $CFG = {
        seg2su => {
            1 => {
                number_of_files   => $number_of_files,
                first_file_number => $first_file_number
            }
        }
    };    # end of CFG hash

    return ( $CFG, $Sseg2su_config->{_values_aref} )
      ;    # hash and arrary reference

};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=1
    my $max_index = 1;

    return ($max_index);
}

1;    # end of package
