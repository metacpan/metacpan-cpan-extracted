package App::SeismicUnixGui::configs::big_streams::Sucat_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: Sucat_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: June 23 2016 
 	   April 10 2018
	
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.

 USED FOR 
      Upper-level variable
      definitions in Sucat 
      Can do sets of files with numerically
      sequential  names,
      such as 1000.su, 1001.su, 1002.su etc.
      Seismic data is assumed currently to be in
      su format.

 Version 1  Based on linux command "cat"
 Version 2 based on Sucat.pm June 29 2016
    Added a simple configuration file readable 
    and writable using Config::Simple (CPAN)
 Version 2.1 chnaged local configuration file name 
 	from Sucat2.config Sucat.config 
 Version 2.2 derives from Sucat_config.pl
 	and removes dependency on Config::Simple (CPAN) 
     
   
 Notes: Simple configuration files is Sucat.config

=cut

=head2 Notes from bash

  cat file1 file2 >output file
 
=cut 

=head2 LOCAL VARIABLES FOR THIS PROJECT 

  One example""
  uncomment the following 3 lines if you need them, while
  commenting out the last few lines as well
  This package uses a list OR a continuous sequence of define 
  numieric names.

  #$number_of_files_in	= 10;
  #$first_file_number_in  	= 1;
  #$last_file_number_in  	= 10;
  
        Common to all data files
  $input_suffix  	= '.su';

  		Path to directory list
  $list_directory       = '.';

  		One-line or  multi-line list with sepcific 
  		file names
  		but without an extension or suffix
  $list                 = 'cat_list_good_sp';

  		Catted file name
  $output_file_name     = 'All_good_sp';

  Another example:
  first_file_number_in   = 1000  a numerical value,
  last_file_number_in    = 1010  a numerical value,
  number_of_files_in     = 11    a numerical value,
  #output_file_name    = 1001_10 
  output_file_name    = 1000_10 
  #output_file_name    = All_good_SH_B4diff 
  #output_file_name    = SH_from_SW 
  #output_file_name    = SH_from_NE 
  input_suffix        =  '_clean.su' 
  #list               = list_good_shot_numbers
  #list               = list_good_shot_numbers
  #list               = list_good_SP_from_SW
  data_type			  =
  #list               = list_good_SP_from_NE
  list_directory= ./ 

=cut

use Moose;
our $VERSION = '2.0.2';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use App::SeismicUnixGui::configs::big_streams::Project_config;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get               = L_SU_global_constants->new();
my $config_superflows = config_superflows->new();
my $control           = control->new();
my $Project           = App::SeismicUnixGui::configs::big_streams::Project_config->new();

my $inbound_directory      = $Project->DATA_SEISMIC_SU(); #defaulted
my $outbound_directory     = $Project->DATA_SEISMIC_SU(); #defaulted
my $superflow_config_names = $get->superflow_config_names_aref();

# WARNING---- watch out for missing underscore!!
# print("1. Sucat_config,superflow_config_name : $$superflow_config_names[10]\n");

=head2 private hash

=cut

my $Sucat_config = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 10 is for Sucat

sub get_values {
    my ($self) = @_;

    # Warning: set using a scalar reference
    $Sucat_config->{_prog_name} = \@{$superflow_config_names}[10];

    # print("Sucat_config, prog_name : @{$superflow_config_names}[10]\n");

    $config_superflows->set_program_name( $Sucat_config->{_prog_name} );

    # parameter values from superflow configuration file
    $Sucat_config->{_values_aref} = $config_superflows->get_values();

    # print("Sucat_config,values=@{$Sucat_config->{_values_aref}}\n");

    my $first_file_number_in = @{ $Sucat_config->{_values_aref} }[0];
    my $last_file_number_in  = @{ $Sucat_config->{_values_aref} }[1];
    my $number_of_files_in   = @{ $Sucat_config->{_values_aref} }[2];

    my $input_suffix         = @{ $Sucat_config->{_values_aref} }[3];
    my $input_name_prefix    = @{ $Sucat_config->{_values_aref} }[4];
    my $input_name_extension = @{ $Sucat_config->{_values_aref} }[5];
    my $list                 = @{ $Sucat_config->{_values_aref} }[6];    
    my $output_file_name     = @{ $Sucat_config->{_values_aref} }[7];
    my $alternative_inbound_directory  = @{ $Sucat_config->{_values_aref} }[8];
    my $alternative_outbound_directory  = @{ $Sucat_config->{_values_aref} }[9];

    my $CFG = {
        sucat => {
            1 => {
                first_file_number_in => $first_file_number_in,
                last_file_number_in  => $last_file_number_in,
                number_of_files_in   => $number_of_files_in,
                output_file_name  => $output_file_name,
                input_suffix      => $input_suffix,
     			input_name_prefix       => $input_name_prefix,
    			input_name_extension    => $input_name_extension,             
                list              => $list,
                alternative_inbound_directory => $alternative_inbound_directory,
                alternative_outbound_directory => $alternative_outbound_directory,
            }
        }
    };    # end of CFG hash

    return ( $CFG, $Sucat_config->{_values_aref} );  # hash and arrary reference

};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    my $max_index = 9;

    return ($max_index);
}

1;
