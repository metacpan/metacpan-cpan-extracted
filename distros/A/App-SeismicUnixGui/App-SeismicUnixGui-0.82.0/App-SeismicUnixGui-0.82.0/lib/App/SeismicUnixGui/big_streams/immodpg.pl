=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: immodpg (interactive ray trace modeling) 
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATES:    Feb 7 2020
 				April 4 2021
 
 Version  0.0.1 , 0.0.2

=head2 DESCRIPTION

   Interactively model first arrivals using raytracing approximation

=head2 USE

=head2 Examplesoff

=head2 SEISMIC UNIX NOTES

=head2 STEPS

=head2 NOTES 

 We are using Moose.
 Moose already declares that you need debuggers turned on
 so you don't need a linewlike the following:
 use warnings;
 
 When program starts change file is initialized to "no". --change file 
 is deleted and reset to a default "no" at the start. 
 change file is set to yes in Perl.
 however we are careful only to do so when the file indicates a previous 'no'
 and reset to no in fortran after fortran uses the setting
 When exiting the change file contains a "yes"

 Avoids asynchronous reading and writing crashes
 Lock files are not failsafe
 
 There are two types of methods:
 
 One method type only sets the message type (immodpg->set_option(message #)) and 
 indicates a forced change (immodpg->set_change(yes)) for use with fortran 
 program immodpg.for
 e.g., _setVbot_plus, _set_move_down.
 The gui shows a symbol for these cases

 A second type of method manages changing values for a parameter as well
 as the functions of the first method. These actions are relegated to
 immodpg
 eg., _setVbot, _setVtop_upper_layer, _setVincrement, _set_clip, _set_layer
 The gui shows a parameter value that can be changed by the user.
 The Entry widget is configured to recognize text value changes and
 a return(1) is needed to indicate a successful validation
 
immodpg must follow premmod to prevent logical circularity
as a result of the use of the 'aliased' syntax

April 2021, removed commented lines

=cut

use Moose;
our $VERSION = '0.0.1';
use Time::HiRes qw(gettimeofday tv_interval);
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::configs::big_streams::immodpg_config';
use aliased 'App::SeismicUnixGui::big_streams::immodpg_global_constants';
use aliased 'App::SeismicUnixGui::misc::premmod';
use App::SeismicUnixGui::big_streams::immodpg '0.0.2';
use aliased 'App::SeismicUnixGui::big_streams::immodpg';
use aliased 'App::SeismicUnixGui::sunix::shell::xk';

=head2 private anonymous hash 
used to hand off variables for external printing

=cut

my $immodpg_Tk = {
	_prompt                     => '',
	_base_file_name             => '',
	_pre_digitized_XT_pairs     => '',
	_data_traces                => '',
	_clip4plotEntry             => '',
	_lower_layerLabel           => '',
	_min_t_s                    => '',
	_min_x_m                    => '',
	_mw						    => '',
	_thickness_increment_m      => '',
	_thickness_mEntry           => '',
	_thickness_mLabel           => '',
	_source_depth_m             => '',
	_receiver_depth_m           => '',
	_reducing_vel_mps           => '',
	_plot_min_x_m               => '',
	_plot_max_x_m               => '',
	_plot_min_t_s               => '',
	_plot_max_t_s               => '',
	_previous_model             => '',
	_new_model                  => '',
	_layer                      => '',
	_mw                      => '',
	_thickness_increment_mEntry => '',
	_upper_layerLabel           => '',
	_VbotEntry                  => '',
	_VbotNtop_factorEntry       => '',
	_Vbot_upper_layerEntry      => '',
	_Vincrement                 => '',
	_VincrementEntry            => '',

};

=head2 Instantiate classes:

 Create a new version of the package 
 with a unique name

=cut

my $get_L_SU       	= L_SU_global_constants->new();
my $get_immodpg    	= immodpg_global_constants->new();
my $immodpg   		= immodpg->new();
my $immodpg_config 	= immodpg_config->new();

my $premmod 		= premmod->new();
my $xk      		= xk->new();
my $Project         = Project_config->new();

my $IMMODPG          	   = $Project->IMMODPG();

my $var_L_SU               = $get_L_SU->var();
my $global_libs 		   = $get_L_SU->global_libs();

my $var_immodpg            = $get_immodpg->var();
my $change_thickness_m_opt = $var_immodpg->{_thickness_m_opt};
my $clip_opt               = $var_immodpg->{_clip_opt};
my $exit_opt               = $var_immodpg->{_exit_opt};
my $immodpg_model 		   = $var_immodpg ->{_immodpg_model};
my $move_down_opt          = $var_immodpg->{_move_down_opt};
my $move_left_opt          = $var_immodpg->{_move_left_opt};
my $move_minus_opt         = $var_immodpg->{_move_minus_opt};
my $move_right_opt         = $var_immodpg->{_move_right_opt};
my $move_up_opt            = $var_immodpg->{_move_up_opt};
my $thickness_m_minus_opt  = $var_immodpg->{_thickness_m_minus_opt};
my $thickness_m_plus_opt   = $var_immodpg->{_thickness_m_plus_opt};
my $zoom_minus_opt         = $var_immodpg->{_zoom_minus_opt};
my $zoom_plus_opt          = $var_immodpg->{_zoom_plus_opt};

my $Vbot_opt             = $var_immodpg->{_Vbot_opt};
my $Vbot_upper_layer_opt = $var_immodpg->{_Vbot_upper_layer_opt};
my $Vbot_minus_opt       = $var_immodpg->{_Vbot_minus_opt};
my $Vbot_plus_opt        = $var_immodpg->{_Vbot_plus_opt};
my $Vtop_opt             = $var_immodpg->{_Vtop_opt};
my $Vtop_lower_layer_opt = $var_immodpg->{_Vtop_lower_layer_opt};
my $Vtop_minus_opt       = $var_immodpg->{_Vtop_minus_opt};
my $Vtop_plus_opt        = $var_immodpg->{_Vtop_plus_opt};

my $VbotNVtop_lower_layer_minus_opt = $var_immodpg->{_VbotNVtop_lower_layer_minus_opt};
my $VbotNVtop_lower_layer_plus_opt  = $var_immodpg->{_VbotNVtop_lower_layer_plus_opt};
my $VtopNVbot_upper_layer_minus_opt = $var_immodpg->{_VtopNVbot_upper_layer_minus_opt};
my $VtopNVbot_upper_layer_plus_opt  = $var_immodpg->{_VtopNVbot_upper_layer_plus_opt};
my $VbotNtop_multiply_opt           = $var_immodpg->{_VbotNtop_multiply_opt};
my $VbotNtop_plus_opt               = $var_immodpg->{_VbotNtop_plus_opt};
my $VbotNtop_minus_opt              = $var_immodpg->{_VbotNtop_minus_opt};

my $update_opt   = $var_immodpg->{_update_opt};
my $yes          = $var_L_SU->{_yes};
my $empty_string = $var_L_SU->{_empty_string};
my $on           = $var_L_SU->{_on};
my $off          = $var_L_SU->{_off};

=head2 Declare variables 
    in local memory space

=cut

my ( $Vtop_plus_button,                  $Vtop_minus_button );
my ( $Vbot_plus_button,                  $Vbot_minus_button );
my ( $VbotNtop_plus_button,              $VbotNtop_minus_button );
my ( $VtopNVbot_upper_layer_plus_button, $VtopNVbot_upper_layer_minus_button );
my ( $VbotNVtop_lower_layer_plus_button, $VbotNVtop_lower_layer_minus_button );
my $VbotNtop_multiply_button;
my ( $zoom_plus_button,        $zoom_minus_button );
my ( $move_down_button,        $move_left_button );
my ( $move_up_button,          $move_right_button );
my ( $thickness_m_plus_button, $thickness_m_minus_button );
my ( $exit_button,             $update_button );

my $rb_value = "red";
our $mw;

=head2 Declare:

default values for screen
when the configuration file is missing

=cut

my $Vtop_default                  = 1500.0;
my $Vbot_default                  = 1600.0;
my $VbotNtop_factor_default       = 1.;
my $Vtop_lower_layer_default      = 1600.0;
my $Vbot_upper_layer_default      = 15000.0;
my $change_default                = $var_immodpg->{_change_default};
my $clip4plot_default             = 1;
my $layer_default                 = 2;
my $lower_layer_default           = 3;
my $thickness_m_default           = 1000.001;
my $upper_layer_default           = 1;
my $Vincrement_mps_default        = 10;
my $thickness_increment_m_default = 10;

=head2 initialize:

useful variables with defaults

=cut

my $Vtop                  = $Vtop_default;
my $Vbot                  = $Vbot_default;
my $VbotNtop_factor       = $VbotNtop_factor_default;
my $Vtop_lower_layer      = $Vtop_lower_layer_default;
my $Vbot_upper_layer      = $Vbot_upper_layer_default;
my $upper_layer           = $upper_layer_default;
my $clip4plot             = $clip4plot_default;
my $layer                 = $layer_default;
my $lower_layer           = $lower_layer_default;
my $thickness_m           = $thickness_m_default;
my $Vincrement_mps        = $Vincrement_mps_default;
my $thickness_increment_m = $thickness_increment_m_default;


=head2 Create Main Window 

 Start event-driven loop
 Interaction with user
 
 immodpg requires Main window widget to display
 error messages

=cut

=head2 Decide whether to 
	Start Main widget but temporarily withdraw
	until checks are complete
	Window is needed for error messages

=cut

$mw = MainWindow->new;
$mw->withdraw;
$immodpg_Tk->{_mw}     = $mw;
$immodpg->set_widgets($immodpg_Tk);
$immodpg->initialize_messages();

=head2 clean old files
from past sessions

=cut

$immodpg->clean_trash();

=head2 initialize files
after cleaning trash

=cut
my $replacement= $global_libs->{_configs_big_streams}.'/'.$immodpg_model;
my $missing = $IMMODPG.'/'.$immodpg_model;
$immodpg->set_missing($missing);
$immodpg->set_replacement4missing($replacement);
$immodpg->get_replacement4missing();


=head2 initialize values
in modules

=cut
$immodpg->set_defaults();
$immodpg->set_change( $change_default);
$immodpg->initialize_model();

=head2 Get starting configuration
 
parameters from a configuration file

=cut

my ( $CFG_h, $CFG_aref ) = $immodpg_config->get_values();

my $base_file_name         = $CFG_h->{immodpg}{1}{base_file_name};
my $pre_digitized_XT_pairs = $CFG_h->{immodpg}{1}{offset_type};
my $data_traces            = $CFG_h->{immodpg}{1}{data_traces};
$clip4plot           = $CFG_h->{immodpg}{1}{clip};
my $min_t_s          = $CFG_h->{immodpg}{1}{min_t_s};
my $min_x_m          = $CFG_h->{immodpg}{1}{min_x_m};
my $data_x_inc_m     = $CFG_h->{immodpg}{1}{data_x_inc_m};
my $source_depth_m   = $CFG_h->{immodpg}{1}{source_depth_m};
my $receiver_depth_m = $CFG_h->{immodpg}{1}{receiver_depth_m};
my $reducing_vel_mps = $CFG_h->{immodpg}{1}{reducing_vel_mps};
my $plot_min_x_m     = $CFG_h->{immodpg}{1}{plot_min_x_m};
my $plot_max_x_m     = $CFG_h->{immodpg}{1}{plot_max_x_m};
my $plot_min_t_s     = $CFG_h->{immodpg}{1}{plot_min_t_s};
my $plot_max_t_s     = $CFG_h->{immodpg}{1}{plot_max_t_s};
my $previous_model   = $CFG_h->{immodpg}{1}{previous_model};
my $new_model        = $CFG_h->{immodpg}{1}{new_model};
$layer                 = $CFG_h->{immodpg}{1}{layer};
$VbotNtop_factor       = $CFG_h->{immodpg}{1}{VbotNtop_factor};
$Vincrement_mps        = $CFG_h->{immodpg}{1}{Vincrement_mps};
$thickness_increment_m = $CFG_h->{immodpg}{1}{thickness_increment_m};

=head2 Error checks
Adjust
working, upper,
and lower layer for
extraneous values

=cut

$immodpg->set_clip_control($clip4plot);
$clip4plot = $immodpg->get_control_clip();

$immodpg->set_layer_control($layer);
$layer = $immodpg->get_control_layer();
my $number_of_layers = $immodpg->get_number_of_layers();

#print("immodpg.pl, layer, number_of_layers=$number_of_layers\n");

$upper_layer = $layer - 1;

if ( $upper_layer < 1 ) {

	$upper_layer = $empty_string;
}

$lower_layer = $layer + 1;

#print("immodpg.pl, upper layer=$upper_layer\n");
#print("immodpg.pl, layer=$layer\n");
#print("immodpg.pl, lower layer=$lower_layer\n");

=head2 Get model values 
of Vp, thickness, and error switch from
immodpg.out for initial settings
in GUI

=cut

$immodpg->set_model_layer($layer);

my ( $Vp_ref, $dz, $error_switch ) = $immodpg->get_initialVp_dz4gui();

if ( $error_switch eq $off ) {
	# CASE 1 ALL OK
	
	my @V = @$Vp_ref;

	$Vbot_upper_layer = $V[0];
	$Vtop             = $V[1];
	$Vbot             = $V[2];
	$Vtop_lower_layer = $V[3];
	
	$thickness_m = $dz;

} elsif ( $error_switch eq $on ) {
		# CASE 2  BAD MODEL FILE
        print("immodpg.pl, CORRUPT immodpg.out (fortran binary model file)\n");
        
} else {
	print("immodpg.pl, unexpected variable\n");
}

=head2 Prepare su file
for input to immodpg.for
generate a binary file
	
=cut

$premmod->set_binary_strip();
$premmod->out_header_values();


=head2 Establish Main Window

=cut 
$mw->deiconify();
$mw->raise();
$mw->geometry("430x280+40+100");
$mw->title("immodpg2");
$mw->configure(
	-highlightcolor => 'blue',
	-background     => $var_L_SU->{_my_purple},
);
$mw->focusFollowsMouse;


=head2  top_settings frame

Contains:
(1) working layer
(2) z inc and V inc in m/s
 
help goes to superflow bindings 

=cut

my $Vlayer_frame = $mw->Frame(
	-borderwidth => $var_L_SU->{_no_borderwidth},
	-background  => $var_L_SU->{_my_purple},
	-relief      => 'groove',
);

=head2 Create

font types

=cut

my $arial_14 = $mw->fontCreate(
	'arial_14',
	-family => 'arial',
	-weight => 'normal',
	-size   => -14
);

my $arial_14_bold = $mw->fontCreate(
	'arial_14_bold',
	-family => 'arial',
	-weight => 'bold',
	-size   => -14
);

my $arial_14_italic = $mw->fontCreate(
	'arial_14_italic',
	-family => 'arial',
	-slant  => 'italic',
	-weight => 'bold',
	-size   => -14
);

my $arial_16 = $mw->fontCreate(
	'arial_16',
	-family => 'arial',
	-weight => 'normal',
	-size   => -16
);

my $arial_16_italic = $mw->fontCreate(
	'arial_16_italic',
	-family => 'arial',
	-slant  => 'italic',
	-weight => 'bold',
	-size   => -16
);
my $arial_18 = $mw->fontCreate(
	'arial_18',
	-family => 'arial',
	-weight => 'normal',
	-size   => -18
);

my $arial_18_italic = $mw->fontCreate(
	'arial_italic_18',
	-family => 'arial',
	-weight => 'normal',
	-slant  => 'italic',
	-size   => -18
);

my $arial_18_bold = $mw->fontCreate(
	'arial_18_bold',
	-family => 'arial',
	-weight => 'bold',
	-size   => -18
);

=head2 Entry widgets

=cut

=head2 VbotEntry

=cut

my $VbotEntry = $mw->Entry(
	-font         => $arial_18,
	-width        => $var_L_SU->{_7_characters},
	-background   => $var_L_SU->{_my_black},
	-foreground   => $var_L_SU->{_my_white},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$Vbot,
);

# print("main,VbotEntry= $VbotEntry\n");

=head2 VbotEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_VbotEntry} = $VbotEntry;

# print("main,immodpg_Tk->{_VbotEntry}= $immodpg_Tk->{_VbotEntry}\n");

$VbotEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVbot,
	-invalidcommand  => sub { print "VbotEntry_box,ERROR.\n" },
);

