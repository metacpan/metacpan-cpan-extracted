package App::SeismicUnixGui::big_streams::immodpg;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: immodpg 
 AUTHOR: Juan Lorenzo
 DATE:   Feb 6 2020
 DESCRIPTION: 
 Version: 0.0.1
 

=head2 USE

=head3 NOTES
	    
	   Original Fortran code is by Emilio Vera
	   and is called mmodpg
	   
	   Modeling of Traveltime (T-X) Curves
	    
	   LDG:146O , 1984-1989
	   BOIGM, 1993
	   Depto. de Geofisica, U. de Chile, 1996-**
	    
	   Computations are carried out for a model consisting
	   of a mixture of horizontal constant velocity, and
   	  constant velocity gradient layers.Low velocity zones
	   can be included. Each layer is specified by its top
       and bottom velocity. Rays are traced using equispaced
	   ray parameterss.
	    
	   Data traces are presented  as a grey scale plot.
	   
	   TODO: _Vbot vs. _Vbot_current may confuse
	   key _Vbot is used only initially herein
	   _Vbot_current is the latest value in the gui
	   
	   The following order of operations is needed
	   to prevent the fortran programs from quickly 
	   reading the change (yes) BEFORE the options
	   and values are written out.
	   
	  _setVtop( $immodpg->{_Vtop_current} );
	  _set_option($changeVtop_opt);
	  _set_change($yes);
	   

=head4 
 Examples

=head3 

=head4 CHANGES and their DATES

V0.2 April 4, 2021

April 2021: controlled data input errors
Added model values to namespace of immodpg.pm


=cut

use Moose;
our $VERSION = '0.0.2';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::configs::big_streams::immodpg_config';
use aliased 'App::SeismicUnixGui::big_streams::immodpg_global_constants';
use aliased 'App::SeismicUnixGui::sunix::header::header_values';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::specs::big_streams::immodpg_spec';
use aliased 'App::SeismicUnixGui::sunix::shell::xk';

use Scalar::Util qw(looks_like_number);

=pod 
instantiate modules

=cut

my $Project        = Project_config->new();
my $get_L_SU       = L_SU_global_constants->new();
my $get_immodpg    = immodpg_global_constants->new();
my $immodpg_config = immodpg_config->new();
my $immodpg_spec   = immodpg_spec->new();

my $var_L_SU          = $get_L_SU->var();
my $var_immodpg       = $get_immodpg->var();
my $IMMODPG           = $Project->IMMODPG();
my $IMMODPG_INVISIBLE = $Project->IMMODPG_INVISIBLE();

my $empty_string            = $var_L_SU->{_empty_string};
my $yes                     = $var_L_SU->{_yes};
my $no                      = $var_L_SU->{_no};
my $on                      = $var_L_SU->{_on};
my $off                     = $var_L_SU->{_off};
my $global_libs             = $get_L_SU->global_libs();
my $immodpg_model_file_text = $var_immodpg->{_immodpg_model_file_text};
my $immodpg_model           = $var_immodpg->{_immodpg_model};

=head2 private anonymous array

=cut

my $immodpg = {
	_Vbot                              => '',
	_VbotEntry                         => '',
	_Vbot_current                      => '',
	_Vbot_default                      => '',
	_Vbot_multiplied                   => '',
	_Vbot_prior                        => '',
	_Vbot_upper_layer                  => '',
	_Vbot_upper_layerEntry             => '',
	_Vbot_upper_layer_current          => '',
	_Vbot_upper_layer_default          => '',
	_Vbot_upper_layer_prior            => '',
	_Vincrement                        => '',
	_VincrementEntry                   => '',
	_Vincrement_current                => '',
	_Vincrement_default                => '',
	_Vincrement_prior                  => '',
	_Vtop                              => '',
	_Vtop_current                      => '',
	_Vtop_prior                        => '',
	_Vtop_lower_layer_current          => '',
	_Vtop_lower_layer                  => '',
	_Vtop_lower_layer_prior            => '',
	_Vtop_multiplied                   => '',
	_VbotNtop_factor                   => '',
	_VbotNtop_factorEntry              => '',
	_VbotNtop_factor_current           => '',
	_VbotNtop_factor_default           => '',
	_VbotNtop_factor_prior             => '',
	_base_file_name                    => '',
	_cdp                               => '',
	_change_file                       => '',
	_change_default                    => $no,
	_clip                              => '',
	_clip_file                         => '',
	_clip4plot                         => '',
	_clip4plotEntry                    => '',
	_clip4plot_current                 => '',
	_clip4plot_default                 => '',
	_clip4plot_prior                   => '',
	_control_value                     => '',
	_data_traces                       => '',
	_control_layer                     => '',
	_control_layer_external            => '',
	_error_switch                      => '',
	_inbound_missing                   => '',
	_inVbot                            => '',
	_inVbot_upper_layer                => '',
	_inVincrement                      => '',
	_inVtop                            => '',
	_inVtop_lower_layer                => '',
	_inVbotNtop_factor                 => '',
	_in_clip                           => '',
	_in_layer                          => '',
	_layerEntry                        => '',
	_layer_current                     => '',
	_layer_default                     => '',
	_layer_prior                       => '',
	_in_thickness_increment_m          => '',
	_invert                            => '',
	_isVbot_changed_in_gui             => $no,
	_isVbot_upper_layer_changed_in_gui => $no,
	_isVincrement_changed_in_gui       => $no,
	_isVtop_changed_in_gui             => $no,
	_isVtop_lower_layer_changed_in_gui => $no,
	_isVbotNtop_factor_changed_in_gui  => $no,
	_is_clip_changed_in_gui            => $no,
	_is_layer_changed_in_gui           => $no,
	_is_layer_changed_in_gui           => $no,
	_layer                             => '',
	_layer_file                        => '',
	_lmute                             => '',
	_lower_layerLabel                  => '',
	_min_t_s                           => '',
	_min_x_m                           => '',
	_model_file_text               => $var_immodpg->{_immodpg_model_file_text},
	_model_error                   => $off,
	_model_layer_number            => '',
	_message_box_w                 => '',
	_message_upper_frame           => '',
	_message_lower_frame           => '',
	_message_label_w               => '',
	_message_box_wait              => '',
	_message_ok_button             => '',
	_mw                            => '',
	_new_model                     => '',
	_option_default                => -1,
	_option_file                   => '',
	_outsideVbot                   => '',
	_outsideVbot_upper_layer       => '',
	_outsideVincrement             => '',
	_outsideVtop                   => '',
	_outsideVtop_lower_layer       => '',
	_outsideVbotNtop_factor        => '',
	_outside_clip                  => '',
	_outside_layer                 => '',
	_outside_thickness_increment_m => '',
	_par                           => '',
	_plot_max_t_s                  => '',
	_plot_max_x_m                  => '',
	_plot_min_t_s                  => '',
	_plot_min_x_m                  => '',
	_pre_digitized_XT_pairs        => '',
	_previous_model                => '',
	_receiver_depth_m              => '',
	_reducing_vel_mps              => '',
	_refVPtop                      => '',
	_refVPbot                      => '',
	_ref_dz                        => '',
	_replacement4missing           => '',
	_scaled_par                    => '',
	_smute                         => '',
	_source_depth_m                => '',
	_sscale                        => '',
	_tnmo                          => '',
	_upper_layerLabel              => '',
	_upward                        => '',
	_vnmo                          => '',
	_voutfile                      => '',
	_thickness_increment_m         => '',
	_thickness_increment_mEntry    => '',
	_thickness_increment_m_current => '',
	_thickness_increment_m_default => '',
	_thickness_increment_m_prior   => '',
	_Step                          => '',
	_note                          => '',
};

#	print("immodpg, starting, _isVtop_lower_layer_changed_in_gui: $immodpg->{_is_isVtop_lower_layer_changed_in_gui}\n");

=head2 Define
private variables

=cut

$immodpg->{_Vbot_file}              = $var_immodpg->{_Vbot_file};
$immodpg->{_Vbot_upper_layer_file}  = $var_immodpg->{_Vbot_upper_layer_file};
$immodpg->{_Vincrement_file}        = $var_immodpg->{_Vincrement_file};
$immodpg->{_Vtop_file}              = $var_immodpg->{_Vtop_file};
$immodpg->{_Vtop_lower_layer_file}  = $var_immodpg->{_Vtop_lower_layer_file};
$immodpg->{_VbotNtop_factor_file}   = $var_immodpg->{_VbotNtop_factor_file};
$immodpg->{_VbotNtop_multiply_file} = $var_immodpg->{_VbotNtop_multiply_file};
$immodpg->{_option_file}            = $var_immodpg->{_option_file};
$immodpg->{_change_file}            = $var_immodpg->{_change_file};
$immodpg->{_clip_file}              = $var_immodpg->{_clip_file};
$immodpg->{_layer_file}             = $var_immodpg->{_layer_file};
$immodpg->{_immodpg_model}          = $var_immodpg->{_immodpg_model};
$immodpg->{_thickness_m_file}       = $var_immodpg->{_thickness_m_file};
$immodpg->{_thickness_increment_m_file} =
  $var_immodpg->{_thickness_increment_m_file};

=head2 Coded user options
Only used in message files
for communication with
immopg.for
'change*_opt' subs change values of repeatedly
used variables whereas other subs change
values of variables more frequently modified
by user

=cut

my $move_down_opt         = $var_immodpg->{_move_down_opt};
my $move_left_opt         = $var_immodpg->{_move_left_opt};
my $move_minus_opt        = $var_immodpg->{_move_minus_opt};
my $move_right_opt        = $var_immodpg->{_move_right_opt};
my $move_up_opt           = $var_immodpg->{_move_up_opt};
my $thickness_m_plus_opt  = $var_immodpg->{_thickness_m_plus_opt};
my $thickness_m_minus_opt = $var_immodpg->{_thickness_m_minus_opt};
my $zoom_minus_opt        = $var_immodpg->{_zoom_minus_opt};
my $zoom_plus_opt         = $var_immodpg->{_zoom_plus_opt};

my $Vbot_opt             = $var_immodpg->{_Vbot_opt};
my $Vbot_upper_layer_opt = $var_immodpg->{_Vbot_upper_layer_opt};
my $Vbot_minus_opt       = $var_immodpg->{_Vbot_minus_opt};
my $Vbot_plus_opt        = $var_immodpg->{_Vbot_plus_opt};
my $Vtop_opt             = $var_immodpg->{_Vtop_opt};
my $Vtop_lower_layer_opt = $var_immodpg->{_Vtop_lower_layer_opt};
my $Vtop_minus_opt       = $var_immodpg->{_Vtop_minus_opt};
my $Vtop_plus_opt        = $var_immodpg->{_Vtop_plus_opt};
my $VbotNVtop_lower_layer_minus_opt =
  $var_immodpg->{_VbotNVtop_lower_layer_minus_opt};
my $VbotNVtop_lower_layer_plus_opt =
  $var_immodpg->{_VbotNVtop_lower_layer_plus_opt};
my $VtopNVbot_upper_layer_minus_opt =
  $var_immodpg->{_VtopNVbot_upper_layer_minus_opt};
my $VtopNVbot_upper_layer_plus_opt =
  $var_immodpg->{_VtopNVbot_upper_layer_plus_opt};
my $VbotNtop_multiply_opt = $var_immodpg->{_VbotNtop_multiply_opt};
my $VbotNtop_plus_opt     = $var_immodpg->{_VbotNtop_plus_opt};
my $VbotNtop_minus_opt    = $var_immodpg->{_VbotNtop_minus_opt};
my $update_opt            = $var_immodpg->{_update_opt};

my $change_clip_opt         = $var_immodpg->{_clip4plot_opt};
my $change_layer_number_opt = $var_immodpg->{_layer_number_opt};
my $change_thickness_increment_m_opt =
  $var_immodpg->{_thickness_increment_m_opt};
my $change_thickness_m_opt        = $var_immodpg->{_thickness_m_opt};
my $changeVtop_opt                = $var_immodpg->{_Vtop_opt};
my $changeVincrement_opt          = $var_immodpg->{_Vincrement_opt};
my $changeVbotNtop_factor_opt     = $var_immodpg->{_VbotNtop_factor_opt};
my $change_working_model_bin_opt  = $var_immodpg->{_working_model_bin_opt};
my $change_working_model_text_opt = $var_immodpg->{_working_model_text_opt};

=head2 sub Step
collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$immodpg->{_Step} = 'mmodpg' . $immodpg->{_Step};
	return ( $immodpg->{_Step} );

}

=head2 sub note
collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$immodpg->{_note} = 'mmodpg' . $immodpg->{_note};
	return ( $immodpg->{_note} );

}

=head2 sub _checkVbot
When you use setVbot
check what the current Vbot value is
compared to former Vbot values

=cut

sub _checkVbot {

    my ($self) = @_;

    return _check_widget_state(
        $self,
        '_VbotEntry',        # entry widget key
        '_inVbot',           # in state key
        '_outsideVbot',      # outside state key
        '_Vbot_current',     # current value key
        '_Vbot_prior'        # prior value key
    );
}

=head2 sub _checkVbot_upper_layer

When you use setVbot_upper_layer
check what the current setVbot_upper_layer value is
compared to former setVbot_upper_layer values

=cut

sub _checkVbot_upper_layer {

    my ($self) = @_;

    return _check_widget_state(
        $self,
        '_Vbot_upper_layerEntry',        # entry widget key
        '_inVbot_upper_layer',           # in state key
        '_outsideVbot_upper_layer',      # outside state key
        '_Vbot_upper_layer_current',     # current value key
        '_Vbot_upper_layer_prior'        # prior value key
    );
}

=head2 sub _checkVincrement

When you use Vincrement
check what the current Vincrement value is
compared to former Vincrement values

=cut

sub _checkVincrement {

    my ($self) = @_;

    return _check_widget_state(
        $self,
        '_VincrementEntry',        # entry widget key
        '_inVincrement',           # in state key
        '_outsideVincrement',      # outside state key
        '_Vincrement_current',     # current value key
        '_Vincrement_prior'        # prior value key
    );
}

=head2 sub _checkVtop

When you modify, enter or leave VtopEntry widget
check what the current Vtop value is
compared to former Vtop values

=cut

sub _checkVtop {

    my ($self) = @_;

    return _check_widget_state(
        $self,
        '_VtopEntry',        # entry widget key
        '_inVtop',           # in state key
        '_outsideVtop',      # outside state key
        '_Vtop_current',     # current value key
        '_Vtop_prior'        # prior value key
    );
}

=head2 sub _check_widget_state

A generic subroutine to check the state of the widget, handle entry and exit, and update the current and prior values.

=cut

sub _check_widget_state {
    my ($self, $entry_key, $in_key, $outside_key, $current_key, $prior_key) = @_;

    if (   defined $immodpg->{$entry_key}
        && length $immodpg->{$entry_key}
        && length $immodpg->{$in_key}
        && length $immodpg->{$outside_key}
        && length $immodpg->{$current_key}
        && length $immodpg->{$prior_key} ) {

        # Convenience variables
        my $in       = $immodpg->{$in_key};
        my $outside  = $immodpg->{$outside_key};
        my $current  = $immodpg->{$current_key};
        my $prior    = $immodpg->{$prior_key};

        if (   $in eq $yes
            && $outside eq $no ) {

            # CASE 1: Previously inside the widget, now leaving
            $current = $immodpg->{$entry_key}->get();

            # Reverse conditions: leaving the widget
            $in      = $no;
            $outside = $yes;

            # Update the module values
            $immodpg->{$in_key}      = $in;
            $immodpg->{$outside_key} = $outside;
            $immodpg->{$current_key} = $current;

            return ();

        } elsif ( $in eq $no
            && $outside eq $yes ) {

            # CASE 2: Previously outside the widget, now entering
            $prior   = $current;
            $current = $immodpg->{$entry_key}->get();

            # Reverse conditions: entering the widget
            $in      = $yes;
            $outside = $no;

            # Update the module values
            $immodpg->{$in_key}      = $in;
            $immodpg->{$outside_key} = $outside;
            $immodpg->{$current_key} = $current;
            $immodpg->{$prior_key}   = $prior;

            return ();

        } else {
            print("immodpg, $entry_key, unexpected values\n");
            return ();
        }

    } else {
        print("immodpg, $entry_key, missing widget or values\n");
        return ();
    }
}


#=head2 sub _checkVbot
#When you use setVbot
#check what the current Vbot value is
#compared to former Vbot values
#
#=cut
#
#sub _checkVbot {
#
#	my ($self) = @_;
#
#	# print("immodpg, _checkVbot, $immodpg->{_VbotEntry}\n");
#
#	if (   defined $immodpg->{_VbotEntry}
#		&& length $immodpg->{_VbotEntry}
#		&& length $immodpg->{_inVbot}
#		&& length $immodpg->{_outsideVbot}
#		&& length $immodpg->{_Vbot_current}
#		&& length $immodpg->{_Vbot_prior} )
#	{
#
#		# rename for convenience
#		my $inVbot       = $immodpg->{_inVbot};
#		my $outsideVbot  = $immodpg->{_outsideVbot};
#		my $Vbot_current = $immodpg->{_Vbot_current};
#		my $Vbot_prior   = $immodpg->{_Vbot_prior};
#
#		# print("immodpg,_checkVbot, inVbot:$inVbot\n");
#		# print("immodpg,_checkVbot, outsideVbot: $outsideVbot\n");
#		if (   $inVbot eq $yes
#			&& $outsideVbot eq $no )
#		{
#
#			# print("immodpg, _checkVbot, Leaving widget\n");
#
#			# CASE 1: Previously, inside Entry widget
#			# Now leaving Entry widget
#			$Vbot_current = $immodpg->{_VbotEntry}->get();
#
#			# print("immodpg,_checkVbot, Vbot_current:$Vbot_current\n");
#			# reverse the conditions now
#			# when user leaves Entry widget
#			$inVbot      = $no;
#			$outsideVbot = $yes;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVbot}       = $inVbot;
#			$immodpg->{_outsideVbot}  = $outsideVbot;
#			$immodpg->{_Vbot_current} = $Vbot_current;
#
#			return ();
#
#		}
#		elsif ($inVbot eq $no
#			&& $outsideVbot eq $yes )
#		{
#
#			# CASE 2: Previously, outside Entry widget
#			# Now entering Entry widget
#			$Vbot_prior   = $Vbot_current;
#			$Vbot_current = $immodpg->{_VbotEntry}->get();
#
#			# print("immodpg, _checkVbot, Entering widget\n");
#
#			# reverse the conditions now
#			# when user enters Entry widget
#			$inVbot      = $yes;
#			$outsideVbot = $no;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVbot}       = $inVbot;
#			$immodpg->{_outsideVbot}  = $outsideVbot;
#			$immodpg->{_Vbot_current} = $Vbot_current;
#			$immodpg->{_Vbot_prior}   = $Vbot_prior;
#			return ();
#
#		}
#		else {
#			print("immodpg, _checkVbot, unexpected values\n");
#			return ();
#		}
#
#	}
#	else {
#		print("immodpg, _checkVbot, missing widget\n");
#		return ();
#	}
#}

#=head2 sub _checkVbot_upper_layer
#
#When you use setVbot_upper_layer
#check what the current setVbot_upper_layer value is
#compared to former setVbot_upper_layer values
#
#=cut
#
#sub _checkVbot_upper_layer {
#
#	my ($self) = @_;
#
## print("immodpg, _checkVbot_upper_layer, $immodpg->{_Vbot_upper_layerEntry}\n");
#
#	if (   length( $immodpg->{_Vbot_upper_layerEntry} )
#		&& length $immodpg->{_Vbot_upper_layerEntry}
#		&& length $immodpg->{_inVbot_upper_layer}
#		&& length $immodpg->{_outsideVbot_upper_layer}
#		&& length $immodpg->{_Vbot_upper_layer_current}
#		&& length $immodpg->{_Vbot_upper_layer_prior} )
#	{
#
#		# rename for convenience
#		my $inVbot_upper_layer       = $immodpg->{_inVbot_upper_layer};
#		my $outsideVbot_upper_layer  = $immodpg->{_outsideVbot_upper_layer};
#		my $Vbot_upper_layer_current = $immodpg->{_Vbot_upper_layer_current};
#		my $Vbot_upper_layer_prior   = $immodpg->{_Vbot_upper_layer_prior};
#
## print("immodpg,_checkVbot_upper_layer, inVbot_upper_layer:$inVbot_upper_layer\n");
## print("immodpg,_checkVbot_upper_layer, outsideVbot_upper_layer: $outsideVbot_upper_layer\n");
#		if (   $inVbot_upper_layer eq $yes
#			&& $outsideVbot_upper_layer eq $no )
#		{
#
#			#	print("immodpg, _checkVbot_upper_layer, Leaving widget\n");
#
#			# CASE 1: Previously, inside Entry widget
#			# Now leaving Entry widget
#			$Vbot_upper_layer_current =
#			  $immodpg->{_Vbot_upper_layerEntry}->get();
#
#			# reverse the conditions now
#			# when user leaves Entry widget
#			$inVbot_upper_layer      = $no;
#			$outsideVbot_upper_layer = $yes;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVbot_upper_layer}       = $inVbot_upper_layer;
#			$immodpg->{_outsideVbot_upper_layer}  = $outsideVbot_upper_layer;
#			$immodpg->{_Vbot_upper_layer_current} = $Vbot_upper_layer_current;
#
#			return ();
#
#		}
#		elsif ($inVbot_upper_layer eq $no
#			&& $outsideVbot_upper_layer eq $yes )
#		{
#
#			# CASE 2: Previously, outside Entry widget
#			# Now entering Entry widget
#			$Vbot_upper_layer_prior = $Vbot_upper_layer_current;
#			$Vbot_upper_layer_current =
#			  $immodpg->{_Vbot_upper_layerEntry}->get();
#
#			#			print("immodpg, _checkVbot_upper_layer, Entering widget\n");
#
#			# reverse the conditions now
#			# when user enters Entry widget
#			$inVbot_upper_layer      = $yes;
#			$outsideVbot_upper_layer = $no;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVbot_upper_layer}       = $inVbot_upper_layer;
#			$immodpg->{_outsideVbot_upper_layer}  = $outsideVbot_upper_layer;
#			$immodpg->{_Vbot_upper_layer_current} = $Vbot_upper_layer_current;
#			$immodpg->{_Vbot_upper_layer_prior}   = $Vbot_upper_layer_prior;
#			return ();
#
#		}
#		else {
#			print("immodpg, _checkVbot_upper_layer, unexpected values\n");
#			return ();
#		}
#
#	}
#	else {
#		print("immodpg, _checkVbot_upper_layer, missing widget or values\n");
#		return ();
#	}
#}

#=head2 sub _checkVincrement
#
#When you use Vincrement
#check what the current Vincrement value is
#compared to former Vincrement values
#
#=cut
#
#sub _checkVincrement {
#
#	my ($self) = @_;
#
#	# print("immodpg, _checkVincrement, $immodpg->{_VincrementEntry}\n");
#
#	if (   defined $immodpg->{_VincrementEntry}
#		&& $immodpg->{_VincrementEntry} ne $empty_string
#		&& $immodpg->{_inVincrement} ne $empty_string
#		&& $immodpg->{_outsideVincrement} ne $empty_string
#		&& $immodpg->{_Vincrement} ne $empty_string )
#	{
#
#		# rename for convenience
#		my $inVincrement       = $immodpg->{_inVincrement};
#		my $outsideVincrement  = $immodpg->{_outsideVincrement};
#		my $Vincrement_current = $immodpg->{_Vincrement_current};
#		my $Vincrement_prior   = $immodpg->{_Vincrement_prior};
#
#   # print("immodpg,_checkVincrement, inVincrement:$inVincrement\n");
#   # print("immodpg,_checkVincrement, outsideVincrement: $outsideVincrement\n");
#		if (   $inVincrement eq $yes
#			&& $outsideVincrement eq $no )
#		{
#
#			# print("immodpg, _checkVincrement, Leaving widget\n");
#
#			# CASE 1: Previously, inside Entry widget
#			# Now leaving Entry widget
#			$Vincrement_current = $immodpg->{_VincrementEntry}->get();
#
#			# reverse the conditions now
#			# when user leaves Entry widget
#			$inVincrement      = $no;
#			$outsideVincrement = $yes;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVincrement}       = $inVincrement;
#			$immodpg->{_outsideVincrement}  = $outsideVincrement;
#			$immodpg->{_Vincrement_current} = $Vincrement_current;
#
#			return ();
#
#		}
#		elsif ($inVincrement eq $no
#			&& $outsideVincrement eq $yes )
#		{
#
#			# CASE 2: Previously, outside Entry widget
#			# Now entering Entry widget
#			$Vincrement_prior   = $Vincrement_current;
#			$Vincrement_current = $immodpg->{_VincrementEntry}->get();
#
#			# print("immodpg, _checkVincrement, Entering widget\n");
#
#			# reverse the conditions now
#			# when user enters Entry widget
#			$inVincrement      = $yes;
#			$outsideVincrement = $no;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVincrement}       = $inVincrement;
#			$immodpg->{_outsideVincrement}  = $outsideVincrement;
#			$immodpg->{_Vincrement_current} = $Vincrement_current;
#			$immodpg->{_Vincrement_prior}   = $Vincrement_prior;
#			return ();
#
#		}
#		else {
#			print("immodpg, _checkVincrement, unexpected values\n");
#			return ();
#		}
#
#	}
#	else {
#		print("immodpg, _checkVincrement, missing widget\n");
#		return ();
#	}
#}

