package App::SeismicUnixGui::misc::conditions4flows;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: conditions4flows.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 16 2018 

 DESCRIPTION 
 		makes gui aware 
 		of what method is active
 		
 		Makes GUI disable and reenable certain widgets depending on which
 		method is called
 		
 		Based on method used, hash values are reset internally
 		one of few packages that changes state of variables outside main
 		for this reason we copy all hash to private variables and reassign
 		them on potential exit so that nothing is lost or mislabeled
 		
 		only conditions are reset. All other parameters travel through safely
 		
 		Be careful to blank as many imported values as possible and only allow
 		the essential to be  used (_reset and reset methods are available)
 		
 		I sometimes reset some values internally (_reset)and only allow 
 		one or a few to survive for manipulation internally. But, because
 		all variables that enter are sheltered in private variables those that are not
 		changed can safely be handed back to the namespace of the module that is calling 
 		conditions4flows.
 		
 		get_flow_index_last_touched needs to be exported so do not reset it
 		
 		For safety we try to encapsulate this module
 		For safety we work internally sometimes with single scalars instead of imported hash and variables
 		For safety, input hash keys are assigned to new variables with short private names
 		New variables with short names are exported from a private hash
 		
 BASED ON:
 
 conditions_gui.pm
 previous version the main L_SU.pl (V 0.3)
  
=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
 refactoring of 2017 version of L_SU.pl

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.2';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $false        = $var->{_false};
my $true         = $var->{_true};
my $empty_string = $var->{_empty_string};

=head2 
 
  106 of convenient private abbreviated-variable names
  These are defiend in every subroutine so that get_hash_ref can export them
  
=cut

my $Data_menubutton;
my $FileDialog_sub_ref;
my $FileDialog_option;
my $Open_menubutton;
my $SaveAs_menubutton;
my $add2flow_button_grey;
my $add2flow_button_pink;
my $add2flow_button_green;
my $add2flow_button_blue;
my $big_stream_name_in;
my $big_stream_name_out;
#my $check_buttons_settings_aref;
#my $check_buttons_w_aref;
#my $check_code_button;
my $delete_from_flow_button;
my $delete_whole_flow_button;
my $dialog_type;
my $file_menubutton;
my $flowNsuperflow_name_w;
my $flow_color;
my $flow_item_down_arrow_button;
my $flow_item_up_arrow_button;
my $flow_listbox_grey_w;
my $flow_listbox_pink_w;
my $flow_listbox_green_w;
my $flow_listbox_blue_w;
my $flow_listbox_color_w;
my $flow_name_in;
my $flow_name_in_blue;
my $flow_name_in_grey;
my $flow_name_in_green;
my $flow_name_in_pink;
my $flow_name_out;
my $flow_name_out_blue;
my $flow_name_out_grey;
my $flow_name_out_green;
my $flow_name_out_pink;
my $flow_type;
my $flow_widget_index;
my $gui_history_ref;
#my $has_used_check_code_button;
my $has_used_Delete_button;
my $has_used_SaveAs_button;
my $has_used_Save_button;
my $has_used_Save_superflow;
my $has_used_open_perl_file_button;
my $has_used_run_button;
my $is_Delete_file_button;
my $is_Save_button;
my $is_SaveAs_button;
my $is_SaveAs_file_button;
my $is_add2flow;
my $is_add2flow_button;
#my $is_check_code_button;
my $is_delete_from_flow_button;
my $is_delete_whole_flow_button;
#my $is_dragNdrop;
my $is_flow_item_down_arrow_button;
my $is_flow_item_up_arrow_button;
my $is_flow_listbox_grey_w;
my $is_flow_listbox_pink_w;
my $is_flow_listbox_green_w;
my $is_flow_listbox_blue_w;
my $is_flow_listbox_color_w;
my $is_future_flow_listbox_grey;
my $is_future_flow_listbox_pink;
my $is_future_flow_listbox_green;
my $is_future_flow_listbox_blue;
my $is_last_flow_index_touched_grey;
my $is_last_flow_index_touched_pink;
my $is_last_flow_index_touched_green;
my $is_last_flow_index_touched_blue;
my $is_last_flow_index_touched;
my $is_last_parameter_index_touched_grey;
my $is_last_parameter_index_touched_pink;
my $is_last_parameter_index_touched_green;
my $is_last_parameter_index_touched_blue;
my $is_last_parameter_index_touched_color;
my $is_neutral_flow;
my $is_moveNdrop_in_flow;
my $is_new_listbox_selection;
my $is_open_file_button;
my $is_pre_built_superflow;
my $is_run_button;
my $is_select_file_button;
my $is_selected_file_name;
my $is_selected_path;
my $is_sunix_listbox;
my $is_superflow_select_button;
my $is_superflow;    # for deprecation
my $is_user_built_flow;
my $is_wipe_plots_button;
my $labels_w_aref;
my $last_flow_listbox_touched;
my $last_flow_listbox_touched_w;
my $last_flow_index_touched_grey;
my $last_flow_index_touched_pink;
my $last_flow_index_touched_green;
my $last_flow_index_touched_blue;
my $last_flow_index_touched;
my $last_flow_color;
my $last_parameter_index_touched_grey;
my $last_parameter_index_touched_pink;
my $last_parameter_index_touched_green;
my $last_parameter_index_touched_blue;
my $last_parameter_index_touched_color;
my $message_w;
my $mw;
my $names_aref;
my $occupied_listbox_aref;
my $parameter_value_index;
my $parameter_values_frame;
my $path;
my $prog_name_sref;
my $run_button;
my $save_button;
my $selected_file_name;
my $sub_ref;
my $values_aref;
my $vacant_listbox_aref;
my $values_w_aref;
my $wipe_plots_button;

=head2 private hash

106 off

=cut

my $conditions4flows = {

	_Data_menubutton                       => '',
	_Open_menubutton                       => '',
	_SaveAs_menubutton                     => '',
	_add2flow_button_grey                  => '',
	_add2flow_button_pink                  => '',
	_add2flow_button_green                 => '',
	_add2flow_button_blue                  => '',
#	_big_stream_name_in                    => '',
#	_big_stream_name_out                   => '',
#	_check_code_button                     => '',
#	_check_buttons_settings_aref           => '',
#	_check_buttons_w_aref                  => '',
	_delete_from_flow_button               => '',
	_delete_whole_flow_button              => '',
	_dialog_type                           => '',
	_file_menubutton                       => '',
	_flowNsuperflow_name_w                 => '',
	_flow_color                            => '',	
	_flow_item_down_arrow_button           => '',
	_flow_item_up_arrow_button             => '',
	_flow_listbox_grey_w                   => '',
	_flow_listbox_pink_w                   => '',
	_flow_listbox_green_w                  => '',
	_flow_listbox_blue_w                   => '',
	_flow_listbox_color_w                  => '',
	_flow_name_in                          => '',
#	_flow_name_in_blue                     => '',
#	_flow_name_in_grey                     => '',
#	_flow_name_in_green                    => '',
#	_flow_name_in_pink                     => '',
	_flow_name_out                         => '',
#	_flow_name_out_blue                    => '',
#	_flow_name_out_grey                    => '',
#	_flow_name_out_green                   => '',
#	_flow_name_out_pink                    => '',
	_flow_type                             => '',
	_flow_widget_index                     => '',
	_gui_history_aref                      => '',
#	_has_used_check_code_button            => '',
	_has_used_Delete_button                => '',
	_has_used_Save_button                  => '',
	_has_used_Save_superflow               => '',
	_has_used_SaveAs_button                => '',
	_has_used_open_perl_file_button        => '',
	_has_used_run_button                   => '',
	_is_Delete_file_button                 => '',
	_is_SaveAs_file_button                 => '',
	_is_SaveAs_button                      => '',
	_is_Save_button                        => '',	
	_is_add2flow                           => '',
	_is_add2flow_button                    => '',
#	_is_check_code_button                  => '',
	_is_delete_from_flow_button            => '',
	_is_delete_whole_flow_button           => '',
#	_is_dragNdrop                          => '',
	_is_flow_item_down_arrow_button        => '',
	_is_flow_item_up_arrow_button          => '',
	_is_flow_listbox_grey_w                => '',
	_is_flow_listbox_pink_w                => '',
	_is_flow_listbox_green_w               => '',
	_is_flow_listbox_blue_w                => '',
	_is_flow_listbox_color_w               => '',
	_is_last_flow_index_touched_grey       => '',
	_is_last_flow_index_touched_pink       => '',
	_is_last_flow_index_touched_green      => '',
	_is_last_flow_index_touched_blue       => '',
	_is_last_flow_index_touched            => '',
	_is_last_parameter_index_touched_grey  => '',
	_is_last_parameter_index_touched_pink  => '',
	_is_last_parameter_index_touched_green => '',
	_is_last_parameter_index_touched_blue  => '',
	_is_last_parameter_index_touched_color => '',
	_is_neutral_flow                       => '',
	_is_moveNdrop_in_flow                  => '',
	_is_new_listbox_selection              => '',
	_is_open_file_button                   => '',
	_is_pre_built_superflow                => '',
	_is_run_button                         => '',
	_is_select_file_button                 => '',
	_is_selected_file_name                 => '',
	_is_selected_path                      => '',
	_is_superflow                          => '',
	_is_sunix_listbox                      => '',
	_is_superflow_select_button            => '',
	_is_run_button                         => '',
	_is_user_built_flow                    => '',
	_is_wipe_plots_button                  => '',
	_labels_w_aref                         => '',
	_last_flow_color                       => '',
	_last_flow_index_touched_grey          => -1,
	_last_flow_index_touched_pink          => -1,
	_last_flow_index_touched_green         => -1,
	_last_flow_index_touched_blue          => -1,
	_last_flow_listbox_touched             => -1,
	_last_flow_listbox_touched_w           => '',
	_last_flow_index_touched               => -1,
	_last_parameter_index_touched_grey     => -1,
	_last_parameter_index_touched_pink     => -1,
	_last_parameter_index_touched_green    => -1,
	_last_parameter_index_touched_blue     => -1,
	_last_parameter_index_touched_color    => -1,
	_message_w                             => '',
	_mw                                    => '',
	_names_aref                            => '',
	_occupied_listbox_aref                 => '',
	_parameter_values_frame                => '',
	_parameter_value_index                 => '',
	_path                                  => '',
	_prog_name_sref                        => '',
	_run_button                            => '',
	_save_button                           => '',
	_sub_ref                               => '',
	_vacant_listbox_aref                   => '',
	_values_aref                           => '',
	_values_w_ref                          => '',
	_wipe_plots_button                     => '',

};

=head2 sub _get_add2flow


=cut 

sub _get_add2flow {
	my ($self) = @_;
	my $color;
	my $correct_add2flow_button;

	$color = $conditions4flows->{_flow_color};

	if ( $color eq 'grey' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_grey};

	} elsif ( $color eq 'pink' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_pink};

	} elsif ( $color eq 'green' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_green};

	} elsif ( $color eq 'blue' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_blue};

	} else {
		print("conditions4flows,  _get_add2flow_button, missing color,missing color, color:$color\n");
	}

	return ($correct_add2flow_button);
}

=head2 sub _get_add2flow_button


=cut 

sub _get_add2flow_button {
	my ($self) = @_;
	my $color;
	my $correct_add2flow_button;

	$color = $conditions4flows->{_flow_color};

	if ( $color eq 'grey' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_grey};

	} elsif ( $color eq 'pink' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_pink};

	} elsif ( $color eq 'green' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_green};

	} elsif ( $color eq 'blue' ) {
		$correct_add2flow_button = $conditions4flows->{_add2flow_button_blue};

	} else {
		print("conditions4flows,  _get_add2flow_button, missing color,missing color, color:$color\n");
	}

	return ($correct_add2flow_button);
}

=head2 sub _get_flow_color


=cut 

sub _get_flow_color {
	my ($self) = @_;
	my $color;

	if ( $conditions4flows->{_flow_color} ) {

		$color = $conditions4flows->{_flow_color};
		return ($color);

	} else {
		print("conditions4flows,_get_flow_color  missing conditions4flows->{_flow_color}\n");

	}

}

=head2 sub _get_flow_listbox_color_w


=cut 

sub _get_flow_listbox_color_w {
	my ($self) = @_;
	my $correct_flow_listbox_color_w;

	if ( $conditions4flows->{_flow_listbox_color_w} ) {

		my $correct_flow_listbox_color_w = $conditions4flows->{_flow_listbox_color_w};
		return ($correct_flow_listbox_color_w);

	} else {
		print("conditions4flows, _get_flow_listbox_color_w, unassigned flow listbox w for current color\n");
		return ();
	}

}

=head2  sub _reset

	26 off
	do not reset important values:
	location within GUI

=cut