=head2 Vbot_upper_layerEntry

=cut

my $Vbot_upper_layerEntry = $mw->Entry(
	-font         => $arial_18,
	-width        => $var_L_SU->{_7_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$Vbot_upper_layer,
);

=head2 Vbot_upper_layerEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_Vbot_upper_layerEntry} = $Vbot_upper_layerEntry;

$Vbot_upper_layerEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVbot_upper_layer,
	-invalidcommand  => sub { print "Vbot_upper_layerEntry_box,ERROR.\n" },
);

=head2 VincrementEntry

=cut

my $VincrementEntry = $mw->Entry(
	-font         => $arial_16,
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$Vincrement_mps,
);

=head2 VincrementEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_VincrementEntry} = $VincrementEntry;

$VincrementEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVincrement,
	-invalidcommand  => sub { print "Vincrement_box,ERROR.\n" },
);

=head2 VtopEntry
=cut

my $VtopEntry = $mw->Entry(
	-font         => $arial_18,
	-width        => $var_L_SU->{_7_characters},
	-background   => $var_L_SU->{_my_black},
	-foreground   => $var_L_SU->{_my_white},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$Vtop,
);

=head2 VtopEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_VtopEntry} = $VtopEntry;

$VtopEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVtop,
	-invalidcommand  => sub { print "Vtop_box,ERROR.\n" },
);

