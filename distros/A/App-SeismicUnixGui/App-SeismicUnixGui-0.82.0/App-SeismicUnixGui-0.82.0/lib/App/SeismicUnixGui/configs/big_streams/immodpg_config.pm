package App::SeismicUnixGui::configs::big_streams::immodpg_config;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: immodpg_config.pm 
 AUTHOR: Juan Lorenzo
 DATE: Feb 24 2020
 DESCRIPTION: interactive raytraced modeling
 of first arrivals

 USED 

 BASED ON:PL_SEISMIC
 mmodpg by Emilio Vera
     
   
 Needs: Simple (ASCII) local configuration 
      file is immodpg.config


=cut

=head2 EXAMPLE
 
 	contains all the configuration variables 

base_file_name			= file (su format by default_path)
pre_digitized_XT_pairs	= no 
data_traces			= yes
clip				= 10.000000
min_t_s				= 0.000000
min_x_m				= 0.000000
thickness_increment_m		= 0.1000
source_depth_m		= 0.
receiver_depth_m	= 0.
reducing_vel_mps	= 0.000
plot_min_x_m		= 0.
plot_max_x_m		= 10.
plot_min_t_s		= 0.000
plot_max_t_s		= .1
previous_model		= yes
new_model			= no
layer		= 1
 
=cut 

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su);
use aliased 'App::SeismicUnixGui::misc::config_superflows';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::big_streams::immodpg_global_constants';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::misc::files_LSU';

my $Project                = Project_config->new();
my $control                = control->new();
my $config_superflows      = config_superflows->new();
my $get                    = L_SU_global_constants->new();
my $manage_files_by2       = manage_files_by2->new();
my $immodpg_global_constants = immodpg_global_constants->new();

my $DATA_SEISMIC_SU        = $Project->DATA_SEISMIC_SU();
my $IMMODPG                = $Project->IMMODPG();
my $superflow_config_names = $get->superflow_config_names_aref();
my $var                    = $immodpg_global_constants->var();

my $GLOBAL_CONFIG_LIB = ( $get->global_libs )->{_configs_big_streams};

# WARNING---- watch out for missing underscore!!

=head2 define private hash

=cut

my $immodpg_config = {
	_prog_name         => '',
	_values_aref       => '',
	_model_file_text   => '',
	_GLOBAL_CONFIG_LIB => '',
};

=head2 assign values to local variables

=cut

my $program_name   = 'immodpg';
my $config_file    = $program_name . '.config';
my $inbound_config = $IMMODPG . '/' . $config_file;

# my $outbound_config             		=  . '/' . $config_file;
$immodpg_config->{_model_file_text}   = $var->{_immodpg_model_file_text};
$immodpg_config->{_GLOBAL_CONFIG_LIB} = $GLOBAL_CONFIG_LIB;

=head Create the configuration file 

Create the configuration file if it does
not exist,using the default configuration
file

=cut

if ( $manage_files_by2->does_file_exist( \$inbound_config ) ) {

	# print("immodpg_config, found configuration file\n");
	# print("immodpg_config, $inbound_config\n");
	# print("immodpg_config, NADA\n");

} elsif ( not $manage_files_by2->does_file_exist( \$inbound_config ) ) {

	# print("immodpg_config, missing immodpg config file\n");
	my $files_LSU = files_LSU->new();

	$files_LSU->set_config();
	$files_LSU->set_prog_name_sref( \$program_name );    # scalar ref
	$files_LSU->outbound();                              # scalar ref
	$files_LSU->copy_default_config();

} else {
	print("immodpg.pl, unexpected config file\n");
}

_set_model_file_text();

=head2 Create a model test file as text

Create a basic model.txt file if it does not exist
in either or both the hidden and invisible working
directories.
copying over an example simple test file

=cut