#=head2 sub _checkVtop
#
#When you modify, enter or leave VtopEntry widget
#check what the current Vtop value is
#compared to former Vtop values
#
#=cut
#
#sub _checkVtop {
#
#	my ($self) = @_;
#
#	# print("immodpg, _checkVtop, $immodpg->{_VtopEntry}\n");
#
#	if (   defined $immodpg->{_VtopEntry}
#		&& $immodpg->{_VtopEntry} ne $empty_string
#		&& $immodpg->{_inVtop} ne $empty_string
#		&& $immodpg->{_outsideVtop} ne $empty_string
#		&& $immodpg->{_Vtop_current} ne $empty_string
#		&& $immodpg->{_Vtop_prior} ne $empty_string )
#	{
#
#		# rename for convenience
#		my $inVtop       = $immodpg->{_inVtop};
#		my $outsideVtop  = $immodpg->{_outsideVtop};
#		my $Vtop_current = $immodpg->{_Vtop_current};
#		my $Vtop_prior   = $immodpg->{_Vtop_prior};
#
#		# print("immodpg,_checkVtop, inVtop:$inVtop\n");
#		# print("immodpg,_checkVtop, outsideVtop: $outsideVtop\n");
#		# print("immodpg,_checkVtop, Vtop_current: $Vtop_current\n");
#		if (   $inVtop eq $yes
#			&& $outsideVtop eq $no )
#		{
#
#			#			print("immodpg, _checkVtop, Leaving widget\n");
#
#			# CASE 1: Previously, inside Entry widget
#			# Now leaving Entry widget
#			$Vtop_current = $immodpg->{_VtopEntry}->get();
#
#			# reverse the conditions now
#			# when user leaves Entry widget
#			$inVtop      = $no;
#			$outsideVtop = $yes;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVtop}       = $inVtop;
#			$immodpg->{_outsideVtop}  = $outsideVtop;
#			$immodpg->{_Vtop_current} = $Vtop_current;
#
#			return ();
#
#		}
#		elsif ($inVtop eq $no
#			&& $outsideVtop eq $yes )
#		{
#
#			# CASE 2: Previously, outside Entry widget
#			# Now entering Entry widget
#			$Vtop_prior   = $Vtop_current;
#			$Vtop_current = $immodpg->{_VtopEntry}->get();
#
#			# print("immodpg, _checkVtop, Entering widget\n");
#
#			# reverse the conditions now
#			# when user enters Entry widget
#			$inVtop      = $yes;
#			$outsideVtop = $no;
#
#			# reset module values for convenience of renaming
#			$immodpg->{_inVtop}       = $inVtop;
#			$immodpg->{_outsideVtop}  = $outsideVtop;
#			$immodpg->{_Vtop_current} = $Vtop_current;
#			$immodpg->{_Vtop_prior}   = $Vtop_prior;
#			return ();
#
#		}
#		else {
#			print("immodpg, _checkVtop, unexpected values\n");
#			return ();
#		}
#
#	}
#	else {
#		print("immodpg, _checkVtop, missing widget\n");
#		return ();
#	}
#}


=head2 sub _checkVtop_lower_layer

When you use Vtop_lower_layer
check what the current Vtop_lower_layer value is
compared to former Vtop_lower_layer values

=cut

sub _checkVtop_lower_layer {

	my ($self) = @_;

#	print("immodpg, _checkVtop_lower_layer, $immodpg->{_Vtop_lower_layerEntry}\n");

	if (   defined $immodpg->{_Vtop_lower_layerEntry}
		&& $immodpg->{_Vtop_lower_layerEntry} ne $empty_string
		&& $immodpg->{_inVtop_lower_layer} ne $empty_string
		&& $immodpg->{_outsideVtop_lower_layer} ne $empty_string
		&& $immodpg->{_Vtop_lower_layer_current} ne $empty_string
		&& $immodpg->{_Vtop_lower_layer_prior} ne $empty_string )
	{

		# rename for convenience
		my $inVtop_lower_layer       = $immodpg->{_inVtop_lower_layer};
		my $outsideVtop_lower_layer  = $immodpg->{_outsideVtop_lower_layer};
		my $Vtop_lower_layer_current = $immodpg->{_Vtop_lower_layer_current};
		my $Vtop_lower_layer_prior   = $immodpg->{_Vtop_lower_layer_prior};

# print("immodpg,_checkVtop_lower_layer, inVtop_lower_layer:$inVtop_lower_layer\n");
# print("immodpg,_checkVtop_lower_layer, outsideVtop_lower_layer: $outsideVtop_lower_layer\n");
		if (   $inVtop_lower_layer eq $yes
			&& $outsideVtop_lower_layer eq $no )
		{

			#			print("immodpg, _checkVtop_lower_layer, Leaving widget\n");

			# CASE 1: Previously, inside Entry widget
			# Now leaving Entry widget
			$Vtop_lower_layer_current =
			  $immodpg->{_Vtop_lower_layerEntry}->get();

			# reverse the conditions now
			# when user leaves Entry widget
			$inVtop_lower_layer      = $no;
			$outsideVtop_lower_layer = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_inVtop_lower_layer}       = $inVtop_lower_layer;
			$immodpg->{_outsideVtop_lower_layer}  = $outsideVtop_lower_layer;
			$immodpg->{_Vtop_lower_layer_current} = $Vtop_lower_layer_current;

#			print("1 _Vtop_lower_layer_current=$immodpg->{_Vtop_lower_layer_current}\n");
			return ();

		}
		elsif ($inVtop_lower_layer eq $no
			&& $outsideVtop_lower_layer eq $yes )
		{

			# CASE 2: Previously, outside Entry widget
			# Now entering Entry widget
			$Vtop_lower_layer_prior = $Vtop_lower_layer_current;
			$Vtop_lower_layer_current =
			  $immodpg->{_Vtop_lower_layerEntry}->get();

			#			print("immodpg, _checkVtop_lower_layer, Entering widget\n");

			# reverse the conditions now
			# when user enters Entry widget
			$inVtop_lower_layer      = $yes;
			$outsideVtop_lower_layer = $no;

			# reset module values for convenience of renaming
			$immodpg->{_inVtop_lower_layer}       = $inVtop_lower_layer;
			$immodpg->{_outsideVtop_lower_layer}  = $outsideVtop_lower_layer;
			$immodpg->{_Vtop_lower_layer_current} = $Vtop_lower_layer_current;
			$immodpg->{_Vtop_lower_layer_prior}   = $Vtop_lower_layer_prior;

#			print("2 _Vtop_lower_layer_current=$immodpg->{_Vtop_lower_layer_current}\n");
			return ();

		}
		else {
			print("immodpg, _checkVtop_lower_layer, unexpected values\n");
			return ();
		}

	}
	else {
		print("immodpg, _checkVtop_lower_layer, missing widget\n");
		return ();
	}
}

=head2 sub _checkVbotNtop_factor

When you enter or leave
check what the current VbotNtop_factor value is
compared to former VbotNtop_factor values

=cut

sub _checkVbotNtop_factor {

	my ($self) = @_;

# print("immodpg, _checkVbotNtop_factor, $immodpg->{_VbotNtop_factor4Entry}\n");

	if (   defined $immodpg->{_VbotNtop_factorEntry}
		&& $immodpg->{_VbotNtop_factorEntry} ne $empty_string
		&& $immodpg->{_inVbotNtop_factor} ne $empty_string
		&& $immodpg->{_outsideVbotNtop_factor} ne $empty_string
		&& $immodpg->{_VbotNtop_factor_current} ne $empty_string
		&& $immodpg->{_VbotNtop_factor_prior} ne $empty_string )
	{

		# rename for convenience
		my $inVbotNtop_factor       = $immodpg->{_inVbotNtop_factor};
		my $outsideVbotNtop_factor  = $immodpg->{_outsideVbotNtop_factor};
		my $VbotNtop_factor_current = $immodpg->{_VbotNtop_factor_current};
		my $VbotNtop_factor_prior   = $immodpg->{_VbotNtop_factor_prior};

# print("immodpg,_checkVbotNtop_factor, inVbotNtop_factor:$inVbotNtop_factor\n");
# print("immodpg,_checkVbotNtop_factor, outsideVbotNtop_factor: $outsideVbotNtop_factor\n");
		if (   $inVbotNtop_factor eq $yes
			&& $outsideVbotNtop_factor eq $no )
		{

			# print("immodpg, _checkVbotNtop_factor, Leaving widget\n");

			# CASE 1: Previously, inside Entry widget
			# Now leaving Entry widget
			$VbotNtop_factor_current = $immodpg->{_VbotNtop_factorEntry}->get();

			# reverse the conditions now
			# when user leaves Entry widget
			$inVbotNtop_factor      = $no;
			$outsideVbotNtop_factor = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_inVbotNtop_factor}       = $inVbotNtop_factor;
			$immodpg->{_outsideVbotNtop_factor}  = $outsideVbotNtop_factor;
			$immodpg->{_VbotNtop_factor_current} = $VbotNtop_factor_current;

			return ();

		}
		elsif ($inVbotNtop_factor eq $no
			&& $outsideVbotNtop_factor eq $yes )
		{

			# CASE 2: Previously, outside Entry widget
			# Now entering Entry widget
			$VbotNtop_factor_prior   = $VbotNtop_factor_current;
			$VbotNtop_factor_current = $immodpg->{_VbotNtop_factorEntry}->get();

			# print("immodpg, _checkVbotNtop_factor, Entering widget\n");

			# reverse the conditions now
			# when user enters Entry widget
			$inVbotNtop_factor      = $yes;
			$outsideVbotNtop_factor = $no;

			# reset module values for convenience of renaming
			$immodpg->{_inVbotNtop_factor}       = $inVbotNtop_factor;
			$immodpg->{_outsideVbotNtop_factor}  = $outsideVbotNtop_factor;
			$immodpg->{_VbotNtop_factor_current} = $VbotNtop_factor_current;
			$immodpg->{_VbotNtop_factor_prior}   = $VbotNtop_factor_prior;
			return ();

		}
		else {
			print("immodpg, _checkVbotNtop_factor, unexpected values\n");
			return ();
		}

	}
	else {
		print("immodpg, _checkVbotNtop_factor, missing widget\n");
		return ();
	}
}

=head2 sub _check_clip

When you enter or leave
check what the current clip value is
compared to former clip values

=cut

sub _check_clip {

	my ($self) = @_;

	# print("immodpg, _check_clip, $immodpg->{_clip4plotEntry}\n");

	if (   defined( $immodpg->{_clip4plotEntry} )
		&& $immodpg->{_clip4plotEntry} ne $empty_string
		&& $immodpg->{_in_clip} ne $empty_string
		&& $immodpg->{_outside_clip} ne $empty_string
		&& $immodpg->{_clip4plot_current} ne $empty_string
		&& $immodpg->{_clip4plot_prior} ne $empty_string )
	{

		# rename for convenience
		my $in_clip           = $immodpg->{_in_clip};
		my $outside_clip      = $immodpg->{_outside_clip};
		my $clip4plot_current = $immodpg->{_clip4plot_current};
		my $clip4plot_prior   = $immodpg->{_clip4plot_prior};

		#		print("immodpg,_check_clip, in_clip:$in_clip\n");
		#		print("immodpg,_check_clip, outside_clip: $outside_clip\n");
		if (   $in_clip eq $yes
			&& $outside_clip eq $no )
		{

			# print("immodpg, _check_clip, Leaving widget\n");

			# CASE 1: Previously, inside Entry widget
			# Now leaving Entry widget
			$clip4plot_current = $immodpg->{_clip4plotEntry}->get();

		 # rint("immodpg, _check_clip, clip4plot_current:$clip4plot_current\n");

			# reverse the conditions now
			# when user leaves Entry widget
			$in_clip      = $no;
			$outside_clip = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_in_clip}           = $in_clip;
			$immodpg->{_outside_clip}      = $outside_clip;
			$immodpg->{_clip4plot_current} = $clip4plot_current;

			return ();

		}
		elsif ($in_clip eq $no
			&& $outside_clip eq $yes )
		{

			# CASE 2: Previously, outside Entry widget
			# Now entering Entry widget
			$clip4plot_prior   = $clip4plot_current;
			$clip4plot_current = $immodpg->{_clip4plotEntry}->get();

			# print("immodpg, _check_clip, Entering widget\n");

			# reverse the conditions now
			# when user enters Entry widget
			$in_clip      = $yes;
			$outside_clip = $no;

			# reset module values for convenience of renaming
			$immodpg->{_in_clip}           = $in_clip;
			$immodpg->{_outside_clip}      = $outside_clip;
			$immodpg->{_clip4plot_current} = $clip4plot_current;
			$immodpg->{_clip4plot_prior}   = $clip4plot_prior;
			return ();

		}
		else {
			print("immodpg, _check_clip, unexpected values\n");
			return ();
		}

	}
	else {
		print("immodpg, _check_clip, missing widget\n");
		return ();
	}
}

=head2 sub _check_layer

When you enter or leave
check what the current layer value is
compared to former layer values

If you enter the LayerEntry widget it will check before you change
its value

If you enter another widget that now has the focus you
will have to recall the current and prior values of the 
layerEntry widget

=cut

sub _check_layer {

	my ($self) = @_;

	# print("immodpg, _check_layer, $immodpg->{_layerEntry}\n");

	if (   length( $immodpg->{_layerEntry} )
		&& length( $immodpg->{_in_layer} )
		&& length( $immodpg->{_outside_layer} )
		&& length( $immodpg->{_layer_current} )
		&& length( $immodpg->{_layer_prior} ) )
	{

		# rename for convenience
		my $in_layer      = $immodpg->{_in_layer};
		my $outside_layer = $immodpg->{_outside_layer};
		my $layer_current = $immodpg->{_layer_current};
		my $layer_prior   = $immodpg->{_layer_prior};

		#		print("immodpg,_check_layer, in_layer:$in_layer\n");
		#		print("immodpg,_check_layer, outside_layer: $outside_layer\n");
		if (   $in_layer eq $yes
			&& $outside_layer eq $no )
		{

			# CASE 1: Previously, inside Entry widget
			# print("immodpg, _check_layer, left widget\n");
			# possible layer number idiosyncracies
			my $temp_layer_current = $immodpg->{_layerEntry}->get();

# print("immodpg, _check_layer, CASE 1 temp layer number = $temp_layer_current\n");
			_set_layer_control($temp_layer_current);
			my $new_layer_current = _get_control_layer();

			# $new_layer_current=99;
			$immodpg->{_layerEntry}->delete( 0, 'end' );
			$immodpg->{_layerEntry}->insert( 0, $new_layer_current );

			# reverse the conditions now
			# when user leaves widget
			# Next will enter layerEntry widget
			$in_layer      = $no;
			$outside_layer = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_in_layer}      = $in_layer;
			$immodpg->{_outside_layer} = $outside_layer;
			$immodpg->{_layer_current} = $new_layer_current;

			return ();

		}
		elsif ($in_layer eq $no
			&& $outside_layer eq $yes )
		{

			# CASE 2: Previously, outside layerEntry widget
			# Now entering entering the layerEntry widget
			#			print("immodpg, _check_layer, Entering widget\n");
			$layer_current = $immodpg->{_layerEntry}->get();

#			print("immodpg, _check_layer,prior =$immodpg->{_layer_prior} current= $layer_current\n\n");

			# reverse the conditions now
			# when user enters Entry widget
			$in_layer      = $yes;
			$outside_layer = $no;

			# reset module values for convenience of renaming
			$immodpg->{_in_layer}      = $in_layer;
			$immodpg->{_outside_layer} = $outside_layer;
			$immodpg->{_layer_current} = $layer_current;

			# $immodpg->{_layer_prior}   = $new_layer_prior;
			return ();

		}
		else {
			print("immodpg, _check_layer, unexpected values\n");
			return ();
		}

	}
	else {
		print("immodpg, _check_layer, missing widget\n");
		return ();
	}
}

=head2 sub _check_thickness_m

When you modify, enter or leave thickness_mEntry widget
check what the current thickness_m value is
compared to former thickness_m values

=cut

sub _check_thickness_m {

	my ($self) = @_;

	# print("immodpg, _check_thickness_m, $immodpg->{_thickness_mEntry}\n");

	if (   defined $immodpg->{_thickness_mEntry}
		&& length $immodpg->{_thickness_mEntry}
		&& length $immodpg->{_in_thickness_m}
		&& length $immodpg->{_outside_thickness_m}
		&& length $immodpg->{_thickness_m} )
	{

		# rename for convenience
		my $in_thickness_m       = $immodpg->{_in_thickness_m};
		my $outside_thickness_m  = $immodpg->{_outside_thickness_m};
		my $_thickness_m_current = $immodpg->{_thickness_m_current};
		my $_thickness_m_prior   = $immodpg->{_thickness_m_prior};

		if (   $in_thickness_m eq $yes
			&& $outside_thickness_m eq $no )
		{

			# CASE 1: Previously, inside Entry widget
			# Now leaving Entry widget
			$_thickness_m_current = $immodpg->{_thickness_mEntry}->get();

			# reverse the conditions now
			# when user leaves Entry widget
			$in_thickness_m      = $no;
			$outside_thickness_m = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_in_thickness_m}      = $in_thickness_m;
			$immodpg->{_outside_thickness_m} = $outside_thickness_m;
			$immodpg->{_thickness_m_current} = $_thickness_m_current;
#			print("immodpg, _check_thickness_m, Leaving widget\n");
#			print(
#				"immodpg,_check_thickness_m, in_thickness_m:$in_thickness_m\n");
#			print(
#"immodpg,_check_thickness_m, outside_thickness_m: $outside_thickness_m\n"
#			);
#			print(
#"immodpg,_check_thickness_m, _thickness_m_current: $_thickness_m_current\n"
#			);

			return ();

		}
		elsif ($in_thickness_m eq $no
			&& $outside_thickness_m eq $yes )
		{

			# CASE 2: Previously, outside Entry widget
			# Now entering Entry widget
			$_thickness_m_prior   = $_thickness_m_current;
			$_thickness_m_current = $immodpg->{_thickness_mEntry}->get();

			# reverse the conditions now
			# when user enters Entry widget
			$in_thickness_m      = $yes;
			$outside_thickness_m = $no;

			# reset module values for convenience of renaming
			$immodpg->{_in_thickness_m}      = $in_thickness_m;
			$immodpg->{_outside_thickness_m} = $outside_thickness_m;
			$immodpg->{_thickness_m_current} = $_thickness_m_current;
			$immodpg->{_thickness_m_prior}   = $_thickness_m_prior;

#			print("immodpg, _check_thickness_m, Entering widget\n");
#			print(
#				"immodpg,_check_thickness_m, in_thickness_m:$in_thickness_m\n");
#			print(
#"immodpg,_check_thickness_m, outside_thickness_m: $outside_thickness_m\n"
#			);
#			print(
#"immodpg,_check_thickness_m, _thickness_m_current: $_thickness_m_current\n"
#			);

			return ();

		}
		else {
			print("immodpg, _check_thickness_m, unexpected values\n");
			return ();
		}

	}
	else {
		print("immodpg, _check_thickness_m, missing widget\n");
		return ();
	}
}

=head2 sub _check_thickness_increment_m

When you enter or leave
check what the current thickness_increment_m value is
compared to former thickness_increment_m values

=cut

sub _check_thickness_increment_m {

	my ($self) = @_;

# print("immodpg, _check_thickness_increment_m, $immodpg->{_thickness_increment_mEntry}\n");

	if (   defined( $immodpg->{_thickness_increment_mEntry} )
		&& $immodpg->{_thickness_increment_mEntry} ne $empty_string
		&& $immodpg->{_in_thickness_increment_m} ne $empty_string
		&& $immodpg->{_outside_thickness_increment_m} ne $empty_string
		&& $immodpg->{_thickness_increment_m_current} ne $empty_string
		&& $immodpg->{_thickness_increment_m_prior} ne $empty_string )
	{

		# rename for convenience
		my $in_thickness_increment_m = $immodpg->{_in_thickness_increment_m};
		my $outside_thickness_increment_m =
		  $immodpg->{_outside_thickness_increment_m};
		my $thickness_increment_m_current =
		  $immodpg->{_thickness_increment_m_current};
		my $thickness_increment_m_prior =
		  $immodpg->{_thickness_increment_m_prior};

# print("immodpg,_check_thickness_increment_m, in_thickness_increment_m:$in_thickness_increment_m\n");
# print("immodpg,_check_thickness_increment_m, outside_thickness_increment_m: $outside_thickness_increment_m\n");
		if (   $in_thickness_increment_m eq $yes
			&& $outside_thickness_increment_m eq $no )
		{

			# print("immodpg, _check_thickness_increment_m, Leaving widget\n");

			# CASE 1: Previously, inside Entry widget
			# Now leaving Entry widget
			$thickness_increment_m_current =
			  $immodpg->{_thickness_increment_mEntry}->get();

			# reverse the conditions now
			# when user leaves Entry widget
			$in_thickness_increment_m      = $no;
			$outside_thickness_increment_m = $yes;

			# reset module values for convenience of renaming
			$immodpg->{_in_thickness_increment_m} = $in_thickness_increment_m;
			$immodpg->{_outside_thickness_increment_m} =
			  $outside_thickness_increment_m;
			$immodpg->{_thickness_increment_m_current} =
			  $thickness_increment_m_current;

			return ();

		}
		elsif ($in_thickness_increment_m eq $no
			&& $outside_thickness_increment_m eq $yes )
		{

			# CASE 2: Previously, outside Entry widget
			# Now entering Entry widget
			$thickness_increment_m_prior = $thickness_increment_m_current;
			$thickness_increment_m_current =
			  $immodpg->{_thickness_increment_mEntry}->get();

			# print("immodpg, _check_thickness_increment_m, Entering widget\n");

			# reverse the conditions now
			# when user enters Entry widget
			$in_thickness_increment_m      = $yes;
			$outside_thickness_increment_m = $no;

			# reset module values for convenience of renaming
			$immodpg->{_in_thickness_increment_m} = $in_thickness_increment_m;
			$immodpg->{_outside_thickness_increment_m} =
			  $outside_thickness_increment_m;
			$immodpg->{_thickness_increment_m_current} =
			  $thickness_increment_m_current;
			$immodpg->{_thickness_increment_m_prior} =
			  $thickness_increment_m_prior;
			return ();

		}
		else {
			return ();
			print("immodpg, _check_thickness_increment_m, unexpected values\n");
		}

	}
	else {
		print("immodpg, _check_thickness_increment_m, missing widget\n");
		return ();
	}
}

=head2 sub _get_control
find corrected value

=cut

sub _get_control {
	my ($self) = @_;

	my $result;

	if ( length( $immodpg->{_control_value} ) ) {

		$result = $immodpg->{_control_value};

	}
	else {
		print("immodpg, _get_control, unexpected value\n");
	}
	return ($result);
}

#=head2 sub _get_control_VbotNtop_factor
#adjust  bad VbotNtop_factor value
#set defaults
#
#=cut
#
#	sub _get_control_VbotNtop_factor {
#
#		my ($self) = @_;
#
#		my $result;
#
#		if ( not( looks_like_number( $immodpg->{_control_VbotNtop_factor} ) ) ) {
#
#			$immodpg->{_VbotNtop_factor_current} = $immodpg->{_VbotNtop_factor_default};
#			$immodpg->{_VbotNtop_factor_prior}   = $immodpg->{_VbotNtop_factor_default};
#			$immodpg->{_VbotNtop_factorEntry}->delete( 0, 'end' );
#			$immodpg->{_VbotNtop_factorEntry}->insert( 0, $immodpg->{_VbotNtop_factor_current} );
#			$immodpg->{_isVbotNtop_factor_changed_in_gui} = $no,;
#
#		} else {
#			print("immodpg, _get_control_VbotNtop_factor,  bad value\n");
#		}
#
#		return ();
#	}

=head2 sub _get_control_clip
adjust clip value

=cut

sub _get_control_clip {

	my ($self) = @_;

	my $result;

	if ( length( $immodpg->{_control_clip} ) ) {

#		print("1. immodpg, _get_control_clip, old control_clip= $immodpg->{_control_clip}\n");
		my $control_clip = $immodpg->{_control_clip};

		if ( $control_clip <= 0 ) {

			# case 1 layer number exceeds possible value
			$control_clip = 1;
			$result       = $control_clip;

		}
		else {

			#			print("immodpg, _get_control_clip, NADA\n");
			$result = $control_clip;
		}

   #		print("2. immodpg, _get_control_clip, new control_clip= $control_clip\n");
		return ($result);

	}
	else {
		print("immodpg, _get_control_clip,  missing clip value\n");
	}
	return ();
}

=head2 sub _get_control_layer
adjust layer number

=cut

sub _get_control_layer {

	my ($self) = @_;

	my $result;

	if ( length( $immodpg->{_control_layer} ) ) {

# print("1. immodpg, _get_control_layer, control_layer= $immodpg->{_control_layer}\n");
		my $control_layer    = $immodpg->{_control_layer};
		my $number_of_layers = _get_number_of_layers();

		if ( $control_layer > $number_of_layers ) {

		# case 1 layer number exceeds possible value
		# print("case1: immodpg, _get_control_layer, layer number too large\n");
		# print("immodpg, _get_control_layer, layer_number=$control_layer}\n");
			$control_layer = $number_of_layers - 1;

	 # print("immodpg, _get_control_layer, new layer_number=$control_layer}\n");
			$result = $control_layer;

		}
		elsif ( $control_layer < 1 ) {

			$control_layer = 1;
			$result        = $control_layer;

		}
		elsif ( ( $control_layer == 1 ) ) {

			$control_layer = 1;
			$result        = $control_layer;

			# NADA

		}
		elsif ( ( $control_layer < $number_of_layers ) ) {

			#print("immodpg, get_control_layer, layer=$control_layer\n");
			$result = $control_layer;

			# NADA

		}
		elsif ( ( $control_layer == $number_of_layers ) ) {

			# print("immodpg, get_control_layer, layer=$control_layer\n");
			$result = $control_layer - 1;

		}
		else {

			# print("immodpg, _get_control_layer, unexpected layer number\n");
			$result = $empty_string;
		}

	}
	else {

		# print("immodpg, _get_control_layer, empty string, result = 1\n");
		$result = 1;
	}

	return ($result);
}

=head2 sub _get_data_scale

get scalco or scalel from file header

=cut

sub _get_data_scale {
	my ($self) = @_;

=head2 instantiate class

=cut

	print(
"immodpg, _get_data_scale, _base_file_name=$immodpg->{_base_file_name}\n"
	);

	# ???
	my $header_values = header_values->new();

	if ( defined $immodpg->{_base_file_name}
		&& $immodpg->{_base_file_name} ne $empty_string )
	{

		$header_values->set_base_file_name( $immodpg->{_base_file_name} );
		$header_values->set_header_name('scalel');
		my $data_scale = $header_values->get_number();

		my $result = $data_scale;

		#		print("immodpg, _get_data_scale, data_scale = $data_scale\n");
		return ($result);

	}
	else {

		my $data_scale = 1;
		my $result     = $data_scale;

		#		print("immodpg, _get_data_scale, data_scale = 1:1\n");
		return ($result);

	}
}

=head2 _get_initial_model

 PERL PERL PROGRAM NAME: _get_initial_model
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 21 2020

 DESCRIPTION:  
    
   read Fortran 77 unformatted binary model file
   from mmodpg

=cut

=head2 USE

=over

=item

Number of layers is passed as a variable
Number of layers is read from an ascii 
version of the model data file

=item


=back
	
=cut