sub _reset {
	my ($self) = @_;

	$conditions4flows->{_is_Delete_file_button}          = $false;
	$conditions4flows->{_is_Save_button}                 = $false;
	$conditions4flows->{_is_SaveAs_file_button}          = $false;
	$conditions4flows->{_is_SaveAs_button}               = $false;
#	$conditions4flows->{_has_used_check_code_button}     = $false;
	$conditions4flows->{_has_used_run_button}            = $false;
	$conditions4flows->{_is_add2flow_button}             = $false;
#	$conditions4flows->{_is_check_code_button}           = $false;
	$conditions4flows->{_is_delete_from_flow_button}     = $false;
	$conditions4flows->{_is_delete_whole_flow_button}    = $false;
	$conditions4flows->{_is_dragNdrop}                   = $false;
	$conditions4flows->{_is_flow_item_down_arrow_button} = $false;
	$conditions4flows->{_is_flow_item_up_arrow_button}   = $false;
	$conditions4flows->{_is_flow_listbox_grey_w}         = $false;
	$conditions4flows->{_is_flow_listbox_pink_w}         = $false;
	$conditions4flows->{_is_flow_listbox_green_w}        = $false;
	$conditions4flows->{_is_flow_listbox_blue_w}         = $false;
	$conditions4flows->{_is_flow_listbox_color_w}        = $false;
	$conditions4flows->{_is_moveNdrop_in_flow}           = $false;
	$conditions4flows->{_is_open_file_button}            = $false;
	$conditions4flows->{_is_select_file_button}          = $false;
	$conditions4flows->{_is_sunix_listbox}               = $false;
	$conditions4flows->{_is_new_listbox_selection}       = $false;
	$conditions4flows->{_is_superflow_select_button}     = $false;
	$conditions4flows->{_is_run_button}                  = $false;
	$conditions4flows->{_is_pre_built_superflow}         = $false;
	$conditions4flows->{_is_superflow}                   = $false;
	$conditions4flows->{_is_user_built_flow}             = $false;
	$conditions4flows->{_is_wipe_plots_button}           = $false;

}

=head2 sub _reset_is_flow_listbox_color_w


=cut

sub _reset_is_flow_listbox_color_w {
	my ($self) = @_;

	if (   $conditions4flows->{_flow_color} eq 'grey'
		|| $conditions4flows->{_flow_color} eq 'pink'
		|| $conditions4flows->{_flow_color} eq 'green'
		|| $conditions4flows->{_flow_color} eq 'blue'
		|| $conditions4flows->{_flow_color} eq 'neutral' ) {

		$conditions4flows->{_is_flow_listbox_grey_w}  = $false;
		$conditions4flows->{_is_flow_listbox_pink_w}  = $false;
		$conditions4flows->{_is_flow_listbox_green_w} = $false;
		$conditions4flows->{_is_flow_listbox_blue_w}  = $false;

		# for export
		$is_flow_listbox_grey_w  = $false;
		$is_flow_listbox_pink_w  = $false;
		$is_flow_listbox_green_w = $false;
		$is_flow_listbox_blue_w  = $false;

	} else {
		print(" conditions4flows, _reset_is_flow_listbox_color_w ,missing flow color \n");
	}

	return ();
}

=head2 sub _set_flow_color


=cut 

sub _set_flow_color {
	my ($color) = @_;

	if ($color) {

		# print("conditions4flows, _set_flow_color , color:$color\n");
		$conditions4flows->{_flow_color} = $color;
	} else {

		print("conditions4flows, set_flow_color, missing color\n");
	}
	return ();
}

=head2 sub _set_flow_listbox_color_w


=cut 

sub _set_flow_listbox_color_w {
	my ($color) = @_;

	if ( $color eq 'grey' ) {
		$conditions4flows->{_flow_listbox_color_w}   = $conditions4flows->{_flow_listbox_grey_w};
		$conditions4flows->{_is_flow_listbox_grey_w} = $true;
		$flow_listbox_color_w   = $conditions4flows->{_flow_listbox_grey_w};    # for possible export via get_hash_ref
		$is_flow_listbox_grey_w = $true;                                        # for possible export via get_hash_ref

	} elsif ( $color eq 'pink' ) {
		$conditions4flows->{_flow_listbox_color_w}   = $conditions4flows->{_flow_listbox_pink_w};
		$conditions4flows->{_is_flow_listbox_pink_w} = $true;
		$flow_listbox_color_w   = $conditions4flows->{_flow_listbox_pink_w};    # for possible export via get_hash_ref
		$is_flow_listbox_pink_w = $true;                                        # for possible export via get_hash_ref

	} elsif ( $color eq 'green' ) {
		$conditions4flows->{_flow_listbox_color_w}    = $conditions4flows->{_flow_listbox_green_w};
		$conditions4flows->{_is_flow_listbox_green_w} = $true;
		$flow_listbox_color_w    = $conditions4flows->{_flow_listbox_green_w};    # for possible export via get_hash_ref
		$is_flow_listbox_green_w = $true;                                         # for possible export via get_hash_ref

	} elsif ( $color eq 'blue' ) {
		$conditions4flows->{_flow_listbox_color_w}   = $conditions4flows->{_flow_listbox_blue_w};
		$conditions4flows->{_is_flow_listbox_blue_w} = $true;
		$flow_listbox_color_w   = $conditions4flows->{_flow_listbox_blue_w};      # for possible export via get_hash_ref
		$is_flow_listbox_blue_w = $true;                                          # for possible export via get_hash_ref

	} else {
		print("conditions4flows, _set_flow_listbox_color_w, missing color, color:$color\n");
	}

	return ();
}

=head2 sub _set_flow_listbox_last_touched_txt

	keep track of whcih listbox was last chosen

=cut

sub _set_flow_listbox_last_touched_txt {
	my ($last_flow_lstbx_touched) = @_;

	if ($last_flow_lstbx_touched) {
		$conditions4flows->{_last_flow_listbox_touched} = $last_flow_lstbx_touched;

		# print("conditions4flows,_set_flow_listbox_touched left listbox = $conditions4flows->{_last_flow_listbox_touched}\n");

		# for possible export via get_hash_ref
		$last_flow_listbox_touched = $last_flow_lstbx_touched;

	} else {
		print("conditions4flows,set_flow_listbox_touched_txt, missing listbox name\n");
	}

	return ();
}

=head2 sub _set_flow_listbox_last_touched_w


=cut

sub _set_flow_listbox_last_touched_w {
	my ($flow_listbox_color_w) = @_;

	# print("1 conditions4flows, _set_flow_listbox_last_touched_w; flow_listbox_color_w: $flow_listbox_color_w \n");

	if ($flow_listbox_color_w) {

		# print("1 conditions4flows, _set_flow_listbox_last_touched_w; $flow_listbox_color_w\n");
		$conditions4flows->{_last_flow_listbox_touched_w} = $flow_listbox_color_w;
		$last_flow_listbox_touched_w = $flow_listbox_color_w;                         # for export via get_hash-ref

	} else {
		print("conditions4flows,_set_flow_listbox_touched_w, missing listbox widget\n");
	}
	return ();
}

=head2 sub get_flow_color

	return flow color if it exists
	
=cut

sub get_flow_color {
	my ($self) = @_;
	my $flow_color;

	if ( $conditions4flows->{_flow_color} ) {

		$flow_color = $conditions4flows->{_flow_color};

		print("conditions4flows, conditions4flows->{_flow_color}: $conditions4flows->{_flow_color}\n");
		return ($flow_color);

	} else {
		print("conditions4flows, get_flow_color , missing flow color value \n");
		return ();
	}
}

=head2 sub get_hash_ref

	return ALL values of the private hash, supposedly
	improtant external widgets have not been reset.. only conditions
	are reset
	TODO: perhaps it is better to have a specific method
		to return one specific widget address at a time?
	}
	
	99
	 
=cut

sub get_hash_ref {
	my ($self) = @_;

	if ($conditions4flows) {

		$conditions4flows->{_Data_menubutton}                       = $Data_menubutton;
		$conditions4flows->{_Open_menubutton}                       = $Open_menubutton;
		$conditions4flows->{_SaveAs_menubutton}                     = $SaveAs_menubutton;
		$conditions4flows->{_add2flow_button_grey}                  = $add2flow_button_grey;
		$conditions4flows->{_add2flow_button_pink}                  = $add2flow_button_pink;
		$conditions4flows->{_add2flow_button_green}                 = $add2flow_button_green;
		$conditions4flows->{_add2flow_button_blue}                  = $add2flow_button_blue;
		$conditions4flows->{_big_stream_name_in}                    = $big_stream_name_in;
		$conditions4flows->{_big_stream_name_out}                   = $big_stream_name_out;
#		$conditions4flows->{_check_buttons_w_aref}                  = $check_buttons_w_aref;
#		$conditions4flows->{_check_buttons_settings_aref}           = $check_buttons_settings_aref;
#		$conditions4flows->{_check_code_button}                     = $check_code_button;
		$conditions4flows->{_delete_from_flow_button}               = $delete_from_flow_button;
		$conditions4flows->{_delete_whole_flow_button}              = $delete_whole_flow_button;
		$conditions4flows->{_file_menubutton}                       = $file_menubutton;
		$conditions4flows->{_flowNsuperflow_name_w}                 = $flowNsuperflow_name_w;
		$conditions4flows->{_flow_item_down_arrow_button}           = $flow_item_down_arrow_button;
		$conditions4flows->{_flow_item_up_arrow_button}             = $flow_item_up_arrow_button;
		$conditions4flows->{_flow_listbox_grey_w}                   = $flow_listbox_grey_w;
		$conditions4flows->{_flow_listbox_pink_w}                   = $flow_listbox_pink_w;
		$conditions4flows->{_flow_listbox_green_w}                  = $flow_listbox_green_w;
		$conditions4flows->{_flow_listbox_blue_w}                   = $flow_listbox_blue_w;
		$conditions4flows->{_flow_listbox_color_w}                  = $flow_listbox_color_w;
		$conditions4flows->{_flow_name_in}                          = $flow_name_in;
		$conditions4flows->{_flow_name_in_blue}                     = $flow_name_in_blue;
		$conditions4flows->{_flow_name_in_grey}                     = $flow_name_in_grey;
		$conditions4flows->{_flow_name_in_green}                    = $flow_name_in_green;
		$conditions4flows->{_flow_name_in_pink}                     = $flow_name_in_pink;
		$conditions4flows->{_flow_name_out}                         = $flow_name_out;
		$conditions4flows->{_flow_name_out_blue}                    = $flow_name_out_blue;
		$conditions4flows->{_flow_name_out_grey}                    = $flow_name_out_grey;
		$conditions4flows->{_flow_name_out_green}                   = $flow_name_out_green;
		$conditions4flows->{_flow_name_out_pink}                    = $flow_name_out_pink;
		$conditions4flows->{_flow_widget_index}                     = $flow_widget_index;
		$conditions4flows->{_labels_w_aref}                         = $labels_w_aref;
		$conditions4flows->{_message_w}                             = $message_w;
		$conditions4flows->{_mw}                                    = $mw;
		$conditions4flows->{_parameter_values_frame}                = $parameter_values_frame;
		$conditions4flows->{_parameter_value_index}                 = $parameter_value_index;
		$conditions4flows->{_run_button}                            = $run_button;
		$conditions4flows->{_save_button}                           = $save_button;
		$conditions4flows->{_values_w_aref}                         = $values_w_aref;
		$conditions4flows->{_dialog_type}                           = $dialog_type;
		$conditions4flows->{_flow_color}                            = $flow_color;
		$conditions4flows->{_flow_type}                             = $flow_type;
		$conditions4flows->{_flow_widget_index}                     = $flow_widget_index;
		$conditions4flows->{_gui_history_ref}                       = $gui_history_ref;
		$conditions4flows->{_has_used_Delete_button}                = $has_used_Delete_button;		
		$conditions4flows->{_has_used_SaveAs_button}                = $has_used_SaveAs_button;
		$conditions4flows->{_has_used_Save_button}                  = $has_used_Save_button;
		$conditions4flows->{_has_used_Save_superflow}               = $has_used_Save_superflow;
#		$conditions4flows->{_has_used_check_code_button}            = $has_used_check_code_button;
		$conditions4flows->{_has_used_open_perl_file_button}        = $has_used_open_perl_file_button;
		$conditions4flows->{_has_used_run_button}                   = $has_used_run_button;
		$conditions4flows->{_is_Delete_file_button}                 = $is_Delete_file_button;		
		$conditions4flows->{_is_Save_button}                        = $is_Save_button;
		$conditions4flows->{_is_SaveAs_button}                      = $is_SaveAs_button;
		$conditions4flows->{_is_SaveAs_file_button}                 = $is_SaveAs_file_button;
#		$conditions4flows->{_is_add2flow_button}                    = $is_add2flow_button;
#		$conditions4flows->{_is_check_code_button}                  = $is_check_code_button;
		$conditions4flows->{_is_delete_from_flow_button}            = $is_delete_from_flow_button;
		$conditions4flows->{_is_delete_whole_flow_button}           = $is_delete_whole_flow_button;
#		$conditions4flows->{_is_dragNdrop}                          = $is_dragNdrop;
		$conditions4flows->{_is_flow_item_up_arrow_button}          = $is_flow_item_up_arrow_button;
		$conditions4flows->{_is_flow_item_down_arrow_button}        = $is_flow_item_down_arrow_button;
		$conditions4flows->{_is_flow_listbox_grey_w}                = $is_flow_listbox_grey_w;
		$conditions4flows->{_is_flow_listbox_pink_w}                = $is_flow_listbox_pink_w;
		$conditions4flows->{_is_flow_listbox_green_w}               = $is_flow_listbox_green_w;
		$conditions4flows->{_is_flow_listbox_blue_w}                = $is_flow_listbox_blue_w;
		$conditions4flows->{_is_flow_listbox_color_w}               = $is_flow_listbox_color_w;
		$conditions4flows->{_is_future_flow_listbox_grey}           = $is_future_flow_listbox_grey;
		$conditions4flows->{_is_future_flow_listbox_pink}           = $is_future_flow_listbox_pink;
		$conditions4flows->{_is_future_flow_listbox_green}          = $is_future_flow_listbox_green;
		$conditions4flows->{_is_future_flow_listbox_blue}           = $is_future_flow_listbox_blue;
		$conditions4flows->{_is_last_flow_index_touched}            = $is_last_flow_index_touched;
		$conditions4flows->{_is_last_flow_index_touched_grey}       = $is_last_flow_index_touched_grey;
		$conditions4flows->{_is_last_flow_index_touched_pink}       = $is_last_flow_index_touched_pink;
		$conditions4flows->{_is_last_flow_index_touched_green}      = $is_last_flow_index_touched_green;
		$conditions4flows->{_is_last_flow_index_touched_blue}       = $is_last_flow_index_touched_blue;
		$conditions4flows->{_is_last_parameter_index_touched_grey}  = $is_last_parameter_index_touched_grey;
		$conditions4flows->{_is_last_parameter_index_touched_pink}  = $is_last_parameter_index_touched_pink;
		$conditions4flows->{_is_last_parameter_index_touched_green} = $is_last_parameter_index_touched_green;
		$conditions4flows->{_is_last_parameter_index_touched_blue}  = $is_last_parameter_index_touched_blue;
		$conditions4flows->{_is_last_parameter_index_touched_color} = $is_last_parameter_index_touched_color;
		$conditions4flows->{_is_open_file_button}                   = $is_open_file_button;
		$conditions4flows->{_is_run_button}                         = $is_run_button;
		$conditions4flows->{_is_moveNdrop_in_flow}                  = $is_moveNdrop_in_flow;
		$conditions4flows->{_is_user_built_flow}                    = $is_user_built_flow;
		$conditions4flows->{_is_select_file_button}                 = $is_select_file_button;
		$conditions4flows->{_is_selected_file_name}                 = $is_selected_file_name;
		$conditions4flows->{_is_selected_path}                      = $is_selected_path;
		$conditions4flows->{_is_sunix_listbox}                      = $is_sunix_listbox;
		$conditions4flows->{_is_new_listbox_selection}              = $is_new_listbox_selection;
		$conditions4flows->{_is_pre_built_superflow}                = $is_pre_built_superflow;
		$conditions4flows->{_is_superflow_select_button}            = $is_superflow_select_button;
		$conditions4flows->{_is_superflow}                          = $is_superflow;           # for deprecation TODO
		$conditions4flows->{_is_moveNdrop_in_flow}                  = $is_moveNdrop_in_flow;
		$conditions4flows->{_is_wipe_plots_button}                  = $is_wipe_plots_button;

		#		$conditions4flows->{_last_flow_color}                       = $last_flow_color;
		$conditions4flows->{_last_flow_index_touched_grey}       = $last_flow_index_touched_grey;
		$conditions4flows->{_last_flow_index_touched_pink}       = $last_flow_index_touched_pink;
		$conditions4flows->{_last_flow_index_touched_green}      = $last_flow_index_touched_green;
		$conditions4flows->{_last_flow_index_touched_blue}       = $last_flow_index_touched_blue;
		$conditions4flows->{_last_parameter_index_touched_grey}  = $last_parameter_index_touched_grey;
		$conditions4flows->{_last_parameter_index_touched_pink}  = $last_parameter_index_touched_pink;
		$conditions4flows->{_last_parameter_index_touched_green} = $last_parameter_index_touched_green;
		$conditions4flows->{_last_parameter_index_touched_blue}  = $last_parameter_index_touched_blue;
		$conditions4flows->{_last_parameter_index_touched_color} = $last_parameter_index_touched_color;
		$conditions4flows->{_last_flow_index_touched}            = $last_flow_index_touched;
		$conditions4flows->{_names_aref}                         = $names_aref;
		$conditions4flows->{_occupied_listbox_aref}              = $occupied_listbox_aref;
		$conditions4flows->{_parameter_values_frame}             = $parameter_values_frame;
		$conditions4flows->{_path}                               = $path;
		$conditions4flows->{_sub_ref}                            = $sub_ref;
		$conditions4flows->{_vacant_listbox_aref}                = $vacant_listbox_aref;
		$conditions4flows->{_values_aref}                        = $values_aref;
		$conditions4flows->{_wipe_plots_button}                  = $wipe_plots_button;

		# print("conditions4flows, get_hash_ref , conditions4flows->{_flowNsuperflow_name_w: $conditions4flows->{_flowNsuperflow_name_w}\n");

		return ($conditions4flows);

	} else {
		print("conditions4flows, get_hash_ref , missing hconditions4flows hash_ref\n");
	}
}