sub _set_model_file_text {
	my ($self) = @_;

	if ( length( $immodpg_config->{_model_file_text} ) ) {

		use File::Copy;
		my ( $to, $from );

		my $inbound_model_file_text_extra
			= ( $immodpg_config->{_GLOBAL_CONFIG_LIB} ) . '/' . $immodpg_config->{_model_file_text};
		my $inbound_model_file_text
			= ( $immodpg_config->{_GLOBAL_CONFIG_LIB} ) . '/' . $immodpg_config->{_model_file_text};

		my $outbound_model_file_text = ( $Project->IMMODPG_INVISIBLE() ) . '/' . $immodpg_config->{_model_file_text};
		my $outbound_model_file_text_extra = ( $Project->IMMODPG() ) . '/' . $immodpg_config->{_model_file_text};

		if (    $manage_files_by2->does_file_exist( \$outbound_model_file_text )
			and $manage_files_by2->does_file_exist( \$outbound_model_file_text_extra ) ) {

			# CASE 1 do nothing--files are there
			# print("case 1, _set_model_file_text, found all model.text files\n");
			# print("case 1, _set_model_file_text, outbound_model_file_text=$outbound_model_file_text \n");
			# print("case 1, _set_model_file_text, outbound_model_file_text_extra=$outbound_model_file_text_extra \n");
			# print("_set_model_file_text, NADA\n");

		} elsif ( not $manage_files_by2->does_file_exist( \$outbound_model_file_text_extra )
			and $manage_files_by2->does_file_exist( \$outbound_model_file_text ) ) {

			# CASE 2 copy the version in the hidden directory to the visible directory
			# print("Case 2 immodpg_config,  _set_model_file_text, one missing case of model.text config file\n");

			$from = $outbound_model_file_text;
			$to   = $outbound_model_file_text_extra;
			copy( $from, $to );

		} elsif ( not $manage_files_by2->does_file_exist( \$outbound_model_file_text )
			and $manage_files_by2->does_file_exist( \$outbound_model_file_text_extra ) ) {

			# CASE 3 copy the file in the visible directory to the hidden directory
			print("case 3 _set_model_file_text, one missing case of model.text config file\n");
			$from = $outbound_model_file_text_extra;
			$to   = $outbound_model_file_text;
			copy( $from, $to );

		} elsif ( not $manage_files_by2->does_file_exist( \$outbound_model_file_text )
			and ( not $manage_files_by2->does_file_exist( \$outbound_model_file_text_extra ) ) ) {

			# CASE 4 copy the file in the hidden directory to the visible directory
#			print("case 4 _set_model_file_text, no cases of model.text file exist\n");
#			print("case 4 _set_model_file_text, inbound_model_file_text=$inbound_model_file_text \n");

			$from = $inbound_model_file_text;
			$to   = $outbound_model_file_text;
			copy( $from, $to );

			$from = $inbound_model_file_text_extra;
			$to   = $outbound_model_file_text_extra;
			copy( $from, $to );

		} else {
			print("immodpg.pl,_set_model_file_text, missing parameters\n");
		}

		return ();
	}
}

=head2 get_values
control for string quotes

=cut

# set the superflow name: 12 is for immodpg