=head2 NOTES

	
=cut	

=head4 Examples

=cut

=head2 CHANGES and their DATES
3.31.21
 Consider storing model values and 
 their changes within this namespace

=cut 

sub _get_initial_model {

	my ($self) = @_;

	use PDL::Core;
	use PDL::IO::FlexRaw;

	my $Project = Project_config->new();
	my $IMMODPG = $Project->IMMODPG();
	my $var     = ( immodpg_global_constants->new() )->var;

	my ( @VPtop, @VStop, @density_top, @dz );
	my ( @VPbot, @VSbot, @density_bot );
	my ( @VP,    @VS,    @model );
	my $error_switch = $off;
	my $result       = '';

	my $inbound = $IMMODPG . '/' . $var->{_immodpg_model};
	my $cols    = 9;                                         #default
	my $km2m    = 1000;
	my $gcc2MKS = 1000;

	my $number_of_layers = _get_number_of_layers();

  # print("immodpg, _get_initial_model,number_of_layers = $number_of_layers\n");

	my $header = [
		{ Type => 'f77' },
		{
			Type  => 'float',
			NDims => 2,
			Dims  => [ $cols, ($number_of_layers) ]
		}
	];

	# does file exist?
	if ( -e $inbound ) {

		# CASE 1: file exists
		my $model_pdl = readflex( $inbound, $header );

		# print("$model_pdl\n");
		my $nelem = nelem($model_pdl);

# print("immodpg,_get_initial_model,nelem=$nelem,#cols=$cols,#layers=$number_of_layers\n");

		for (
			my $layer_index = 0 ;
			$layer_index < $number_of_layers ;
			$layer_index++
		  )
		{

			my $magic_number_str = '0:1';
			my $value_indices    = $magic_number_str;
			my $full_indices     = $value_indices . ',' . $layer_index;

			# pdl 2 perl
			@VP = ( $model_pdl->slice($full_indices) )->list;
			$VPtop[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot2f}", ( $VP[0] * $km2m ) );
			$VPbot[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot2f}", ( $VP[1] * $km2m ) );

			$value_indices = '2:6';
			$full_indices  = $value_indices . ',' . $layer_index;

			# pdl 2 perl
			@model = ( $model_pdl->slice($full_indices) )->list;
			$dz[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot3f}", ( $model[0] * $km2m ) );
			$VStop[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot3f}", ( $model[1] * $km2m ) );
			$VSbot[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot3f}", ( $model[2] * $km2m ) );
			$density_top[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot3f}",
				( $model[3] * $gcc2MKS ) );
			$density_bot[$layer_index] =
			  sprintf( "$var_immodpg->{_format_dot3f}",
				( $model[4] * $gcc2MKS ) );

#				print(
#					"immodpg,_get_initial_model,V,layer_index=$layer_index\n"
#				);
#				print(
#					"immodpg,_get_initial_model,VPtop = $VPtop[$layer_index], VPbot=$VPbot[$layer_index]\n"
#				);

#			print("VStop = $VStop[$layer_index], VSbot=$VSbot[$layer_index],layer_index=$layer_index\n");
#			print("dz = $dz[$layer_index], rho_top=$density_top[$layer_index],rho_bot=$density_bot[$layer_index]\n");

			#				my $x_indices     = pdl(5);
			#				my $layer_indices = pdl(2);
		}    # end a for loop

		# test for errors
		_set_model_control( \@VPbot, \@VPtop, \@VSbot, \@VStop, \@density_bot,
			\@density_top, \@dz );
		my $error_switch = _get_model_control();

		if ( $error_switch eq $on ) {

			# CASE 1A File exists and is corrupt
			_messages( 'immodpg', 1 );
			return ();

		}
		elsif ( $error_switch eq $off ) {

			# CASE 1B File exists and is OK
			# print("immodpg,_get_initial_model, MODEL OK ;NADA\n");
			return ( \@VPtop, \@VPbot, \@dz, $error_switch );
		}
		else {
			print("immodpg,_get_initial_model, unexpected value\n");
		}

 #	        print pdl(@VPtop,@VPbot,@dz,@VStop,@VSbot,@density_top,@density_bot);
 #	        print ("\n");
 #			print $model_pdl->index2d($x_indices,$layer_indices);
 #			print ("\n");
 #			print $model_pdl;

	}
	elsif ( not( -e $inbound ) ) {

		print("immodpg,_get_initial_model,file is missing\n");
		use File::Copy;
		my $from = $global_libs->{_configs_big_streams} . '/' . $immodpg_model;
		my $to   = $IMMODPG . '/' . $immodpg_model_file_text;
		copy( $from, $to );

		$from =
		  $global_libs->{_configs_big_streams} . '/' . $immodpg_model_file_text;
		$to = $IMMODPG . '/' . $immodpg_model_file_text;
		copy( $from, $to );

		return ();

	}
	else {
		print("immodpg,_get_initial_model,unexpected value\n");
		return ();
	}

	return ();
}

=head2 _get_initial_model4gui

 PERL PERL PROGRAM NAME: _get_initial_model4gui
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 21 2020

 DESCRIPTION:  
    
   read Fortran 77 unformatted binary model file
   from mmodpg

=cut

=head2 USE

=over

=item

Number of layers is passed as a variable
Number of layers is read from an ascii 
version of the model data file

=item


=back
	
=cut

=head2 NOTES

	
=cut	

=head4 Examples

=cut

=head2 CHANGES and their DATES
3.31.21
 Consider storing model values and 
 their changes within this namespace

=cut 

sub _get_initial_model4gui {

	my ($self) = @_;

	use PDL::Core;
	use PDL::IO::FlexRaw;

	my $Project = Project_config->new();
	my $IMMODPG = $Project->IMMODPG();
	my $var     = ( immodpg_global_constants->new() )->var;

	my ( @VPtop, @VStop, @density_top, @dz );
	my ( @VPbot, @VSbot, @density_bot );
	my ( @VP,    @VS,    @model );
	my $error_switch = $off;
	my $result       = '';

	my $inbound = $IMMODPG . '/' . $var->{_immodpg_model};
	my $cols    = 9;                                         #default
	my $km2m    = 1000;
	my $gcc2MKS = 1000;

#		print("immodpg, _get_initial_model4gui,model_layer_number =$immodpg->{_model_layer_number}\n");
	my $number_of_layers = _get_number_of_layers();

#		print("immodpg, _get_initial_model4gui,number_of_layers = $number_of_layers\n");

	if (   $immodpg->{_model_layer_number} > 0
		&& $immodpg->{_model_layer_number} <= $number_of_layers )
	{

		my $header = [
			{ Type => 'f77' },
			{
				Type  => 'float',
				NDims => 2,
				Dims  => [ $cols, ($number_of_layers) ]
			}
		];

		# does file exist?
		if ( -e $inbound ) {

			# CASE 1: file exists
			my $model_pdl = readflex( $inbound, $header );

			# print("$model_pdl\n");
			my $nelem = nelem($model_pdl);

#			print("immodpg,_get_initial_model4gui,nelem=$nelem,#cols=$cols,#layers=$number_of_layers\n");
#           print("immodpg,_get_initial_model4gui,=format_dot2f=$var_immodpg->{_format_dot2f}\n");
			for (
				my $layer_index = 0 ;
				$layer_index < $number_of_layers ;
				$layer_index++
			  )
			{

				my $magic_number_str = '0:1';
				my $value_indices    = $magic_number_str;
				my $full_indices     = $value_indices . ',' . $layer_index;

				# pdl 2 perl
				@VP = ( $model_pdl->slice($full_indices) )->list;

				$VPtop[$layer_index] = sprintf( "$var_immodpg->{_format_dot2f}",
					( $VP[0] * $km2m ) );
				$VPbot[$layer_index] = sprintf( "$var_immodpg->{_format_dot2f}",
					( $VP[1] * $km2m ) );

				$value_indices = '2:6';
				$full_indices  = $value_indices . ',' . $layer_index;

				# pdl 2 perl
				@model = ( $model_pdl->slice($full_indices) )->list;
				$dz[$layer_index] = sprintf( "$var_immodpg->{_format_dot3f}",
					( $model[0] * $km2m ) );
				$VStop[$layer_index] = sprintf( "$var_immodpg->{_format_dot3f}",
					( $model[1] * $km2m ) );
				$VSbot[$layer_index] = sprintf( "$var_immodpg->{_format_dot3f}",
					( $model[2] * $km2m ) );
				$density_top[$layer_index] =
				  sprintf( "$var_immodpg->{_format_dot3f}",
					( $model[3] * $gcc2MKS ) );
				$density_bot[$layer_index] =
				  sprintf( "$var_immodpg->{_format_dot3f}",
					( $model[4] * $gcc2MKS ) );

# print(
# 	"immodpg,_get_initial_model4gui,VPtop = $VPtop[$layer_index], VPbot=$VPbot[$layer_index],layer_index=$layer_index\n"
# );

#			print("VStop = $VStop[$layer_index], VSbot=$VSbot[$layer_index],layer_index=$layer_index\n");
#			print("dz = $dz[$layer_index], rho_top=$density_top[$layer_index],rho_bot=$density_bot[$layer_index]\n");

				#				my $x_indices     = pdl(5);
				#				my $layer_indices = pdl(2);
			}    # end a for loop

			# test for errors
			_set_model_control( \@VPbot, \@VPtop, \@VSbot, \@VStop,
				\@density_bot, \@density_top, \@dz );
			my $error_switch = _get_model_control();

			if ( $error_switch eq $on ) {

				# CASE 1A File exists and is corrupt
				_messages( 'immodpg', 1 );
				return ();

			}
			elsif ( $error_switch eq $off ) {

				# CASE 1B File exists and is OK
				# print("immodpg,_get_initial_model4gui, MODEL OK ;NADA\n");
				return ( \@VPtop, \@VPbot, \@dz, $error_switch );

			}
			else {
				print("immodpg,_get_initial_model4gui, unexpected value\n");
			}

 #	        print pdl(@VPtop,@VPbot,@dz,@VStop,@VSbot,@density_top,@density_bot);
 #	        print ("\n");
 #			print $model_pdl->index2d($x_indices,$layer_indices);
 #			print ("\n");
 #			print $model_pdl;

		}
		elsif ( not( -e $inbound ) ) {

			print("immodpg,_get_initial_model4gui,file is missing\n");
			use File::Copy;
			my $from =
			  $global_libs->{_configs_big_streams} . '/' . $immodpg_model;
			my $to = $IMMODPG . '/' . $immodpg_model_file_text;
			copy( $from, $to );

			$from = $global_libs->{_configs_big_streams} . '/'
			  . $immodpg_model_file_text;
			$to = $IMMODPG . '/' . $immodpg_model_file_text;
			copy( $from, $to );

			return ();
		}
		else {
			print("immodpg,_get_initial_model4gui,unexpected value\n");
			return ();
		}

	}
	else {
		print("immodpg,_get_initial_model4gui,bad layer number\n");
		return ();
	}
	return ();
}

=head2

determine number of layers
from model.text file

=cut

sub _get_number_of_layers {

	my ($self) = @_;
	my $number_of_layers;

	if ( length( $immodpg->{_model_file_text} ) ) {

		my $count        = 0;
		my $magic_number = 4;
		my $inbound_model_file_text =
		  $IMMODPG . '/' . $immodpg->{_model_file_text};

# print ("immodpg,_get_number_of_layers,inbound_model_file_text=$inbound_model_file_text\n");

		open( my $fh, '<', $inbound_model_file_text );

		while (<$fh>) {

			$count++;

		}
		close($fh);

		$number_of_layers = $count - $magic_number;

	  #			print("immodpg,_get_number_of_layers, layers = $number_of_layers \n");

	}
	else {

		#		print("immodpg,_get_number_of_layers, missing values\n");
		$number_of_layers = 0;
	}

	my $result = $number_of_layers;
	return ($result);
}

=head2 sub _getVp_ref_dz_ref
Collect the currently update
values in the model for
layers and their velocities and 
thicknesses

=cut

sub _getVp_ref_dz_ref {

	my ($self) = @_;

	my @VPtop = @{ $immodpg->{_refVPtop} };
	my @VPbot = @{ $immodpg->{_refVPbot} };
	my @dz    = @{ $immodpg->{_ref_dz} };
	my $layer = $immodpg->{_model_layer_number};

	#	 print("immodpg,_getVp_ref_dz_ref layer_number = $layer \n");

	if (    looks_like_number($layer)
		and scalar(@VPtop)
		and scalar(@VPbot)
		and scalar(@dz) )
	{

		return ( \@VPtop, \@VPbot, \@dz );

	}
	else {
		print("immodpg,_getVp_ref_dz_ref , unexpected value\n");
		return ();
	}

}

=head2 sub _getVp_ref_dz_scalar
Collect the currently update
values in the model for
layers and their velocities and 
thicknesses

=cut

sub _getVp_ref_dz_scalar {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_model_layer_number} ) ) {

		my ( $_thickness_m_upper_layer, $Vbot_lower_layer );
		my ( @V,                        @result );

		my $layer = $immodpg->{_model_layer_number};

		#			print("immodpg,_getVp_ref_dz_scalar layer_number = $layer \n");

		my @VPtop = @{ $immodpg->{_refVPtop} };
		my @VPbot = @{ $immodpg->{_refVPbot} };
		my @dz    = @{ $immodpg->{_ref_dz} };

		#		$error_switch		= $immodpg->{_error_switch};

		if (    scalar(@VPtop)
			and scalar(@VPbot)
			and scalar(@dz) )
		{

# print("immodpg,_getVp_ref_dz_scalar VPtop= $VPtop[($layer-1)]\n");
# print("immodpg,_getVp_ref_dz_scalar for layer:($layer), VPbot= $VPbot[($layer-1)]\n");

			my $layer_index             = $layer - 1;
			my $layer_index_upper_layer = $layer - 2;
			my $layer_index_lower_layer = $layer;

			# For all cases
			my $Vtop = $VPtop[$layer_index];
			my $Vbot = $VPbot[$layer_index];
			my $dz   = $dz[$layer_index];

			if ( $layer >= 2 ) {

				# CASE of second of two or more layers
				my $Vbot_upper_layer = $VPbot[$layer_index_upper_layer];
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;

				# print("immodpg,_getVp_ref_dz_scalar: velocities are:  @V \n");
				return ( \@result, $dz );

				#				return ( \@result, $dz, $error_switch );

			}
			elsif ( $layer >= 1 ) {

				# CASE of first of one or more layers
				my $Vbot_upper_layer = $empty_string;
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;

				#				return ( \@result, $dz, $error_switch );
				return ( \@result, $dz );
			}
			else {
				print(
					"immodpg, _getVp_ref_dz_scalar, unexpected layer number \n"
				);
				return ();
			}
		}
		else {
			return ();
			print(
"immodpg,_getVp_ref_dz_scalar, _get_initial_model gives bad values\ n"
			);
		}

	}
	else {
		print("immodpg,_getVp_ref_dz_scalar,missing layer\n");
		return ();
	}
	return ();

}

=head2 sub _get_initialVp_dz4gui

=cut

sub _get_initialVp_dz4gui {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_model_layer_number} ) ) {

		my ( $_thickness_m_upper_layer, $Vbot_lower_layer );
		my ( @V,                        @result );

		my $layer = $immodpg->{_model_layer_number};
		my ( $refVPtop, $refVPbot, $ref_dz, $error_switch ) =
		  _get_initial_model4gui();

		if (    length($refVPtop)
			and length($refVPbot)
			and length($ref_dz)
			and length($error_switch) )
		{

			my @VPtop = @$refVPtop;
			my @VPbot = @$refVPbot;
			my @dz    = @$ref_dz;

			#		print("immodpg,_get_initialVp_dz4gui VPtop= @VPtop\n");
			#		print("immodpg,_get_initialVp_dz4gui VPbot= @VPbot\n");
			#		print("immodpg,_get_initialVp_dz4gui layer_number = $layer \n");

			my $layer_index             = $layer - 1;
			my $layer_index_upper_layer = $layer - 2;
			my $layer_index_lower_layer = $layer;

			# For all cases
			my $Vtop = $VPtop[$layer_index];
			my $Vbot = $VPbot[$layer_index];
			my $dz   = $dz[$layer_index];

			if ( $layer >= 2 ) {

				# CASE of second of two or more layers
				my $Vbot_upper_layer = $VPbot[$layer_index_upper_layer];
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;

			  #			print("immodpg_get_initialVp_dz4gui: velocities are:  @V \n");
				return ( \@result, $dz, $error_switch );

			}
			elsif ( $layer >= 1 ) {

				# CASE of first of one or more layers
				my $Vbot_upper_layer = $empty_string;
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;
				return ( \@result, $dz, $error_switch );

			}
			else {
				print(
					"immodpg, _get_initialVp_dz4gui, unexpected layer number \n"
				);
				return ();
			}
		}
		else {
			return ();
			print(
"immodpg,_get_initialVp_dz4gui, _get_initial_model gives bad values \n"
			);
		}

	}
	else {
		print("immodpg,_get_initialVp_dz4gui,missing layer\\n");
		return ();
	}
	return ();

}

=head2 sub _messages
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK is clicked and wait variable changes from yes 
to no.

=cut

sub _messages {

	my ( $run_name, $number ) = @_;

	my $run_name_message = message_director->new();
	my $message          = $run_name_message->immodpg($number);

	my $message_box       = $immodpg->{_message_box_w};
	my $message_label     = $immodpg->{_message_label_w};
	my $message_box_wait  = $immodpg->{_message_box_wait};
	my $message_ok_button = $immodpg->{_message_ok_button};

	# print("1 immodpg,_messages, message_box=$message_box\n");

	$message_box->title($run_name);

	$message_label->configure( -textvariable => \$message, );

	$message_box->deiconify();
	$message_box->raise();
	$message_ok_button->waitVariable( \$message_box_wait );
	return ();
}