=head2

 25 off  only reset the conditional parameters, not the widgets and other information

=cut

sub reset {
	my ($self) = @_;

	# location within GUI
#	$conditions4flows->{_has_used_check_code_button}     = $false;
	$conditions4flows->{_has_used_run_button}            = $false;
    $conditions4flows->{_is_Delete_file_button}          = $false;
	$conditions4flows->{_is_Save_button}                 = $false;
	$conditions4flows->{_is_SaveAs_file_button}          = $false;
	$conditions4flows->{_is_SaveAs_button}              = $false;	
	$conditions4flows->{_is_add2flow_button}             = $false;
#	$conditions4flows->{_is_check_code_button}           = $false;
	$conditions4flows->{_is_delete_from_flow_button}     = $false;
	$conditions4flows->{_is_delete_whole_flow_button}    = $false;
	$conditions4flows->{_is_dragNdrop}                   = $false;
	$conditions4flows->{_is_flow_item_down_arrow_button} = $false;
	$conditions4flows->{_is_flow_item_up_arrow_button}   = $false;
	$conditions4flows->{_is_flow_listbox_grey_w}         = $false;
	$conditions4flows->{_is_flow_listbox_pink_w}         = $false;
	$conditions4flows->{_is_flow_listbox_green_w}        = $false;
	$conditions4flows->{_is_flow_listbox_blue_w}         = $false;
	$conditions4flows->{_is_flow_listbox_color_w}        = $false;
	$conditions4flows->{_is_open_file_button}            = $false;
	$conditions4flows->{_is_select_file_button}          = $false;
	$conditions4flows->{_is_sunix_listbox}               = $false;
	$conditions4flows->{_is_new_listbox_selection}       = $false;
	$conditions4flows->{_is_superflow_select_button}     = $false;
	$conditions4flows->{_is_run_button}                  = $false;
	$conditions4flows->{_is_pre_built_superflow}         = $false;
	$conditions4flows->{_is_superflow}                   = $false;    # for deprecation TODO
	$conditions4flows->{_is_user_built_flow}             = $false;
	$conditions4flows->{_is_moveNdrop_in_flow}           = $false;
	$conditions4flows->{_is_wipe_plots_button}           = $false;

}

=head2 sub set_flow_color


=cut 

sub set_flow_color {
	my ( $self, $color ) = @_;

	if ($color) {

		$conditions4flows->{_flow_color} = $color;
		$flow_color = $color;                         # export via get_hash_ref

	} else {

		# my $parameter					 			= '_is_flow_listbox_'.$color.'_w';
		# $conditions4flows->{$parameter} 				 = $true;
		print("conditions4flows, set_flow_color, missing color\n");
	}
	return ();
}

=head2 sub set_hash_ref
A private hash that helps
track all past actions in the gui
	
=cut

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {

		$conditions4flows = $hash_ref;

		$Data_menubutton             = $hash_ref->{_Data_menubutton};
		$Open_menubutton             = $hash_ref->{_Open_menubutton};
		$SaveAs_menubutton           = $hash_ref->{_SaveAs_menubutton};
		$add2flow_button_grey        = $hash_ref->{_add2flow_button_grey};
		$add2flow_button_pink        = $hash_ref->{_add2flow_button_pink};
		$add2flow_button_green       = $hash_ref->{_add2flow_button_green};
		$add2flow_button_blue        = $hash_ref->{_add2flow_button_blue};
		$big_stream_name_in          = $hash_ref->{_big_stream_name_in};
		$big_stream_name_out         = $hash_ref->{_big_stream_name_out};
#		$check_buttons_w_aref        = $hash_ref->{_check_buttons_w_aref};
#		$check_code_button           = $hash_ref->{_check_code_button};
		$delete_from_flow_button     = $hash_ref->{_delete_from_flow_button};
		$delete_whole_flow_button    = $hash_ref->{_delete_whole_flow_button};
		$file_menubutton             = $hash_ref->{_file_menubutton};
		$flowNsuperflow_name_w       = $hash_ref->{_flowNsuperflow_name_w};
		$flow_color                  = $hash_ref->{_flow_color};
		$flow_item_down_arrow_button = $hash_ref->{_flow_item_down_arrow_button};
		$flow_item_up_arrow_button   = $hash_ref->{_flow_item_up_arrow_button};
		$flow_listbox_grey_w         = $hash_ref->{_flow_listbox_grey_w};
		$flow_listbox_pink_w         = $hash_ref->{_flow_listbox_pink_w};
		$flow_listbox_green_w        = $hash_ref->{_flow_listbox_green_w};
		$flow_listbox_blue_w         = $hash_ref->{_flow_listbox_blue_w};
		$flow_listbox_color_w        = $hash_ref->{_flow_listbox_color_w};
		$flow_widget_index           = $hash_ref->{_flow_widget_iindex};
		$labels_w_aref               = $hash_ref->{_labels_w_aref};
		$message_w                   = $hash_ref->{_message_w};
		$mw                          = $hash_ref->{_mw};
		$parameter_values_frame      = $hash_ref->{_parameter_values_frame};
		$parameter_value_index       = $hash_ref->{_parameter_value_index};
		$run_button                  = $hash_ref->{_run_button};
		$save_button                 = $hash_ref->{_save_button};
		$values_w_aref               = $hash_ref->{_values_w_aref};
		$wipe_plots_button           = $hash_ref->{_wipe_plots_button};
#		$check_buttons_settings_aref           = $hash_ref->{_check_buttons_settings_aref};
		$dialog_type                           = $hash_ref->{_dialog_type};
		$flow_color                            = $hash_ref->{_flow_color};
		$flow_item_down_arrow_button           = $hash_ref->{_flow_item_down_arrow_button};
		$flow_item_up_arrow_button             = $hash_ref->{_flow_item_up_arrow_button};
		$flow_name_in                          = $hash_ref->{_flow_name_in};
		$flow_name_in_blue                     = $hash_ref->{_flow_name_in_blue};
		$flow_name_in_grey                     = $hash_ref->{_flow_name_in_grey};
		$flow_name_in_green                    = $hash_ref->{_flow_name_in_green};
		$flow_name_in_pink                     = $hash_ref->{_flow_name_in_pink};
		$flow_name_out                         = $hash_ref->{_flow_name_out};
		$flow_name_out_blue                    = $hash_ref->{_flow_name_out_blue};
		$flow_name_out_grey                    = $hash_ref->{_flow_name_out_grey};
		$flow_name_out_green                   = $hash_ref->{_flow_name_out_green};
		$flow_name_out_pink                    = $hash_ref->{_flow_name_out_pink};
		$flow_type                             = $hash_ref->{_flow_type};
		$flow_widget_index                     = $hash_ref->{_flow_widget_index};
		$gui_history_ref                       = $hash_ref->{_gui_history_ref};
#		$has_used_check_code_button            = $hash_ref->{_has_used_check_code_button};
		$has_used_Delete_button                = $hash_ref->{_has_used_Delete_button};
		$has_used_SaveAs_button                = $hash_ref->{_has_used_SaveAs_button};
		$has_used_Save_button                  = $hash_ref->{_has_used_Save_button};
		$has_used_Save_superflow               = $hash_ref->{_has_used_Save_superflow};
		$has_used_open_perl_file_button        = $hash_ref->{_has_used_open_perl_file_button};
		$has_used_run_button                   = $hash_ref->{_has_used_run_button};
		$is_add2flow_button                    = $hash_ref->{_is_add2flow_button};
		$is_Delete_file_button                 = $hash_ref->{_is_Delete_file_button};
		$is_Save_button                        = $hash_ref->{_is_Save_button};
		$is_SaveAs_button                      = $hash_ref->{_is_SaveAs_button};
		$is_SaveAs_file_button                 = $hash_ref->{_is_SaveAs_file_button};
#		$is_check_code_button                  = $hash_ref->{_is_check_code_button};
#		$is_dragNdrop                          = $hash_ref->{_is_dragNdrop};
		$is_delete_from_flow_button            = $hash_ref->{_is_delete_from_flow_button};
		$is_delete_whole_flow_button           = $hash_ref->{_is_delete_whole_flow_button};
		$is_flow_item_down_arrow_button        = $hash_ref->{_is_flow_item_down_arrow_button};
		$is_flow_item_up_arrow_button          = $hash_ref->{_is_flow_item_up_arrow_button};
		$is_flow_listbox_grey_w                = $hash_ref->{_is_flow_listbox_grey_w};
		$is_flow_listbox_pink_w                = $hash_ref->{_is_flow_listbox_pink_w};
		$is_flow_listbox_green_w               = $hash_ref->{_is_flow_listbox_green_w};
		$is_flow_listbox_blue_w                = $hash_ref->{_is_flow_listbox_blue_w};
		$is_flow_listbox_color_w               = $hash_ref->{_is_flow_listbox_color_w};
		$is_future_flow_listbox_grey           = $hash_ref->{_is_future_flow_listbox_grey};
		$is_future_flow_listbox_pink           = $hash_ref->{_is_future_flow_listbox_pink};
		$is_future_flow_listbox_green          = $hash_ref->{_is_future_flow_listbox_green};
		$is_future_flow_listbox_blue           = $hash_ref->{_is_future_flow_listbox_blue};
		$is_last_flow_index_touched_grey       = $hash_ref->{_is_last_flow_index_touched_grey};
		$is_last_flow_index_touched_pink       = $hash_ref->{_is_last_flow_index_touched_pink};
		$is_last_flow_index_touched_green      = $hash_ref->{_is_last_flow_index_touched_green};
		$is_last_flow_index_touched_blue       = $hash_ref->{_is_last_flow_index_touched_blue};
		$is_last_flow_index_touched            = $hash_ref->{_is_last_flow_index_touched};
		$is_last_parameter_index_touched_grey  = $hash_ref->{_is_last_parameter_index_touched_grey};
		$is_last_parameter_index_touched_pink  = $hash_ref->{_is_last_parameter_index_touched_pink};
		$is_last_parameter_index_touched_green = $hash_ref->{_is_last_parameter_index_touched_green};
		$is_last_parameter_index_touched_blue  = $hash_ref->{_is_last_parameter_index_touched_blue};
		$is_open_file_button                   = $hash_ref->{_is_open_file_button};
		$is_run_button                         = $hash_ref->{_is_run_button};
		$is_moveNdrop_in_flow                  = $hash_ref->{_is_moveNdrop_in_flow};
		$is_user_built_flow                    = $hash_ref->{_is_user_built_flow};
		$is_select_file_button                 = $hash_ref->{_is_select_file_button};
		$is_selected_file_name                 = $hash_ref->{_is_selected_file_name};
		$is_selected_path                      = $hash_ref->{_is_selected_path};
		$is_sunix_listbox                      = $hash_ref->{_is_sunix_listbox};
		$is_new_listbox_selection              = $hash_ref->{_is_new_listbox_selection};
		$is_pre_built_superflow                = $hash_ref->{_is_pre_built_superflow};
		$is_superflow_select_button            = $hash_ref->{_is_superflow_select_button};
		$is_superflow                          = $hash_ref->{_is_superflow};           # for deprecation TODO
		$is_moveNdrop_in_flow                  = $hash_ref->{_is_moveNdrop_in_flow};
		$is_wipe_plots_button                  = $hash_ref->{_is_wipe_plots_button};
		#		$last_flow_color                       = $hash_ref->{_last_flow_color};
		$last_flow_index_touched_grey       = $hash_ref->{_last_flow_index_touched_grey};
		$last_flow_index_touched_pink       = $hash_ref->{_last_flow_index_touched_pink};
		$last_flow_index_touched_green      = $hash_ref->{_last_flow_index_touched_green};
		$last_flow_index_touched_blue       = $hash_ref->{_last_flow_index_touched_blue};
		$last_flow_index_touched            = $hash_ref->{_last_flow_index_touched};
		$last_parameter_index_touched_grey  = $hash_ref->{_last_parameter_index_touched_grey};
		$last_parameter_index_touched_pink  = $hash_ref->{_last_parameter_index_touched_pink};
		$last_parameter_index_touched_green = $hash_ref->{_last_parameter_index_touched_green};
		$last_parameter_index_touched_blue  = $hash_ref->{_last_parameter_index_touched_blue};
		$last_parameter_index_touched_color = $hash_ref->{_last_parameter_index_touched_color};
		$occupied_listbox_aref              = $hash_ref->{_occupied_listbox_aref};
		$path                               = $hash_ref->{_path};
		$sub_ref                            = $hash_ref->{_sub_ref};
		$names_aref                         = $hash_ref->{_names_aref};                           # equiv labels
		$vacant_listbox_aref                = $hash_ref->{_vacant_listbox_aref};
		$values_aref                        = $hash_ref->{_values_aref};
		$wipe_plots_button                  = $hash_ref->{_wipe_plots_button};

	} else {

		print("conditions4flows, set_hash_ref , missing hash_ref\n");
	}
	return ();
}

