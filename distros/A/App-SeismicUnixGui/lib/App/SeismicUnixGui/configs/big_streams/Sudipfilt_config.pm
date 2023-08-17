package App::SeismicUnixGui::configs::big_streams::Sudipfilt_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: Sudipfilt_config.pm
 AUTHOR: Juan Lorenzo
 DATE: 	 July 1 2016 
 	   
 DESCRIPTION Upper-level variable
 definitions for Sudipfilt 
 Package name is the same as the file name

 Package control corrects some values read
 in by Config::Simple
 
  	   Jan 11, 2018
  	   
 remove dependency on Config::Simple 

=cut

=head2 Notes 

 
=cut 

=head2 LOCAL VARIABLES FOR THIS PROJECT 

 Values taken from the simple,local
 file: Sudipfilt.config called
 LOCAL VARIABLES FOR THIS PROJECT
=head2 LOCAL VARIABLES FOR THIS PROJECT 

 Values taken from the simple,local
 file: Sudipfilt.config called

base_file_name = '11' 
sudipfilter_1_dt	= 1
sudipfilter_1_dx	= 1
sudipfilter_1_bias	= 0	
sudipfilter_1_slopes	='3,8,15,25,80'
sudipfilter_1_slopes	='1,4,7,12,80'
sudipfilter_1_amps	='0,0,1,0,0'
sudipfilter_1_amps	='1,1,0,0,1'

# second filter is not enacted
sudipfilter_2_dt	= 1
sudipfilter_2_dx	= 1
sudipfilter_2_bias	= 0
sudipfilter_2_slopes	= '-80,-20,-5,-1'
sudipfilter_2_slopes	= '-40,-10,-3,0'

sudipfilter_2_amps	= '0,0,0,1'

suinterp_ninterp                     = 1     

suwind_1_tmin	= 0
suwind_1_tmax	= 1 

suwind_2_key	= 'tracl'
suwind_2_min	= 1 
suwind_2_max	= 50 

suspecfk_1_dt	= 1
suspecfk_1_dx	= 1

sufilter_1_freq	= '0,3,80,200'
sufilter_1_amplitude	= '1,1,1,0'

#TOP_LEFT
TOP_LEFT_sugain_agc_switch = 1
TOP_LEFT_sugain_agc_width  = .1
TOP_LEFT_sugain_pbal_switch = 10

BOTTOM_RIGHT_suximage_absclip = 5 
 
=cut  

use Moose;
our $VERSION = '1.0.0';
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
#print("1. Sudipfilt_config,fk superflow_config_name : @{$superflow_config_names}\n");

=head2  private hash

=cut

my $Sudipfilt = {
    _prog_name   => '',
    _values_aref => '',
};

# set the superflow name: 0 is for fk-to-Sudipfilt