=head2 sub _setVbot

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _setVbot {
	my ($Vbot) = @_;

	if ( looks_like_number($Vbot)
		&& $immodpg->{_isVbot_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $Vbot_file = $immodpg->{_Vbot_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $Vbot_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $Vbot;
				$format = $var_immodpg->{_format_real};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVbot_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _setVbot, unexpected answer\n");
	}

	return ();
}

=head2 sub _setVbot_upper_layer

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files
_setVbot_upper_layer

=cut

sub _setVbot_upper_layer {
	my ($Vbot_upper_layer) = @_;

	if (   $Vbot_upper_layer ne $empty_string
		&& $immodpg->{_isVbot_upper_layer_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $Vbot_upper_layer_file = $immodpg->{_Vbot_upper_layer_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $Vbot_upper_layer_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {

				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $Vbot_upper_layer;
				$format = $var_immodpg->{_format_real};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVbot_upper_layer_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _setVbot_upper_layer, unexpected answer\n");
	}

	return ();
}

=head2 sub _setVbotNtop_factor

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files
_setVbotNtop_factor

=cut

sub _setVbotNtop_factor {
	my ($VbotNtop_factor) = @_;

	if (   $VbotNtop_factor ne $empty_string
		&& $immodpg->{_isVbotNtop_factor_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $VbotNtop_factor_file = $immodpg->{_VbotNtop_factor_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $VbotNtop_factor_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $VbotNtop_factor;
				$format = '  0.0';
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVbotNtop_factor_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _setVbotNtop_factor, unexpected answer\n");
	}

	return ();
}

=head2 sub _setVbotNtop_multiply
Verify another lock file does not exist and
only then:
Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files
_setVbotNtop_multiply

=cut

sub _setVbotNtop_multiply {
	my ($self) = @_;

	if (   looks_like_number( $immodpg->{_Vbot_multiplied} )
		&& looks_like_number( $immodpg->{_Vtop_multiplied} )
		&& looks_like_number( $immodpg->{_Vbot_current} )
		&& looks_like_number( $immodpg->{_Vtop_current} ) )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $file = $immodpg->{_VbotNtop_multiply_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0]   = $immodpg->{_Vbot_multiplied};
				$X[1]   = $immodpg->{_Vtop_multiplied};
				$format = $var_immodpg->{_format_real};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	else {
		print("immodpg, _setVbotNtop_multiply, unexpected answer\n");
	}

	return ();
}

=head2 sub _setVincrement

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _setVincrement {
	my ($Vincrement) = @_;

		
	if (   $Vincrement ne $empty_string
		&& $immodpg->{_isVincrement_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $Vincrement_file = $immodpg->{_Vincrement_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $Vincrement_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $Vincrement;
		        
				$format = $var_immodpg->{_format51f};				    
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVincrement_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _setVincrement, unexpected answer\n");
	}

	return ();
}

=head2 sub _set_control
Correct improper values

=cut

sub _set_control {

	my ( $name, $value ) = @_;

	if (   length($name)
		&& length($value) )
	{

		# print("immodpg, _set_control, name=$name, value=$value\n");

		if ( $name eq 'Vtop' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 10;

# print("immodpg, _set_control, new corrected Vtop=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;
			}

		}
		elsif ( $name eq 'Vbot' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 10;

# print("immodpg, _set_control, new corrected Vbot=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;
			}

		}
		elsif ( $name eq 'Vbot_upper_layer' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 10;

# print("immodpg, _set_control, corrected Vbot_upper_layer=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;

# print("immodpg, _set_control, uncorrected Vbot_upper_layer=$immodpg->{_control_value}\n");
			}

		}
		elsif ( $name eq 'VbotNtop_factor' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 1;

# print("immodpg, _set_control, new corrected VbotNtop_factor=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;

# print("immodpg, _set_control, uncorrected VbotNtop_factor=$immodpg->{_control_value}\n");
			}
		}
		elsif ( $name eq 'Vincrement' ) {
			if ( $value < 0 ) {

				# Vincrement is wild
				$immodpg->{_control_value} = $value;

# print("immodpg, _set_control, new corrected Vincrement=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;

# print("immodpg, _set_control, uncorrected VbotNtop_factor=$immodpg->{_control_value}\n");
			}

		}
		elsif ( $name eq 'Vtop_lower_layer' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 10;

# print("immodpg, _set_control, new corrected Vtop_lower_layer=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;
			}

		}
		elsif ( $name eq 'clip4plot' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 0.1;

# print("immodpg, _set_control, new corrected clip4plot=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;

# print("immodpg, _set_control, uncorrected clip4plot=$immodpg->{_control_value}\n");
			}

		}
		elsif ( $name eq 'thickness_m' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 0.1;

# print("immodpg, _set_control, new corrected thickness_m=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;
			}

		}
		elsif ( $name eq 'thickness_increment_m' ) {
			if ( $value < 0 ) {

				$immodpg->{_control_value} = 1;

# print("immodpg, _set_control, new corrected thicknessincrement_m=$immodpg->{_control_value}\n");

			}
			else {
				$immodpg->{_control_value} = $value;
			}
		}
		else {
			print("immodpg,_setVp_dz, unexpected name \n");
		}

	}
	else {
		print("immodpg, _setVp_dz, missing variable\n");
		print("immodpg, _setVp_dz, name=$name\n");
		print("immodpg, _setVp_dz, value=$value\n");
	}
	return ();
}

=head2 sub _set_initialVp_dz
Establish the initial values
from the model that will
be used in the gui 
initially

=cut

sub _set_initialVp_dz {

	my ( $refVPtop, $refVPbot, $ref_dz, $error_switch ) = @_;

	if (   length($refVPtop)
		&& length($refVPbot)
		&& length($ref_dz)
		&& length($error_switch) )
	{

		if ( $error_switch eq $on ) {

			print("immodpg, _set_initialVp_dz, corrupt model\n");

		}
		elsif ( $error_switch eq $off ) {

			$immodpg->{_refVPtop}     = $refVPtop;
			$immodpg->{_refVPbot}     = $refVPbot;
			$immodpg->{_ref_dz}       = $ref_dz;
			$immodpg->{_error_switch} = $error_switch;

		}
		else {
			print(
				"immodpg, _set_initialVp_dz, unexpected error switch value\n");
		}
	}
	else {
		print("immodpg, _set_initialVp_dz, unexpected model values \n");
	}
	return ();
}

=head2 sub _setVp_dz
Dynamically collect 
values layers, layer velocities and 
thicknesses
during interaction with user

=cut

sub _setVp_dz {

	my ( $name, $value ) = @_;

	if (   length($name)
		&& length($value)
		&& length( $immodpg->{_refVPtop} )
		&& length( $immodpg->{_refVPbot} )
		&& length( $immodpg->{_ref_dz} ) )
	{

		my $layer_index = $immodpg->{_layer_current} - 1;

		if ( $name eq 'Vtop' ) {

			my $refVPtop = $immodpg->{_refVPtop};
			my @VPtop    = @$refVPtop;
			$VPtop[$layer_index] = $value;

  # print("immodpg, _setVp_dz,Vtop,VPtop[$layer_index]=$VPtop[$layer_index]\n");
			$immodpg->{_refVPtop} = \@VPtop;

		}
		elsif ( $name eq 'Vtop_lower_layer' ) {

			my $refVPtop = $immodpg->{_refVPtop};
			my @VPtop    = @$refVPtop;
			$VPtop[ ( $layer_index + 1 ) ] = $value;

# print("immodpg, _setVp_dz,Vtop_lower_layer, VPtop[($layer_index+1)]=$VPtop[($layer_index+1)]\n");
			$immodpg->{_refVPtop} = \@VPtop;

		}
		elsif ( $name eq 'Vbot' ) {

#			print("immodpg, _setVp_dz,immodpg->{_Vbot_current}= $immodpg->{_Vbot_current}\n");
#			print("immodpg, _setVp_dz,immodpg->{_layer_current}= $immodpg->{_layer_current}\n");
			my $refVPbot = $immodpg->{_refVPbot};
			my @VPbot    = @$refVPbot;
			$VPbot[$layer_index] = $value;

  # print("immodpg, _setVp_dz,Vbot,VPbot[$layer_index]=$VPbot[$layer_index]\n");
			$immodpg->{_refVPbot} = \@VPbot;

		}
		elsif ( $name eq 'Vbot_upper_layer' ) {

			my $refVPbot = $immodpg->{_refVPbot};
			my @VPbot    = @$refVPbot;
			$VPbot[ ( $layer_index - 1 ) ] = $value;

# print("immodpg, _setVp_dz,Vbot_upper_layer,VPbot[($layer_index-1)]=$VPbot[($layer_index-1)]\n");
			$immodpg->{_refVPbot} = \@VPbot;

		}
		elsif ( $name eq 'thickness_m' ) {

			my $ref_dz = $immodpg->{_ref_dz};
			my @dz     = @$ref_dz;
			$dz[$layer_index] = $value;

		# print("immodpg, _setVp_dz, dz: dz[$layer_index]=$dz[$layer_index]\n");
			$immodpg->{_ref_dz} = \@dz;

		}
		else {
			print("immodpg,_setVp_dz, unexpected name \n");
		}
	}
	else {
		print("immodpg, _setVp_dz, missing variable\n");
		print("immodpg, _setVp_dz, name=$name\n");
		print("immodpg, _setVp_dz, value = $value\n");
		print("immodpg, _setVp_dz, _refVPtop = @{$immodpg->{_refVPtop}}\n");
		print("immodpg, _setVp_dz, _refVPbot = @{$immodpg->{_refVPbot}}\n");
		print("immodpg, _setVp_dz, _dz = $immodpg->{_dz}\n");
	}

	return ();
}

=head2 sub _setVtop

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _setVtop {

	my ($Vtop) = @_;

	if ( looks_like_number($Vtop)
		&& $immodpg->{_isVtop_changed_in_gui} eq $yes )
	{

		# print("immodpg,_setVtop,write out fortran value of Vtop\n");

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $Vtop_file = $immodpg->{_Vtop_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $Vtop_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $Vtop;
				$format = $var_immodpg->{_format_real};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVtop_changed_in_gui} eq $no ) {

		# NADA
		print("immodpg, _setVtop, no change\n");

	}
	else {
		print("immodpg, _setVtop, unexpected answer\n");
	}

	return ();
}

=head2 sub _setVtop_lower_layer

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _setVtop_lower_layer {
	my ($Vtop_lower_layer) = @_;

	if ( looks_like_number($Vtop_lower_layer)
		&& $immodpg->{_isVtop_lower_layer_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $Vtop_lower_layer_file = $immodpg->{_Vtop_lower_layer_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $Vtop_lower_layer_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $Vtop_lower_layer;
				$format = $var_immodpg->{_format_real};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_isVtop_lower_layer_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _setVtop_lower_layer, unexpected answer\n");
	}

	return ();
}

=head2 sub _set_change

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _set_change {

	my ($yes_or_no) = @_;

	if (   length($yes_or_no)
		&& length( $immodpg->{_change_file} ) )
	{

		# print("immodpg, _set_change, yes_or_no:$yes_or_no\n");

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $test   = $yes;
		my $change = $immodpg->{_change_file};

		my $outbound        = $IMMODPG_INVISIBLE . '/' . $change;
		my $outbound_locked = $outbound . '_locked';
		my $format          = $var_immodpg->{_format_string};

		my $count      = 0;
		my $max_counts = 1000;
		for (
			my $i = 0 ;
			( $test eq $yes ) and ( $count < $max_counts ) ;
			$i++
		  )
		{

			#			print("1. immodpg,_set_change, in loop count=$count \n");

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {

				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

		# print("immodpg, _set_change, outbound_locked=$outbound_locked\n");
		# print("immodpg, _set_change, IMMODPG_INVISIBLE=$IMMODPG_INVISIBLE\n");
		# print("immodpg, _set_change, created empty locked file=$X[0]\n");

		# print("immodpg, _set_change, outbound=$outbound\n");
		# print("immodpg, _set_change, IMMODPG_INVISIBLE=$IMMODPG_INVISIBLE\n");

				# do not overwrite a waiting change (= yes)
				my $response_aref = $files->read_1col_aref( \$outbound );
				my $ans           = @{$response_aref}[0];

				if ( $ans eq $yes ) {

				 # do not overwrite a waiting change (= yes)
				 # print("2. immodpg, _set_change, SKIP\n");
				 # print("immodpg, _set_change,do not overwrite change_file\n");

					unlink($outbound_locked);

				}
				elsif ( $ans eq $no ) {

					# overwrite change_file(=no) with no or yes
					$X[0] = $yes_or_no;
					$files->write_1col_aref( \@X, \$outbound, \$format );

			# print("immodpg, _set_change, overwrite change file with $X[0]\n");

					unlink($outbound_locked);

					# print("3. immodpg, _set_change, delete locked file\n");
					# print("4. immodpg, _set_change, yes_or_no=$X[0]\n");

					$test = $no;

				}
				else {
					print("immodpg, _set_change, unexpected result \n");
				}    # test change_file's content

			}
			else {

				# print("immodpg,_set_change, locked change file\n");
				$count++;    # governor on finding an unlocked change_file
			}    # if unlocked file is missing and change_file is free

			$count++;    # governor on checking for a change_file = yes
		}    # for

	}
	else {
		print("immodpg, _set_change, missing values\n");
	}
	return ();
}

=head2 sub _set_clip

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _set_clip {
	my ($clip) = @_;

	if (   $clip ne $empty_string
		&& $immodpg->{_is_clip_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $clip_file = $immodpg->{_clip_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $clip_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $clip;
				$format = $var_immodpg->{_format51f};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				# print("immodpg, _set_clip, output clip = $clip\n");
				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_clip_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _set_clip, unexpected answer\n");
	}

	return ();
}

=head2 sub _set_thickness_m

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _set_thickness_m {
	my ($thickness_m) = @_;

	if (   $thickness_m ne $empty_string
		&& $immodpg->{_is_thickness_m_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $thickness_m_file = $immodpg->{_thickness_m_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $thickness_m_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $thickness_m;
				$format = $var_immodpg->{_format51f};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_thickness_m_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _set_thickness_m, unexpected answer\n");
	}

	return ();
}

=head2 sub _set_thickness_increment_m

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub _set_thickness_increment_m {
	my ($thickness_increment_m) = @_;

	if (   $thickness_increment_m ne $empty_string
		&& $immodpg->{_is_layer_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $thickness_increment_m_file =
		  $immodpg->{_thickness_increment_m_file};

		my $test     = $no;
		my $outbound = $IMMODPG_INVISIBLE . '/' . $thickness_increment_m_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $thickness_increment_m;
				print("thickness_increment_m=$thickness_increment_m\n");
				$format = $var_immodpg->{_format51f};
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);
				$test = $yes;

			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_layer_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _set_thickness_increment_m, unexpected answer\n");
	}

	return ();
}

=head2 sub _fortran_layer

set layer
Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files


=cut

sub _fortran_layer {
	my ($layer) = @_;

	if (   $layer ne $empty_string
		&& $immodpg->{_is_layer_changed_in_gui} eq $yes )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $layer_file = $immodpg->{_layer_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $layer_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			# print("in loop \n");

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $layer;
				$format = $var_immodpg->{_format_integer};
				$files->write_1col_aref( \@X, \$outbound, \$format );
				unlink($outbound_locked);

				$test = $yes;
			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_layer_changed_in_gui} eq $no ) {

		# NADA

	}
	else {
		print("immodpg, _fortran_layer, unexpected answer\n");
	}

	return ();

}

=head2 sub set_working_model_bin

=cut

sub _set_working_model_bin {
	my ($self) = @_;

	#		print("l3171 $immodpg->{_working_model_bin_opt} \n");
	_set_option($change_working_model_bin_opt);
	_set_change($yes);

	return ();
}

=head2 sub set_working_model_text

=cut

sub _set_working_model_text {

	_set_option($change_working_model_text_opt);
	_set_change($yes);

	return ();
}

=head2 sub _set_clip_control
value adjusts to current
clip value in use

=cut

sub _set_clip_control {

	my ($control_clip) = @_;

	my $result;

	if ( length($control_clip) ) {

		$immodpg->{_control_clip} = $control_clip;

 # print("immodpg,_set_clip_control, control_clip=$immodpg->{_control_clip}\n");

	}
	elsif ( not( length($control_clip) ) ) {

		# print("immodpg,_set_clip_control, empty string\n");
		$immodpg->{_control_clip} = $control_clip;

	}
	else {
		print("immodpg,_set_clip_control, missing value\n");
	}

	return ();
}

=head2 sub _set_layer_control
value adjusts to current
layer number in use

=cut

sub _set_layer_control {

	my ($control_layer) = @_;

	my $result;

	if ( length($control_layer) ) {

		$immodpg->{_control_layer} = $control_layer;

#		print("immodpg,_set_layer_control, control_layer=$immodpg->{_control_layer}\n");

	}
	elsif ( not( length($control_layer) ) ) {

		#		print("immodpg,_set_layer_control, empty string\n");
		$immodpg->{_control_layer} = $control_layer;

	}
	else {
		print("immodpg,_set_layer_control, missing value\n");
	}

	return ();
}

=head2 sub _get_model_control
is there an error with the model?

=cut

sub _get_model_control {

	my ($self) = @_;

	my $result = $off;

	if ( length( $immodpg->{_model_error} ) ) {

		$result = $immodpg->{_model_error};

	}
	else {
		print(
			"immodpg,get_model_control,num_layers=unexpected missing value\n");
	}

	return ($result);

}

=head2 sub set_model_control
find out if there is an error in the binary
fortran model

=cut

sub _set_model_control {

	my ( $refVPbot, $refVPtop, $ref_VSbot, $ref_VStop, $ref_density_bot,
		$ref_density_top, $ref_dz )
	  = @_;

	my $result       = '';
	my $error_switch = $off;

	if (    length($refVPbot)
		and length($refVPtop)
		and length($ref_VSbot)
		and length($ref_VStop)
		and length($ref_density_bot)
		and length($ref_density_top)
		and length($ref_dz) )
	{

		my @VSbot            = @$ref_VSbot;
		my @VStop            = @$ref_VStop;
		my @VPbot            = @$refVPbot;
		my @VPtop            = @$refVPtop;
		my @density_bot      = @$ref_density_bot;
		my @density_top      = @$ref_density_top;
		my @dz               = @$ref_dz;
		my $number_of_layers = scalar @$refVPbot;

		#		print("immodpg,set_model_control,num_layers=$number_of_layers\n");
		if ( $number_of_layers > 1 ) {

			for (
				my $layer_index = 0 ;
				$layer_index < $number_of_layers ;
				$layer_index++
			  )
			{

				if (   $VStop[$layer_index] < 0
					or $VSbot[$layer_index] < 0
					or $VPtop[$layer_index] < 0
					or $VPbot[$layer_index] < 0
					or $density_bot[$layer_index] < 0
					or $density_top[$layer_index] < 0
					or $dz[$layer_index] < 0 )
				{

					$error_switch = $on;

				}
				else {

					# print("immodpg,_get_initial_model, TEST OK NADA\n");
				}
			}    # end for loop

			if ( $error_switch eq $on ) {

				#	print("immodpg,set_model_control, CORRUPT MODEL\n");
				$immodpg->{_model_error} = $error_switch;
			}

			return ($result);

		}
		else {
			print("immodpg, _set_model_control, error with layer number\n");
			return ($result);
		}

	}
	else {
		print("immodpg, _set_model_control, unexpected model error\n");
		return ($result);
	}

}

=head2 _set_model_layer
Set the number of layers in 
mmodpg 

=cut

sub _set_model_layer {

	my ($model_layer_number) = @_;

	if ( $model_layer_number != 0
		&& length($model_layer_number) )
	{

		$immodpg->{_model_layer_number} = $model_layer_number;

	}
	else {
		print("immodpg, _set_model_layer, unexpected layer# \n");
	}

#	print("immodpg, _set_model_layer,model layer# =$immodpg->{_model_layer_number}\n");

	return ();
}

=head2 sub _set_option

Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files


=cut

sub _set_option {

	my ($option) = @_;

#	print("1.immodpg,_set_option,option:$option\n");

	if ( defined($option)
		&& $immodpg->{_option_file} ne $empty_string )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $option_file = $immodpg->{_option_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $option_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			# print("immodpg,_set_option, in loop \n");

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $option;
				$format = $var_immodpg->{_format2i};

#				print("2.immodpg,_set_option,option:$option\n");
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);

				$test = $yes;
			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_option_changed} eq $no ) {
		# NADA
	}
	else {
		print("immodpg, _set_option, unexpected answer\n");
	}
	return ();
}

=head2 sub _updateVbot

keep tabs on Vbot values
and changes in the values in the  
GUI
Also updates an shared copy
of the model properties

use App::SeismicUnixGui::misc::control '0.0.3' method to check for bad values;

=cut

sub _updateVbot {

	my ($self) = @_;

	if (    looks_like_number( $immodpg->{_Vbot_current} )
		and looks_like_number( $immodpg->{_Vbot_prior} )
		&& $immodpg->{_Vbot_current} != $immodpg->{_Vbot_prior} )
	{

		# CASE Vbot has changed
		$immodpg->{_isVbot_changed_in_gui} = $yes;
		$immodpg->{_Vbot_prior}            = $immodpg->{_Vbot_current};

	 # print("immodpg, _updateVbot, has changed\n");
	 # print("1. immodpg,_updateVbot,Vbot_current=$immodpg->{_Vbot_current}\n");
	 # print("1. immodpg,_updateVbot,Vbot_prior=$immodpg->{_Vbot_prior}\n");

		_set_control( 'Vbot', $immodpg->{_Vbot_current} );
		$immodpg->{_Vbot_current} = _get_control('Vbot');

		_setVp_dz( 'Vbot', $immodpg->{_Vbot_current} );

		return ();

	}
	elsif ( $immodpg->{_Vbot_current} == $immodpg->{_Vbot_prior} ) {

		# CASE Vbot is unchanged
		# print("immodpg, _updateVbot, unchanged\n");
		$immodpg->{_isVbot_changed_in_gui} = $no;

	 # print("2. immodpg,_updateVbot,Vbot_current=$immodpg->{_Vbot_current}\n");
	 # print("2. immodpg,_updateVbot,Vbot_prior=$immodpg->{_Vbot_prior}\n");
		return ();

	}
	else {
		print("immodpg, _updateVbot, unexpected\n");
		return ();
	}
}

=head2 sub _updateVbot_upper_layer

keep tabs on upper layer Vbottom values
and changes in the values in the 
GUI
current layer must >0

=cut

sub _updateVbot_upper_layer {

	my ($self) = @_;

#	print("mmodpg, _updateVbot_upper_layer, Vbot_upper_layer_current=..$immodpg->{_Vbot_upper_layer_current}..\n");
	if (   looks_like_number( $immodpg->{_Vbot_upper_layer_current} )
		&& $immodpg->{_layer_current} > 0
		&& $immodpg->{_Vbot_upper_layer_current} !=
		$immodpg->{_Vbot_upper_layer_prior} )
	{

		# CASE Vbot_upper_layer changed
		$immodpg->{_isVbot_upper_layer_changed_in_gui} = $yes;
		$immodpg->{_Vbot_upper_layer_prior} =
		  $immodpg->{_Vbot_upper_layer_current};

# print("immodpg, _updateVbot_upper_layer, updated to $immodpg->{_Vbot_upper_layer_current}\n");
# print("immodpg,_updateVbot_upper_layer,Vbot_upper_layer_current=$immodpg->{_Vbot_upper_layer_current}\n");
# print("immodpg,_updateVbot_upper_layer,Vbot_upper_layer_prior=$immodpg->{_Vbot_upper_layer_prior}\n");
		_set_control( 'Vbot_upper_layer',
			$immodpg->{_Vbot_upper_layer_current} );
		$immodpg->{_Vbot_upper_layer_current} =
		  _get_control('Vbot_upper_layer');

		_setVp_dz( 'Vbot_upper_layer', $immodpg->{_Vbot_upper_layer_current} );
		return ();

	}
	elsif ( looks_like_number( $immodpg->{_Vbot_upper_layer_current} )
		&& $immodpg->{_Vbot_upper_layer_current} ==
		$immodpg->{_Vbot_upper_layer_prior} )
	{

		# CASE Vbot_upper_layer is unchanged
		# print("immodpg, _updateVbot_upper_layer, unchanged\n");
		$immodpg->{_isVbot_upper_layer_changed_in_gui} = $no;

# print("immodpg,_updateVbot_upper_layer,Vbot_upper_layer_prior=$immodpg->{_Vbot_upper_layer_prior}\n");
		return ();

	}
	elsif ( not( looks_like_number( $immodpg->{_Vbot_upper_layer_current} ) ) )
	{

# CASE Vbot_upper_layer is unchanged
#		print("immodpg, _updateVbot_upper_layer, no value in Vbot_upper_layer NADA\n");
# print("immodpg,_updateVbot_upper_layer,Vbot_upper_layer_prior=$immodpg->{_Vbot_upper_layer_prior}\n");
		return ();

	}
	else {
		print("immodpg, _updateVbot_upper_layer, unexpected\n");

#		print("immodpg,_updateVbot_upper_layer,Vbot_upper_layer_current=$immodpg->{_Vbot_upper_layer_current}\n");
		return ();
	}
}

=head2 sub _update_Vincrement

keep tabs on Vincrement values
and changes in the values in the  
GUI

=cut

sub _updateVincrement {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_Vincrement_current} )
		&& $immodpg->{_Vincrement_current} != $immodpg->{_Vincrement_prior} )
	{

		# CASE Vincrement changed
		$immodpg->{_Vincrement_current} = $immodpg->{_Vincrement_current};
		$immodpg->{_isVincrement_changed_in_gui} = $yes;

# print("immodpg, _updateVincrement, updated to $immodpg->{_Vincrement_current}\n");

#		print("immodpg,_updateVincrement,Vincrement_current=$immodpg->{_Vincrement_current}\n");
#		print("immodpg,_updateVincrement,Vincrement_prior=$immodpg->{_Vincrement_prior}\n");
		return ();

	}
	elsif ( $immodpg->{_Vincrement_current} == $immodpg->{_Vincrement_prior} ) {

		# CASE Vincrement is unchanged
		# print("immodpg, _updateVincrement, unchanged\n");
		$immodpg->{_isVincrement_changed_in_gui} = $no;

# print("immodpg,_updateVincrement,Vincrement_current=$immodpg->{_Vincrement_current}\n");
# print("immodpg,_updateVincrement,Vincrement_prior=$immodpg->{_Vincrement_prior}\n");
		return ();

	}
	else {
		print("immodpg, _updateVincrement, unexpected\n");
		return ();
	}
}

=head2 sub _updateVtop

keep tabs on Vtop values
and changes in the values in the  
GUI
Also updates an shared copy
of the model properties

=cut

sub _updateVtop {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_Vtop_current} )
		&& $immodpg->{_Vtop_current} != $immodpg->{_Vtop_prior} )
	{

		# CASE Vtop changed
		$immodpg->{_isVtop_changed_in_gui} = $yes;
		$immodpg->{_Vtop_prior}            = $immodpg->{_Vtop_current};

	   #		print("immodpg, _updateVtop, updated to $immodpg->{_Vtop_current}\n");
	   #		print("immodpg,_updateVtop,Vtop_current=$immodpg->{_Vtop_current}\n");
	   #		print("immodpg,_updateVtop,Vtop_prior=$immodpg->{_Vtop_prior}\n");

		_set_control( 'Vtop', $immodpg->{_Vtop_current} );
		$immodpg->{_Vtop_current} = _get_control('Vtop');
		_setVp_dz( 'Vtop', $immodpg->{_Vtop_current} );

		return ();

	}
	elsif ( $immodpg->{_Vtop_current} == $immodpg->{_Vtop_prior} ) {

		# CASE Vtop is unchanged
		#		print("immodpg, _updateVtop, unchanged\n");
		$immodpg->{_isVtop_changed_in_gui} = $no;

	   #		print("immodpg,_updateVtop,Vtop_current=$immodpg->{_Vtop_current}\n");
	   #		print("immodpg,_updateVtop,Vtop_prior=$immodpg->{_Vtop_prior}\n");
		return ();

	}
	else {
		print("immodpg, _updateVtop, unexpected\n");
		return ();
	}
}

=head2 sub _updateVtop_lower_layer

keep tabs on Vtop_lower_layer values
and changes in the values in the  
GUI
Also updates an shared copy
of the model properties

=cut

sub _updateVtop_lower_layer {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_Vtop_lower_layer_current} )
		&& $immodpg->{_Vtop_lower_layer_current} !=
		$immodpg->{_Vtop_lower_layer_prior} )
	{

# CASE Vtop changed
#		print("immodpg, _updateVtop_lower_layer, Vcurrent=$immodpg->{_Vtop_lower_layer_current}\n");
		$immodpg->{_isVtop_lower_layer_changed_in_gui} = $yes;
		$immodpg->{_Vtop_lower_layer_prior} =
		  $immodpg->{_Vtop_lower_layer_current};

		#		print("immodpg, _updateVtop_lower_layer, changed\n");
		_set_control( 'Vtop_lower_layer',
			$immodpg->{_Vtop_lower_layer_current} );
		$immodpg->{_Vtop_lower_layer_current} =
		  _get_control('Vtop_lower_layer');

		_setVp_dz( 'Vtop_lower_layer', $immodpg->{_Vtop_lower_layer_current} );

		return ();

	}
	elsif ( $immodpg->{_Vtop_lower_layer_current} ==
		$immodpg->{_Vtop_lower_layer_prior} )
	{

# CASE Vtop_lower_layer is unchanged
#		print("immodpg, _updateVtop_lower_layer, unchanged\n");
#		print("immodpg, _updateVtop_lower_layer, Vcurrent=$immodpg->{_Vtop_lower_layer_current}\n");
		$immodpg->{_isVtop_lower_layer_changed_in_gui} = $no;

		return ();

	}
	else {
		print("immodpg, _updateVtop_lower_layer, unexpected\n");
		return ();
	}
}

=head2 sub _updateVbotNtop_factor

keep tabs on VbotNtop_factor  values
and changes in the values in the  
GUI

=cut

sub _updateVbotNtop_factor {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_VbotNtop_factor_current} )
		&& $immodpg->{_VbotNtop_factor_current} !=
		$immodpg->{_VbotNtop_factor_prior} )
	{

# CASE VbotNtop_factor changed
#			$immodpg->{_VbotNtop_factor_current}          = $immodpg->{_VbotNtop_factor_current};
		_set_control( 'VbotNtop_factor', $immodpg->{_VbotNtop_factor_current} );
		$immodpg->{_VbotNtop_factor_current} = _get_control('VbotNtop_factor');
		$immodpg->{_isVbotNtop_factor_changed_in_gui} = $yes;

#			print("immodpg, _updateVbotNtop_factor, updated to $immodpg->{_VbotNtop_factor_current}\n");
#			print("immodpg,_updateVbotNtop_factor,VbotNtop_factor_current=$immodpg->{_VbotNtop_factor_current}\n");
#			print("immodpg,_updateVbotNtop_factor,VbotNtop_factor_prior=$immodpg->{_VbotNtop_factor_prior}\n");
		return ();

	}
	elsif ( $immodpg->{_VbotNtop_factor_current} ==
		$immodpg->{_VbotNtop_factor_prior} )
	{

		# CASE VbotNtop_factor is unchanged
		# print("immodpg, _updateVbotNtop_factor, unchanged\n");
		$immodpg->{_isVbotNtop_factor_changed_in_gui} = $no;

# print("immodpg,_updateVbotNtop_factor,VbotNtop_factor_current=$immodpg->{_VbotNtop_factor_current}\n");
# print("immodpg,_updateVbotNtop_factor,VbotNtop_factor_prior=$immodpg->{_VbotNtop_factor_prior}\n");
		return ();

	}
	else {
		print("immodpg, _updateVbotNtop_factor, unexpected\n");
		return ();
	}
}

=head2 sub _updateVbotNtop_multiply

keep tabs on Vbot AND Vtop values together
and changes in the values in the  
GUI
Also updates an shared copy
of the model properties

=cut

sub _updateVbotNtop_multiply {

	my ($self) = @_;

	if (   looks_like_number( $immodpg->{_Vbot_current} )
		&& looks_like_number( $immodpg->{_Vtop_current} )
		&& looks_like_number( $immodpg->{_Vbot_multiplied} )
		&& looks_like_number( $immodpg->{_Vtop_multiplied} ) )
	{

		$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
		$immodpg->{_Vbot_current} = $immodpg->{_Vbot_multiplied};

		$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
		$immodpg->{_Vtop_current} = $immodpg->{_Vtop_multiplied};

		_set_control( 'Vbot', $immodpg->{_Vbot_current} );
		$immodpg->{_Vbot_current} = _get_control('Vbot');

		_set_control( 'Vtop', $immodpg->{_Vtop_current} );
		$immodpg->{_Vtop_current} = _get_control('Vtop');

		# conveniently short variable names
		my $Vtop_current = $immodpg->{_Vtop_current};
		my $Vbot_current = $immodpg->{_Vbot_current};

		$immodpg->{_VtopEntry}->delete( 0, 'end' );
		$immodpg->{_VtopEntry}->insert( 0, $Vtop_current );
		$immodpg->{_VbotEntry}->delete( 0, 'end' );
		$immodpg->{_VbotEntry}->insert( 0, $Vbot_current );

# print("immodpg, _updateVbotNtop_multiply, updated to $immodpg->{_VbotNtop_multiply_current}\n");
# print("immodpg,_updateVbotNtop_multiply,VbotNtop_multiply_current=$immodpg->{_VbotNtop_multiply_current}\n");
# print("immodpg,_updateVbotNtop_multiply,VbotNtop_multiply_prior=$immodpg->{_VbotNtop_multiply_prior}\n");
#			_checkVbot(); #todo
		_updateVbot();

		#			_checkVtop(); #todo
		_updateVtop();

	}
	else {
		print("immodpg, _updateVbotNtop_factor, unexpected\n");
		return ();
	}
}

=head2 sub _update_clip

keep tabs on clip values
and changes in the values in the  
GUI

=cut

sub _update_clip {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_clip4plot_current} )
		&& $immodpg->{_clip4plot_current} != $immodpg->{_clip4plot_prior} )
	{

		# CASE clip changed
		$immodpg->{_clip4plot_current}      = $immodpg->{_clip4plot_current};
		$immodpg->{_is_clip_changed_in_gui} = $yes;

# print("immodpg, _update_clip, updated to $immodpg->{_clip4plot_current}\n");
# print("immodpg,_update_clip,clip4plot_current=$immodpg->{_clip4plot_current}\n");
# print("immodpg,_update_clip,clip4plot_prior=$immodpg->{_clip4plot_prior}\n");
		return ();

	}
	elsif ( $immodpg->{_clip4plot_current} == $immodpg->{_clip4plot_prior} ) {

		# CASE clip4plot  is unchanged
		# print("immodpg, _update_clip, unchanged\n");
		$immodpg->{_is_clip_changed_in_gui} = $no;

# print("immodpg,_update_clip,clip4plot_current=$immodpg->{_clip4plot_current}\n");
# print("immodpg,_update_clip,clip4plot_prior=$immodpg->{_clip4plot_prior}\n");
		return ();

	}
	else {
		print("immodpg, _update_clip, unexpected\n");
		return ();
	}
}