#=head2
#
#
#=cut
#
#sub set4_check_code_button {
#	my ($self) = @_;
#
#	# _conditions	->reset();
#	# print("1. conditions4flows, set4end_of_check_code_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
#	# location within GUI
#	$conditions4flows->{_has_used_check_code_button} = $true;
#
#	# for potential export via get_hash_ref
#	$has_used_check_code_button = $true;
#
#	return ();
#}

=head2 sub  set4FileDialog_Delete_end 


=cut

sub set4FileDialog_Delete_end {
	my ($self) = @_;

	$conditions4flows->{_is_Delete_file_button}  = $false;
	$conditions4flows->{_is_neutral_flow}        = $false;
	$conditions4flows->{_has_used_Delete_button} = $true;

	# for potential export via get_hash_ref
	$is_Delete_file_button  = $false;
	$is_neutral_flow        = $false;
	$has_used_Delete_button = $true;

	# clean path
	$conditions4flows->{_path}						= '';
#	 print("conditions4flows,set4FileDialog_Delete_end
#	$conditions4flows->{_is_Delete_file_button}\n");
	return ();
}


=head2 sub  set4FileDialog_Delete_start 


=cut

sub set4FileDialog_Delete_start {
	my ($self) = @_;

	$conditions4flows->{_is_Delete_file_button}  = $true;
	$conditions4flows->{_is_neutral_flow}        = $true;	
	$conditions4flows->{_has_used_Delete_button} = $false;

	# for potential export via get_hash_ref
	$is_Delete_file_button  = $true;
	$is_neutral_flow        = $true;
	$has_used_Delete_button = $false;

	# clean path
	$conditions4flows->{_path}						= '';
#	 print("conditions4flows,set4FileDialog_Delete_start
#	$conditions4flows->{_is_Delete_file_button}\n");
	return ();
}
=head2 sub  set4FileDialog_SaveAs_end 


=cut

sub set4FileDialog_SaveAs_end {
	my ($self) = @_;

	$conditions4flows->{_is_SaveAs_file_button}  = $false;
	$conditions4flows->{_has_used_SaveAs_button} = $true;

	# for potential export via get_hash_ref
	$is_SaveAs_file_button  = $false;
	$has_used_SaveAs_button = $true;

	# clean path
	# $conditions4flows->{_path}						= '';
	# print("conditions4flows,set4FileDialog_SaveAs_end
	# $conditions4flows->{_is_SaveAs_file_button}\n");
	return ();
}

=head2 sub  set4FileDialog_open_end


=cut