sub get_values {
    my ($self) = @_;

    # Warning: set using a scalar reference
    $Sudipfilt->{_prog_name} = \@{$superflow_config_names}[0];

#    print("Sudipfilt_config, get_values, prog_name : @{$superflow_config_names}[0]\n");

    $config_superflows->set_program_name( $Sudipfilt->{_prog_name} );

    # parameter values from superflow configuration file
    $Sudipfilt->{_values_aref} = $config_superflows->get_values();

    # print("Sudipfilt_config,values=@{$Sudipfilt->{_values_aref}}\n");

    # remove single or double quotes
    $Sudipfilt->{_values_aref} =
      $control->get_no_quotes4array( $Sudipfilt->{_values_aref} );

    my $base_file_name                = @{ $Sudipfilt->{_values_aref} }[0];
    my $sudipfilter_1_dt              = @{ $Sudipfilt->{_values_aref} }[1];
    my $sudipfilter_1_dx              = @{ $Sudipfilt->{_values_aref} }[2];
    my $sudipfilter_1_bias            = @{ $Sudipfilt->{_values_aref} }[3];
    my $sudipfilter_1_slopes          = @{ $Sudipfilt->{_values_aref} }[4];
    my $sudipfilter_1_amps            = @{ $Sudipfilt->{_values_aref} }[5];
    my $sudipfilter_2_dt              = @{ $Sudipfilt->{_values_aref} }[6];
    my $sudipfilter_2_dx              = @{ $Sudipfilt->{_values_aref} }[7];
    my $sudipfilter_2_bias            = @{ $Sudipfilt->{_values_aref} }[8];
    my $sudipfilter_2_slopes          = @{ $Sudipfilt->{_values_aref} }[9];
    my $sudipfilter_2_amps            = @{ $Sudipfilt->{_values_aref} }[10];
     my $suinterp_ninterp                = @{ $Sudipfilt->{_values_aref} }[11];
    my $suwind_1_tmin                 = @{ $Sudipfilt->{_values_aref} }[12];
    my $suwind_1_tmax                 = @{ $Sudipfilt->{_values_aref} }[13];
    my $suwind_2_key                  = @{ $Sudipfilt->{_values_aref} }[14];
    my $suwind_2_min                  = @{ $Sudipfilt->{_values_aref} }[15];
    my $suwind_2_max                  = @{ $Sudipfilt->{_values_aref} }[16];
    my $suspecfk_1_dt                 = @{ $Sudipfilt->{_values_aref} }[17];
    my $suspecfk_1_dx                 = @{ $Sudipfilt->{_values_aref} }[18];
    my $sufilter_1_freq               = @{ $Sudipfilt->{_values_aref} }[19];
    my $sufilter_1_amplitude          = @{ $Sudipfilt->{_values_aref} }[20];
    my $TOP_LEFT_sugain_pbal_switch   = @{ $Sudipfilt->{_values_aref} }[21];
    my $TOP_LEFT_sugain_agc_switch    = @{ $Sudipfilt->{_values_aref} }[22];
    my $TOP_LEFT_sugain_agc_width     = @{ $Sudipfilt->{_values_aref} }[23];
    my $BOTTOM_RIGHT_suximage_absclip = @{ $Sudipfilt->{_values_aref} }[24];

    # check on formats
    # $freq 							= $control->commas(\$freq); # needed?

    # print(" Sudipfilt_config, base_file_name is $base_file_name\n\n");
    # print ("Sudipfilt_config, pbal is $TOP_LEFT_sugain_pbal_switch\n\n");
    # print ("Sudipfilt_config,suwind_1_tmin  is $suwind_1_tmin\n\n");

=pod Package control 

 filename is file, without a suffix!
 In some cases, some numbers must be
 separated by commas

=cut

    # print ("Sudipfilt_config.pl,base_file_name was $base_file_name\n\n");
    # $base_file_name 		= $control->su_data_name($base_file_name);
    # print ("3. Sudipfilt_config.pl,base_file_name  is $base_file_name\n\n");
    #$CFG[7] 			= $control->commas(\$CFG[7]);
    #$CFG[11] 			= $control->commas(\$CFG[11]);
    #$CFG[17] 			= $control->commas(\$CFG[17]);
    #$CFG[21] 			= $control->commas(\$CFG[21]);
    #$CFG[23]      	= $control->commas(\$CFG[23]);
    #$CFG[25]      	= $control->commas(\$CFG[25]);

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut 

    my $CFG = {
        TOP_LEFT => {
            sugain => {
                agc_switch  => $TOP_LEFT_sugain_agc_switch,
                pbal_switch => $TOP_LEFT_sugain_pbal_switch,
                agc_width   => $TOP_LEFT_sugain_agc_width,
            },
        },
        BOTTOM_RIGHT =>
          { suximage => { absclip => $BOTTOM_RIGHT_suximage_absclip }, },
        sudipfilter => {
            1 => {
                dt     => $sudipfilter_1_dt,
                dx     => $sudipfilter_1_dx,
                slopes => $sudipfilter_1_slopes,
                bias   => $sudipfilter_1_bias,
                amps   => $sudipfilter_1_amps,
            },
            2 => {
                dt     => $sudipfilter_2_dt,
                dx     => $sudipfilter_2_dx,
                slopes => $sudipfilter_2_slopes,
                bias   => $sudipfilter_2_bias,
                amps   => $sudipfilter_2_amps,
            },
        },
        suwind => {
            1 => {
                tmin => $suwind_1_tmin,
                tmax => $suwind_1_tmax,
            },
            2 => {
                key => $suwind_2_key,
                min => $suwind_2_min,
                max => $suwind_2_max,
            },
        },
        sufilter => {
            1 => {
                freq      => $sufilter_1_freq,
                amplitude => $sufilter_1_amplitude,
            },
        },
         suinterp => {
            1 => {
                ninterp => $suinterp_ninterp,
            },
         },
        suspecfk => {
            1 => {
                dt => $suspecfk_1_dt,
                dx => $suspecfk_1_dx,
            }
        },
        base_file_name    => $base_file_name,
        inbound_directory => $DATA_SEISMIC_SU,

    };    # end of CFG hash

    return ( $CFG, $Sudipfilt->{_values_aref} );    # hash and arrary reference

};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=24
    my $max_index = 24;

    return ($max_index);
}

1;