=head2 sub _update_thickness_m

keep tabs on thickness_m values
and changes in the values in the  
GUI
Also updates an shared copy
of the model properties

=cut

sub _update_thickness_m {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_thickness_m_current} )
		&& $immodpg->{_thickness_m_current} != $immodpg->{_thickness_m_prior} )
	{

		# CASE _thickness_m changed
		$immodpg->{_is_thickness_m_changed_in_gui} = $yes;

# print("immodpg, _update_thickness_m, updated to $immodpg->{_thickness_m_current}\n");
#	print("immodpg,_update_thickness_m,_thickness_m_current=$immodpg->{_thickness_m_current}\n");
# print("immodpg,_update_thickness_m,_thickness_m_prior=$immodpg->{_thickness_m_prior}\n");

		_set_control( 'thickness_m', $immodpg->{_thickness_m_current} );
		$immodpg->{_thickness_m_current} = _get_control('thickness_m');
		_setVp_dz( 'thickness_m', $immodpg->{_thickness_m_current} );

		return ();

	}
	elsif ( $immodpg->{_thickness_m_current} == $immodpg->{_thickness_m_prior} )
	{

		# CASE _thickness_m is unchanged
		# print("immodpg, _update_thickness_m, unchanged\n");
		$immodpg->{_is_thickness_m_changed_in_gui} = $no;

# print("immodpg,_update_thickness_m,_thickness_m_current=$immodpg->{_thickness_m_current}\n");
# print("immodpg,_update_thickness_m,_thickness_m_prior=$immodpg->{_thickness_m_prior}\n");
		return ();

	}
	else {
		print("immodpg, _update_thickness_m, unexpected\n");
		return ();
	}
}

=head2 sub _update_thickness_increment_m_in_gui

keep tabs on thickness_increment_m values
and changes in the values in the  
GUI

=cut

sub _update_thickness_increment_m_in_gui {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_thickness_increment_m_current} )
		&& $immodpg->{_thickness_increment_m_current} !=
		$immodpg->{_thickness_increment_m_prior} )
	{

		# CASE thickness changed
		$immodpg->{_thickness_increment_m_prior} =
		  $immodpg->{_thickness_increment_m_current};
		$immodpg->{_is_layer_changed_in_gui} = $yes;

# print("immodpg, _update_thickness_increment_m_in_gui, updated to $immodpg->{_thickness_increment_m_current}\n");
# print("immodpg,_update_thickness_increment_m_in_gui,thickness_increment_m_current=$immodpg->{_thickness_increment_m_current}\n");
# print("immodpg,_update_thickness_increment_m_in_gui,thickness_increment_m_prior=$immodpg->{_thickness_increment_m_prior}\n");
		return ();

	}
	elsif ( $immodpg->{_thickness_increment_m_current} ==
		$immodpg->{_thickness_increment_m_prior} )
	{

		# CASE thickness_increment_m is unchanged
		# print("immodpg, _update_thickness_increment_m_in_gui, unchanged\n");
		$immodpg->{_is_layer_changed_in_gui} = $no;

# print("immodpg,_update_thickness_increment_m_in_gui,thickness_increment_m_current=$immodpg->{_thickness_increment_m_current}\n");
# print("immodpg,_update_thickness_increment_m_in_gui,thickness_increment_m_prior=$immodpg->{_thickness_increment_m_prior}\n");
		return ();

	}
	else {
		print("immodpg, _update_thickness_increment_m_in_gui, unexpected\n");
		return ();
	}
}

=head2 sub _update_layer_in_gui

keep tabs on layer values
and changes in the values in the  
GUI

update prior in advance of _check_layer

=cut

sub _update_layer_in_gui {

	my ($self) = @_;

	if (
		looks_like_number( $immodpg->{_layer_current} )
		and length(
			$immodpg->{_layer_prior} and length( $immodpg->{_layerEntry} )
		)
		and ( $immodpg->{_layer_current} != $immodpg->{_layer_prior} )
	  )
	{

		# CASE layer changed
		$immodpg->{_is_layer_changed_in_gui} = $yes;
		my $layer_current   = $immodpg->{_layer_current};
		my $new_layer_prior = $immodpg->{_layer_current};

		$immodpg->{_layerEntry}->delete( 0, 'end' );
		$immodpg->{_layerEntry}->insert( 0, $layer_current );

		$immodpg->{_layer_prior} = $new_layer_prior;

#		print("immodpg, _update_layer_in_gui, prior=$immodpg->{_layer_prior}current= $immodpg->{_layer_current}\n");

		return ();

	}
	elsif ( looks_like_number( $immodpg->{_layer_current} )
		and looks_like_number( $immodpg->{_layer_prior} )
		and ( $immodpg->{_layer_current} == $immodpg->{_layer_prior} ) )
	{

		# CASE layer has not changed
		#		print("immodpg, _update_layer_in_gui, unchanged\n");
		$immodpg->{_is_layer_changed_in_gui} = $no;

		$immodpg->{_layerEntry}->delete( 0, 'end' );
		$immodpg->{_layerEntry}->insert( 0, $immodpg->{_layer_current} );

#		print("immodpg,_update_layer_in_gui, prior=$immodpg->{_layer_prior},current=$immodpg->{_layer_current}\n");
		return ();

	}
	else {
		print("immodpg, _update_layer_in_gui, unexpected\n");
		return ();
	}
	return ();
}

=head2 sub _update_lower_layer_in_gui

keep tabs on lower_layer values
and changes in the values in the  
GUI

=cut

sub _update_lower_layer_in_gui {

	my ($self) = @_;

	if (   $immodpg->{_is_layer_changed_in_gui} eq $yes
		&& $immodpg->{_layer_current} >= 1 )
	{

		# CASE layer changed
		my $lower_layer   = $immodpg->{_layer_current} + 1;
		my $layer_current = ( $immodpg->{_lower_layerLabel} )
		  ->configure( -textvariable => \$lower_layer, );

		return ();

	}
	elsif ( $immodpg->{_is_layer_changed_in_gui} eq $no ) {

		# CASE layer is unchanged
		#		print("immodpg, _update_lower_layer_in_gui, unchanged\n");
		return ();

	}
	else {
		print("immodpg, _update_lower_layer_in_gui, unexpected\n");
		return ();
	}
}

=head2 sub _update_upper_layer_in_gui

keep tabs on upper_layer values
and changes in the values in the  
GUI

=cut

sub _update_upper_layer_in_gui {

	my ($self) = @_;

	if (   $immodpg->{_is_layer_changed_in_gui} eq $yes
		&& $immodpg->{_layer_current} >= 1 )
	{

		# CASE layer changed
		my $upper_layer = $immodpg->{_layer_current} - 1;

		if ( $upper_layer == 0 ) {

			# control output
			$upper_layer = $empty_string;
		}
		my $layer_current = ( $immodpg->{_upper_layerLabel} )
		  ->configure( -textvariable => \$upper_layer, );
		return ();

	}
	elsif ( $immodpg->{_is_layer_changed_in_gui} eq $no ) {

		# CASE layer is unchanged
		#		print("immodpg, _update_upper_layer_in_gui, unchanged\n");
		return ();

	}
	else {
		return ();
		print("immodpg, _update_upper_layer_in_gui, unexpected\n");
	}
}

=head2 sub _writeVincrement

write out Vincrement

=cut

sub _writeVincrement {
	my ($self) = @_;

	if ( $immodpg->{_isVincrement_changed_in_gui} eq $yes ) {
		_write_config();

	}
	elsif ( $immodpg->{_isVincrement_changed_in_gui} eq $no ) {

		#NADA

	}
	else {
		print("immodpg, _writeVincrement, unexpected\n");
	}
	return ();
}

=head2 sub _writeVbotNtop_factor

write out VbotNtop_factor

=cut

sub _writeVbotNtop_factor {
	my ($self) = @_;

	if ( $immodpg->{_isVbotNtop_factor_changed_in_gui} eq $yes ) {
		_write_config();

	}
	elsif ( $immodpg->{_isVbotNtop_factor_changed_in_gui} eq $no ) {

		#NADA

	}
	else {
		print("immodpg, _writeVbotNtop_factor, unexpected\n");
	}
	return ();
}

=head2 sub _write_clip

write out clip

=cut

sub _write_clip {
	my ($self) = @_;

	if ( $immodpg->{_is_clip_changed_in_gui} eq $yes ) {
		_write_config();

	}
	elsif ( $immodpg->{_is_clip_changed_in_gui} eq $no ) {

		#NADA

	}
	else {
		print("immodpg, _write_clip, unexpected\n");
	}
	return ();
}

=head2 sub _write_thickness_increment_m

write out thickness_increment_m

=cut

sub _write_thickness_increment_m {
	my ($self) = @_;

	if ( $immodpg->{_is_layer_changed_in_gui} eq $yes ) {
		_write_config();

	}
	elsif ( $immodpg->{_is_layer_changed_in_gui} eq $no ) {

		#NADA

	}
	else {
		print("immodpg, _write_thickness_increment_m, unexpected\n");
	}
	return ();
}

=head2 sub _write_config

write out the new values
as well as old values and their
names to the configuration file
called immodpg.config
External parameter names do not
agree always with variable names
used inside the programs
e.g., starting_layer versus layer
or   data_x_inc_m_m  versus thickness_increment_m

=cut

sub _write_config {

	my ($self) = @_;

=pod import private variables

=cut	

	my $variables     = $immodpg_spec->variables();
	my $format_clip   = $var_immodpg->{_config_file_format_clip};
	my $format_string = $var_immodpg->{_config_file_format};
	my $format_real   = $var_immodpg->{_config_file_format_real};
	my $format_signed_integer =
	  $var_immodpg->{_config_file_format_signed_integer};

=head2 correct errors

=cut

  #print("immodpg, _write_config,base_file_name:$immodpg->{_base_file_name}\n");

=pod
declare private variables

=cut

	my $file     = 'immodpg.config';
	my $outbound = $variables->{_CONFIG} . '/' . $file;

	open( OUT, ">$outbound" );

	printf OUT $format_string . "\n", "base_file_name ", "= ",
	  $immodpg->{_base_file_name};
	printf OUT $format_string . "\n", "pre_digitized_XT_pairs ", "= ",
	  $immodpg->{_pre_digitized_XT_pairs};
	printf OUT $format_string . "\n", "data_traces ", "= ",
	  $immodpg->{_data_traces};
	printf OUT $format_clip . "\n", "clip ", "= ",
	  $immodpg->{_clip4plot_current};
	printf OUT $format_real . "\n", "min_t_s ", "= ", $immodpg->{_min_t_s};
	printf OUT $format_real . "\n", "min_x_m ", "= ", $immodpg->{_min_x_m};
	printf OUT $format_real . "\n", "data_x_inc_m ", "= ",
	  $immodpg->{_data_x_inc_m};
	printf OUT $format_real . "\n", "source_depth_m ", "= ",
	  $immodpg->{_source_depth_m};
	printf OUT $format_real . "\n", "receiver_depth_m ", "= ",
	  $immodpg->{_receiver_depth_m};
	printf OUT $format_real . "\n", "reducing_vel_mps ", "= ",
	  $immodpg->{_reducing_vel_mps};
	printf OUT $format_real . "\n", "plot_min_x_m ", "= ",
	  $immodpg->{_plot_min_x_m};
	printf OUT $format_real . "\n", "plot_max_x_m ", "= ",
	  $immodpg->{_plot_max_x_m};
	printf OUT $format_real . "\n", "plot_min_t_s ", "= ",
	  $immodpg->{_plot_min_t_s};
	printf OUT $format_real . "\n", "plot_max_t_s ", "= ",
	  $immodpg->{_plot_max_t_s};
	printf OUT $format_string . "\n", "previous_model ", "= ",
	  $immodpg->{_previous_model};
	printf OUT $format_string . "\n", "new_model ", "= ",
	  $immodpg->{_new_model};
	printf OUT $format_signed_integer . "\n", "starting_layer ", "= ",
	  $immodpg->{_layer_current};
	printf OUT $format_real . "\n", "VbotNtop_factor ", "= ",
	  $immodpg->{_VbotNtop_factor_current};
	printf OUT $format_real . "\n", "Vincrement_mps", "= ",
	  $immodpg->{_Vincrement_current};
	printf OUT $format_real . "\n", "thickness_increment_m ", "= ",
	  $immodpg->{_thickness_increment_m_current};

	close(OUT);

}

=head2 sub _set_simple_model_text

write out the model in ASCII
format

=cut

sub _set_simple_model_text {

	my ($self) = @_;

=pod import private variables

=cut	

	my $variables        = $immodpg_spec->variables();
	my $format_title     = $var_immodpg->{_model_text_file_format_title};
	my $format_values    = $var_immodpg->{_model_text_file_format_values};
	my $simple_model_txt = $var_immodpg->{_simple_model_txt};
	my $number_of_layers = _get_number_of_layers();

	#    print("$simple_model_txt \n");

	if (   length($variables)
		&& length($format_title)
		&& length($format_values)
		&& length($simple_model_txt)
		&& length($number_of_layers) )
	{

=pod
declare private variables

=cut

		my ( @Vtop, @Vbot, @dz );
		my $file     = $simple_model_txt;
		my $outbound = $variables->{_CONFIG} . '/' . $file;

		my ( $Vtop_ref, $Vbot_ref, $dz_ref ) = _getVp_ref_dz_ref();
		@Vtop = @$Vtop_ref;
		@Vbot = @$Vbot_ref;
		@dz   = @$dz_ref;

		# print("immodpg,_getVp_ref_dz_ref; VPtop,VPbot,dz= @Vtop,@Vbot,@dz\n");

		open( OUT, ">$outbound" );
		printf OUT $format_title . "\n",
		  "    VPtop    VPbottom    thickness(m)";

		for ( my $i = 0 ; $i < $number_of_layers ; $i++ ) {
			print OUT ("     $Vtop[$i] \t$Vbot[$i]\t\t$dz[$i]\n");
		}

		close(OUT);

		#		print("immodpg,_write_simple_model_txt\n");

	}
	else {
		print("immodpg,_write_simple_model_txt, no output\n");
		print("variables             = $immodpg_spec->variables()\n");
		print(
"format_title         = $var_immodpg->{_model_text_file_format_title}\n"
		);
		print(
"format_values           = $var_immodpg->{_model_text_file_format_values}\n"
		);
		print("simple_model_txt     = $var_immodpg->{_simple_model_txt}\n");
		print("number_of_layers     = _get_number_of_layers()\n");
	}
}

=head2 sub get_initialVp_dz4gui

=cut

sub get_initialVp_dz4gui {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_model_layer_number} ) ) {

		my ( $_thickness_m_upper_layer, $Vbot_lower_layer );
		my ( @V,                        @result );

		my $layer = $immodpg->{_model_layer_number};

		my ( $refVPtop, $refVPbot, $ref_dz, $error_switch ) =
		  _get_initial_model();

		if (    length($refVPtop)
			and length($refVPbot)
			and length($ref_dz)
			and length($error_switch) )
		{

			my @VPtop = @$refVPtop;
			my @VPbot = @$refVPbot;
			my @dz    = @$ref_dz;

			#			print("immodpg,get_initialVp_dz4gui VPtop= @VPtop\n");
			#			print("immodpg,get_initialVp_dz4gui VPbot= @VPbot\n");
			#			print("immodpg,get_initialVp_dz4gui dz= @dz\n");
			#			print("immodpg,get_initialVp_dz4gui layer_number = $layer \n");

			my $layer_index             = $layer - 1;
			my $layer_index_upper_layer = $layer - 2;
			my $layer_index_lower_layer = $layer;

			# For all cases
			my $Vtop = $VPtop[$layer_index];
			my $Vbot = $VPbot[$layer_index];
			my $dz   = $dz[$layer_index];

			if ( $layer >= 2 ) {

				#	 CASE of second of two or more layers
				my $Vbot_upper_layer = $VPbot[$layer_index_upper_layer];
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;

			#				print("immodpg, get_initialVp_dz4gui: velocities are:  @V \n");
				return ( \@result, $dz, $error_switch );

			}
			elsif ( $layer >= 1 ) {

				# CASE of first of one or more layers
				my $Vbot_upper_layer = $empty_string;
				my $Vtop_lower_layer = $VPtop[$layer_index_lower_layer];

				$V[0] = $Vbot_upper_layer;
				$V[1] = $Vtop;
				$V[2] = $Vbot;
				$V[3] = $Vtop_lower_layer;

				@result = @V;
				return ( \@result, $dz, $error_switch );

			}
			else {
				print(
					"immodpg, get_initialVp_dz4gui, unexpected layer number \n"
				);
				return ();
			}

		}
		else {
			print(
"immodpg,get_initialVp_dz4gui, _get_initial_model gives bad values \n"
			);
			return ();
		}

	}
	else {
		print("immodpg,get_initialVp_dz4gui,missing layer\\n");
		return ();
	}
	return ();
}

=head2 set_defaults
1. Get starting configuration 
parameters from configuration file
directly and independently of main

=cut

sub set_defaults {

	my ($self) = @_;

	my ( $CFG_h, $CFG_aref ) = $immodpg_config->get_values();

	$immodpg->{_base_file_name} = $CFG_h->{immodpg}{1}{base_file_name};
	$immodpg->{_pre_digitized_XT_pairs} =
	  $CFG_h->{immodpg}{1}{pre_digitized_XT_pairs};
	$immodpg->{_data_traces}      = $CFG_h->{immodpg}{1}{data_traces};
	$immodpg->{_clip}             = $CFG_h->{immodpg}{1}{clip};
	$immodpg->{_min_t_s}          = $CFG_h->{immodpg}{1}{min_t_s};
	$immodpg->{_min_x_m}          = $CFG_h->{immodpg}{1}{min_x_m};
	$immodpg->{_data_x_inc_m}     = $CFG_h->{immodpg}{1}{data_x_inc_m};
	$immodpg->{_source_depth_m}   = $CFG_h->{immodpg}{1}{source_depth_m};
	$immodpg->{_receiver_depth_m} = $CFG_h->{immodpg}{1}{receiver_depth_m};
	$immodpg->{_reducing_vel_mps} = $CFG_h->{immodpg}{1}{reducing_vel_mps};
	$immodpg->{_plot_min_x_m}     = $CFG_h->{immodpg}{1}{plot_min_x_m};
	$immodpg->{_plot_max_x_m}     = $CFG_h->{immodpg}{1}{plot_max_x_m};
	$immodpg->{_plot_min_t_s}     = $CFG_h->{immodpg}{1}{plot_min_t_s};
	$immodpg->{_plot_max_t_s}     = $CFG_h->{immodpg}{1}{plot_max_t_s};
	$immodpg->{_previous_model}   = $CFG_h->{immodpg}{1}{previous_model};
	$immodpg->{_new_model}        = $CFG_h->{immodpg}{1}{new_model};
	$immodpg->{_layer}            = $CFG_h->{immodpg}{1}{layer};
	$immodpg->{_VbotNtop_factor}  = $CFG_h->{immodpg}{1}{VbotNtop_factor};
	$immodpg->{_Vincrement}       = $CFG_h->{immodpg}{1}{Vincrement_mps};
	$immodpg->{_thickness_increment_m} =
	  $CFG_h->{immodpg}{1}{thickness_increment_m};

	#    print("immodpg,set_defaults,data_x_inc_m=$immodpg->{_data_x_inc_m}\n");

=head2 Error control
 - clip ( ne 0)
 - layer number can be no smaller than 1
 or greater than max-1
 
 clip >=0
 
=cut

	_set_clip_control( $immodpg->{_clip} );
	$immodpg->{_clip} = _get_control_clip();

	_set_layer_control( $immodpg->{_layer} );
	$immodpg->{_layer} = _get_control_layer();

	_set_model_layer( $immodpg->{_layer} );
	my ( $Vp_ref, $dz ) = _get_initialVp_dz4gui();
	my @V = @$Vp_ref;
	$immodpg->{_thickness_m} = $dz;

	my $Vbot_upper_layer = $V[0];
	my $Vtop             = $V[1];
	my $Vbot             = $V[2];
	my $Vtop_lower_layer = $V[3];

	$immodpg->{_Vbot}             = $Vbot;
	$immodpg->{_Vbot_upper_layer} = $Vbot_upper_layer;
	$immodpg->{_Vtop}             = $Vtop;
	$immodpg->{_Vtop_lower_layer} = $Vtop_lower_layer;

	# default values for Vbot-related variables
	$immodpg->{_Vbot_default} = $immodpg->{_Vbot};
	$immodpg->{_Vbot_current} = $immodpg->{_Vbot_default};
	$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_default};
	$immodpg->{_inVbot}       = $no;
	$immodpg->{_outsideVbot}  = $yes;

	# default values for Vbot_upper_layer-related variables
	$immodpg->{_Vbot_upper_layer_default} = $immodpg->{_Vbot_upper_layer};
	$immodpg->{_Vbot_upper_layer_current} =
	  $immodpg->{_Vbot_upper_layer_default};
	$immodpg->{_Vbot_upper_layer_prior} = $immodpg->{_Vbot_upper_layer_default};
	$immodpg->{_inVbot_upper_layer}     = $no;
	$immodpg->{_outsideVbot_upper_layer} = $yes;

	# default values for Vincrement-related variables
	$immodpg->{_Vincrement_default} = $immodpg->{_Vincrement};
	$immodpg->{_Vincrement_current} = $immodpg->{_Vincrement_default};
	$immodpg->{_Vincrement_prior}   = $immodpg->{_Vincrement_default};
	$immodpg->{_inVincrement}       = $no;
	$immodpg->{_outsideVincrement}  = $yes;

	# default values for Vtop-related variables
	$immodpg->{_Vtop_default} = $immodpg->{_Vtop};
	$immodpg->{_Vtop_current} = $immodpg->{_Vtop_default};
	$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_default};
	$immodpg->{_inVtop}       = $no;
	$immodpg->{_outsideVtop}  = $yes;

	# default values for Vtop_lower_layer-related variables
	$immodpg->{_Vtop_lower_layer_default} = $immodpg->{_Vtop_lower_layer};
	$immodpg->{_Vtop_lower_layer_current} =
	  $immodpg->{_Vtop_lower_layer_default};
	$immodpg->{_Vtop_lower_layer_prior} = $immodpg->{_Vtop_lower_layer_default};
	$immodpg->{_inVtop_lower_layer}     = $no;
	$immodpg->{_outsideVtop_lower_layer} = $yes;

	# default values for VbotNtop_factor-related variables
	$immodpg->{_VbotNtop_factor_default} = $immodpg->{_VbotNtop_factor};
	$immodpg->{_VbotNtop_factor_current} = $immodpg->{_VbotNtop_factor_default};
	$immodpg->{_VbotNtop_factor_prior}   = $immodpg->{_VbotNtop_factor_default};
	$immodpg->{_inVbotNtop_factor}       = $no;
	$immodpg->{_outsideVbotNtop_factor}  = $yes;

	# default values for clip-related variables
	$immodpg->{_clip4plot_default} = $immodpg->{_clip};
	$immodpg->{_clip4plot_current} = $immodpg->{_clip4plot_default};
	$immodpg->{_clip4plot_prior}   = $immodpg->{_clip4plot_default};
	$immodpg->{_clip4plot}         = $immodpg->{_clip4plot_default};
	$immodpg->{_in_clip}           = $no;
	$immodpg->{_outside_clip}      = $yes;

	# default values for layer-related variables
	$immodpg->{_layer_default} = $immodpg->{_layer};
	$immodpg->{_layer_current} = $immodpg->{_layer_default};
	$immodpg->{_layer_prior}   = $immodpg->{_layer_default};
	$immodpg->{_in_layer}      = $no;
	$immodpg->{_outside_layer} = $yes;

	# default values for thickness_m-related variables
	$immodpg->{_thickness_m_default} = $immodpg->{_thickness_m};
	$immodpg->{_thickness_m_current} = $immodpg->{_thickness_m_default};
	$immodpg->{_thickness_m_prior}   = $immodpg->{_thickness_m_default};
	$immodpg->{_in_thickness_m}      = $no;
	$immodpg->{_outside_thickness_m} = $yes;

	# default values for thickness_increment_m-related variables
	$immodpg->{_thickness_increment_m_default} =
	  $immodpg->{_thickness_increment_m};
	$immodpg->{_thickness_increment_m_current} =
	  $immodpg->{_thickness_increment_m_default};
	$immodpg->{_thickness_increment_m_prior} =
	  $immodpg->{_thickness_increment_m_default};
	$immodpg->{_in_thickness_increment_m}      = $no;
	$immodpg->{_outside_thickness_increment_m} = $yes;

}

=head2 sub setVbot_minus

update Vbot value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVbot_minus {

	my ($self) = @_;

	if ( length( $immodpg->{_VbotEntry} )
		and looks_like_number( $immodpg->{_Vincrement_current} ) )
	{

		my $Vbot = ( $immodpg->{_VbotEntry} )->get();

		if ( looks_like_number($Vbot) ) {

			my $Vincrement = ( $immodpg->{_VincrementEntry} )->get();
			my $newVbot    = $Vbot - $Vincrement;
			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			#				$immodpg->{_isVbot_changed_in_gui} = $yes;
			#				_checkVbot(); # todo
			_updateVbot();

			if ( $immodpg->{_isVbot_changed_in_gui} eq $yes ) {

				# for fortran program to read
				_set_option($Vbot_minus_opt);
				_set_change($yes);

		   #					print("immodpg, setVbot_minus, Vbot is changed: $yes \n");
		   #					print("immodpg, setVbot_minus,option:$Vbot_minus_opt\n");
		   #					print("immodpg, setVbot_minus, V=$immodpg->{_Vbot_current}\n");

			}
			else {

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				# print("immodpg, setVbot_minus, same Vbot NADA\n");
			}

		}
		else {
			print("immodpg, setVbot_minus, Vbot value missing\n");
		}

	}
	else {
		print("immodpg, setVbot_minus, missing widget or Vincrement\n");

#		print("immodpg, setVbot_minus, VbotEntry=$immodpg->{_VbotEntry}\n");
#		print("immodpg, setVbot_minus, Vincrement=$immodpg->{_Vincrement_current}\n");
	}
	return ();
}

=head2 sub setVbot_plus

update Vbot value in gui
update private value in this module
output option for immodpg.for

=cut