sub set4FileDialog_open_end {
	my ($self) = @_;

	$conditions4flows->{_is_open_file_button} = $false;

	# for potential export via get_hash_ref
	$is_open_file_button = $false;

	# print("conditions4flows,set4FileDialog_open_end  $conditions4flows->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_perl_file_end


=cut

sub set4FileDialog_open_perl_file_end {
	my ($self) = @_;

	$conditions4flows->{_is_open_file_button}            = $false;
	$conditions4flows->{_has_used_open_perl_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button            = $false;
	$has_used_open_perl_file_button = $true;

	# print("conditions4flows,set4FileDialog_open_perl_file_end  $conditions4flows->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_perl_file_fail


=cut

sub set4FileDialog_open_perl_file_fail {
	my ($self) = @_;

	$conditions4flows->{_is_open_file_button}            = $false;
	$conditions4flows->{_has_used_open_perl_file_button} = $false;

	# for potential export via get_hash_ref
	$is_open_file_button            = $false;
	$has_used_open_perl_file_button = $false;

	# print("conditions4flows,set4FileDialog_open_perl_file_fail  $conditions4flows->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_start


=cut

sub set4FileDialog_open_start {

	my ($self) = @_;

	$conditions4flows->{_is_open_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button = $true;

	# print("conditions4flows,set4FileDialog_open_start _is_open_file_button}:  $conditions4flows->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_perl_file_start


=cut

sub set4FileDialog_open_perl_file_start {

	my ($self) = @_;

	$conditions4flows->{_is_open_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button = $true;

	# print("conditions4flows,set4FileDialog_open_perl_file_start _is_open_file_button}:  $conditions4flows->{_is_open_file_button}\n");

	return ();
}

=head2


=cut

sub set4FileDialog_SaveAs_start {
	my ($self) = @_;

	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	$conditions4flows->{_is_SaveAs_file_button} = $true;
	$conditions4flows->{_is_SaveAs_button}      = $true;

	# for potential export via get_hash_ref
	$is_SaveAs_file_button = $true;
	$is_SaveAs_button      = $true;

	if ( $conditions4flows->{_flow_type} eq $flow_type_h->{_user_built} ) {
		$conditions4flows->{_is_user_built_flow}     = $true;
		$conditions4flows->{_is_pre_built_superflow} = $false;

		# for potential export via get_hash_ref
		$is_user_built_flow     = $true;
		$is_pre_built_superflow = $false;

	} elsif ( $conditions4flows->{_flow_type} eq $flow_type_h->{_pre_built_superflow} ) {

		$conditions4flows->{_user_built_flow}        = $false;
		$conditions4flows->{_is_pre_built_superflow} = $true;

		# for potential export via get_hash_ref
		$is_user_built_flow     = $false;
		$is_pre_built_superflow = $true;
	}

	# print("conditions4flows,set4FileDialog_SaveAs_start
	# $conditions4flows->{_is_SaveAs_file_button}\n");
	return ();
}

=head2


=cut

sub set4_Save_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4flows, set4end_of_save_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4flows->{_has_used_Save_button} = $true;

	return ();
}

=head2 sub set4_end_of_SaveAs_button


=cut

sub set4_end_of_SaveAs_button {
	my ($self) = @_;

	$conditions4flows->{_has_used_SaveAs_button} = $true;
	$conditions4flows->{_is_SaveAs_button}       = $false;

	_reset_is_flow_listbox_color_w();

	if ( $conditions4flows->{_flow_color} eq 'grey' ) {
		$conditions4flows->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'pink' ) {
		$conditions4flows->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'green' ) {
		$conditions4flows->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'blue' ) {
		$conditions4flows->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4flows->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4flows,set4start_of_run_button Running a pre-built superflow\n");
		# NADA

	} else {
		print("2 conditions4flows,set4start_of_run_button missing color \n");
	}
	return ();

}

=head2 sub set4_start_of_SaveAs_button


=cut

sub set4_start_of_SaveAs_button {
	my ($self) = @_;

	$conditions4flows->{_is_SaveAs_button} = $true;

	return ();
}

#=head2
#
#
#=cut
#
#sub set4end_of_check_code_button {
#	my ($self) = @_;
#
#	# _conditions	->reset();
#	# print("1. conditions4flows, set4end_of_check_code_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
#	# location within GUI
#	$conditions4flows->{_is_check_code_button} = $false;
#
#	return ();
#}

=head2


=cut

sub set4end_of_SaveAs_button {
	my ($self) = @_;

	$conditions4flows->{_is_SaveAs_button}       = $false;
	$conditions4flows->{_has_used_SaveAs_button} = $true;
	return ();
}

#=head2
#
#
#=cut
#
#sub set4start_of_check_code_button {
#	my ($self) = @_;
#
#	# _conditions	->reset();
#	# print("1. conditions4flows, set4start_of_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
#	# location within GUI
#	$conditions4flows->{_is_check_code_button}       = $true;
#	$conditions4flows->{_has_used_check_code_button} = $false;
#
#	return ();
#}

=head2 sub set4end_of_flow_item_up_arrow_button 

	when the arrow that moves flow items up a list is clicked

=cut

sub set4end_of_flow_item_up_arrow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		$conditions4flows->{_is_flow_item_up_arrow_button} = $true;
		_set_flow_color($color);

		# from color create general keys and assign values to those keys (text names)
		# from color generalize which colored flow is being used and set it true
		# save copies of values for reassignment during get_hash_ref call from outside modules
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';

		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;
		$conditions4flows->{_is_user_built_flow} = $true;

		$conditions4flows->{_flow_listbox_color_w} = $conditions4flows->{$flow_listbox_color_w_key};
		$flow_listbox_color_w = $conditions4flows->{$flow_listbox_color_w_key};

	} else {
		print("conditions4flows, set4end_of_flow_item_up_arrow_button, no color: $color\n");
	}

	return ();
}

#=head2 sub set4end_of_wipe_plots_button
#
#	when the arrow that moves flow items up a list is clicked
#
#=cut
#
#sub set4end_of_wipe_plots_button {
#	my ( $self, $color ) = @_;
#
#	if ($color) {
#		_reset();
#
#		$conditions4flows->{_is_wipe_plots_button} = $true;
#		_set_flow_color($color);
#
## from color create general keys and assign values to those keys (text names)
## from color generalize which colored flow is being used and set it true
## save copies of values for reassignment during get_hash_ref call from outside modules
#		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
#		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
#
#		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;
#		$conditions4flows->{_is_user_built_flow} = $true;
#
#		$conditions4flows->{_flow_listbox_color_w} =
#			$conditions4flows->{$flow_listbox_color_w_key};
#		$flow_listbox_color_w = $conditions4flows->{$flow_listbox_color_w_key};
#
#	}
#	else {
#		print(
#			"conditions4flows, set4end_of_wipe_plots_button, no color: $color\n"
#		);
#	}
#
#	return ();
#}

=head2

   location within GUI
   
   foreach my $key (sort keys %$conditions4flows) {
     print ("conditions4flows user,set4end_of_flow_select,key is $key, value is $conditions4flows->{$key}\n");
   }
   
   if an item within a user-built list of programs is selected then 
   the following options are set to be true--they can now be activated from the GUI
   Also the color of the flow is maintained
   

=cut

sub set4end_of_flow_select {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();
		_reset_is_flow_listbox_color_w();
		_set_flow_color($color);

		# my $is_flow_listbox_color_w_key      	= '_is_flow_listbox_'.$color.'_w';
		# print("conditions4flows, set4end_of_flow_select, color:$color\n");
		# print("1. conditions4flows, set4end_of_flow_select,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
		# print("1. conditions4flows, set4end_of_flow_select, is_flow_listbox_color_w: $is_flow_listbox_color_w \n");
		# $conditions4flows->{$is_flow_listbox_color_w_key}			= $true;
		# my $ans = $conditions4flows->{$is_flow_listbox_color_w_key};
		# print("1. conditions4flows, set4end_of_flow_select, is_flow_listbox_color_w: $ans is EMPTY\n");

		$conditions4flows->{_flow_color}                  = $color;
		$conditions4flows->{_is_delete_from_flow_button}  = $true;
		$conditions4flows->{_is_delete_whole_flow_button} = $true;
		$conditions4flows->{_is_flow_listbox_color_w}     = $true;

		$conditions4flows->{_flow_item_down_arrow_button} = $true;
		$conditions4flows->{_flow_item_up_arrow_button}   = $true;

		# Because the flow is selected automatically without user clicking,
		# as the case of when a perl flow has been read in, then
		# at least the grey flow listbox will have been touched
		# which is not the case when flow_select is directly chosen
		# Note that color_flow->_flow_select points to flow_select, so do not complicate yourself
		# and place these requirements into _flow_select as well
		if ( $color eq 'grey' ) {

			$conditions4flows->{_is_flow_listbox_grey_w} = $true;

			$conditions4flows->{_is_last_flow_index_touched_grey}      = $true;
			$conditions4flows->{_is_last_parameter_index_touched_grey} = $true;

			# for export
			$is_flow_listbox_grey_w                = $true;
			$is_last_flow_index_touched_grey       = $true;
			$is_last_parameter_index_touched_grey  = $true;
			$is_last_parameter_index_touched_color = $true;

			# print("conditions4flows, set4end_of_flow_select,is_last_parameter_index_touched_grey=$is_last_parameter_index_touched_grey\n");
			# print("conditions4flows, set4end_of_flow_select,is_last_flow_index_touched_grey=$is_last_flow_index_touched_grey\n");

		} elsif ( $color eq 'pink' ) {

			$conditions4flows->{_is_flow_listbox_pink_w} = $true;

			# for export
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {

			$conditions4flows->{_is_flow_listbox_green_w} = $true;

			# for export
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {

			$conditions4flows->{_is_flow_listbox_blue_w} = $true;

			# for export
			$is_flow_listbox_blue_w = $true;

		} else {
			print("conditions4flows, set4end_of_flow_select , color missing: $color\n");
		}

	} else {
		print("conditions4flows, set4end_of_flow_select , color missing: $color\n");
	}

	#		my $ans = $conditions4flows->{$is_flow_listbox_color_w};
	#	   	print("conditions4flows, set4end_of_flow_select, color:$color\n");
	#   		print("conditions4flows, set4end_of_flow_select, is_flow_listbox_color_w 'grey pink green or blue'_w: $ans \n");

	return ();
}

=head2 sub set4end_of_run_button

location within GUI 

	sets 
	conditions4flows

=cut

sub set4end_of_run_button {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button}           = $false;
	$conditions4flows->{_has_used_run_button}     = $false;
	$conditions4flows->{_has_used_Save_button}    = $false;
	$conditions4flows->{_has_used_Save_superflow} = $false;
	$conditions4flows->{_last_flow_index_touched} = -1;

	# for potential export
	$has_used_run_button     = $false;
	$is_run_button           = $false;
	$has_used_Save_button    = $false;    # allows re-use of run_button
	$has_used_Save_superflow = $false;    # allows re-use of run_button

	# the last program that was touched is cancelled out
	$last_flow_index_touched = -1;

	return ();
}

=head2 sub set4end_of_run_superflow

location within GUI 

	sets 
	conditions4flows

=cut

sub set4end_of_run_superflow {

	# location within GUI
	$conditions4flows->{_is_run_button}           = $false;
	$conditions4flows->{_has_used_Save_superflow} = $true;

	# for potential export
	$is_run_button           = $false;
	$has_used_Save_superflow = $true;    # allows re-use of run_button

	return ();
}

=head2


=cut

sub set4start_of_Save_button {
	my ($self) = @_;

	# print("1. conditions4flows, set4start_of_Save_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4flows->{_is_Save_button}       = $true;
	$conditions4flows->{_has_used_Save_button} = $false;

	# for potential export
	$is_Save_button       = $true;
	$has_used_Save_button = $false;

	return ();
}

=head2


=cut

sub set4start_of_SaveAs_button {
	my ($self) = @_;

	# print("1. conditions4flows, set4start_of_Save_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4flows->{_is_SaveAs_button}       = $true;
	$conditions4flows->{_has_used_SaveAs_button} = $false;

	# for potential export
	$is_SaveAs_button       = $true;
	$has_used_SaveAs_button = $false;

	return ();
}

sub set4end_of_sunix_select {
	my ($self) = @_;

	# _set_gui_widgets();

	$add2flow_button_grey->configure( -state => 'normal', );
	$add2flow_button_pink->configure( -state => 'normal', );
	$add2flow_button_green->configure( -state => 'normal', );
	$add2flow_button_blue->configure( -state => 'normal', );

	# print ("conditions4flows,set4end_of_sunix_select, prog_name: ${$conditions4flows->{_prog_name_sref}}\n");

	#   	$conditions4flows->{_is_flow_listbox_grey_w}			= $false;
	#   	$conditions4flows->{_is_flow_listbox_pink_w}			= $false;
	#   	$conditions4flows->{_is_flow_listbox_green_w}			= $false;
	#   	$conditions4flows->{_is_flow_listbox_blue_w}			= $false;
	#   	$conditions4flows->{_is_flow_listbox_color_w}			= $false;
	# $conditions4flows->{_is_add2flow_button} = $true; LOOK

	# for export
	#   	$is_flow_listbox_grey_w								= $false;
	#   	$is_flow_listbox_pink_w								= $false;
	#   	$is_flow_listbox_green_w							= $false;
	#   	$is_flow_listbox_blue_w								= $false;
	#   	$is_flow_listbox_color_w							= $false;
	# $is_add2flow_button = $true; LOOK

	# $conditions4flows->{_is_sunix_listbox} = $false;
}

=head2


=cut

sub set4end_of_Save_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4flows, set4end_of_save_button,last left listbox flow program touched had index = $conditions4flows->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4flows->{_is_Save_button}                 = $false;
	$conditions4flows->{_has_used_Save_button}           = $true;
	$conditions4flows->{_has_used_SaveAs_button}         = $false;
	$conditions4flows->{_has_used_open_perl_file_button} = $false;

	# for export
	$is_Save_button       = $false;    # a reset
	$has_used_Save_button = $true;

	# N.B. Save can only be used if SaveAs is true
	# But, after Save is used, reset SaveAs to false
	$has_used_SaveAs_button         = $false;
	$has_used_open_perl_file_button = $false;

	_reset_is_flow_listbox_color_w();

	if ( $conditions4flows->{_flow_color} eq 'grey' ) {
		$conditions4flows->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'pink' ) {
		$conditions4flows->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'green' ) {
		$conditions4flows->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'blue' ) {
		$conditions4flows->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4flows->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4flows,set4end_of_save_button Running a pre-built superflow NADA\n");

	} else {
		print("2 conditions4flows,set4start_of_run_button missing color \n");
	}
	return ();

}

=head2 sub set4user_built_flow_close_path_end
inherited from set4superflow_close_path_end 

=cut

sub set4user_built_flow_close_path_end {
	my ($self) = @_;

	# print("conditions4flows, set4user_built_flow_close_path_end OK \n");
	# Forces a Save before the next Run
	$conditions4flows->{_has_used_Save_button} = $false;

	# for potential export
	$has_used_Save_button = $false;

	# Allows user to open a user-built perl flow
	$Open_menubutton->configure( -state => 'normal', );

	return ();
}

=head2 sub set4user_built_open_path_end
inherited from
set4superflow_open_path_end


=cut

sub set4user_built_flow_open_path_end {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_open_path_end OK \n");
	$conditions4flows->{_is_user_built_flow} = $true;

	# for potential export
	$is_user_built_flow = $true;

	return ();
}

=head2 sub _get_num_listboxes_occupied


=cut

sub _get_num_listboxes_occupied {
	my ($self) = @_;

	# print("1 conditions4flows, _get_num_listboxes_occupied: @{$conditions4flows->{_occupied_listbox_aref}} \n");
	if ( $conditions4flows->{_occupied_listbox_aref} ) {

		my $number
			= @{ $conditions4flows->{_occupied_listbox_aref} }[0]
			+ @{ $conditions4flows->{_occupied_listbox_aref} }[1]
			+ @{ $conditions4flows->{_occupied_listbox_aref} }[2]
			+ @{ $conditions4flows->{_occupied_listbox_aref} }[3];

		# print("2 conditions4flows, _get_num_listboxes_occupied= $number \n");
		return ($number);

	} else {
		print("2 conditions4flows, get_num_listboxes_occupied: missing conditions4flows->{_occupied_listbox_aref} \n");
	}
}

=head2  sub set_defaults4end_of_delete_whole_flow_button 

	when all items are removed from a flow listbox
	the following conditions are set
	

=cut

sub set_defaults4end_of_delete_whole_flow_button {
	my ($self) = @_;

	my $color = _get_flow_color();

	if (   $color eq 'grey'
		|| $color eq 'pink'
		|| $color eq 'green'
		|| $color eq 'blue' ) {

		# the last program that was touched is cancelled out
		$last_flow_index_touched = -1;

		$flow_item_down_arrow_button->configure( -state => 'disabled', );
		$flow_item_up_arrow_button->configure( -state => 'disabled', );
		$delete_from_flow_button->configure( -state => 'disabled', );
		$delete_whole_flow_button->configure( -state => 'disabled', );

	} else {
		print("conditions4flows, set_defaults4delete_whole_flow_button, color missing: $color\n");
	}

	if ( $color eq 'grey' ) {

		$conditions4flows->{_is_flow_listbox_grey_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[0] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[0]   = $true;

		# turn off flow listbox
		$flow_listbox_grey_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_grey} = $empty_string;

		# for export
		$is_flow_listbox_grey_w = $false;
		$flow_name_out_grey     = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_grey = $false;

	} elsif ( $color eq 'pink' ) {

		$conditions4flows->{_is_flow_listbox_pink_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[1] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[1]   = $true;

		# turn off flow -listbox
		$flow_listbox_pink_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_pink} = $empty_string;

		# for export
		$is_flow_listbox_pink_w = $false;
		$flow_name_out_pink          = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_pink = $false;

	} elsif ( $color eq 'green' ) {

		$conditions4flows->{_is_flow_listbox_green_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[2] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[2]   = $true;

		# turn off flow -listbox
		$flow_listbox_green_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_green} = $empty_string;

		# for export
		$is_flow_listbox_green_w = $false;
		$flow_name_out_green           = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_green = $false;

	} elsif ( $color eq 'blue' ) {

		$conditions4flows->{_is_flow_listbox_blue_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[3] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[3]   = $true;

		# turn off flow -listbox
		$flow_listbox_blue_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_blue} = $empty_string;

		# for export
		$is_flow_listbox_blue_w = $false;
		$flow_name_out_blue          = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_blue = $false;

	} else {
		print("conditions4flows, set_defaults4delete_whole_flow_buttonset, color missing: $color\n");
	}

	my $number = _get_num_listboxes_occupied();

	# print("conditions4flows, set_defaults4delete_whole_flow_button, number of list boxes occupied=$number\n");

	# because the last item in last listbox is deleted
	# print("conditions4flows, set_defaults4delete_whole_flow_button, if number < 0 remove this if statement\n");
	# turn off delete button
	$delete_from_flow_button->configure( -state => 'disabled', );

	# turn off delete whole flow button
	$delete_whole_flow_button->configure( -state => 'disabled', );

	# turn off up-arrow
	$flow_item_up_arrow_button->configure( -state => 'disabled', );

	# turn off down_arrow
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# turn off run button
	#		$run_button->configure( -state => 'disabled' );

	#		# turn off SaveAs menu button
	#		$SaveAs_menubutton->configure( -state => 'disabled' );

	#		# turn off Data menu button
	#		$Data_menubutton->configure( -state => 'disabled' );

	#		# turn on Flow menu button
	$Open_menubutton->configure( -state => 'normal' );

	# turn off save button
	#		$save_button->configure( -state => 'disabled' );

	# turn off  check_code_button
#	$check_code_button->configure( -state => 'disabled' );

	$conditions4flows->{_is_flow_listbox_color_w}        = $false;
	$conditions4flows->{_is_user_built_flow}             = $false;
	$conditions4flows->{_is_sunix_listbox}               = $false;
	$conditions4flows->{_is_delete_from_flow_button}     = $false;
	$conditions4flows->{_is_delete_whole_flow_button}    = $false;
	$conditions4flows->{_is_flow_item_down_arrow_button} = $false;
	$conditions4flows->{_is_flow_item_up_arrow_button}   = $false;

	# for export
	$is_delete_from_flow_button     = $false;
	$is_delete_whole_flow_button    = $false;
	$is_flow_item_down_arrow_button = $false;
	$is_flow_item_up_arrow_button   = $false;

	$is_flow_listbox_color_w = $false;
	$is_sunix_listbox        = $false;
	$is_user_built_flow      = $false;

	return ();
}

=head2  sub set_defaults4last_delete_from_flow_button 

	when all items are removed from a flow listbox
	the following conditions are set
	

=cut

sub set_defaults4last_delete_from_flow_button {
	my ($self) = @_;

	my $color = _get_flow_color();

	if (   $color eq 'grey'
		|| $color eq 'pink'
		|| $color eq 'green'
		|| $color eq 'blue' ) {

		# the last program that was touched is cancelled out
		$last_flow_index_touched = -1;

		$flow_item_down_arrow_button->configure( -state => 'disabled', );
		$flow_item_up_arrow_button->configure( -state => 'disabled', );
		$delete_whole_flow_button->configure( -state => 'disabled', );
	} else {
		print("conditions4flows, set_defaults4last_delete_from_flow_button, color missing: $color\n");
	}

	if ( $color eq 'grey' ) {

		$conditions4flows->{_is_flow_listbox_grey_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[0] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[0]   = $true;

		# turn off flow listbox
		$flow_listbox_grey_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_grey} = $empty_string;

		# for export
		$is_flow_listbox_grey_w = $false;
		$flow_name_out_grey          = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_grey = $false;

	} elsif ( $color eq 'pink' ) {

		$conditions4flows->{_is_flow_listbox_pink_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[1] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[1]   = $true;

		# turn off flow -listbox
		$flow_listbox_pink_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_pink} = $empty_string;

		# for export
		$is_flow_listbox_pink_w = $false;
		$flow_name_out_pink          = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_pink = $false;

	} elsif ( $color eq 'green' ) {

		$conditions4flows->{_is_flow_listbox_green_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[2] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[2]   = $true;

		# turn off flow -listbox
		$flow_listbox_green_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_green} = $empty_string;

		# for export
		$is_flow_listbox_green_w = $false;
		$flow_name_out_green           = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_green = $false;

	} elsif ( $color eq 'blue' ) {

		$conditions4flows->{_is_flow_listbox_blue_w} = $false;
		@{ $conditions4flows->{_occupied_listbox_aref} }[3] = $false;
		@{ $conditions4flows->{_vacant_listbox_aref} }[3]   = $true;

		# turn off flow -listbox
		$flow_listbox_blue_w->configure( -state => 'disabled', );

		# name is removed from the namespace
		$conditions4flows->{_flow_name_out_blue} = $empty_string;

		# for export
		$is_flow_listbox_blue_w = $false;
		$flow_name_out_blue          = $empty_string;

		# the last program that was touched is cancelled out
		$is_last_flow_index_touched_blue = $false;

	} else {
		print("conditions4flows, set_defaults4last_delete_from_flow_buttonset, color missing: $color\n");
	}

	my $number = _get_num_listboxes_occupied();

	# print("conditions4flows, set_defaults4last_delete_from_flow_button, number=$number\n");

	# when last item in last listbox is deleted
	if ( $number < 0 ) {

		# turn off delete button
		$delete_from_flow_button->configure( -state => 'disabled', );

		# turn off whole-flow delete button
		$delete_whole_flow_button->configure( -state => 'disabled', );

		# turn off up-arrow
		$flow_item_up_arrow_button->configure( -state => 'disabled', );

		# turn off down_arrow
		$flow_item_down_arrow_button->configure( -state => 'disabled', );

		# turn off run button
		$run_button->configure( -state => 'disabled' );

		$SaveAs_menubutton->configure( -state => 'disabled' );

		# turn off Data menu button
#		$Data_menubutton->configure( -state => 'disabled' );

		# turn off Flow menu button
		$Open_menubutton->configure( -state => 'normal' );

		# turn off save button
		$save_button->configure( -state => 'disabled' );

		# turn off  check_code_button
#		$check_code_button->configure( -state => 'disabled' );
	} else {

		# NADA print("conditions4flows,set_defaults4last_delete_from_flow_button, not at the last listbox yet\n");
	}

	$conditions4flows->{_is_flow_listbox_color_w}        = $false;
	$conditions4flows->{_is_user_built_flow}             = $false;
	$conditions4flows->{_is_sunix_listbox}               = $false;
	$conditions4flows->{_is_delete_from_flow_button}     = $false;
	$conditions4flows->{_is_delete_whole_flow_button}    = $false;
	$conditions4flows->{_is_flow_item_down_arrow_button} = $false;
	$conditions4flows->{_is_flow_item_up_arrow_button}   = $false;

	# for export
	$is_delete_from_flow_button     = $false;
	$is_delete_whole_flow_button    = $false;
	$is_flow_item_down_arrow_button = $false;
	$is_flow_item_up_arrow_button   = $false;

	$is_flow_listbox_color_w = $false;
	$is_sunix_listbox        = $false;
	$is_user_built_flow      = $false;

	return ();
}

=head2 sub set4run_button 

is used by both pre-built sueprflows and
user-built flows
look at set4start_of_run_button and set4end_of_run_button

legacy?

=cut

sub set4run_button {
	my ($self) = @_;

	# _reset();
	# location within GUI
	$conditions4flows->{_is_run_button}       = $true;
	$conditions4flows->{_has_used_run_button} = $true;

	# reset save and SaveAs options because
	# file must be saved before running, always
	$conditions4flows->{_has_used_SaveAs_button}         = $false;
	$conditions4flows->{_has_used_Save_button}           = $false;
	$conditions4flows->{_has_used_Save_superflow}        = $false;
	$conditions4flows->{_has_used_open_perl_file_button} = $false;

	# for export to calling module via get_hash_ref
	$is_run_button       = $true;
	$has_used_run_button = $true;

	$has_used_SaveAs_button         = $false;
	$has_used_Save_button           = $false;
	$has_used_Save_superflow        = $false;
	$has_used_open_perl_file_button = $false;

	return ();

}

=head2 sub set4run_button_end

location within GUI 

	sets 
		$conditions4flows
		
		legacy?
		look at set4start_of_run_button and set4end_of_run_button

=cut

sub set4run_button_end {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button}       = $false;
	$conditions4flows->{_has_used_run_button} = $false;

	$is_run_button       = $false;
	$has_used_run_button = $false;

	return ();
}

=head2

	location within GUI on first clicking delete button

=cut

sub set_defaults4start_of_delete_from_flow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		# print("conditions4flows, set_defaults_4start_of_delete_from_flow_button, color: $color\n");
		$conditions4flows->{_is_delete_from_flow_button} = $true;
		$is_delete_from_flow_button = $true;
		_set_flow_color($color);

		# from color generalize which colored flow is being used and set it true
		# from color create general keys and assign values to those keys (text names)
		# save copies of values for reassignment during get_hash_ref call from outside modules

		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';    # true or false
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';       # value a widget hash
		$conditions4flows->{_flow_listbox_color_w} = $conditions4flows->{$flow_listbox_color_w_key};
		$conditions4flows->{_is_user_built_flow}   = $true;

		# set treu or false values for a colored flow ( the reset are assumed = 0)
		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;

		# set up for get_hash_ref call from outside module
		$is_user_built_flow      = $true;
		$is_flow_listbox_color_w = $true;

		if ( $color eq 'grey' ) {
			$flow_listbox_grey_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_grey_w = $true;

		} elsif ( $color eq 'pink' ) {
			$flow_listbox_pink_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {
			$flow_listbox_green_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {
			$flow_listbox_blue_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_blue_w = $true;
		}

		#   				print("conditions4flows, set_defaults_4start_of_delete_from_flow_button, conditions4flows->$is_flow_listbox_color_w_key: $is_flow_listbox_color_w\n");
		#   				print("conditions4flows, set_defaults_4start_of_delete_from_flow_button, conditions4flows->$flow_listbox_color_w_key: $flow_listbox_color_w\n");
		#   				print("conditions4flows, set_defaults_4start_of_delete_from_flow_button, _is_flow_listbox_color_w_key: $is_flow_listbox_color_w_key\n");
		#   				print("conditions4flows, set_defaults_4start_of_delete_from_flow_button, flow_listbox_color_w_key: $flow_listbox_color_w_key\n");

	} else {
		print("conditions4flows, set_defaults4start_of_delete_from_flow_button, no color: $color\n");
	}

	return ();
}

=head2 sub set_defaults4start_of_delete_whole_flow_button 

	location within GUI on clicking whole-flow-delete button

=cut

sub set_defaults4start_of_delete_whole_flow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		# print("conditions4flows, set_defaults_4start_of_delete_whole_flow_button, color: $color\n");
		$conditions4flows->{_is_delete_whole_flow_button} = $true;
		$is_delete_whole_flow_button = $true;
		_set_flow_color($color);

		# use color to generalize which colored flow is being used and set it true
		# from color create general keys and assign values to those keys (text names)
		# save copies of values for reassignment during get_hash_ref call from outside modules

		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';    # true or false
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';       # value a widget hash
		$conditions4flows->{_flow_listbox_color_w} = $conditions4flows->{$flow_listbox_color_w_key};
		$conditions4flows->{_is_user_built_flow}   = $true;

		# set true or false values for a colored flow ( the rest are assumed = 0)
		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;

		# set up for get_hash_ref call from outside module
		$is_user_built_flow      = $true;
		$is_flow_listbox_color_w = $true;

		if ( $color eq 'grey' ) {

			$flow_listbox_grey_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_grey_w = $true;

		} elsif ( $color eq 'pink' ) {

			$flow_listbox_pink_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {

			$flow_listbox_green_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {

			$flow_listbox_blue_w    = $conditions4flows->{$flow_listbox_color_w_key};
			$is_flow_listbox_blue_w = $true;
		}

	} else {
		print("conditions4flows, set_defaults4start_of_delete_whole_flow_button, no color: $color\n");
	}

	return ();
}

=head2

	when the arrow that moves flow items up a list is clicked

=cut

sub set4start_of_flow_item_up_arrow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		$conditions4flows->{_is_flow_item_up_arrow_button} = $true;
		_set_flow_color($color);
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;
		$conditions4flows->{_is_user_built_flow} = $true;

		# set up for get_hash_ref call from outside module
		$is_user_built_flow      = $true;
		$is_flow_listbox_color_w = $true;

	} else {
		print("conditions4flows, set4start_of_flow_item_up_arrow_button, no color: $color\n");
	}

	return ();
}