sub get_values {

	my ($self) = @_;

	my $control = control->new();

	# Warning: set using a scalar reference
	$immodpg_config->{_prog_name} = \@{$superflow_config_names}[12];

#	print("immodpg_config, prog_name : @{$superflow_config_names}[12]\n");

	$config_superflows->set_program_name( $immodpg_config->{_prog_name} );

	# parameter values from superflow configuration file
	$immodpg_config->{_values_aref} = $config_superflows->get_values();

	# print("immodpg_config,values=--@{$immodpg_config->{_values_aref}}--\n");
	my $base_file_name = @{ $immodpg_config->{_values_aref} }[0];
	$base_file_name = $control->get_no_quotes($base_file_name);

	my $pre_digitized_XT_pairs = @{ $immodpg_config->{_values_aref} }[1];
	$pre_digitized_XT_pairs = $control->get_no_quotes($pre_digitized_XT_pairs);

	my $data_traces = @{ $immodpg_config->{_values_aref} }[2];
	$data_traces = $control->get_no_quotes($data_traces);

	my $clip                  = @{ $immodpg_config->{_values_aref} }[3];
	my $min_t_s               = @{ $immodpg_config->{_values_aref} }[4];
	my $min_x_m               = @{ $immodpg_config->{_values_aref} }[5];
	my $data_x_inc_m 			= @{ $immodpg_config->{_values_aref} }[6];
	my $source_depth_m        = @{ $immodpg_config->{_values_aref} }[7];
	my $receiver_depth_m      = @{ $immodpg_config->{_values_aref} }[8];
	my $reducing_vel_mps      = @{ $immodpg_config->{_values_aref} }[9];
	my $plot_min_x_m          = @{ $immodpg_config->{_values_aref} }[10];
	my $plot_max_x_m          = @{ $immodpg_config->{_values_aref} }[11];
	my $plot_min_t_s          = @{ $immodpg_config->{_values_aref} }[12];
	my $plot_max_t_s          = @{ $immodpg_config->{_values_aref} }[13];
	
	my $previous_model        = @{ $immodpg_config->{_values_aref} }[14];
	$previous_model = $control->get_no_quotes($previous_model);
	
	my $new_model = @{ $immodpg_config->{_values_aref} }[15];
	$new_model = $control->get_no_quotes($new_model);
	
	my $layer           = @{ $immodpg_config->{_values_aref} }[16];
	my $VbotNtop_factor = @{ $immodpg_config->{_values_aref} }[17];
	my $Vincrement_mps      = @{ $immodpg_config->{_values_aref} }[18];
	my $thickness_increment_m = @{ $immodpg_config->{_values_aref} }[19];

	# print("1. immodpg_config,base_file_name=$base_file_name\n");\
#	print("1. immodpg_config,Vincrement_mps=$Vincrement_mps\n");
#	print("1. immodpg_config,data_x_inc_m =$data_x_inc_m \n");
	$base_file_name         = $control->su_data_name( \$base_file_name );
	$new_model              = $control->get_no_quotes($new_model);
	$previous_model         = $control->get_no_quotes($previous_model);
	$data_traces            = $control->get_no_quotes($data_traces);
	$pre_digitized_XT_pairs = $control->get_no_quotes($pre_digitized_XT_pairs);

	# print("2. immodpg_config,new_model=$new_model\n");
	# print("immodpg_config, plot_min_t_s: $plot_min_t_s\n");
	# print("2. immodpg_config,base_file_name=$base_file_name\n");

=head2 Example LOCAL VARIABLES FOR THIS PROJECT

=cut

	my $CFG = {
		immodpg => {
			1 => {
				base_file_name         => $base_file_name,
				pre_digitized_XT_pairs => $pre_digitized_XT_pairs,
				data_traces            => $data_traces,
				clip                   => $clip,
				min_t_s                => $min_t_s,
				min_x_m                => $min_x_m,
				data_x_inc_m		   => $data_x_inc_m,
				source_depth_m         => $source_depth_m,
				receiver_depth_m       => $receiver_depth_m,
				reducing_vel_mps       => $reducing_vel_mps,
				plot_min_x_m           => $plot_min_x_m,
				plot_max_x_m           => $plot_max_x_m,
				plot_min_t_s           => $plot_min_t_s,
				plot_max_t_s           => $plot_max_t_s,
				previous_model         => $previous_model,
				new_model              => $new_model,
				layer                  => $layer,
				VbotNtop_factor        => $VbotNtop_factor,
				Vincrement_mps         => $Vincrement_mps,
				thickness_increment_m  => $thickness_increment_m,				

			}
		}
	};    # end of CFG hash
		  # print("immodpg_config,base_file_name=$CFG->{immodpg}{1}{base_file_name}\n");
#		  print("immodpg_config,data_x_inc_m=$CFG->{immodpg}{1}{data_x_inc_m/data_x}\n");
	return ( $CFG, $immodpg_config->{_values_aref} );    # hash and arrary reference
};    # end of sub get_values

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 19;

	return ($max_index);
}

1;