sub setVbot_plus {

	my ($self) = @_;

	if ( length( $immodpg->{_VbotEntry} )
		&& looks_like_number( $immodpg->{_Vincrement_current} ) )
	{

		my $Vbot = ( $immodpg->{_VbotEntry} )->get();

		if ( looks_like_number($Vbot) ) {

			my $Vincrement = ( $immodpg->{_VincrementEntry} )->get();
			my $newVbot    = $Vbot + $Vincrement;

			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			#				$immodpg->{_isVbot_changed_in_gui} = $yes;
			#				_checkVbot(); #todo
			_updateVbot();

			#			print("immodpg, setVbot_plus, new Vbot= $newVbot\n");

			# print("immodpg, setVbot_plus, Vincrement= $Vincrement\n");

			if ( $immodpg->{_isVbot_changed_in_gui} eq $yes ) {

				# for fortran program to read
				_set_option($Vbot_plus_opt);
				_set_change($yes);

		  #					print("immodpg, setVbot_plus, Vbot_plus_opt:$Vbot_plus_opt \n");

			}
			else {

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				#				print("immodpg, setVbot_plus, same Vbot NADA\n");
			}

		}
		else {
			print("immodpg, setVbot_plus, Vbot value missing\n");
		}

	}
	else {
		print("immodpg, setVbot_plus, missing widget or Vincrement\n");

		#		print("immodpg, setVbot_plus, VbotEntry=$immodpg->{_VbotEntry}\n");
		#		print("immodpg, setVbot_plus, Vincrement=$immodpg->{_Vincrement}\n");
	}
	return ();
}

=head2 sub setVtop_minus

update Vtop value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVtop_minus {

	my ($self) = @_;

	if ( length( $immodpg->{_VtopEntry} )
		&& looks_like_number( $immodpg->{_Vincrement_current} ) )
	{

		my $Vtop = ( $immodpg->{_VtopEntry} )->get();

		if ( looks_like_number($Vtop) ) {

			my $Vincrement = ( $immodpg->{_VincrementEntry} )->get();
			my $newVtop    = $Vtop - $Vincrement;

			_set_control( 'Vtop', $newVtop );
			$newVtop = _get_control('Vtop');

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			#				$immodpg->{_isVtop_changed_in_gui} = $yes;
			#				_checkVtop(); #todo
			_updateVtop();

			if ( $immodpg->{_isVtop_changed_in_gui} eq $yes ) {

				# for fortran program to read
				_set_option($Vtop_minus_opt);
				_set_change($yes);

			#				print("immodpg, setVtop_minus,option:$Vtop_minus_opt\n");
			#				print("immodpg, setVtop_minus, V=$immodpg->{_Vtop_current}\n");

			}
			else {

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				print("immodpg, setVtop_minus, same Vtop NADA\n");
			}

		}
		else {
			print("immodpg, setVtop_minus, Vtop value missing\n");
		}

	}
	else {
		print("immodpg, setVtop_minus, missing widget or Vincrement\n");
		print("immodpg, setVtop_minus, VtopEntry=$immodpg->{_VtopEntry}\n");
		print(
"immodpg, setVtop_minus, Vincrement=$immodpg->{_Vincrement_current}\n"
		);
	}
	return ();
}

=head2 sub setVtop_plus

update Vtop value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVtop_plus {

	my ($self) = @_;

	#   print("0. immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
	if (   length( $immodpg->{_VtopEntry} )
		&& length( $immodpg->{_VincrementEntry} ) )
	{

	   #		print("1. immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
		my $Vtop = ( $immodpg->{_VtopEntry} )->get();

		if ( looks_like_number($Vtop) ) {

			my $Vincrement = ( $immodpg->{_VincrementEntry} )->get();
			my $newVtop    = $Vtop + $Vincrement;

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			_set_control( 'Vtop', $immodpg->{_Vtop_current} );
			$immodpg->{_Vtop_current} = _get_control('Vtop');
			$newVtop = $immodpg->{_Vtop_current};

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			#				$immodpg->{_isVtop_changed_in_gui} = $yes;
			#				_checkVtop(); #todo
			_updateVtop();

#				print("immodpg, setVtop_plus, $immodpg->{_Vtop_current}= $immodpg->{_Vtop_current}\n");
#			print("immodpg, setVtop_plus, Vincrement= $Vincrement\n");
#			print("2. immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
			if ( $immodpg->{_isVtop_changed_in_gui} eq $yes ) {

				# for fortran program to read
				_set_option($Vtop_plus_opt);
				_set_change($yes);

			#					print("immodpg, setVtop_plus,option:$Vtop_plus_opt\n");
			#					print("immodpg, setVtop_plus, V=$immodpg->{_Vtop_current}\n");

			}
			else {

#				print("immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
#				print("immodpg, setVtop_plus, Vincrement=$immodpg->{_Vincrement_current}\n");

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				#				print("immodpg, setVtop_plus, same Vtop NADA\n");
			}

		}
		else {
			print("immodpg, setVtop_plus, Vtop value missing\n");

#			print("immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
#			print("immodpg, setVtop_plus, Vincrement=$immodpg->{_Vincrement_current}\n");
		}

	}
	else {
		print("immodpg, setVtop_plus, missing widget or Vincrement\n");
		print("immodpg, setVtop_plus, VtopEntry=$immodpg->{_VtopEntry}\n");
		print(
"immodpg, setVtop_plus, Vincrement=$immodpg->{_Vincrement_current}\n"
		);
	}
	return ();
}

=head2 sub cdp 


=cut

sub cdp {

	my ( $self, $cdp ) = @_;
	if ($cdp) {

		$immodpg->{_cdp}  = $cdp;
		$immodpg->{_note} = $immodpg->{_note} . ' cdp=' . $immodpg->{_cdp};
		$immodpg->{_Step} = $immodpg->{_Step} . ' cdp=' . $immodpg->{_cdp};

	}
	else {
		print("immodpg, cdp, missing cdp,\n");
	}
}

=head2 sub clean_trash
delete remaining locked files
reset default files as well

=cut

sub clean_trash {
	my ($self) = @_;
	use File::stat;

	my $xk    = xk->new();
	my $files = manage_files_by2->new();
	my ( $outbound_locked, $outbound );

	my @X;
	my $Vbot_file                  = $immodpg->{_Vbot_file};
	my $VbotNtop_factor_file       = $immodpg->{_VbotNtop_factor_file};
	my $Vbot_upper_layer_file      = $immodpg->{_Vbot_upper_layer_file};
	my $Vincrement_file            = $immodpg->{_Vincrement_file};
	my $Vtop_file                  = $immodpg->{_Vtop_file};
	my $Vtop_lower_layer_file      = $immodpg->{_Vtop_lower_layer_file};
	my $change_file                = $immodpg->{_change_file};
	my $clip_file                  = $immodpg->{_clip_file};
	my $immodpg_model              = $immodpg->{_immodpg_model};
	my $layer_file                 = $immodpg->{_layer_file};
	my $option_file                = $immodpg->{_option_file};
	my $thickness_m_file           = $immodpg->{_thickness_m_file};
	my $thickness_increment_m_file = $immodpg->{_thickness_increment_m_file};

	# kill previous processes
	$xk->set_process('immodpg1.1');
	$xk->kill_process();

	$xk->set_process('pgxwin_server');

	# print("immodpg,exit: kill pgxwin_server\n");
	$xk->kill_process();

	# deleted lock files
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $Vbot_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked =
	  $IMMODPG_INVISIBLE . '/' . $VbotNtop_factor_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked =
	  $IMMODPG_INVISIBLE . '/' . $Vbot_upper_layer_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $Vincrement_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $Vtop_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked =
	  $IMMODPG_INVISIBLE . '/' . $Vtop_lower_layer_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $change_file . '_locked';

	#	print("immodpg, clean_trash, delete $outbound_locked\n");
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $clip_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG . '/' . $immodpg_model . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $layer_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $option_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked = $IMMODPG_INVISIBLE . '/' . $thickness_m_file . '_locked';
	unlink($outbound_locked);
	$outbound_locked =
	  $IMMODPG_INVISIBLE . '/' . $thickness_increment_m_file . '_locked';
	unlink($outbound_locked);

	# reset files to their default options
	$outbound = $IMMODPG_INVISIBLE . '/' . $change_file;
	unlink($outbound);
	my $format = $var_immodpg->{_format_string};
	$X[0] = $immodpg->{_change_default};
	$files->write_1col_aref( \@X, \$outbound, \$format );

	_fortran_layer( $immodpg->{_layer_default} );
	_set_option( $immodpg->{_option_default} );
	_set_change( $immodpg->{_change_default} );

	# delete empty files (including surviving lock files)
	# remove weird, locked files from the current directory
	my $CD = `pwd`;
	$files->set_directory($CD);
	$files->clear_empty_files();

	# remove weird lock files from the main directory
	$files->set_directory($IMMODPG);
	$files->clear_empty_files();

	# remove weird lock files from the IMMODPG_INVISIBLE
	$files->set_directory($IMMODPG_INVISIBLE);
	$files->clear_empty_files();

	return ();
}

=head2 sub clear

=cut

sub clear {
	$immodpg->{_base_file_name} = '';
	$immodpg->{_cdp}            = '';
	$immodpg->{_invert}         = '';
	$immodpg->{_lmute}          = '';
	$immodpg->{_smute}          = '';
	$immodpg->{_sscale}         = '';
	$immodpg->{_scaled_par}     = '';
	$immodpg->{_tnmo}           = '';
	$immodpg->{_upward}         = '';
	$immodpg->{_vnmo}           = '';
	$immodpg->{_voutfile}       = '';
	$immodpg->{_Step}           = '';
	$immodpg->{_note}           = '';
}

=head2 subroutine exit

=cut

sub exit {

	my $xk = xk->new();

	$xk->set_process('pgxwin_server');

	# print("immodpg,exit: kill pgxwin_server\n");
	$xk->kill_process();

	$xk->set_process('immodpg1.1');

	#	print("immodpg,exit: kill immodpg1.1\n");
	$xk->kill_process();

	$xk->set_process('immodpg');
	$xk->kill_process();

	#	print("immodpg,exit: Goodbye!\n");

	return ();

}

=head2 sub get_control_clip
adjust clip value

=cut

sub get_control_clip {

	my ($self) = @_;

	my $result;

	if ( length( $immodpg->{_control_clip} ) ) {

#		print("1. immodpg, get_control_clip, old control_clip= $immodpg->{_control_clip}\n");
		my $control_clip = $immodpg->{_control_clip};

		if ( $control_clip <= 0 ) {

			# case 1 layer number exceeds possible value
			$control_clip = 1;
			$result       = $control_clip;

		}
		else {

			#			print("immodpg, get_control_clip, NADA\n");
			$result = $control_clip;
		}

	#		print("2. immodpg, get_control_clip, new control_clip= $control_clip\n");
		return ($result);

	}
	else {
		print("immodpg, get_control_clip,  missing clip value\n");
	}
	return ();
}

=head2 sub  get_control_layer
Layer value is adjustable
Working layer
number must be
>= 1

=cut

sub get_control_layer {

	my ($self) = @_;

	my $result;

#	print("1. immodpg, get_control_layer, control_layer_external= $immodpg->{_control_layer_external}\n");

	if ( length( $immodpg->{_control_layer_external} ) ) {

# CASE 1
#		print("CASE 1: immodpg, get_control_layer, control_layer_external= $immodpg->{_control_layer_external}\n");

		my $layer_current    = $immodpg->{_control_layer_external};
		my $number_of_layers = _get_number_of_layers();

#		print("2. immodpg, get_control_layer, number_of_layers= $number_of_layers\n");

		if ( $layer_current > $number_of_layers ) {

	  # case 1A layer number exceeds possible value
	  #			print("case1A: immodpg, get_control_layer, layer number too large\n");
	  #			print("immodpg, get_control_layer, layer_number=$layer_current}\n");
			$layer_current = $number_of_layers - 1;

	  # print("immodpg, get_control_layer, new layer_number=$layer_current}\n");
			$result = $layer_current;

		}
		elsif ( $layer_current < 1 ) {

			$layer_current = 1;
			$result        = $layer_current;

#			print("CASE 1B immodpg, get_control_layer, layer_number=$layer_current}\n");

		}
		elsif ( $layer_current == 1 ) {

			$layer_current = 1;
			$result        = $layer_current;

	   #			print("CASE 1 C immodpg, get_control_layer, layer=$layer_current\n");

		}
		elsif ( ( $layer_current < $number_of_layers ) ) {

			$result = $layer_current;

	   #			print("CASE 1 D immodpg, get_control_layer, layer=$layer_current\n");

			# NADA

		}
		elsif ( ( $layer_current == $number_of_layers ) ) {

			$result = $layer_current - 1;

	   #			print("iCASE 1 E mmodpg, get_control_layer, layer=$layer_current\n");
	   # NADA

		}
		else {
			print("immodpg, get_control_layer, unexpected layer number\n");
			$result = $empty_string;
		}

	}
	elsif ( length( $immodpg->{_control_layer_external} ) == 0 ) {

		$result = 1;

#		print("CASE 2immodpg, get_control_layer, empty string layer updated to $result\n");

	}
	else {
		print("immodpg, get_control_layer, unexpected value\n");
	}

	return ($result);
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 14;

	return ($max_index);
}

=head2 sub initialize_messages
Create widgets that show messages
Show warnings or errors in a message box
Message box is defined in main where it is
also made invisible (withdraw)
Here we turn on the message box (deiconify, raise)
The message does not release the program
until OK is clicked and wait variable changes from yes 
to no.

=cut

sub initialize_messages {

	my ($self) = @_;

	my $arial_14_b = ( $immodpg->{_mw} )->fontCreate(
		'arial_14_b',
		-family => 'arial',
		-weight => 'bold',
		-size   => -14
	);

=head2 message box
withdraw temporarily while filling
with widgets

=cut 

	$immodpg->{_message_box_w} =
	  $immodpg->{_mw}->Toplevel( -background => $var_L_SU->{_my_yellow}, );
	$immodpg->{_message_box_w}->withdraw;

	$immodpg->{_message_box_w}->geometry( $var_L_SU->{_message_box_geometry} );

	$immodpg->{_message_upper_frame} = $immodpg->{_message_box_w}->Frame(
		-borderwidth => $var_L_SU->{_no_borderwidth},
		-background  => $var_L_SU->{_my_yellow},
	);
	$immodpg->{_message_lower_frame} = $immodpg->{_message_box_w}->Frame(
		-borderwidth => $var_L_SU->{_no_borderwidth},
		-background  => $var_L_SU->{_my_yellow},
		-height      => '10',
	);
	$immodpg->{_message_label_w} = $immodpg->{_message_upper_frame}->Label(
		-background => $var_L_SU->{_my_yellow},
		-font       => $arial_14_b,
		-justify    => 'left',
	);

	$immodpg->{_message_box_wait}  = $var_L_SU->{_yes};
	$immodpg->{_message_ok_button} = $immodpg->{_message_box_w}->Button(
		-text    => "ok",
		-font    => $arial_14_b,
		-command => sub {
			$immodpg->{_message_box_w}->grabRelease;
			$immodpg->{_message_box_w}->withdraw;
		},
	);

=head2 Pack message box
This Toplevel window has 
geometry that is independent
of the main window widget.
Upper frame contains message.
Lower frame contains ok button.

=cut

	$immodpg->{_message_upper_frame}->pack();
	$immodpg->{_message_label_w}->pack( -side => 'top', );
	$immodpg->{_message_lower_frame}->pack( -side => 'top', );

	$immodpg->{_message_ok_button}->pack(
		-side   => "top",
		-fill   => 'none',
		-expand => 0,
	);

	return ();
}

=head2 sub initialize_model

Load into namespace the immodpg model to 
establish the first set of layers
their velocities and thickness

=cut

sub initialize_model {
	my ($self) = @_;

	my ( $refVPtop, $refVPbot, $ref_dz, $error_switch ) = _get_initial_model();

	if (   length($refVPtop)
		&& length($refVPbot)
		&& length($ref_dz)
		&& length($error_switch) )
	{

		_set_initialVp_dz( $refVPtop, $refVPbot, $ref_dz, $error_switch );

	}
	else {
		print(" immodpg, L5046, missing or corrupt variables \n");
	}

	return ();

}

=head2 sub get_number_of_layers

determine number of layers
from model.text file

=cut

sub get_number_of_layers {

	my ($self) = @_;
	my $number_of_layers;

	if ( length( $immodpg->{_model_file_text} ) ) {

		my $count        = 0;
		my $magic_number = 4;
		my $inbound_model_file_text =
		  $IMMODPG_INVISIBLE . '/' . $immodpg->{_model_file_text};

#		print ("immodpg,_get_number_of_layers,inbound_model_file_text=$inbound_model_file_text\n");

		open( my $fh, '<', $inbound_model_file_text );

		while (<$fh>) {

			$count++;

		}
		close($fh);

		$number_of_layers = $count - $magic_number;

	   #		print("immodpg,_get_number_of_layers, layers = $number_of_layers \n");

	}
	else {

		# print("immodpg,_get_number_of_layers, missing values\n");
		$number_of_layers = 0;
	}

	my $result = $number_of_layers;
	return ($result);
}

=head2 sub get_replacement4missing


=cut

sub get_replacement4missing {

	my ($self) = @_;

	if (    length( $immodpg->{_replacement4missing} )
		and length( $immodpg->{_inbound_missing} ) )
	{

		my $inbound     = $immodpg->{_inbound_missing};
		my $replacement = $immodpg->{_replacement4missing};

		if ( not( -e $inbound ) ) {

			#				print("immodpg,get_replacement4missing ,file is missing\n");
			use File::Copy;
			my $from = $replacement;
			my $to   = $inbound;
			copy( $from, $to );

		}
		elsif ( -e $inbound ) {

			#				print("immodpg,get_replacement4missing,OK-NADA \n");

		}
		else {
			print("immodpg,get_replacement4missing,unexpected value\n");
		}

	}
	else {
		print("immodpg, get_replacement4missing, missing replacement\n");
	}

	return ();
}

=head2 sub setVbot

When you enter or leave
check what the current Vbot value is
compared to former Vbot values.

Vtop value is updated for immodpg.for 
through a message in file= "Vbot"

=cut

sub setVbot {

	my ($self) = @_;

	if ( length( $immodpg->{_VbotEntry} ) ) {

		$immodpg->{_Vbot_current} = ( $immodpg->{_VbotEntry} )->get();

		_set_control( 'Vbot', $immodpg->{_Vbot_current} );
		$immodpg->{_Vbot_current} = _get_control('Vbot');
		my $newVbot = $immodpg->{_Vbot_current};

		$immodpg->{_VbotEntry}->delete( 0, 'end' );
		$immodpg->{_VbotEntry}->insert( 0, $newVbot );

		_checkVbot();
		_updateVbot();

		if ( length( $immodpg->{_isVbot_changed_in_gui} )
			&& $immodpg->{_isVbot_changed_in_gui} eq $yes )
		{

			# for fortran program to read
			#				print("immodpg, set_Vbot, Vbot is changed: $yes \n");
			#				print("immodpg, setVbot,option:$Vbot_opt\n");
			#				print("immodpg, setVbot, V=$immodpg->{_Vbot_current}\n");

			_setVbot( $immodpg->{_Vbot_current} );
			_set_option($Vbot_opt);
			_set_change($yes);

		}
		else {

			#			negative cases are reset by fortran program
			#			and so eliminate need to read locked files
			#			while use of locked files helps most of the time
			#			creation and deletion of locked files in perl are not
			#			failsafe

			#  print("immodpg, setVbot, same Vbot NADA\n");
		}

	}
	else {

	}
}

=head2 sub setVbot_upper_layer

When you enter or leave
check what the current Vbot_upper_layer value is
compared to former Vbot_upper_layer values
Vtop value is updated in immodpg.for 
through a message in file= "Vbot_lower"
(&_setVbot_upper_layer)

=cut

sub setVbot_upper_layer {

	my ($self) = @_;

	# for convenience
	my $layer_current = $immodpg->{_layer_current};
	my $newVbot_upper_layer;

	if ( length( $immodpg->{_Vbot_upper_layerEntry} ) ) {

		$immodpg->{_Vbot_upper_layer_current} =
		  ( $immodpg->{_Vbot_upper_layerEntry} )->get();
		my $Vbot_upper_layer_current = $immodpg->{_Vbot_upper_layer_current};

# print("1. immodpg, setVbot_upper_layer, immodpg->{_Vbot_upper_layer_current}=$Vbot_upper_layer_current\n");
		if (    length $Vbot_upper_layer_current
			and looks_like_number($Vbot_upper_layer_current)
			and $layer_current > 0 )
		{

# print("immodpg, setVbot_upper_layer, immodpg->{_Vbot_upper_layer_current}=$immodpg->{_Vbot_upper_layer_current}\n");

			_set_control( 'Vbot_upper_layer',
				$immodpg->{_Vbot_upper_layer_current} );
			$immodpg->{_Vbot_upper_layer_current} =
			  _get_control('Vbot_upper_layer');
			$newVbot_upper_layer = $immodpg->{_Vbot_upper_layer_current};

# print("2. immodpg, setVbot_upper_layer, newVbot_upper_layer=$newVbot_upper_layer\n");

			$immodpg->{_Vbot_upper_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vbot_upper_layerEntry}
			  ->insert( 0, $newVbot_upper_layer );

			_checkVbot_upper_layer();
			_updateVbot_upper_layer();

			if ( $immodpg->{_isVbot_upper_layer_changed_in_gui} eq $yes ) {

				# for fortran program to read

				_setVbot_upper_layer( $immodpg->{_Vbot_upper_layer_current} );
				_set_option($Vbot_upper_layer_opt);
				_set_change($yes);

#				print("immodpg, setVbot_upper_layer,option:$Vbot_upper_layer_opt\n");
#				print("immodpg, setVbot_upper_layer,V= $immodpg->{_Vbot_upper_layer_current}\n");

			}
			else {

				#			negative cases are reset by fortran program
				#			and so eliminate need to read locked files
				#			while use of locked files helps most of the time
				#			creation and deletion of locked files in perl are not
				#			failsafe

				# print("immodpg, setVbot_upper_layer, same Vbot NADA\n");
			}

		}
		else {

 # print("immodpg, setVbot_upper_layer, Velocity is empty in non-layer NADA\n");
		}

	}
	else {

	}
}

=head2 setVbotNVtop_lower_layer_minus
update Vbot value in gui
update Vtop_lower_layer value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVbotNVtop_lower_layer_minus {

	my ($self) = @_;

	if (   looks_like_number( $immodpg->{_Vincrement_current} )
		&& length( $immodpg->{_Vtop_lower_layerEntry} )
		&& length( $immodpg->{_VbotEntry} ) )
	{

		my $Vbot             = ( $immodpg->{_VbotEntry} )->get();
		my $Vtop_lower_layer = ( $immodpg->{_Vtop_lower_layerEntry} )->get();
		my $Vincrement       = ( $immodpg->{_VincrementEntry} )->get();

		if (   looks_like_number($Vtop_lower_layer)
			&& looks_like_number($Vbot) )
		{

			my $newVtop_lower_layer = $Vtop_lower_layer - $Vincrement;
			my $newVbot             = $Vbot - $Vincrement;

			_set_control( 'Vtop', $newVtop_lower_layer );
			$newVtop_lower_layer = _get_control('Vtop');
			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');

			$immodpg->{_Vtop_lower_layer_prior} =
			  $immodpg->{_Vtop_lower_layer_current};
			$immodpg->{_Vtop_lower_layer_current} = $newVtop_lower_layer;

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_Vtop_lower_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vtop_lower_layerEntry}
			  ->insert( 0, $newVtop_lower_layer );

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			#				$immodpg->{_isVtop_lower_layer_changed_in_gui} = $yes;
			#				$immodpg->{_isVbot_changed_in_gui}             = $yes;
			#				_checkVbot(); #todo
			_updateVbot();

			#				_checkVtop_lower_layer(); #todo
			_updateVtop_lower_layer();

			if (   $immodpg->{_isVtop_lower_layer_changed_in_gui} eq $yes
				&& $immodpg->{_isVbot_changed_in_gui} eq $yes )
			{

# for fortran program to read
#				print("immodpg, setVbotNVtop_lower_layer_minus, Vbot is changed: $yes \n");

				_set_option($VbotNVtop_lower_layer_minus_opt);
				_set_change($yes);

#				print("immodpg, setVbotNVtop_lower_layer_minus,option:$VbotNVtop_lower_layer_minus_opt\n");
#				print("immodpg, setVbotNVtop_lower_layer_minus, V=$immodpg->{_Vtop_lower_layer_current}\n");

			}
			else {

#	negative cases are reset by fortran program
#	and so eliminate need to read locked files
#	while use of locked files helps most of the time
#	creation and deletion of locked files in perl are not
#	failsafe
#
#				print("immodpg, setVbotNVtop_lower_layer_minus, same Vbot and Vtop_lower_layer; NADA\n");
			}

		}
		else {
			print(
"immodpg, setVbotNVtop_lower_layer_minus, Vbot or Vtop_lower_layer value missing\n"
			);
		}

	}
	else {
		print(
"immodpg, setVbotNVtop_lower_layer_minus, missing widget or Vincrement\n"
		);

#		print("immodpg, setVtopNVtop_lower_layer_minus, Vtop_lower_layerEntry=$immodpg->{_Vtop_lower_layerEntry}\n");
#		print("immodpg, setVtopNVtop_lower_layer_minus, Vincrement=$immodpg->{_Vincrement_current}\n");
	}
	return ();
}