#=head2
#
#	when the lightning cartoon that mzamps background images is clicked
#
#=cut
#
#sub set4start_of_wipe_plots_button {
#	my ( $self, $color ) = @_;
#
#	if ($color) {
#		_reset();
#
#		$conditions4flows->{_is_wipe_plots_button} = $true;
#		_set_flow_color($color);
#		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
#		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;
#		$conditions4flows->{_is_user_built_flow} = $true;
#
#		# set up for get_hash_ref call from outside module
#		$is_user_built_flow      = $true;
#		$is_flow_listbox_color_w = $true;
#
#	}
#	else {
#		print(
#			"conditions4flows, set4start_of_wipe_plots_button, no color: $color\n"
#		);
#	}
#
#	return ();
#}

=head2 sub set_defaults_4start_of_flow_select

take focus of the first Entry button/Value
for all listboxes
returns only a few parameters
All others have been reset to false

dynamically change the color
and associated logical hash values

WARNING, _reset may make color disappear

=cut

sub set_defaults_4start_of_flow_select {
	my ( $self, $color ) = @_;

	_reset();

	if ($color) {
		_set_flow_color($color);
		my $flow_listbox_color_w_key = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt = 'flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w     = $conditions4flows->{$flow_listbox_color_w_key};

		my $value2 = '_is_flow_listbox_' . $color . '_w';
		$conditions4flows->{$value2} = $true;
		$conditions4flows->{_is_flow_listbox_color_w} = $true;

		# print("conditions4flows, set_defaults_4start_of_flow_select , color:$color; flow_listbox_color_w =$conditions4flows->{$flow_listbox_color_w_key}\n");
		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);
		_set_flow_listbox_last_touched_w($flow_listbox_color_w);

		# print("conditions4flows, set_defaults_4start_of_flow_select , _set_flow_listbox_last_touched_w\n");

		#		# location within GUI
		#		if ( $color eq 'grey' ) {
		#
		#			$conditions4flows->{_is_flow_listbox_grey_w} = $true;
		#
		#			# for export to calling module via get_hash_ref
		#			$is_flow_listbox_grey_w = $true;
		#
		#		}
		#		elsif ( $color eq 'pink' ) {
		#			$conditions4flows->{_is_flow_listbox_pink_w} = $true;
		#
		#			# for export to calling module via get_hash_ref
		#			$is_flow_listbox_pink_w = $true;
		#
		#		}
		#		elsif ( $color eq 'green' ) {
		#
		#			$conditions4flows->{_is_flow_listbox_green_w} = $true;
		#
		#			# for export to calling module via get_hash_ref
		#			$is_flow_listbox_green_w = $true;
		#
		#		}
		#		elsif ( $color eq 'blue' ) {
		#
		#			$conditions4flows->{_is_flow_listbox_blue_w} = $true;
		#
		#			# for export to calling module via get_hash_ref
		#			$is_flow_listbox_blue_w = $true;
		#
		#		}
		#		else {
		#			print("conditions4flows, set_defaults_4start_of_flow_select , missing color\n");
		#		}

		$conditions4flows->{_is_flow_listbox_color_w}    = $true;
		$conditions4flows->{_is_pre_built_superflow}     = $false;
		$conditions4flows->{_is_superflow}               = $false;
		$conditions4flows->{_is_superflow_select_button} = $false;
		$conditions4flows->{_is_user_built_flow}         = $true;

		$delete_from_flow_button->configure( -state => 'active', );
		$delete_whole_flow_button->configure( -state => 'active', );
		$flow_item_down_arrow_button->configure( -state => 'active', );
		$flow_item_up_arrow_button->configure( -state => 'active', );
		$flow_listbox_grey_w->configure( -state => 'normal', );
		$flow_listbox_pink_w->configure( -state => 'normal', );
		$flow_listbox_green_w->configure( -state => 'normal', );
		$flow_listbox_blue_w->configure( -state => 'normal', );
#		$check_code_button->configure( -state => 'normal', );

		# for export to calling module via get_hash_ref
		$is_flow_listbox_color_w    = $true;
		$is_pre_built_superflow     = $false;
		$is_superflow               = $false;
		$is_superflow_select_button = $false;
		$is_user_built_flow         = $true;

		# spme menu buttons that pre-built superflows turn off
		$SaveAs_menubutton->configure( -state => 'normal' );

		# keep add2flow buttons turned off

		# turn on 'action' buttons to arrange the programs in a flow
		$delete_from_flow_button->configure( -state => 'active', );
		$delete_whole_flow_button->configure( -state => 'active', );
		$flow_item_up_arrow_button->configure( -state => 'active', );
		$flow_item_down_arrow_button->configure( -state => 'active', );

		#	$entry_button->focus
	} else {
		print("conditions4flows, set_defaults_4start_of_flow_select , no color:$color\n");

	}
	return ();

}

