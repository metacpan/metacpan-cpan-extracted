package App::SeismicUnixGui::configs::big_streams::iSpectralAnalysis_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: iSpectralAnalysis_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: August 1 2016 
 DESCRIPTION Combines configuration variables
     both from a simple text file and from
     from additional packages.
     
=head2 CHANGES
DATE: Jan 11, 2018 
		remove dependency on Config::Simple

=head2 PURPOSE 

      Upper-level variable
      definitions in iSpectralAnalysis 
      Seismic data is assumed currently to be in
      su format.

 BASED ON:
     
   
 Needs: Simple (ASCII) local configuration 
      file is iSpectralAnalysis.config

=cut

=head2 Notes 
	anonymous array reference $CFG

 contains all the configuration variables in
 text script

  base_file_name     		= '1072_clean';

  sufilter_1_freq	  	= '0,1,20,40'

  sugain_1_agc_gain_width 	= 2.6;

  suxwigb_1_absclip 	= 100000;

  suxwigb_2_absclip_phase	= 100;

  suxwigb_3_absclip_freq	= 100;
      
 
=cut 

use Moose;
our $VERSION = '1.0.0';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);

my $Project                = Project_config->new();
my $config_superflows      = config_superflows->new();
my $L_SU_global_constants  = L_SU_global_constants->new();
my $DATA_SEISMIC_SU        = $Project->DATA_SEISMIC_SU();
my $superflow_config_names = $L_SU_global_constants->superflow_config_names_aref();

# WARNING---- watch out for missing underscore!!

=head2  private hash

=cut

my $iSpectralAnalysis_config = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 3 is for fk-to-Sudipfilt
sub get_values {

    my ($self) = @_;

    # Warning: set using a scalar reference
    $iSpectralAnalysis_config->{_prog_name} = \@{$superflow_config_names}[3];

# print("iSpectralAnalysis_config_config, prog_name : @{$superflow_config_names}[3]\n");

    $config_superflows->set_program_name(
        $iSpectralAnalysis_config->{_prog_name} );

    # parameter values from superflow configuration file
    $iSpectralAnalysis_config->{_values_aref} =
      $config_superflows->get_values();

# print("iSpectralAnalysis_config ,values=@{$iSpectralAnalysis_config->{_values_aref}}\n");

    my $base_file_name  = @{ $iSpectralAnalysis_config->{_values_aref} }[0];
    my $sufilter_1_freq = @{ $iSpectralAnalysis_config->{_values_aref} }[1];
    my $sugain_1_agc_gain_width =
      @{ $iSpectralAnalysis_config->{_values_aref} }[2];
    my $suxwigb_1_absclip = @{ $iSpectralAnalysis_config->{_values_aref} }[3];
    my $suxwigb_1_headerWord =
      @{ $iSpectralAnalysis_config->{_values_aref} }[4];
    my $suxwigb_2_absclip_phase =
      @{ $iSpectralAnalysis_config->{_values_aref} }[5];
    my $suxwigb_3_absclip_freq =
      @{ $iSpectralAnalysis_config->{_values_aref} }[6];

    # print("file name is $base_file_name\n\n");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

    my $CFG = {
        sufilter => { 1 => { freq           => $sufilter_1_freq, }, },
        sugain   => { 1 => { agc_gain_width => $sugain_1_agc_gain_width, }, },
        suxwigb  => {
            1 => {
                absclip    => $suxwigb_1_absclip,
                headerWord => $suxwigb_1_headerWord,
            },
            2 => { absclip_phase => $suxwigb_2_absclip_phase, },
            3 => { absclip_freq  => $suxwigb_3_absclip_freq, }
        },
        base_file_name => $base_file_name,
    };    # end of CFG hash

    return ( $CFG, $iSpectralAnalysis_config->{_values_aref} )
      ;    # hash and arrary reference

};    # end of sub get_values

=head2 sub get_max_index


max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 6;

    return ($max_index);
}
1;