=head2 setVbotNVtop_lower_layer_plus
update Vbot value in gui
update Vtop_lower_layer value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVbotNVtop_lower_layer_plus {

	my ($self) = @_;

	if (   looks_like_number( $immodpg->{_Vincrement_current} )
		&& length( $immodpg->{_Vtop_lower_layerEntry} )
		&& length( $immodpg->{_VbotEntry} ) )
	{

		my $Vbot             = ( $immodpg->{_VbotEntry} )->get();
		my $Vtop_lower_layer = ( $immodpg->{_Vtop_lower_layerEntry} )->get();
		my $Vincrement       = ( $immodpg->{_VincrementEntry} )->get();

		if (   looks_like_number($Vtop_lower_layer)
			&& looks_like_number($Vbot) )
		{

			my $newVtop_lower_layer = $Vtop_lower_layer + $Vincrement;
			my $newVbot             = $Vbot + $Vincrement;

			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');
			_set_control( 'Vtop', $newVtop_lower_layer );
			$newVtop_lower_layer = _get_control('Vtop');

			$immodpg->{_Vtop_lower_layer_prior} =
			  $immodpg->{_Vtop_lower_layer_current};
			$immodpg->{_Vtop_lower_layer_current} = $newVtop_lower_layer;

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_Vtop_lower_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vtop_lower_layerEntry}
			  ->insert( 0, $newVtop_lower_layer );

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			#				$immodpg->{_isVtop_lower_layer_changed_in_gui} = $yes;
			#				$immodpg->{_isVbot_changed_in_gui}             = $yes;

			_checkVbot();                # todo
			_updateVbot();
			_checkVtop_lower_layer();    # todo
			_updateVtop_lower_layer();

#			print("immodpg, setVbotNVtop_lower_layer_plus, new Vtop_lower_layer= $newVtop_lower_layer\n");
#			print("immodpg, setVbotNVtop_lower_layer_plus, Vincrement= $Vincrement\n");

			if (   $immodpg->{_isVtop_lower_layer_changed_in_gui} eq $yes
				&& $immodpg->{_isVbot_changed_in_gui} eq $yes )
			{

 # for fortran program to read
 #				print("immodpg, setVbotNVtop_lower_layer_plus, Vbot is changed: $yes \n");

				_set_option($VbotNVtop_lower_layer_plus_opt);
				_set_change($yes);

#				print("immodpg, setVbotNVtop_lower_layer_plus,option:$VbotNVtop_lower_layer_plus_opt\n");
#				print("immodpg, setVbotNVtop_lower_layer_plus, V=$immodpg->{_Vtop_lower_layer_current}\n");

			}
			else {

#	negative cases are reset by fortran program
#	and so eliminate need to read locked files
#	while use of locked files helps most of the time
#	creation and deletion of locked files in perl are not
#	failsafe
#
#				print("immodpg, setVbotNVtop_lower_layer_plus, same Vbot and Vtop_lower_layer; NADA\n");
			}

		}
		else {
			print(
"immodpg, setVbotNVtop_lower_layer_plus, Vbot or Vtop_lower_layer value missing\n"
			);
		}

	}
	else {
		print(
"immodpg, setVbotNVtop_lower_layer_plus, missing widget or Vincrement\n"
		);

#		print("immodpg, setVtopNVtop_lower_layer_plus, Vtop_lower_layerEntry=$immodpg->{_Vtop_lower_layerEntry}\n");
		print(
"immodpg, setVtopNVtop_lower_layer_plus, Vincrement=$immodpg->{_Vincrement_current}\n"
		);
	}
	return ();
}

=head2 sub setVtopNVbot_upper_layer_minus
update Vtop value in gui
update Vbot_upper_layer value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVtopNVbot_upper_layer_minus {

	my ($self) = @_;

	# print("layer_current = $immodpg->{_layer_current};\n");
	if (
		   looks_like_number( $immodpg->{_Vincrement_current} )
		&& length( $immodpg->{_Vbot_upper_layerEntry} )
		&& length( $immodpg->{_VtopEntry} )

	  )
	{

		my $Vtop             = ( $immodpg->{_VtopEntry} )->get();
		my $Vbot_upper_layer = ( $immodpg->{_Vbot_upper_layerEntry} )->get();
		my $Vincrement       = ( $immodpg->{_VincrementEntry} )->get();
		my $layer_current    = $immodpg->{_layer_current};

		if ( looks_like_number($Vbot_upper_layer) && looks_like_number($Vtop)
			and $layer_current > 1 )
		{

			my $newVbot_upper_layer = $Vbot_upper_layer - $Vincrement;
			my $newVtop             = $Vtop - $Vincrement;

			_set_control( 'Vbot', $newVbot_upper_layer );
			$newVbot_upper_layer = _get_control('Vbot');

			_set_control( 'Vtop', $newVtop );
			$newVtop = _get_control('Vtop');

			$immodpg->{_Vbot_upper_layer_prior} =
			  $immodpg->{_Vbot_upper_layer_current};
			$immodpg->{_Vbot_upper_layer_current} = $newVbot_upper_layer;

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			$immodpg->{_Vbot_upper_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vbot_upper_layerEntry}
			  ->insert( 0, $newVbot_upper_layer );

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			#				$immodpg->{_isVbot_upper_layer_changed_in_gui} = $yes;
			#				$immodpg->{_isVtop_changed_in_gui}             = $yes;

#			print("immodpg, setVtopNVbot_upper_layer_minus, new Vbot_upper_layer= $newVbot_upper_layer\n");
# print("immodpg, setVtopNVbot_upper_layer_minus, Vincrement= $Vincrement\n");

			#				_checkVtop(); #todo
			_updateVtop();

			#				_checkVbot_upper_layer(); #todo
			_updateVbot_upper_layer();

			if (   $immodpg->{_isVbot_upper_layer_changed_in_gui} eq $yes
				&& $immodpg->{_isVtop_changed_in_gui} eq $yes )
			{

# for fortran program to read
#					print("immodpg, setVtopNVbot_upper_layer_minus, Vbot is changed: $yes \n");

				_set_option($VtopNVbot_upper_layer_minus_opt);
				_set_change($yes);

#				print("immodpg, setVtopNVbot_upper_layer_minus,option:$VtopNVbot_upper_layer_minus_opt\n");
#				print("immodpg, setVtopNVbot_upper_layer_minus, V=$immodpg->{_Vbot_upper_layer_current}\n");

			}
			else {

#	negative cases are reset by fortran program
#	and so eliminate need to read locked files
#	while use of locked files helps most of the time
#	creation and deletion of locked files in perl are not
#	failsafe
#
# print("immodpg, setVtopNVbot_upper_layer_minus, same Vtop and Vbot_upper_layer; NADA\n");
			}

		}
		else {

# print("immodpg, setVtopNVbot_upper_layer_minus, Vtop or Vbot_upper_layer value missing-NADA\n");
		}

	}
	else {
		print(
"immodpg, setVtopNVbot_upper_layer_minus, missing widget or Vincrement\n"
		);

#		print("immodpg, setVtopNVbot_upper_layer_minus, Vbot_upper_layerEntry=$immodpg->{_Vbot_upper_layerEntry}\n");
#		print("immodpg, setVtopNVbot_upper_layer_minus, Vincrement=$immodpg->{_Vincrement_current}\n");
	}
	return ();
}

=head2 sub setVtopNVbot_upper_layer_plus

update Vtop value in gui
update Vbot_upper_layer value in gui
update private value in this module

output option for immodpg.for

=cut

sub setVtopNVbot_upper_layer_plus {

	my ($self) = @_;

	if (
		   looks_like_number( $immodpg->{_Vincrement_current} )
		&& length( $immodpg->{_Vbot_upper_layerEntry} )
		&& length( $immodpg->{_VtopEntry} )

	  )
	{

		my $Vtop             = ( $immodpg->{_VtopEntry} )->get();
		my $Vbot_upper_layer = ( $immodpg->{_Vbot_upper_layerEntry} )->get();
		my $Vincrement       = ( $immodpg->{_VincrementEntry} )->get();
		my $layer_current    = $immodpg->{_layer_current};

		if ( looks_like_number($Vbot_upper_layer) && looks_like_number($Vtop)
			and $layer_current > 1 )
		{

			my $newVbot_upper_layer = $Vbot_upper_layer + $Vincrement;
			my $newVtop             = $Vtop + $Vincrement;

			_set_control( 'Vbot', $newVbot_upper_layer );
			$newVbot_upper_layer = _get_control('Vbot');

			_set_control( 'Vtop', $newVtop );
			$newVtop = _get_control('Vtop');

			$immodpg->{_Vbot_upper_layer_prior} =
			  $immodpg->{_Vbot_upper_layer_current};
			$immodpg->{_Vbot_upper_layer_current} = $newVbot_upper_layer;

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			$immodpg->{_Vbot_upper_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vbot_upper_layerEntry}
			  ->insert( 0, $newVbot_upper_layer );

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			#				$immodpg->{_isVbot_upper_layer_changed_in_gui} = $yes;
			#				$immodpg->{_isVtop_changed_in_gui}             = $yes;
			#				_checkVtop(); #todo
			_updateVtop();

			#				_checkVbot_upper_layer(); # todo
			_updateVbot_upper_layer();

#			print("immodpg, setVtopNVbot_upper_layer_plus, new Vbot_upper_layer= $newVbot_upper_layer\n");
#			print("immodpg, setVtopNVbot_upper_layer_plus, Vincrement= $Vincrement\n");

			if (   $immodpg->{_isVbot_upper_layer_changed_in_gui} eq $yes
				&& $immodpg->{_isVtop_changed_in_gui} eq $yes )
			{

	# for fortran program to read
	#	print("immodpg, setVtopNVbot_upper_layer_plus, Vbot is changed: $yes \n");

				_set_option($VtopNVbot_upper_layer_plus_opt);
				_set_change($yes);

#				print("immodpg, setVtopNVbot_upper_layer_plus,option:$VtopNVbot_upper_layer_plus_opt\n");
#				print("immodpg, setVtopNVbot_upper_layer_plus, V=$immodpg->{_Vbot_upper_layer_current}\n");

			}
			else {

#	negative cases are reset by fortran program
#	and so eliminate need to read locked files
#	while use of locked files helps most of the time
#	creation and deletion of locked files in perl are not
#	failsafe
#
#				print("immodpg, setVtopNVbot_upper_layer_plus, same Vtop and Vbot_upper_layer; NADA\n");
			}

		}
		else {

# print("immodpg, setVtopNVbot_upper_layer_plus, Vtop or Vbot_upper_layer value missing NADA\n");
		}

	}
	else {
		print(
"immodpg, setVtopNVbot_upper_layer_plus, missing widget or Vincrement\n"
		);

#		print("immodpg, setVtopNVbot_upper_layer_plus, Vbot_upper_layerEntry=$immodpg->{_Vbot_upper_layerEntry}\n");
#		print("immodpg, setVtopNVbot_upper_layer_plus, Vincrement=$immodpg->{_Vincrement}\n");
	}
	return ();
}

=head2 sub setVincrement

When you enter or leave
check what the current Vincrement value is
compared to former Vincrement values

=cut

sub setVincrement {

	my ($self) = @_;

	if ( length( $immodpg->{_VincrementEntry} ) ) {

		$immodpg->{_Vincrement_current} = $immodpg->{_VincrementEntry}->get();

# print("1. immodpg, setVincrement ,immodpg->{_Vincrement_current}:$immodpg->{_Vincrement_current}\n");

		_set_control( 'Vincrement', $immodpg->{_Vincrement_current} );
		$immodpg->{_Vincrement_current} = _get_control('Vincrement');
		my $newVincrement = $immodpg->{_Vincrement_current};

# print("2. immodpg, setVincrement,immodpg->{_Vincrement_current}:$immodpg->{_Vincrement_current}\n");

		$immodpg->{_VincrementEntry}->delete( 0, 'end' );
		$immodpg->{_VincrementEntry}->insert( 0, $newVincrement );

		_checkVincrement();
		_updateVincrement();
		_write_config();

		if ( $immodpg->{_isVincrement_changed_in_gui} eq $yes ) {

			# for fortran program to read
#			print("immodpg, setVincrement, Vincrement is changed: $yes \n");
#			print("immodpg, setVincrement,option:$changeVincrement_opt\n");
#		    print("immodpg, setVincrement, $immodpg->{_Vincrement_current}\n");

			_setVincrement( $immodpg->{_Vincrement_current} );
			_set_option($changeVincrement_opt);
			_set_change($yes);

		}
		else {

			#			negative cases are reset by fortran program
			#			and so eliminate need to read locked files
			#			while use of locked files helps most of the time
			#			creation and deletion of locked files in perl are not
			#			failsafe

			# print("immodpg, setVincrement, same Vincrement NADA\n");
		}

	}
	else {
	print("immodpg, setVincrement, missing value\n");
	}

}

=head2 sub setVtop

When you enter or leave,
check what the current Vtop value is
compared to former Vtop values

Vtop value is updated in immodpg.for 
through a message in file= "Vtop"
(&_setVtop)

=cut

sub setVtop {

	my ($self) = @_;

	if ( length( $immodpg->{_VtopEntry} ) ) {

		$immodpg->{_Vtop_current} = ( $immodpg->{_VtopEntry} )->get();

		_set_control( 'Vtop', $immodpg->{_Vtop_current} );
		$immodpg->{_Vtop_current} = _get_control('Vtop');
		my $newVtop = $immodpg->{_Vtop_current};

		$immodpg->{_VtopEntry}->delete( 0, 'end' );
		$immodpg->{_VtopEntry}->insert( 0, $newVtop );

		_checkVtop();
		_updateVtop();

		if ( $immodpg->{_isVtop_changed_in_gui} eq $yes ) {

			# for fortran program to read
			# print("immodpg, set_Vtop, Vtop is changed: $yes \n");

			#				$immodpg->{_VtopEntry}->delete( 0, 'end');
			#				$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			_setVtop( $immodpg->{_Vtop_current} );
			_set_option($changeVtop_opt);
			_set_change($yes);

			#			print("immodpg, setVtop,option:$changeVtop_opt\n");
			#			print("immodpg, setVtop, V=$immodpg->{_Vtop_current}\n");

		}
		else {

			#			negative cases are reset by fortran program
			#			and so eliminate need to read locked files
			#			while use of locked files helps most of the time
			#			creation and deletion of locked files in perl are not
			#			failsafe

			#					print("immodpg, setVtop, same Vtop NADA\n");
		}

	}
	else {
		print("immodpg, setVtop, _Vtop value missing\n");
		print("immodpg, setVtop, Vtop=$immodpg->{_Vtop}\n");
	}
}

=head2 sub setVtop_lower_layer

When you enter or leave
check what the current Vtop_lower_layer value is
compared to former Vtop_lower_layer values
Vtop value is updated in immodpg.for 
through a message in file= "Vtop_lower_layer"
(&_setVtop_lower_layer)

=cut

sub setVtop_lower_layer {

	my ($self) = @_;

	my $newVtop_lower_layer;

# my $isVtop_lower_layer_changed = $immodpg->{_isVtop_lower_layer_changed_in_gui};

	if ( length( $immodpg->{_Vtop_lower_layerEntry} ) ) {

		$immodpg->{_Vtop_lower_layer} =
		  ( $immodpg->{_Vtop_lower_layerEntry} )->get();

		_set_control( 'Vtop_lower_layer', $immodpg->{_Vtop_lower_layer} );
		$immodpg->{_Vtop_lower_layer} = _get_control('Vtop_lower_layer');
		$newVtop_lower_layer = $immodpg->{_Vtop_lower_layer};

		$immodpg->{_Vtop_lower_layerEntry}->delete( 0, 'end' );
		$immodpg->{_Vtop_lower_layerEntry}->insert( 0, $newVtop_lower_layer );

		_checkVtop_lower_layer();
		_updateVtop_lower_layer();

		if ( $immodpg->{_isVtop_lower_layer_changed_in_gui} eq $yes ) {

# for fortran program to read
#            print(" immodpg, set_Vtop_lower_layer, newVtop_lower_layer = $newVtop_lower_layer\n");

	  #				$immodpg->{_Vtop_lower_layerEntry}->delete( 0, 'end' );
	  #				$immodpg->{_Vtop_lower_layerEntry}->insert( 0, $newVtop_lower_layer);

			_setVtop_lower_layer( $immodpg->{_Vtop_lower_layer_current} );
			_set_option($Vtop_lower_layer_opt);
			_set_change($yes);

		 #	print("immodpg, setVtop_lower_layer,option:$Vtop_lower_layer_opt\n");

		}
		else {

			#			negative cases are reset by fortran program
			#			and so eliminate need to read locked files
			#			while use of locked files helps most of the time
			#			creation and deletion of locked files in perl are not
			#			failsafe

		#			print("immodpg, setVtop_lower_layer, same Vtop_lower_layer NADA\n");
		}

	}
	else {
		("immodpg, setVtop_lower_layer, missing widget\n");
	}
}

=head2 sub setVbotNtop_factor

When you enter or leave
check what the current VbotNtop_factor value is
compared to former VbotNtop_factor values

=cut

sub setVbotNtop_factor {

	my ($self) = @_;

	if ( length( $immodpg->{_VbotNtop_factorEntry} ) ) {

		$immodpg->{_VbotNtop_factor_current} =
		  $immodpg->{_VbotNtop_factorEntry}->get();

# print("1, immodpg, setVbotNtop_factor,immodpg->{_VbotNtop_factor_current}: $immodpg->{_VbotNtop_factor_current} \n");
		_set_control( 'VbotNtop_factor', $immodpg->{_VbotNtop_factor_current} );
		$immodpg->{_VbotNtop_factor_current} = _get_control('VbotNtop_factor');
		my $newVbotNtop_factor = $immodpg->{_VbotNtop_factor_current};

# print("2. immodpg, setVbotNtop_factor,newVbotNtop_factor:$newVbotNtop_factor\n");

		$immodpg->{_VbotNtop_factorEntry}->delete( 0, 'end' );
		$immodpg->{_VbotNtop_factorEntry}->insert( 0, $newVbotNtop_factor );

		_checkVbotNtop_factor();
		_updateVbotNtop_factor();
		_write_config();

		if ( $immodpg->{_isVbotNtop_factor_changed_in_gui} eq $yes ) {

			_setVbotNtop_factor( $immodpg->{_VbotNtop_factor_current} );
			_set_option($changeVbotNtop_factor_opt);
			_set_change($yes);

	 # print("immodpg, setVbotNtop_factor,option:$changeVbotNtop_factor_opt\n");

		}
		else {
			_set_change($no);

		# print("immodpg, setVbotNtop_factor, same VbotNtop_factor_opt NADA\n");
		}

	}
	else {
		print("immodpg, setVbotNtop_factor, bad factor or widget\n");

		# correct for bad typing
		#			_set_control('VbotNtop_factor',)
		#			_set_VbotNtop_factor_control();
		#			_get_control_VbotNtop_factor();
	}
}

#

=head2 sub setVbotNtop_multiply
Multiply Vbot and Vtop with factor

_updateVbotNtop_multiply
gui values for widgets
VbotEntry and VtopEntry 
	
output option for immodpg.for

=cut

sub setVbotNtop_multiply {

	my ($self) = @_;

	if (   looks_like_number( $immodpg->{_VbotNtop_factor_current} )
		&& length( $immodpg->{_VbotEntry}->get() )
		&& length( $immodpg->{_VtopEntry}->get() ) )
	{

		my $factor          = $immodpg->{_VbotNtop_factorEntry}->get();
		my $Vbot            = ( $immodpg->{_VbotEntry} )->get();
		my $Vtop            = ( $immodpg->{_VtopEntry} )->get();
		my $Vbot_multiplied = $Vbot * $factor;
		my $Vtop_multiplied = $Vtop * $factor;
		$immodpg->{_Vbot_multiplied} = $Vbot_multiplied;
		$immodpg->{_Vtop_multiplied} = $Vtop_multiplied;

# print("immodpg, setVbotNtop_multiply, Vbot=$Vbot_multiplied=, Vtop= $Vtop_multiplied\n");

		_updateVbotNtop_multiply();
		_set_option($VbotNtop_multiply_opt);
		_set_change($yes);

	}
	else {
		print("immodpg, setVbotNtop_multiply, missing value\n");
	}

	return ();

}

=head2 sub setVbotNtop_minus

update Vbot and Vtop values in gui
update private svalue in this module
output option for immodpg.for

=cut

sub setVbotNtop_minus {

	my ($self) = @_;

	if (   length( $immodpg->{_VbotEntry} )
		&& length( $immodpg->{_VtopEntry} ) )
	{

		my $Vbot       = ( $immodpg->{_VbotEntry} )->get();
		my $Vtop       = ( $immodpg->{_VtopEntry} )->get();
		my $Vincrement = $immodpg->{_VincrementEntry}->get();

		if (   looks_like_number($Vbot)
			&& looks_like_number($Vtop)
			&& looks_like_number($Vincrement) )
		{

			my $newVbot = $Vbot - $Vincrement;

			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			_updateVbot();

			my $newVtop = $Vtop - $Vincrement;
			_set_control( 'Vtop', $newVtop );
			$newVtop = _get_control('Vtop');

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			_updateVtop();

#			print("immodpg, setVbotNtop_minus, new Vbot= $newVbot\n");
#			print("immodpg, setVbotNtop_minus, new Vtop= $newVtop\n");
#			print("immodpg, setVbotNtop_minus, Vincrement= $Vincrement\n");

			if (   $immodpg->{_isVbot_changed_in_gui} eq $yes
				&& $immodpg->{_isVtop_changed_in_gui} eq $yes )
			{

				# for fortran program to read
				_set_option($VbotNtop_minus_opt);
				_set_change($yes);

#				print("immodpg, setVbotNtop_minus, VbotNtop_minus_opt:$VbotNtop_minus_opt \n");

			}
			else {

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				#				print("immodpg, setVbotNtop_minus, same VbotNtop NADA\n");
			}

		}
		else {
			print("immodpg, setVbotNtop_minus, VbotNtop value missing\n");
		}

	}
	else {
		print("immodpg, setVbotNtop_minus, missing widget or Vincrement\n");
   #		print("immodpg, setVbotNtop_minus, Vincrement=$immodpg->{_Vincrement}\n");
	}
	return ();
}

=head2 sub setVbotNtop_plus

update Vbot and Vtop values in gui
update private svalue in this module
output option for immodpg.for

=cut

sub setVbotNtop_plus {

	my ($self) = @_;

	if (   length( $immodpg->{_VbotEntry} )
		&& length( $immodpg->{_VtopEntry} ) )
	{

		my $Vbot       = ( $immodpg->{_VbotEntry} )->get();
		my $Vtop       = ( $immodpg->{_VtopEntry} )->get();
		my $Vincrement = $immodpg->{_VincrementEntry}->get();

		if (   looks_like_number($Vbot)
			&& looks_like_number($Vtop)
			&& looks_like_number($Vincrement) )
		{

			my $newVbot = $Vbot + $Vincrement;

			_set_control( 'Vbot', $newVbot );
			$newVbot = _get_control('Vbot');

			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $newVbot;

			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $newVbot );

			_updateVbot();

			my $newVtop = $Vtop + $Vincrement;
			_set_control( 'Vtop', $newVtop );
			$newVtop = _get_control('Vtop');

			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $newVtop;

			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $newVtop );

			_updateVtop();

#			print("immodpg, setVbotNtop_plus, new Vbot= $newVbot\n");
#			print("immodpg, setVbotNtop_plus, new Vtop= $newVtop\n");
#			print("immodpg, setVbotNtop_plus, Vincrement= $Vincrement\n");

			if (   $immodpg->{_isVbot_changed_in_gui} eq $yes
				&& $immodpg->{_isVtop_changed_in_gui} eq $yes )
			{

				# for fortran program to read
				_set_option($VbotNtop_plus_opt);
				_set_change($yes);

#					print("immodpg, setVbotNtop_plus, VbotNtop_plus_opt:$VbotNtop_plus_opt \n");

			}
			else {

				#	negative cases are reset by fortran program
				#	and so eliminate need to read locked files
				#	while use of locked files helps most of the time
				#	creation and deletion of locked files in perl are not
				#	failsafe
				#
				#				print("immodpg, setVbotNtop_plus, same VbotNtop NADA\n");
			}

		}
		else {
			print("immodpg, setVbotNtop_plus, VbotNtop value missing\n");
		}

	}
	else {
		print("immodpg, setVbotNtop_plus, missing widget or Vincrement\n");
		print("immodpg, setVbotNtop_plus, Vincrement=$immodpg->{_Vincrement}\n");
	}
	return ();
}

=head2 sub invert 


=cut

sub invert {

	my ( $self, $invert ) = @_;
	if ( $invert ne $empty_string ) {

		$immodpg->{_invert} = $invert;
		$immodpg->{_note} =
		  $immodpg->{_note} . ' invert=' . $immodpg->{_invert};
		$immodpg->{_Step} =
		  $immodpg->{_Step} . ' invert=' . $immodpg->{_invert};

	}
	else {
		print("immodpg, invert, missing invert,\n");
	}
}

=head2 sub lmute 


=cut

sub lmute {

	my ( $self, $lmute ) = @_;
	if ($lmute) {

		$immodpg->{_lmute} = $lmute;
		$immodpg->{_note}  = $immodpg->{_note} . ' lmute=' . $immodpg->{_lmute};
		$immodpg->{_Step}  = $immodpg->{_Step} . ' lmute=' . $immodpg->{_lmute};

	}
	else {
		print("immodpg, lmute, missing lmute,\n");
	}
}

=head2 sub premmod 

prepare su file as a binary file for (i)mmodpg
This program read a SU file, and creates the file: 
datammod
which is a binary fortran file containing the SU file with 
no headers, and that
can be read by program mmodpg.  It also create the ascii 
file: parmmod  
containing
basic parameters of the SU file (ntr,ns,dt) also used by mmodpg.

=cut

sub premmod {
	my ($self) = @_;

	#	_set_inbound;
	#	my $inbound = _get_inbound();
	my $inbound;

	if ( $inbound ne $empty_string ) {

	}
	else {
		print("immodpg,premmod, unexpected result\n");
	}

}

=head2 sub set_clip

When you enter or leave
check what the current clip value is
compared to former clip values

=cut

sub set_clip {

	my ($self) = @_;

	if ( length( $immodpg->{_clip4plotEntry} ) ) {

		$immodpg->{_clip4plot_current} = $immodpg->{_clip4plotEntry}->get();

# print("1. immodpg, set_clip,immodpg->{_clip4plot_current}:$immodpg->{_clip4plot_current}\n");

		_set_control( 'clip4plot', $immodpg->{_clip4plot_current} );
		$immodpg->{_clip4plot_current} = _get_control('clip4plot');
		my $new_clip4plot = $immodpg->{_clip4plot_current};

# print("2. immodpg, set_clip,immodpg->{_clip4plot_current}:$immodpg->{_clip4plot_current}\n");

		$immodpg->{_clip4plotEntry}->delete( 0, 'end' );
		$immodpg->{_clip4plotEntry}->insert( 0, $new_clip4plot );

		_check_clip();
		_update_clip();
		_write_config();

		if ( $immodpg->{_is_clip_changed_in_gui} eq $yes ) {

			_set_clip( $immodpg->{_clip4plot_current} );
			_set_option($change_clip_opt);
			_set_change($yes);

#			print("immodpg, set_clip,immodpg->{_clip4plot_current}=$immodpg->{_clip4plot_current}\n");

		}
		else {
			_set_change($no);

			# print("immodpg, set_clip, same clip NADA\n");
		}

	}
	else {

	}
}