=head2

legacy
look at set4start_of_run_button and set4end_of_run_button

=cut

sub set4run_button_start {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button} = $true;

	# for export to calling module via get_hash_ref
	$is_run_button = $true;

	return ();

}

=head2 sub set4end_of_add2flow

		sets 
			$conditions4flows
			$add2flow_button_grey
			$flow_listbox_grey_w
			
		calls
			_reset();
		
		sees a
			listbox
			my $color 						= _get_flow_color();
=cut

sub set4end_of_add2flow {
	my ( $self, $color ) = @_;

	# print("2 conditions4flows,set4end_of_add2flow  color: $color\n");

	if ($color) {
		_set_flow_color($color);

		my $add2flow_button_color       = _get_add2flow_button();
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt    = 'flow_listbox_' . $color . '_w';
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';

		# print("2 conditions4flows,set4end_of_add2flow  flow_listbox_color_w: $flow_listbox_color_w\n");
		# print("2 conditions4flows,set4end_of_add2flow  color: $color");

		my $flow_listbox_color_w = $conditions4flows->{$flow_listbox_color_w_key};

		_set_flow_listbox_last_touched_w($flow_listbox_color_w);
		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);

		# clear any and all previous highlighted indices
		$flow_listbox_color_w->selectionClear( 0, "end" );

		# highlight new index !!!!!!!!!
		$flow_listbox_color_w->selectionSet("end");

		# note the last program that was touched
		$conditions4flows->{_is_add2flow} = $false;
		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;

		# for potential export via get_hash-ref
		$is_add2flow             = $false;
		$is_flow_listbox_color_w = $true;

		# keep track of which listbox was just chosen
		# for possible export
		if ( $conditions4flows->{_flow_color} eq 'grey' ) {
			$is_flow_listbox_grey_w = $conditions4flows->{_is_flow_listbox_grey_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'pink' ) {
			$is_flow_listbox_pink_w = $conditions4flows->{_is_flow_listbox_pink_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'green' ) {
			$is_flow_listbox_green_w = $conditions4flows->{_is_flow_listbox_green_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'blue' ) {
			$is_flow_listbox_blue_w = $conditions4flows->{_is_flow_listbox_blue_w};

		} else {
			print("2 conditions4flows,set4end_of_add2flow_of_run_button missing color \n");
		}

		# disable All Add-to-flow buttons
		# regardless of only one button having been clicked
		# For all listboxes
		$add2flow_button_grey->configure( -state => 'disabled' );
		$add2flow_button_pink->configure( -state => 'disabled' );
		$add2flow_button_green->configure( -state => 'disabled' );
		$add2flow_button_blue->configure( -state => 'disabled' );

		# print("1 conditions4flows,set4end_of_add2flow_button color: $color\n");

		# set flow color back to neutral after add2flow ends
		# _set_flow_color('neutral');

		# print("2 conditions4flows,set4end_of_add2flow color: $color\n");
		return ();

	} else {
		print("2 conditions4flows,set4end_of_add2flow reset color: $color\n");
	}

}

=head2 sub set4end_of_add2flow_button

		sets 
			$conditions4flows
			$add2flow_button_color
			$flow_listbox_color_w
			
		calls
			_reset();
		
		sees a
			listbox
			my $color 						= _get_flow_color();
=cut

sub set4end_of_add2flow_button {
	my ( $self, $color ) = @_;

	# print("2 conditions4flows,set4end_of_add2flow_button  color: $color\n");

	if ($color) {

		_set_flow_color($color);

		my $add2flow_button_color       = _get_add2flow_button();
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt    = 'flow_listbox_' . $color . '_w';
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';

		my $flow_listbox_color_w = $conditions4flows->{$flow_listbox_color_w_key};

		#		print("2 conditions4flows,set4end_of_add2flow_button  flow_listbox_color_w: $flow_listbox_color_w\n");

		_set_flow_listbox_last_touched_w($flow_listbox_color_w);
		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);

		# highlight new index
		$flow_listbox_color_w->selectionSet("end");

		# note the last program that was touched
		$conditions4flows->{_is_add2flow} = $false;
		$conditions4flows->{$is_flow_listbox_color_w_key} = $true;

		# for potential export via get_hash-ref
		$is_add2flow             = $false;
		$is_flow_listbox_color_w = $true;

		# keep track of which listbox was just chosen
		if ( $conditions4flows->{_flow_color} eq 'grey' ) {
			$is_flow_listbox_grey_w = $conditions4flows->{_is_flow_listbox_grey_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'pink' ) {
			$is_flow_listbox_pink_w = $conditions4flows->{_is_flow_listbox_pink_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'green' ) {
			$is_flow_listbox_green_w = $conditions4flows->{_is_flow_listbox_green_w};

		} elsif ( $conditions4flows->{_flow_color} eq 'blue' ) {
			$is_flow_listbox_blue_w = $conditions4flows->{_is_flow_listbox_blue_w};

		} else {
			print("2 conditions4flows,set4end_of_add2flow_button_of_run_button missing color \n");
		}

		# disable All Add-to-flow buttons
		# regardless of only one button having been clicked
		# For all listboxes
		$add2flow_button_grey->configure( -state => 'disabled' );
		$add2flow_button_pink->configure( -state => 'disabled' );
		$add2flow_button_green->configure( -state => 'disabled' );
		$add2flow_button_blue->configure( -state => 'disabled' );

		#		print("1 conditions4flows,set4end_of_add2flow_button color: $color\n");

		# set flow color back to neutral after add2flow_button is clicked
		# _set_flow_color('neutral');

		#		print("2 conditions4flows,set4end_of_add2flow_button color: $color\n");
		return ();

	} else {
		print("2 conditions4flows,set4end_of_add2flow_button reset color: $color\n");
	}
}

=head2 sub set4end_of_superflow_Save 
	

=cut

sub set4end_of_superflow_Save {
	my ($self) = @_;

	# print("conditions4flows, set4end_of_superflow_Save OK \n");
	$conditions4flows->{_has_used_Save_superflow}    = $true;
	$conditions4flows->{_is_pre_built_superflow}     = $false;
	$conditions4flows->{_is_superflow}               = $false;
	$conditions4flows->{_is_superflow_select_button} = $false;

	# for possible later export
	$has_used_Save_superflow    = $true;
	$is_pre_built_superflow     = $false;
	$is_superflow               = $false;
	$is_superflow_select_button = $false;

	return ();
}

=head2


=cut

sub set4end_of_superflow_run_button {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button}       = $false;
	$conditions4flows->{_has_used_run_button} = $true;

	# reset save and SaveAs options because
	# file must be saved before running, always
	$conditions4flows->{_has_used_SaveAs_button}  = $false;
	$conditions4flows->{_has_used_Save_superflow} = $false;

	# for export to calling module via get_hash_ref
	$has_used_SaveAs_button  = $false;
	$has_used_Save_superflow = $false;

	$is_run_button       = $false;
	$has_used_run_button = $true;
	return ();
}

=head2 sub set4end_of_superflow_select 
	

=cut

sub set4end_of_superflow_select {
	my ($self) = @_;

	# print("conditions4flows, set4end_of_superflow_select OK \n");
	$conditions4flows->{_is_superflow}               = $false;
	$conditions4flows->{_is_superflow_select_button} = $false;
	$conditions4flows->{_is_pre_built_superflow}     = $false;

	# for possible later export
	$is_superflow               = $false;
	$is_superflow_select_button = $false;
	$is_pre_built_superflow     = $false;

	return ();

}

=head2


=cut

sub set4start_of_run_button {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button} = $true;
	$is_run_button = $true;
	_reset_is_flow_listbox_color_w();

	if ( $conditions4flows->{_flow_color} eq 'grey' ) {
		$conditions4flows->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'pink' ) {
		$conditions4flows->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'green' ) {
		$conditions4flows->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4flows->{_flow_color} eq 'blue' ) {
		$conditions4flows->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4flows->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4flows,set4start_of_run_button Running a pre-built superflow\n");
		# NADA

	} else {
		print("2 conditions4flows,set4start_of_run_button missing color \n");
	}
	return ();
}

=head2 sub set4start_of_add2flow

 find out correct color

=cut

sub set4start_of_add2flow {
	my ( $self, $color ) = @_;

	# _reset();
	# _set_gui_widgets();
	_set_flow_listbox_color_w($color);

	my $flow_listbox_color_w = _get_flow_listbox_color_w();

	# print("conditions4flows, set4start_of_add2flow flow_listbox_color_w $flow_listbox_color_w\n");

	_set_flow_listbox_last_touched_w($flow_listbox_color_w);

	$conditions4flows->{_is_add2flow}              = $true;
	$conditions4flows->{_is_new_listbox_selection} = $true;

	# null some user dialogs
	$conditions4flows->{_has_used_Save_button}    = $false;
	$conditions4flows->{_has_used_SaveAs_button}  = $false;
	$conditions4flows->{_has_used_Save_superflow} = $false;

	# for potential later export
	$is_add2flow              = $true;
	$is_new_listbox_selection = $true;
	$has_used_SaveAs_button   = $false;
	$has_used_Save_button     = $false;
	$has_used_Save_superflow  = $false;

	#turn on the following buttons
	# print("conditions4flows, set4start_of_add2flow file_menubutton $file_menubutton\n");
	$file_menubutton->configure( -state => 'normal' );
#	$Data_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'normal' );
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );
#	$check_code_button->configure( -state => 'normal' );

	# turn on delete buttons
	$delete_from_flow_button->configure( -state => 'active', );
	$delete_whole_flow_button->configure( -state => 'active', );

	# turn on flow list item move up and down arrow buttons
	$flow_item_up_arrow_button->configure( -state => 'active', );
	$flow_item_down_arrow_button->configure( -state => 'active', );

	# turn on All ListBox(es) for possible later use
	$flow_listbox_grey_w->configure( -state => 'normal', );
	$flow_listbox_pink_w->configure( -state => 'normal', );
	$flow_listbox_green_w->configure( -state => 'normal', );
	$flow_listbox_blue_w->configure( -state => 'normal', );

	# unselect the previously selected item is set4end_of_add2flow ( 'end' )
	# the color of the listbox is identifiable via widget reference: $flow_listbox_color_w

	$flow_listbox_color_w->selectionClear( 0, "end" );

	# print("conditions4flows, set4start_of_add2flow, color is: $color \n");
	return ();
}

=head2

 find out correct color

=cut