=head2 VbotNtop_factorEntry

=cut

my $VbotNtop_factorEntry = $mw->Entry(
	-font         => $arial_16,
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$VbotNtop_factor,
);

=head2 VbotNtop_factorEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_VbotNtop_factorEntry} = $VbotNtop_factorEntry;

# print("immodpg.pl, VbotNtop_factorEntry = $immodpg_Tk->{_VbotNtop_factorEntry}\n");

$VbotNtop_factorEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVbotNtop_factor,
	-invalidcommand  => sub { print "VtopNbit_box,ERROR.\n" },
);

=head2 Vtop_lower_layerEntry

=cut

my $Vtop_lower_layerEntry = $mw->Entry(
	-font         => $arial_18,
	-width        => $var_L_SU->{_7_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$Vtop_lower_layer,
);

=head2 Vtop_lower_layerEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_Vtop_lower_layerEntry} = $Vtop_lower_layerEntry;

$Vtop_lower_layerEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_setVtop_lower_layer,
	-invalidcommand  => sub { print "Vtop_lower_layerEntry_box,ERROR.\n" },
);

=head2 clip4plotEntry

=cut

my $clip4plotEntry = $mw->Entry(
	-font         => $arial_16,
	-width        => $var_L_SU->{_1_character},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$clip4plot,
);