=head2 sub set_layer
When you enter or leave
check what the current layer value is
compared to former layer values

=cut

sub set_layer {
	my ($self) = @_;

	#	print("immodpg, set_layer, $immodpg->{_layerEntry}\n");

	if (   length( $immodpg->{_layerEntry} )
		&& looks_like_number( $immodpg->{_layer_current} )
		&& length $immodpg->{_VbotEntry}
		&& length $immodpg->{_VtopEntry}
		&& length $immodpg->{_Vbot_upper_layerEntry}
		&& length $immodpg->{_Vtop_lower_layerEntry}
		&& length( $immodpg->{_thickness_mEntry} )
		&& looks_like_number( $immodpg->{_thickness_m_current} ) )
	{

		_check_layer();
		_update_layer_in_gui();
		_update_upper_layer_in_gui();
		_update_lower_layer_in_gui();

		#		_write_config();  TODO

		if ( $immodpg->{_is_layer_changed_in_gui} eq $yes ) {

=head3 Get model values from
immodpg.out for initial settings
in GUI
If the layer changes, also change associated 
velocity values and thickness values of the new layer

=cut

# print("immodpg, set_layer, layer is changed to: $immodpg->{_layer_current}\n");
			_set_model_layer( $immodpg->{_layer_current} );

			my ( $Vp_ref, $dz ) = _getVp_ref_dz_scalar();
			my @V           = @$Vp_ref;
			my $thickness_m = $dz;

			#	print("immodpg,set_layer,thickness=$thickness_m \n");

			my $Vbot_upper_layer = $V[0];
			my $Vtop             = $V[1];
			my $Vbot             = $V[2];
			my $Vtop_lower_layer = $V[3];

# print("immodpg, set_layer, Vbot=$Vbot for layer=$immodpg->{_layer_current} \n");
			$immodpg->{_thickness_mEntry}->delete( 0, 'end' );
			$immodpg->{_thickness_mEntry}->insert( 0, $thickness_m );

			# print("immodpg, set_layer, Vbot=$Vbot\n");
			$immodpg->{_VbotEntry}->delete( 0, 'end' );
			$immodpg->{_VbotEntry}->insert( 0, $Vbot );

			# print("immodpg, set_layer, Vtop=$Vtop\n");
			$immodpg->{_VtopEntry}->delete( 0, 'end' );
			$immodpg->{_VtopEntry}->insert( 0, $Vtop );

			# print("immodpg, set_layer, Vbot_upper_layer=$Vbot_upper_layer\n");
			$immodpg->{_Vbot_upper_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vbot_upper_layerEntry}->insert( 0, $Vbot_upper_layer );

			# print("immodpg, set_layer, Vtop_lower_layer=$Vtop_lower_layer\n");
			$immodpg->{_Vtop_lower_layerEntry}->delete( 0, 'end' );
			$immodpg->{_Vtop_lower_layerEntry}->insert( 0, $Vtop_lower_layer );

			# update stored values
			$immodpg->{_Vtop_prior}   = $immodpg->{_Vtop_current};
			$immodpg->{_Vtop_current} = $Vtop;
			$immodpg->{_Vbot_prior}   = $immodpg->{_Vbot_current};
			$immodpg->{_Vbot_current} = $Vbot;
			$immodpg->{_Vbot_upper_layer_prior} =
			  $immodpg->{_Vbot_upper_layer_current};
			$immodpg->{_Vbot_upper_layer_current} = $Vbot_upper_layer;
			$immodpg->{_Vtop_lower_layer_prior} =
			  $immodpg->{_Vtop_lower_layer_current};
			$immodpg->{_Vtop_lower_layer_current} = $Vtop_lower_layer;
			$immodpg->{_thickness_m_prior}   = $immodpg->{_thickness_m_current};
			$immodpg->{_thickness_m_current} = $thickness_m;

			# affects immodpg.for
			# print("3. immodpg, set_layer, layer is changed: $yes \n");
			_fortran_layer( $immodpg->{_layer_current} );
			_set_option($change_layer_number_opt);
			_set_change($yes);

			# print("immodpg, set_layer,option:$change_layer_number_opt\n");

		}
		else {
			_set_change($no);

			#	print("immodpg, layer, same layer NADA\n");
		}

	}
	else {

	}
}

=head2 sub set_layer_control
Value adjusts to current
layer number in use

=cut

sub set_layer_control {

	my ( $self, $control_layer_external ) = @_;

	my $result;

	if ( length($control_layer_external) ) {

		$immodpg->{_control_layer_external} = $control_layer_external;

#		print("immodpg,set_layer_control,control_layer_external = $control_layer_external \n");

	}
	elsif ( not( length($control_layer_external) ) ) {

		#		print("immodpg,set_layer_control, empty string\n");
		$immodpg->{_control_layer_external} = $control_layer_external;

	}
	else {
		print("immodpg,set_layer_control, missing value\n");
	}

	return ();
}

=head2 sub set_missing 


=cut

sub set_missing {

	my ( $self, $inbound_missing ) = @_;

	if ( length($inbound_missing) ) {

		$immodpg->{_inbound_missing} = $inbound_missing;

	}
	else {
		print("immodpg, missing, missing file,\n");
	}
	return ();
}

=head2 set_model_layer
Set the number of layers in
mmodpg

=cut

sub set_model_layer {

	my ( $self, $model_layer_number ) = @_;

	if ( $model_layer_number != 0
		&& length($model_layer_number) )
	{

		$immodpg->{_model_layer_number} = $model_layer_number;

	}
	else {
		print("immodpg, set_model_layer, unexpected layer# \n");
	}

#	print("immodpg, set_model_layer,modellayer# =$immodpg->{_model_layer_number}\n");

	return ();
}

=head2 sub set_replacement4missing


=cut

sub set_replacement4missing {

	my ( $self, $replacement4missing ) = @_;

	if ( length($replacement4missing) ) {

		$immodpg->{_replacement4missing} = $replacement4missing;

	}
	else {
		print("immodpg, set_replacement4missing, missing replacement\n");
	}
	return ();
}

=head2 sub set_thickness_m_minus

update _thickness_m value in gui
update private value in this module

output option for immodpg.for

=cut

sub set_thickness_m_minus {

	my ($self) = @_;

	if ( length( $immodpg->{_thickness_mEntry} )
		&& looks_like_number( $immodpg->{_thickness_increment_m} ) )
	{

		my $thickness_m = ( $immodpg->{_thickness_mEntry} )->get();

		if ( looks_like_number($thickness_m) ) {

			my $thickness_increment_m =
			  ( $immodpg->{_thickness_increment_mEntry} )->get();
			my $new_thickness_m = $thickness_m - $thickness_increment_m;
			_set_control( 'thickness_m', $new_thickness_m );
			$new_thickness_m = _get_control('thickness_m');

			$immodpg->{_thickness_m_prior}   = $immodpg->{_thickness_m_current};
			$immodpg->{_thickness_m_current} = $new_thickness_m;

			$immodpg->{_thickness_mEntry}->delete( 0, 'end' );
			$immodpg->{_thickness_mEntry}->insert( 0, $new_thickness_m );

#			print("immodpg, set new _thickness_m= $new_thickness_m\n");
#			print("immodpg, set_thickness_m_minus, thickness_increment_m= $thickness_increment_m\n");

			#				_check_thickness_m(); #todo
			_update_thickness_m();

			$immodpg->{_is_thickness_m_changed_in_gui} = $yes;

			if ( $immodpg->{_is_thickness_m_changed_in_gui} eq $yes ) {

	# for fortran program to read
	# print("immodpg, set_thickness_m_minus, _thickness_m is changed: $yes \n");

				#				   _set_thickness_m( $immodpg->{_thickness_m_current} );
				_set_option($thickness_m_minus_opt);
				_set_change($yes);

#								print("immodpg, set_thickness_m_minus,option:$thickness_m_minus_opt\n");
#								print("immodpg, set_thickness_m_minus, V=$immodpg->{_thickness_m_current}\n");

			}
			else {

			#	negative cases are reset by fortran program
			#	and so eliminate need to read locked files
			#	while use of locked files helps most of the time
			#	creation and deletion of locked files in perl are not
			#	failsafe
			#
			#	print("immodpg, set_thickness_m_minus, same _thickness_m NADA\n");
			}

		}
		else {
			print(
				"immodpg, set_thickness_m_minus, _thickness_m value missing\n");

#			print("immodpg, set_thickness_m_minus, _thickness_mEntry=$immodpg->{_thickness_mEntry}\n");
#			print("immodpg, set_thickness_m_minus, thickness_increment_m=$immodpg->{_thickness_increment_m}\n");
		}

	}
	else {
		print(
"immodpg, set_thickness_m_minus, missing widget or thickness_increment_m\n"
		);
	}
	return ();
}

=head2 sub set_thickness_m_plus

update _thickness_m value in gui
update private value in this module

output option for immodpg.for

=cut

sub set_thickness_m_plus {

	my ($self) = @_;

	if ( length( $immodpg->{_thickness_mEntry} )
		&& looks_like_number( $immodpg->{_thickness_increment_m} ) )
	{

		my $thickness_m = ( $immodpg->{_thickness_mEntry} )->get();

		if ( looks_like_number($thickness_m) ) {

			my $thickness_increment_m =
			  ( $immodpg->{_thickness_increment_mEntry} )->get();
			my $new_thickness_m = $thickness_m + $thickness_increment_m;
			_set_control( 'thickness_m', $new_thickness_m );
			$new_thickness_m = _get_control('thickness_m');

			$immodpg->{_thickness_m_prior}   = $immodpg->{_thickness_m_current};
			$immodpg->{_thickness_m_current} = $new_thickness_m;

			$immodpg->{_thickness_mEntry}->delete( 0, 'end' );
			$immodpg->{_thickness_mEntry}->insert( 0, $new_thickness_m );

#				print("immodpg, set_thickness_m_plus, set new _thickness_m= $new_thickness_m\n");
			_check_thickness_m();    #todo
			_update_thickness_m();

			$immodpg->{_is_thickness_m_changed_in_gui} = $yes;

			if ( $immodpg->{_is_thickness_m_changed_in_gui} eq $yes ) {

	 # for fortran program to read
	 # print("immodpg, set_thickness_m_plus, _thickness_m is changed: $yes \n");

				#				    _set_thickness_m( $immodpg->{_thickness_m_current} );
				_set_option($thickness_m_plus_opt);
				_set_change($yes);

#	print("immodpg, set_thickness_m_plus,option:$_thickness_m_plus_opt\n");
# print("immodpg, set_thickness_m_plus, dz=$immodpg->{_thickness_m_current}\n");

			}
			else {

#				print("immodpg, set_thickness_m_plus, _thickness_mEntry=$immodpg->{_thickness_mEntry}\n");
#				print("immodpg, set_thickness_m_plus, thickness_increment_m=$immodpg->{_thickness_increment_m}\n");

			 #	negative cases are reset by fortran program
			 #	and so eliminate need to read locked files
			 #	while use of locked files helps most of the time
			 #	creation and deletion of locked files in perl are not
			 #	failsafe
			 #
			 #	print("immodpg, set_thickness_m_plus, same _thickness_m NADA\n");
			}

		}
		else {
			print(
				"immodpg, set_thickness_m_plus, _thickness_m value missing\n");

#			print("immodpg, set_thickness_m_plus, _thickness_mEntry=$immodpg->{_thickness_mEntry}\n");
#			print("immodpg, set_thickness_m_plus, thickness_increment_m=$immodpg->{_thickness_increment_m}\n");
		}

	}
	else {
		print(
"immodpg, set_thickness_m_plus, missing widget or thickness_increment_m\n"
		);
	}
	return ();
}

=head2 sub set_update
Save all values in the immodpg
gui to immodpg.config

=cut

sub set_update {
	my ($self) = @_;

    print("immodpg, set_update\n");

	setVincrement();
	set_thickness_increment_m();
	set_thickness_m();
	setVbotNtop_factor();
	set_clip();

	setVbot();
	setVtop();
	setVbot_upper_layer();
	setVtop_lower_layer();
	set_layer();
	_set_simple_model_text();
	_set_working_model_bin();
	_set_working_model_text();

}

sub set_widgets {

	my ( $self, $widget_h ) = @_;

	if ($widget_h) {

		# print("immodpg, set_widgets, widget_ ->{_mw}: $widget_h ->{_mw}\n");
		$immodpg->{_VbotEntry} = $widget_h->{_VbotEntry};
		$immodpg->{_Vbot_upper_layerEntry} =
		  $widget_h->{_Vbot_upper_layerEntry};
		$immodpg->{_VincrementEntry} = $widget_h->{_VincrementEntry};
		$immodpg->{_VtopEntry}       = $widget_h->{_VtopEntry};
		$immodpg->{_Vtop_lower_layerEntry} =
		  $widget_h->{_Vtop_lower_layerEntry};
		$immodpg->{_VbotNtop_factorEntry} = $widget_h->{_VbotNtop_factorEntry};
		$immodpg->{_clip4plotEntry}       = $widget_h->{_clip4plotEntry};
		$immodpg->{_layerEntry}           = $widget_h->{_layerEntry};
		$immodpg->{_thickness_mEntry}     = $widget_h->{_thickness_mEntry};
		$immodpg->{_thickness_increment_mEntry} =
		  $widget_h->{_thickness_increment_mEntry};
		$immodpg->{_upper_layerLabel} = $widget_h->{_upper_layerLabel};
		$immodpg->{_lower_layerLabel} = $widget_h->{_lower_layerLabel};
		$immodpg->{_mw}               = $widget_h->{_mw};

 #		$immodpg->{_message_box_w}              = $widget_h->{_message_box_w};
 #		$immodpg->{_message_upper_frame}        = $widget_h->{_message_upper_frame};
 #		$immodpg->{_message_lower_frame}        = $widget_h->{_message_lower_frame};
 #		$immodpg->{_message_label_w}            = $widget_h->{_message_label_w};
 #		$immodpg->{_message_box_wait}           = $widget_h->{_message_box_wait};
 #		$immodpg->{_message_ok_button}          = $widget_h->{_message_ok_button};

# print("immodpg, set_widgets, immodpg->{_message_box_w}: $immodpg->{_message_box_w}\n");
# print("immodpg, set_widgets, OK\n");

		return ();

	}
	else {
		print("immodpg, set_widgets, unexpected\n");
	}

}

=head2 sub set_base_file_name

=cut

sub set_base_file_name {

	my ( $self, $base_file_name ) = @_;

	if ( $base_file_name ne $empty_string ) {

		$immodpg->{_base_file_name} = $base_file_name;

		print("header_values,set_base_file_name,$immodpg->{_base_file_name}\n");

	}
	else {
		print("header_values,set_base_file_name, missing base file name\n");
	}

	return ();

}

=head2 sub set_change
verify another lock file does not exist and
only then:

create another lock file
while change file is written.
that revents fortran file from reading
Then delete lock file
Aavoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub set_change {

	my ( $self, $yes_or_no ) = @_;

	#	print("immodpg, set_change, yes_or_no:$yes_or_no\n");

	if ( defined($yes_or_no)
		&& $immodpg->{_change_file} ne $empty_string )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $change = $immodpg->{_change_file};

		my $test            = $yes;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $change;
		my $outbound_locked = $outbound . '_locked';
		my $format          = $var_immodpg->{_format_string};

		my $count      = 0;
		my $max_counts = $var_immodpg->{_loop_limit};
		for (
			my $i = 0 ;
			( $test eq $yes ) and ( $count < $max_counts ) ;
			$i++
		  )
		{

			#			print("1. immodpg,set_change, in loop count=$count \n");

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {

				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

		 # print("immodpg, set_change, outbound_locked=$outbound_locked\n");
		 # print("immodpg, set_change, IMMODPG_INVISIBLE=$IMMODPG_INVISIBLE\n");
		 # print("immodpg, set_change, created empty locked file=$X[0]\n");

		 # print("immodpg, set_change, outbound=$outbound\n");
		 # print("immodpg, set_change, IMMODPG_INVISIBLE=$IMMODPG_INVISIBLE\n");

				# do not overwrite a waiting change (= yes)
				my $response_aref = $files->read_1col_aref( \$outbound );
				my $ans           = @{$response_aref}[0];

				if ( $ans eq $yes ) {

				  # do not overwrite a waiting change (= yes)
				  # print("2. immodpg, set_change, SKIP\n");
				  # print("immodpg, set_change,do not overwrite change_file\n");

					unlink($outbound_locked);

				}
				elsif ( $ans eq $no ) {

					# overwrite change_file(=no) with no or yes
					$X[0] = $yes_or_no;
					$files->write_1col_aref( \@X, \$outbound, \$format );

		 #					print("immodpg, set_change, overwrite change file with $X[0]\n");

					unlink($outbound_locked);

					# print("3. immodpg, set_change, delete locked file\n");
					# print("4. immodpg, set_change, yes_or_no=$X[0]\n");

					$test = $no;

				}
				else {
					print("immodpg, set_change, unexpected result \n");
				}    # test change_file's content

			}
			else {

				# print("immodpg,_set_change, locked change file\n");
				$count++;    # governor on finding an unlocked change_file
			}    # if unlocked file is missing and change_file is free

			$count++;    # governor on checking for a change_file = yes
		}    # for

	}
	else {
		print("immodpg, set_change, missing values\n");
	}
	return ();

}    # sub

=head2 sub set_clip_control
value adjusts to current
clip value in use

=cut

sub set_clip_control {

	my ( $self, $control_clip ) = @_;

	my $result;

	if ( length($control_clip)
		&& $control_clip > 0 )
	{

		$immodpg->{_control_clip} = $control_clip;

 #		print("immodpg,set_clip_control, control_clip=$immodpg->{_control_clip}\n");

	}
	elsif ( not( length($control_clip) ) ) {

		# print("immodpg,_set_clip_control, empty string\n");
		$immodpg->{_control_clip} = $control_clip;

	}
	else {
		print("immodpg,set_clip_control, missing value\n");
	}

	return ();
}

=head2 sub set_option
Verify another lock file does not exist and
only then:

Create another lock file
while change file is written
that prevents fortran file from reading.
Then, delete the lock file
Avoids crash between asynchronous 
reading (fortran) and
writing (Perl) of files

=cut

sub set_option {

	my ( $self, $option ) = @_;

	if ( looks_like_number($option)
		&& $immodpg->{_option_file} ne $empty_string )
	{

=head2 instantiate classes

=cut

		my $files   = manage_files_by2->new();
		my $control = control->new();

=head2 Define local
variables

=cut		

		my @X;
		my $option_file = $immodpg->{_option_file};

		my $test            = $no;
		my $outbound        = $IMMODPG_INVISIBLE . '/' . $option_file;
		my $outbound_locked = $outbound . '_locked';

		for ( my $i = 0 ; $test eq $no ; $i++ ) {

			if ( not( $files->does_file_exist( \$outbound_locked ) ) ) {
				
				my $format = $var_immodpg->{_format_string};
				$X[0] = $empty_string;
				$files->write_1col_aref( \@X, \$outbound_locked, \$format );

				$X[0] = $option;
				$format = $var_immodpg->{_format_integer};

#				print("immodpg,set_option,option=$option\n");
				$files->write_1col_aref( \@X, \$outbound, \$format );

				unlink($outbound_locked);

				$test = $yes;
			}    # if
		}    # for

	}
	elsif ( $immodpg->{_is_option_changed} eq $no ) {

		# NADA
	}
	else {
		print("immodpg, set_option, unexpected answer\n");
	}

	return ();
}

=head2 sub smute 


=cut

sub smute {

	my ( $self, $smute ) = @_;
	if ($smute) {

		$immodpg->{_smute} = $smute;
		$immodpg->{_note}  = $immodpg->{_note} . ' smute=' . $immodpg->{_smute};
		$immodpg->{_Step}  = $immodpg->{_Step} . ' smute=' . $immodpg->{_smute};

	}
	else {
		print("immodpg, smute, missing smute,\n");
	}
}

=head2 sub sscale 


=cut

sub sscale {

	my ( $self, $sscale ) = @_;
	if ($sscale) {

		$immodpg->{_sscale} = $sscale;
		$immodpg->{_note} =
		  $immodpg->{_note} . ' sscale=' . $immodpg->{_sscale};
		$immodpg->{_Step} =
		  $immodpg->{_Step} . ' sscale=' . $immodpg->{_sscale};

	}
	else {
		print("immodpg, sscale, missing sscale,\n");
	}
}

=head2 sub set_thickness_m

When you enter or leave,
check what the current thickness_m value is
compared to former thickness_m values

thickness_m value is updated in immodpg.for 
through a message in file="thickness_m"
($_set_thickness_m)

=cut

sub set_thickness_m {

	my ($self) = @_;

	if ( looks_like_number( $immodpg->{_thickness_m_current} ) ) {

		_set_control( 'thickness_m', $immodpg->{_thickness_m_current} );
		$immodpg->{_thickness_m_current} = _get_control('thickness_m');

		_check_thickness_m();
		_update_thickness_m();

		if ( length( $immodpg->{_is_thickness_m_changed_in_gui} )
			&& $immodpg->{_is_thickness_m_changed_in_gui} eq $yes )
		{

		   # for fortran program to read
		   # print("immodpg, set_thickness_m, thickness_m is changed: $yes \n");

			_set_thickness_m( $immodpg->{_thickness_m_current} );
			_set_option($change_thickness_m_opt);
			_set_change($yes);

		}
		else {

			#			negative cases are reset by fortran program
			#			and so eliminate need to read locked files
			#			while use of locked files helps most of the time
			#			creation and deletion of locked files in perl are not
			#			failsafe

			# print("immodpg, set_thickness_m, same thickness_m NADA\n");
		}

	}
	else {
		print("immodpg, set_thickness_m, _thickness_m value missing\n");
		print(
			"immodpg, set_thickness_m, thickness_m=$immodpg->{_thickness_m}\n");
	}
}

=head2 sub set_thickness_increment_m
When you enter or leave
check what the current thickness_increment_m value is
compared to former thickness_increment_m values

thickness_increment_m value is updated in immodpg.for 
through a message in file= "thickness_increment_m"
(&_set_thickness_increment_m)

=cut

sub set_thickness_increment_m {

	my ($self) = @_;

	# print("immodpg, set_thickness_increment_m, self, $self\n");

	if ( length( $immodpg->{_thickness_increment_mEntry} ) ) {

		$immodpg->{_thickness_increment_m_current} =
		  ( $immodpg->{_thickness_increment_mEntry} )->get();
		_set_control( 'thickness_increment_m',
			$immodpg->{_thickness_increment_m_current} );
		$immodpg->{_thickness_increment_m_current} =
		  _get_control('thickness_increment_m');
		my $new_thickness_increment_m =
		  $immodpg->{_thickness_increment_m_current};

		$immodpg->{_thickness_increment_mEntry}->delete( 0, 'end' );
		$immodpg->{_thickness_increment_mEntry}
		  ->insert( 0, $new_thickness_increment_m );

# print("immodpg, set_thickness_increment_m, $immodpg->{_thickness_increment_mEntry}\n");
		_check_thickness_increment_m();
		_update_thickness_increment_m_in_gui();
		_write_config();

		if ( $immodpg->{_is_layer_changed_in_gui} eq $yes ) {

			print(
"immodpg, set_thickness_increment_m, thickness_increment_m is changed: $yes \n"
			);

			_set_thickness_increment_m(
				$immodpg->{_thickness_increment_m_current} );
			_set_option($change_thickness_increment_m_opt);
			_set_change($yes);

#				print("immodpg, set_thickness_increment_m,option:$change_thickness_increment_m_opt\n");
#				print(
#					"immodpg, set_thickness_increment_m,immodpg->{_thickness_increment_m_current}=$immodpg->{_thickness_increment_m_current}\n"
#				);

		}
		else {
			_set_change($no);

# print("immodpg, set_thickness_increment_m, same thickness_increment_m NADA\n");
		}

	}
	else {

	}
}

=head2 sub tnmo 


=cut

sub tnmo {

	my ( $self, $tnmo ) = @_;
	if ( $tnmo ne $empty_string ) {

		$immodpg->{_tnmo} = $tnmo;
		$immodpg->{_note} = $immodpg->{_note} . ' tnmo=' . $immodpg->{_tnmo};
		$immodpg->{_Step} = $immodpg->{_Step} . ' tnmo=' . $immodpg->{_tnmo};

	}
	else {
		print("immodpg, tnmo, missing tnmo,\n");
	}
}

=head2 sub upward 


=cut

sub upward {

	my ( $self, $upward ) = @_;
	if ( $upward ne $empty_string ) {

		$immodpg->{_upward} = $upward;
		$immodpg->{_note} =
		  $immodpg->{_note} . ' upward=' . $immodpg->{_upward};
		$immodpg->{_Step} =
		  $immodpg->{_Step} . ' upward=' . $immodpg->{_upward};

	}
	else {
		print("immodpg, upward, missing upward,\n");
	}
}

=head2 sub vnmo 


=cut

sub vnmo {

	my ( $self, $vnmo ) = @_;
	if ($vnmo) {

		$immodpg->{_vnmo} = $vnmo;
		$immodpg->{_note} = $immodpg->{_note} . ' vnmo=' . $immodpg->{_vnmo};
		$immodpg->{_Step} = $immodpg->{_Step} . ' vnmo=' . $immodpg->{_vnmo};

	}
	else {
		print("immodpg, vnmo, missing vnmo,\n");
	}
}

=head2 sub vnmo_mps 


=cut

sub vnmo_mps {

	my ( $self, $vnmo ) = @_;
	if ($vnmo) {

		$immodpg->{_vnmo} = $vnmo;
		$immodpg->{_note} = $immodpg->{_note} . ' vnmo=' . $immodpg->{_vnmo};
		$immodpg->{_Step} = $immodpg->{_Step} . ' vnmo=' . $immodpg->{_vnmo};

	}
	else {
		print("immodpg, vnmo, missing vnmo,\n");
	}
}

=head2 sub voutfile 


=cut

sub voutfile {

	my ( $self, $voutfile ) = @_;
	if ($voutfile) {

		$immodpg->{_voutfile} = $voutfile;
		$immodpg->{_note} =
		  $immodpg->{_note} . ' voutfile=' . $immodpg->{_voutfile};
		$immodpg->{_Step} =
		  $immodpg->{_Step} . ' voutfile=' . $immodpg->{_voutfile};

	}
	else {
		print("immodpg, voutfile, missing voutfile,\n");
	}
}

1;