sub set4start_of_add2flow_button {
	my ( $self, $color ) = @_;

	# _reset();
	# _set_gui_widgets();
	_set_flow_listbox_color_w($color);

	my $flow_listbox_color_w = _get_flow_listbox_color_w();

	_set_flow_listbox_last_touched_w($flow_listbox_color_w);

	$conditions4flows->{_is_add2flow_button}       = $true;
	$conditions4flows->{_is_sunix_listbox}         = $true;
	$conditions4flows->{_is_new_listbox_selection} = $true;

	# null some user dialogs
	$conditions4flows->{_has_used_Save_button}    = $false;
	$conditions4flows->{_has_used_Save_superflow} = $false;
	$conditions4flows->{_has_used_SaveAs_button}  = $false;

	# for potential later export
	$is_add2flow_button       = $true;
	$is_sunix_listbox         = $true;
	$is_new_listbox_selection = $true;
	$has_used_SaveAs_button   = $false;
	$has_used_Save_button     = $false;
	$has_used_Save_superflow  = $false;

	#turn on the following buttons
	$file_menubutton->configure( -state => 'normal' );
#	$Data_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'normal' );
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );
#	$check_code_button->configure( -state => 'normal' );

	#$parameter_names_frame ->configure(
	#							-state=>'disabled');
	# 	$parameter_values_button_frame ->configure(
	#							-state=>'disabled');

	# turn on delete buttons
	$delete_from_flow_button->configure( -state => 'active', );
	$delete_whole_flow_button->configure( -state => 'active', );

	# turn on flow list item move up and down arrow buttons
	$flow_item_up_arrow_button->configure( -state => 'active', );
	$flow_item_down_arrow_button->configure( -state => 'active', );

	# turn on All ListBox(es) for possible later use
	$flow_listbox_grey_w->configure( -state => 'normal', );
	$flow_listbox_pink_w->configure( -state => 'normal', );
	$flow_listbox_green_w->configure( -state => 'normal', );
	$flow_listbox_blue_w->configure( -state => 'normal', );

	# print("conditions4flows, set4start_of_add2flow_button, color is: $color \n");
	return ();
}

=head2 sub set4start_of_sunix_select 


=cut

sub set4start_of_sunix_select {
	my ($self) = @_;

	_reset();
	$conditions4flows->{_is_sunix_listbox} = $true;

	# print("conditions4flows, set4start_of_sunix_select, $conditions4flows->{_is_sunix_listbox}\n");
	$delete_from_flow_button->configure( -state => 'disabled', );
	$delete_whole_flow_button->configure( -state => 'disabled', );
	$flow_item_up_arrow_button->configure( -state => 'disabled', );
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# for export via get_hash_ref
	$is_sunix_listbox = $true;

	return ();
}

=head2


=cut

sub set4start_of_superflow_run_button {
	my ($self) = @_;

	# location within GUI
	$conditions4flows->{_is_run_button} = $true;
	$is_run_button = $true;

	return ();
}

=head2 sub set4start_of_superflow_Save 


=cut

sub set4start_of_superflow_Save {
	my ($self) = @_;

	$conditions4flows->{_is_Save_button} = $true;

	$is_Save_button = $true;

}

=head2 sub set4start_of_superflow_select 


=cut

sub set4start_of_superflow_select {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_open_data_file_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get                           = L_SU_global_constants->new();
	my $flow_type_h                   = $get->flow_type_href();
	my $alias_FileDialog_button_label = $get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4flows->{_flow_type}                  = $flow_type_h->{_pre_built_superflow};
	$conditions4flows->{_is_new_listbox_selection}   = $true;
	$conditions4flows->{_is_pre_built_superflow}     = $true;
	$conditions4flows->{_is_superflow}               = $true;
	$conditions4flows->{_is_superflow_select_button} = $true;
	$conditions4flows->{_is_user_built_flow}         = $false;

	# for re-export via get_hash-ref
	$flow_type                  = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection   = $true;
	$is_pre_built_superflow     = $true;
	$is_superflow               = $true;
	$is_superflow_select_button = $true;
	$is_user_built_flow         = $false;

	$delete_from_flow_button->configure( -state => 'disabled', );
	$delete_whole_flow_button->configure( -state => 'disabled', );
	$flow_item_up_arrow_button->configure( -state => 'disabled', );
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# turn off Flow label
	$flow_listbox_grey_w->configure( -state => 'disabled' );      # turn off top left flow listbox
	$flow_listbox_pink_w->configure( -state => 'disabled' );      # turn off top-right flow listbox
	$flow_listbox_green_w->configure( -state => 'disabled' );     # turn off bottom-left flow listbox
	$flow_listbox_blue_w->configure( -state => 'disabled' );      # turn off bottom-right flow listbox
	$add2flow_button_grey->configure( -state => 'disable', );     # turn off Flow label
	$add2flow_button_pink->configure( -state => 'disable', );     # turn off Flow label
	$add2flow_button_green->configure( -state => 'disable', );    # turn off Flow label
	$add2flow_button_blue->configure( -state => 'disable', );     # turn off Flow label
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );

#	$Data_menubutton->configure( -state => 'normal' );
	$Open_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'disable' );

#	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_close_data_file_end 

=cut

sub set4superflow_close_data_file_end {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_close_data_file_end OK \n");
	# Forces a Save before the next Run
	$conditions4flows->{_has_used_Save_button} = $false;

	# for potential export
	$has_used_Save_button = $false;

	# Allows user to open a user-built perl flow
	$Open_menubutton->configure( -state => 'normal', );

	return ();
}

=head2 sub set4superflow_close_path_end 

=cut

sub set4superflow_close_path_end {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_close_path_end OK \n");
	# Forces a Save before the next Run
	$conditions4flows->{_has_used_Save_superflow} = $false;

	# for potential export
	$has_used_Save_superflow = $false;

	# Allows user to open a user-built perl flow
	$Open_menubutton->configure( -state => 'normal', );

	return ();
}

=head2 sub set4superflow_open_data_file_end 

=cut

sub set4superflow_open_data_file_end {
	my ($self) = @_;

	# print("conditions4flows, set4end_of_superflow_select OK \n");
	$conditions4flows->{_is_pre_built_superflow} = $true;
	$conditions4flows->{_is_superflow}           = $true;

	#  	$conditions4flows->{_is_superflow_select_button}	= $true;

	# for potential export
	$is_pre_built_superflow = $true;
	$is_superflow           = $true;

	#   	$is_superflow_select_button						= $true;

	return ();
}

=head2 sub set4superflow_open_data_file_start 

=cut

sub set4superflow_open_data_file_start {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_open_data_file_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get                           = L_SU_global_constants->new();
	my $flow_type_h                   = $get->flow_type_href();
	my $alias_FileDialog_button_label = $get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4flows->{_flow_type}                = $flow_type_h->{_pre_built_superflow};
	$conditions4flows->{_is_new_listbox_selection} = $true;
	$conditions4flows->{_is_pre_built_superflow}   = $true;
	$conditions4flows->{_is_superflow}             = $true;

	#	$conditions4flows->{_is_superflow_select_button}	= $true;

	# for re-export via get_hash-ref
	$flow_type                = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection = $true;
	$is_superflow             = $true;
	$is_pre_built_superflow   = $true;

	#	$is_superflow_select_button						= $true;

	$delete_from_flow_button->configure( -state => 'disabled', );
	$delete_whole_flow_button->configure( -state => 'disabled', );
	$flow_item_up_arrow_button->configure( -state => 'disabled', );
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# turn off Flow label
	$flow_listbox_grey_w->configure( -state => 'disabled' );      # turn off top left flow listbox
	$flow_listbox_pink_w->configure( -state => 'disabled' );      # turn off top-right flow listbox
	$flow_listbox_green_w->configure( -state => 'disabled' );     # turn off bottom-left flow listbox
	$flow_listbox_blue_w->configure( -state => 'disabled' );      # turn off bottom-right flow listbox
	$add2flow_button_grey->configure( -state => 'disable', );     # turn off Flow label
	$add2flow_button_pink->configure( -state => 'disable', );     # turn off Flow label
	$add2flow_button_green->configure( -state => 'disable', );    # turn off Flow label
	$add2flow_button_blue->configure( -state => 'disable', );     # turn off Flow label
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );

#	$Data_menubutton->configure( -state => 'normal' );
	$Open_menubutton->configure( -state => 'disable', );
	$SaveAs_menubutton->configure( -state => 'disable' );

#	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_open_path_end 

=cut

sub set4superflow_open_path_end {

	my ($self) = @_;

	# print("conditions4flows, set4superflow_open_path_end OK \n");
	$conditions4flows->{_is_pre_built_superflow} = $true;
	$conditions4flows->{_is_superflow}           = $true;

	# for potential export
	$is_pre_built_superflow = $true;
	$is_superflow           = $true;

	return ();
}

=head2 sub set4superflow_open_path_start 

=cut

sub set4superflow_open_path_start {
	my ($self) = @_;

	# print("conditions4flows, set4superflow_open_path_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	# my $alias_FileDialog_button_label				= $get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4flows->{_flow_type}                = $flow_type_h->{_pre_built_superflow};
	$conditions4flows->{_is_new_listbox_selection} = $true;
	$conditions4flows->{_is_pre_built_superflow}   = $true;
	$conditions4flows->{_is_superflow}             = $true;

	# for re-export via get_hash-ref
	$flow_type                = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection = $true;
	$is_superflow             = $true;
	$is_pre_built_superflow   = $true;

	$delete_from_flow_button->configure( -state => 'disabled', );
	$delete_whole_flow_button->configure( -state => 'disabled', );
	$flow_item_up_arrow_button->configure( -state => 'disabled', );
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# turn off Flow label
	$flow_listbox_grey_w->configure( -state => 'disabled' );             # turn off top left flow listbox
	$flow_listbox_pink_w->configure( -state => 'disabled' );             # turn off top-right flow listbox
	$flow_listbox_green_w->configure( -state => 'disabled' );            # turn off bottom-left flow listbox
	$flow_listbox_blue_w->configure( -state => 'disabled' );             # turn off bottom-right flow listbox
	$add2flow_button_grey->configure( -state => 'disable', );            # turn off Flow label
	$add2flow_button_pink->configure( -state => 'disable', );            # turn off Flow label
	$add2flow_button_green->configure( -state => 'disable', );           # turn off Flow label
	$add2flow_button_blue->configure( -state => 'disable', );            # turn off Flow label
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );

#	$Data_menubutton->configure( -state => 'normal' );
	$Open_menubutton->configure( -state => 'disable', );
	$SaveAs_menubutton->configure( -state => 'disable' );

#	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_Save 


=cut

sub set4superflow_Save {
	my ($self) = @_;

	$conditions4flows->{_has_used_Save_superflow} = $true;
	$conditions4flows->{_has_used_Save_button}    = $false;

	#for possible export

	$has_used_Save_superflow = $true;
	$has_used_Save_button    = $false;

	return ();

}

=head2 sub set_flow_index_last_touched


=cut

sub set_flow_index_last_touched {
	my ( $self, $index ) = @_;

	if ( length($index) ) {    # if defined

		if ( $index >= 0 ) {    # -1 does exist in conditions4flows thru default definition
			$conditions4flows->{_last_flow_index_touched_grey}  = $index;    # internal
			$conditions4flows->{_last_flow_index_touched_pink}  = $index;    # internal
			$conditions4flows->{_last_flow_index_touched_green} = $index;    # internal
			$conditions4flows->{_last_flow_index_touched_blue}  = $index;    # internal
			$conditions4flows->{_last_flow_index_touched}       = $index;    # internal
			$last_flow_index_touched_grey                       = $index;    # for get_hash-ref
			$last_flow_index_touched_pink                       = $index;    # for get_hash-ref
			$last_flow_index_touched_green                      = $index;    # for get_hash-ref
			$last_flow_index_touched_blue                       = $index;    # for get_hash-ref
			$last_flow_index_touched                            = $index;    # for get_hash-ref
			$is_last_flow_index_touched_grey                    = $true;     # for get_hash-ref
			$is_last_flow_index_touched_pink                    = $true;     # for get_hash-ref
			$is_last_flow_index_touched_green                   = $true;     # for get_hash-ref
			$is_last_flow_index_touched_blue                    = $true;     # for get_hash-ref
			$is_last_flow_index_touched                         = $true;     # for get_hash-ref

			#print("1. conditions4flows, set_flow_index_last_touched had index = $conditions4flows->{_last_flow_index_touched}\n");
		} else {
			print("conditions4flows,set_flow_index_touched, missing index\n");
		}

	} else {

		#print("conditions4flows,set_flow_index_touched, index is undefined but needed, so assume index=0\n");
		$index                                              = 0;
		$conditions4flows->{_last_flow_index_touched_grey}  = $index;        # internal
		$conditions4flows->{_last_flow_index_touched_pink}  = $index;        # internal
		$conditions4flows->{_last_flow_index_touched_green} = $index;        # internal
		$conditions4flows->{_last_flow_index_touched_blue}  = $index;        # internal
		$conditions4flows->{_last_flow_index_touched}       = $index;        # internal
		$last_flow_index_touched_grey                       = $index;        # for get_hash-ref
		$last_flow_index_touched_pink                       = $index;        # for get_hash-ref
		$last_flow_index_touched_green                      = $index;        # for get_hash-ref
		$last_flow_index_touched_blue                       = $index;        # for get_hash-ref
		$last_flow_index_touched                            = $index;        # for get_hash-ref
		$is_last_flow_index_touched_grey                    = $true;         # for get_hash-ref
		$is_last_flow_index_touched_pink                    = $true;         # for get_hash-ref
		$is_last_flow_index_touched_green                   = $true;         # for get_hash-ref
		$is_last_flow_index_touched_blue                    = $true;         # for get_hash-ref
		$is_last_flow_index_touched                         = $true;         # for get_hash-ref
	}

	# print("1. conditions4flows, set_flow_index_last_touched had index = $index\n");
	return ();
}

__PACKAGE__->meta->make_immutable;
1;