=head2 clip4plotEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_clip4plotEntry} = $clip4plotEntry;

$clip4plotEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_set_clip,
	-invalidcommand  => sub { print "clip_box,ERROR.\n" },
);

=head2 layerEntry

=cut

my $layerEntry = $mw->Entry(
	-font         => $arial_18,
	-justify      => 'center',
	-width        => $var_L_SU->{_1_character},
	-background   => $var_L_SU->{_my_black},
	-foreground   => $var_L_SU->{_my_white},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$layer,
);

=head2 layerEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_layerEntry} = $layerEntry;

$layerEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_set_layer,
	-invalidcommand  => sub { print "layer_box,ERROR.\n" },
);

=head2 lower_layerLabel

=cut

my $lower_layerLabel = $mw->Label(
	-font         => $arial_18,
	-justify      => 'center',
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$lower_layer,
);

=head2 lower_layerLabel widget will be updated
in immodpg

=cut

$immodpg_Tk->{_lower_layerLabel} = $lower_layerLabel;

=head2 Entry _thickness_increment_mEntryEntry

=cut

my $thickness_increment_mEntry = $mw->Entry(
	-font         => $arial_16,
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$thickness_increment_m,
);

=head2 thickness_increment_mEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_thickness_increment_mEntry} = $thickness_increment_mEntry;

$thickness_increment_mEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_set_thickness_increment_m,
	-invalidcommand  => sub { print "thickness_increment_box,ERROR.\n" },
);

=head2 thickness_mEntry

=cut

my $thickness_mEntry = $mw->Entry(
	-font         => $arial_18,
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_black},
	-foreground   => $var_L_SU->{_my_white},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$thickness_m,
);

=head2 thickness_mEntry 
MUST first be created before it can be used by
a callback subroutine
=cut

$immodpg_Tk->{_thickness_mEntry} = $thickness_mEntry;

$thickness_mEntry->configure(
	-validate        => 'focus',
	-validatecommand => \&_set_thickness_m,
	-invalidcommand  => sub { print "thickness_increment_box,ERROR.\n" },
);

=head2 thickness_mLabel

=cut

my $thickness_mLabel = $mw->Label(
	-font        => $arial_18_italic,
	-justify     => 'right',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
	-text        => ' thickness (m)',
);

=head2 upper_layerLabel

=cut

my $upper_layerLabel = $mw->Label(
	-font         => $arial_18,
	-justify      => 'center',
	-width        => $var_L_SU->{_4_characters},
	-background   => $var_L_SU->{_my_light_grey},
	-foreground   => $var_L_SU->{_my_black},
	-borderwidth  => $var_L_SU->{_no_borderwidth},
	-textvariable => \$upper_layer,
);

=head2 upper_layerLabel widget will be update
in immodpg

=cut

$immodpg_Tk->{_upper_layerLabel} = $upper_layerLabel;

=head2 Buttons widgets

=cut

=head2 Buttons widgets

=cut

=head2
row index=0

=cut 

$exit_button = $mw->Button(
	-font               => $arial_14_bold,
	-height             => $var_L_SU->{_1_character},
	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => 'Exit',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_yellow},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_black},
	-activeforeground   => $var_L_SU->{_my_black},
	-activebackground   => $var_L_SU->{_my_yellow},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_exit ],
);

=head2
row index

=cut 

$move_down_button = $mw->Button(
	-font               => $arial_14_bold,
	-height             => $var_L_SU->{_1_character},
	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => 'down',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_move_down ],
);

=head2
row index

=cut 

$move_left_button = $mw->Button(
	-font   => $arial_14_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '<--',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_move_left ],
);

=head2
row index

=cut 

$move_right_button = $mw->Button(
	-font   => $arial_14_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-->',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_move_right ],
);

=head2
row index

=cut 

$move_up_button = $mw->Button(
	-font   => $arial_14_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => 'up',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_move_up ],
);

=head2
row index 1-2 col 3

=cut 

$VtopNVbot_upper_layer_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVtopNVbot_upper_layer_plus ],
);

=head2
row index 3-4 col 4

=cut 

$VtopNVbot_upper_layer_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVtopNVbot_upper_layer_minus ],
);

=head2
row index 2, col 6

=cut 

$Vtop_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVtop_plus ],
);

=head2
row index 

=cut 

$VbotNtop_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbotNtop_plus ],
);

=head2

row index 

=cut 

$Vbot_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',

	#	-takefocus			=> 1,
	-command => [ \&_setVbot_plus ],
);

=head2

row index 

=cut 

$VbotNVtop_lower_layer_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_one_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_one_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbotNVtop_lower_layer_plus ],

);

=head2

row index 

=cut 

$VbotNVtop_lower_layer_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_one_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_one_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbotNVtop_lower_layer_minus ],

);

=head2 VbotNtop_multiply_button
row index = 1 col 2

=cut

$VbotNtop_multiply_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => 'x',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbotNtop_multiply ],
);

=head2 
row index = 1 col 2

=cut

$VbotNtop_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbotNtop_minus ],
);

=head2 
row index = 2 col 7

=cut

$Vtop_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_one_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_one_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVtop_minus ],

);

=head2 
row index = 3 col 7

=cut

$Vbot_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_one_character},

	#	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_one_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_setVbot_minus ],

);

=head2
row index

=cut 

$thickness_m_minus_button = $mw->Button(
	-font   => $arial_14_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_thickness_m_minus ],
);

=head2
row index

=cut 

$thickness_m_plus_button = $mw->Button(
	-font   => $arial_14_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_thickness_m_plus ],
);

=head2
row index=5

=cut 

$update_button = $mw->Button(
	-font               => $arial_14_bold,
	-height             => $var_L_SU->{_1_character},
	-border             => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => 'Update',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_yellow},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_black},
	-activeforeground   => $var_L_SU->{_my_black},
	-activebackground   => $var_L_SU->{_my_yellow},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_update ],
);

=head2 zoom_minus_button
row index 1-2 col 3

=cut 

$zoom_minus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '-',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_zoom_minus ],
);

=head2 zoom_plus_button
row index 1-2 col 3

=cut 

$zoom_plus_button = $mw->Button(
	-font   => $arial_18_bold,
	-height => $var_L_SU->{_1_character},

	#	-border            => 0,
	-padx               => 0,
	-pady               => 0,
	-text               => '+',
	-width              => $var_L_SU->{_1_character},
	-background         => $var_L_SU->{_my_light_grey},
	-foreground         => $var_L_SU->{_my_black},
	-disabledforeground => $var_L_SU->{_my_dark_grey},
	-activeforeground   => $var_L_SU->{_my_white},
	-activebackground   => $var_L_SU->{_my_dark_grey},
	-relief             => 'flat',
	-state              => 'active',
	-command            => [ \&_set_zoom_plus ],
);

=head2 Label widgets

=cut

=head2 Label 
widget box for Vbot of upper layer

=cut

my $Vbot_upper_label = $mw->Label(
	-font        => $arial_18,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vbot',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for Vincrement

=cut

my $Vincrement_label = $mw->Label(
	-font        => $arial_16_italic,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vinc (m/s)',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
#widget box for Vtop

=cut

my $Vtop_label = $mw->Label(
	-font        => $arial_18_bold,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vtop',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for Vtop of lower layer

=cut

my $Vtop_lower_layer_label = $mw->Label(
	-font        => $arial_18,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vtop',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for Vbot

=cut

my $Vbot_label = $mw->Label(
	-font        => $arial_18_bold,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vbot',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
 factor

=cut

my $VbotNtop_factor_label = $mw->Label(
	-font        => $arial_16_italic,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'Vfactor',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
 clip4plot

=cut

my $clip4plot_label = $mw->Label(
	-font        => $arial_16_italic,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'clip',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for thicknes increment

=cut

my $thickness_increment_m_label = $mw->Label(
	-font        => $arial_16_italic,
	-padx        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => 'inc (m)',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
 empty

=cut

my $empty_label = $mw->Label(
	-font        => $arial_14,
	-pady        => $var_L_SU->{_3_pixels},
	-height      => $var_L_SU->{_1_character},
	-width       => $var_L_SU->{_4_characters},
	-text        => '',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_my_purple},
);

=head2 Label 
widget box for Layer number

=cut

my $layerLabel = $mw->Label(
	-font    => $arial_18_italic,
	-justify => 'left',

	#	-padx		 => $var_L_SU->{_3_pixels},
	#	-height      => $var_L_SU->{_1_character},
	#	-width       => $var_L_SU->{_2_characters},
	-text        => 'layer',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for Layer number

=cut

my $move_label = $mw->Label(
	-font    => $arial_14_italic,
	-justify => 'center',

	#	-padx		 => $var_L_SU->{_3_pixels},
	#	-height      => $var_L_SU->{_1_character},
	#	-width       => $var_L_SU->{_2_characters},
	-text        => 'move',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for velocity m/s

=cut

my $velocity_label = $mw->Label(
	-font    => $arial_18_italic,
	-justify => 'center',

	#	-padx		 => $var_L_SU->{_3_pixels},
	#	-height      => $var_L_SU->{_1_character},
	#	-width       => $var_L_SU->{_2_characters},
	-text        => 'Vp m/s',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=head2 Label 
widget box for Layer number

=cut

my $zoom_label = $mw->Label(
	-font    => $arial_14_italic,
	-justify => 'center',

	#	-padx		 => $var_L_SU->{_3_pixels},
	#	-height      => $var_L_SU->{_1_character},
	#	-width       => $var_L_SU->{_2_characters},
	-text        => 'zoom',
	-borderwidth => $var_L_SU->{_1_pixel},
	-background  => $var_L_SU->{_light_gray},
);

=pod GRID STARTS HERE 

=cut

=head2
row index = 0 col8

=cut

$Vlayer_frame->grid(
	$velocity_label,
	-row        => 0,
	-column     => 8,
	-columnspan => 1,
	-sticky     => 'ew',
);

=head2
row index = 0 col 9

=cut

$Vlayer_frame->grid(
	$layerLabel,
	-row        => 0,
	-column     => 9,
	-columnspan => 1,
	-sticky     => 'ew',
);

=head2
row index = 0 col 10

=cut

$Vlayer_frame->grid(
	$thickness_mLabel,
	-row        => 0,
	-column     => 10,
	-columnspan => 2,
	-sticky     => 'ew',
);

=head2
row index = 1-2 col 3

=cut

$Vlayer_frame->grid(
	$VtopNVbot_upper_layer_plus_button,
	-row     => 1,
	-column  => 3,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 1-2 col4

=cut

$Vlayer_frame->grid(
	$VtopNVbot_upper_layer_minus_button,
	-row     => 1,
	-column  => 4,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 1 col 8

=cut

$Vlayer_frame->grid(
	$Vbot_upper_layerEntry,
	-row     => 1,
	-column  => 8,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 1 col 9

=cut

$Vlayer_frame->grid(
	$upper_layerLabel,
	-row     => 1,
	-column  => 9,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 2 col 8

=cut

$Vlayer_frame->grid(
	$VtopEntry,
	-row     => 2,
	-column  => 8,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 2 col9

=cut

$Vlayer_frame->grid(
	$layerEntry,
	-row     => 2,
	-column  => 9,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 2 col10

=cut

$Vlayer_frame->grid(
	$thickness_mEntry,
	-row     => 2,
	-column  => 10,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 2 col11

=cut

$Vlayer_frame->grid(
	$thickness_m_minus_button,
	-row     => 2,
	-column  => 11,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 3 col11

=cut

$Vlayer_frame->grid(
	$thickness_m_plus_button,
	-row     => 3,
	-column  => 11,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 3 col 8

=cut

$Vlayer_frame->grid(
	$VbotEntry,
	-row     => 3,
	-column  => 8,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 4 col 8

=cut

$Vlayer_frame->grid(
	$Vtop_lower_layerEntry,
	-row     => 4,
	-column  => 8,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 4 col 9

=cut

$Vlayer_frame->grid(
	$lower_layerLabel,
	-row     => 4,
	-column  => 9,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 3-4 col 3

=cut

$Vlayer_frame->grid(
	$VbotNVtop_lower_layer_plus_button,
	-row     => 3,
	-column  => 3,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 3-4 col 4

=cut

$Vlayer_frame->grid(
	$VbotNVtop_lower_layer_minus_button,
	-row     => 3,
	-column  => 4,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 1 col 5

=cut

$Vlayer_frame->grid(
	$Vbot_upper_label,
	-row     => 1,
	-column  => 5,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index = 2-3 col0

=cut

$Vlayer_frame->grid(
	$VbotNtop_multiply_button,
	-row     => 2,
	-column  => 0,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 2-3 col 1

=cut

$Vlayer_frame->grid(
	$VbotNtop_plus_button,
	-row     => 2,
	-column  => 1,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
row index = 2-3 col2

=cut

$Vlayer_frame->grid(
	$VbotNtop_minus_button,
	-row     => 2,
	-column  => 2,
	-rowspan => 2,
	-sticky  => 'nsew',
);

=head2
 row index 2 col 5
 
=cut

$Vlayer_frame->grid(
	$Vtop_label,
	-row     => 2,
	-column  => 5,
	-rowspan => 1,
);

=head2
row index 2 col 6

=cut

$Vlayer_frame->grid(
	$Vtop_plus_button,
	-row     => 2,
	-column  => 6,
	-rowspan => 1,
);

=head2
row index 2 col 7

=cut

$Vlayer_frame->grid(
	$Vtop_minus_button,
	-row     => 2,
	-column  => 7,
	-rowspan => 1,
);

=head2
row index 3 col5

=cut

$Vlayer_frame->grid(
	$Vbot_label,
	-row     => 3,
	-column  => 5,
	-rowspan => 1,
);

=head2
row index 3 col 6

=cut

$Vlayer_frame->grid(
	$Vbot_plus_button,
	-row     => 3,
	-column  => 6,
	-rowspan => 1,
);

=head2
row index 3 col 7

=cut

$Vlayer_frame->grid(
	$Vbot_minus_button,
	-row     => 3,
	-column  => 7,
	-rowspan => 1,
);

=head2
row index 4 col 5
=cut

$Vlayer_frame->grid(
	$Vtop_lower_layer_label,
	-row     => 4,
	-column  => 5,
	-rowspan => 1,
	-sticky  => 'nsew',
);

=head2
row index 5 col 8
=cut

$Vlayer_frame->grid(
	$update_button,
	-row        => 5,
	-column     => 8,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 5 col 4

=cut

$Vlayer_frame->grid(
	$empty_label,
	-row        => 5,
	-column     => 4,
	-columnspan => 2,
	-rowspan    => 1,
	-pady       => 1,
	-sticky     => 'nsew',
);

=head2
row index = 0 col 0

=cut

$Vlayer_frame->grid(
	$exit_button,
	-row        => 0,
	-column     => 0,
	-columnspan => 2,
	-rowspan    => 1,
	-pady       => 1,
	-sticky     => 'nsew',
);

=head2
row index = 8 col 1

=cut

$Vlayer_frame->grid(
	$move_down_button,
	-row        => 8,
	-column     => 1,
	-columnspan => 2,
	-rowspan    => 1,
	-pady       => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 0

=cut

$Vlayer_frame->grid(
	$move_left_button,
	-row        => 7,
	-column     => 0,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 3

=cut

$Vlayer_frame->grid(
	$move_right_button,
	-row        => 7,
	-column     => 3,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 6 col 1

=cut

$Vlayer_frame->grid(
	$move_up_button,
	-row        => 6,
	-column     => 1,
	-columnspan => 2,
	-pady       => 0,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 1

=cut

$Vlayer_frame->grid(
	$move_label,
	-row        => 7,
	-column     => 1,
	-columnspan => 2,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 5

=cut

$Vlayer_frame->grid(
	$zoom_label,
	-row        => 7,
	-column     => 5,
	-columnspan => 2,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 6 col 5

=cut

$Vlayer_frame->grid(
	$zoom_plus_button,
	-row        => 6,
	-column     => 5,
	-columnspan => 2,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 8 col 5

=cut

$Vlayer_frame->grid(
	$zoom_minus_button,
	-row        => 8,
	-column     => 5,
	-columnspan => 2,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 6 col 8

=cut

$Vlayer_frame->grid(
	$Vincrement_label,
	-row        => 6,
	-column     => 8,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 8

=cut

$Vlayer_frame->grid(
	$thickness_increment_m_label,
	-row        => 7,
	-column     => 8,        #
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 8 col 8

=cut

$Vlayer_frame->grid(
	$VbotNtop_factor_label,
	-row        => 8,
	-column     => 8,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 9 col 9

=cut

$Vlayer_frame->grid(
	$clip4plot_label,
	-row        => 9,
	-column     => 8,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 9 col 8

=cut

$Vlayer_frame->grid(
	$clip4plotEntry,
	-row        => 9,
	-column     => 9,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 6 col 9

=cut

$Vlayer_frame->grid(
	$VincrementEntry,
	-row        => 6,
	-column     => 9,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 7 col 9

=cut

$Vlayer_frame->grid(
	$thickness_increment_mEntry,
	-row        => 7,
	-column     => 9,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

=head2
row index = 9 col 8

=cut

$Vlayer_frame->grid(
	$VbotNtop_factorEntry,
	-row        => 8,
	-column     => 9,
	-columnspan => 1,
	-rowspan    => 1,
	-sticky     => 'nsew',
);

MainLoop;    # for Tk widgets

sub _delay {
	my ($self) = @_;
	
	my ($time_passed, $usecs_now,$usecs_start);
	my ($secs_now,$secs_start);
	
	($secs_start,$usecs_start) = gettimeofday(); 
	$time_passed = $var_immodpg->{_time_passed_us_default};
	
	while ( $time_passed < $var_immodpg->{_time_delay_us} ) {

		($secs_now,$usecs_now) = gettimeofday();
	    $time_passed = $usecs_now - $usecs_start;

	}
	
#	if( $time_passed > $var_immodpg->{_time_delay_s} ) {
#	 	   print("usecs_now  = $usecs_now\n");
#           print("time_passed=$time_passed\n");
#	}
	
	return();
	 }

=head2 sub _setVincrement
_setVincrement sets
interaction with immodpg.for
writes out Vincrement for immodpg to read
 return(1) validates command for Entry
 
=cut

sub _setVincrement {

	# print("immodpg.pl,_Vincrement,$immodpg_Tk->{_VincrementEntry}\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVincrement();
	return (1);
}

=head2 sub _setVbotNtop_factor
_setVbotNtop_factor sets
interaction with immodpg.for
writes out VbotNtop_factor for immodpg to read
 return(1) validates command for Entry
 
=cut

sub _setVbotNtop_factor {

	# print("immodpg.pl,_setVbotNtop_factor,$immodpg_Tk->{_VbotNtop_factorEntry}\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbotNtop_factor();
	return (1);
}

=head2 sub _set_clip
_set_clip sets
interaction with immodpg.for
writes out clip for immodpg to read
return(1) validates command for Entry'

=cut

sub _set_clip {

	#	print("immodpg.pl,_set_clip,$immodpg_Tk->{_clip4plotEntry}\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->set_clip();
	return (1);
}

=head2 sub _set_layer
 callbacks
 write out message for mmodpg.f
 writes out layer for immodpg to read
 return(1) validates command for Entry
 
=cut

sub _set_layer {

	#	print("immodpg.pl,_set_layer,$immodpg_Tk->{_layerEntry}\n");
	#	print("\nimmodpg.pl,_set_layer,layer=$layer\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->set_layer();
	return (1);
}

=head2 sub _setVbot
 callbacks:
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f
 return(1) validates command for Entry
 
=cut

sub _setVbot {

	# print("main,_setVbot, Vbot_opt=$Vbot_opt\n");
	# print("main,_setVbot, immodpg_Tk->{_VbotEntry}= $immodpg_Tk->{_VbotEntry}\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbot();
	return (1);
}

=head2 sub _setVbot_upper_layer
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f
 return(1) validates command for Entry
 
=cut

sub _setVbot_upper_layer {

	my ($self) = @_;

	#	print("main,_setVbot_upper_layer, Vbot_upper_layer_opt=$Vbot_upper_layer_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbot_upper_layer();
	return (1);
}

=head2 sub _setVtop
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f
 return(1) validates command for Entry

=cut

sub _setVtop {

	# print("main,_setVtop, Vtop_opt=$Vtop_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVtop();
	return (1);
}

=head2 sub _setVtop_lower_layer
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f
 return(1) validates command for Entry
 
=cut

sub _setVtop_lower_layer {

	my ($self) = @_;

	#	print("main,_setVtop_lower_layer, Vtop_lower_layer_opt=$Vtop_lower_layer_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVtop_lower_layer();
	return (1);
}

=head2 sub _setVbotNtop_multiply
 callbacks:
 - provide widgets to immodpg
 -refocus allows other Entries to update (focus)
 -update the gui for factor (_setVbotNtop_factor)
 _setVbotNtop_factor ALSO provides widgets to immodpg
 -update gui velocities (->setVbotNtop_multiply)
 -write out message for mmodpg.f:
 	set_option
 	set_change
 	set interactions with immodpg.f

=cut

sub _setVbotNtop_multiply {

	# print("main,_setVbotNtop_multiply, VbotNtop_multiply_opt=$VbotNtop_multiply_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbotNtop_multiply();

}

=head2 sub _setVbot_minus

 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f

=cut

sub _setVbot_minus {

	$immodpg->set_widgets($immodpg_Tk);

	# print("write Vbot_minus_opt -, $Vbot_minus_opt\n");
	$immodpg->setVbot_minus();

}


=head2 sub _setVbotNVtop_lower_layer_minus
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f

=cut

sub _setVbotNVtop_lower_layer_minus {

	$immodpg->set_widgets($immodpg_Tk);

	#	print("write VbotNVtop_lower_layer_minus -, $VbotNVtop_lower_layer_minus_opt \n");
	$immodpg->setVbotNVtop_lower_layer_minus();

}

=head2 sub _setVbotNVtop_lower_layer_plus
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f

=cut

sub _setVbotNVtop_lower_layer_plus {

	$immodpg->set_widgets($immodpg_Tk);

	# print("write VbotNVtop_lower_layer_plus +, $VbotNVtop_lower_layer_plus_opt \n");
	$immodpg->setVbotNVtop_lower_layer_plus();

}

=head2 sub _setVbot_plus
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f

=cut

sub _setVbot_plus {

	#	print("main  _setVbot_plus,Vbot_plus_opt +=$Vbot_plus_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbot_plus();

}

=head2 sub _setVtop_minus
 callbacks
 setVtop_minus:
 modify gui
 set_option: 
 write out message for mmodpg.f
 set_change:
 set interactions with immodpg.f

=cut

sub _setVtop_minus {

	# print("write Vtop_minus_opt -, $Vtop_minus_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVtop_minus();

}

=head2 sub _setVtop_plus
 callbacks
 setVtop_plus:
 modify gui
 set_option: 
 write out message for mmodpg.f
 set_change:
 set interactions with immodpg.f

=cut

sub _setVtop_plus {

	# print("write Vtop_plus_opt +,$Vtop_plus_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVtop_plus();

}

=head2 sub _setVbotNtop_minus
 callbacks
 setVtop_plus:
 modify gui
 set_option: 
 write out message for mmodpg.f
 set_change:
 set interactions with immodpg.f
 
 create pause between Vbot and Vtop changes

=cut

sub _setVbotNtop_minus {
	my ($self) = @_;
    
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbotNtop_minus();
	
}

=head2 sub _setVbotNtop_plus
 callbacks
 write out message for mmodpg.f
 set_option and set_change
 set interactions with immodpg.f
 
=cut

sub _setVbotNtop_plus {

	# print("write VbotNVtop_plus +\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->setVbotNtop_plus();

}


=head2 sub _setVtopNVbot_upper_layer_minus
 callbacks
 setVtop_plus:
 modify gui
 set_option: 
 write out message for mmodpg.f
 set_change:
 set interactions with immodpg.f

=cut

sub _setVtopNVbot_upper_layer_minus {

	$immodpg->set_widgets($immodpg_Tk);
	# print("main,_setVtopNVbot_upper_layer_minus, write VtopNVbot_upper_layer_minus -,$VtopNVbot_upper_layer_minus_opt \n");
	$immodpg->setVtopNVbot_upper_layer_minus();
}

=head2 sub _setVtopNVbot_upper_layer_plus
 callbacks
 setVtop_plus:
 modify gui
 set_option: 
 write out message for mmodpg.f
 set_change:
 set interactions with immodpg.f

=cut

sub _setVtopNVbot_upper_layer_plus {

	$immodpg->set_widgets($immodpg_Tk);

	#	print("write VtopNVbot_upper_layer_plus +, $VtopNVbot_upper_layer_plus_opt \n");
	$immodpg->setVtopNVbot_upper_layer_plus();

}

=head2 sub _set_exit

 callbacks
 write out message for mmodpg.f
 write out
  saying goodbye
  clear old images
  kill window
  stop script

=cut

sub _set_exit {

	my ($self) = @_;

	# print("write_set_exit\n");
	#	$exit_button->focus;
	$immodpg->set_option($exit_opt);
	$immodpg->set_change($yes);
	
	# kill pgxwin_server
	$immodpg->exit();

	# kill mw window
	$mw->destroy() if Tk::Exists($mw);

}

=head2 sub _set_move_down
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_move_down {

	#	$move_down_button->focus;
	# print("write _set_move_down -\n");
	$immodpg->set_option($move_down_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_move_left
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_move_left {

	#	$move_left_button->focus;
	# print("write_set_move_left -\n");
	$immodpg->set_option($move_left_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_move_right
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_move_right {

	#	$move_right_button->focus;
	# print("write_set_move_right -\n");
	$immodpg->set_option($move_right_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_move_up
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_move_up {

	# print("write_set_move_up -\n");
	#	$move_up_button->focus;
	$immodpg->set_option($move_up_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_update
New focus is needed within set_update,
specifically:
 immodpg,_check_update
=cut

sub _set_update {

	my ($self) = @_;

	#print("immodpg.pl,_set_update\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->set_update();
	return ();
}

=head2 sub _set_zoom_minus
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_zoom_minus {

	# print("write_set_zoom_minus -\n");
	$immodpg->set_option($zoom_minus_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_zoom_plus
 callbacks
 write out message for mmodpg.f
 write out

=cut

sub _set_zoom_plus {

	# print("write _set_zoom_plus +\n");
	$immodpg->set_option($zoom_plus_opt);
	$immodpg->set_change($yes);

}

=head2 sub _set_thickness_m

=cut

sub _set_thickness_m {

	# print("main,_set_thickness_m, change_thickness_m_opt=$change_thickness_m_opt\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->set_thickness_m();
	return (1);

}

=head2 sub _set_thickness_m_minus

=cut

sub _set_thickness_m_minus {

	$immodpg->set_widgets($immodpg_Tk);

	# print("write _set_thickness_m_minus - \n");
	$immodpg->set_thickness_m_minus();

}

=head2 sub _set_thickness_m_plus

=cut

sub _set_thickness_m_plus {

	$immodpg->set_widgets($immodpg_Tk);

	# print("write _set_thickness_m_plus -\n");
	$immodpg->set_thickness_m_plus();

}

=head2 sub _set_thickness_increment_m

=cut

sub _set_thickness_increment_m {

	# print("immodpg.pl,_thickness_increment_m,$immodpg_Tk->{_thickness_increment_mEntry}\n");
	$immodpg->set_widgets($immodpg_Tk);
	$immodpg->set_thickness_increment_m();
	return (1);
}
