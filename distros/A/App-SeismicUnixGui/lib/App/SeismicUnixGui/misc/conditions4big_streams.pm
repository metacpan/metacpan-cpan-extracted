package App::SeismicUnixGui::misc::conditions4big_streams;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: conditions4big_streams.pm
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
 		conditions4big_streams.
 		
 		get_flow_index_last_touched needs to be exported so do not reset it
 		
 		For safety we try to encapsulate this module
 		For safety we work internally sometimes with single scalars instead of imported hash and variables
 		For safety, input hash keys are assigned to new variables with short private names
 		New variables with short names are exported from a private hash
 		
 BASED ON:
 
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
my $Flow_menubutton;
my $SaveAs_menubutton;
my $add2flow_button_grey;
my $add2flow_button_pink;
my $add2flow_button_green;
my $add2flow_button_blue;
#my $big_stream_name_in;
#my $big_stream_name_out;
my $check_buttons_settings_aref;
my $check_buttons_w_aref;
my $check_code_button;
my $delete_from_flow_button;
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
#my $flow_name_in_blue;
#my $flow_name_in_grey;
#my $flow_name_in_green;
#my $flow_name_in_pink;
my $flow_name_out;
#my $flow_name_out_blue;
#my $flow_name_out_grey;
#my $flow_name_out_green;
#my $flow_name_out_pink;
my $flow_type;
my $flow_widget_index;
my $gui_history_ref;
my $has_used_check_code_button;
my $has_used_open_perl_file_button;
my $has_used_run_button;
my $has_used_SaveAs_button;
my $has_used_Save_button;
my $has_used_Save_superflow;
my $is_add2flow;
my $is_add2flow_button;
my $is_check_code_button;
my $is_delete_from_flow_button;
my $is_dragNdrop;
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
my $is_moveNdrop_in_flow;
my $is_new_listbox_selection;
my $is_open_file_button;
my $is_pre_built_superflow;
my $is_run_button;
my $is_select_file_button;
my $is_selected_file_name;
my $is_selected_path;
my $is_Save_button;
my $is_SaveAs_button;
my $is_SaveAs_file_button;
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

#my $vacant_listbox_aref;
my $values_aref;
my $values_w_aref;
my $wipe_plots_button;

=head2 private hash

106 off

=cut

my $conditions4big_streams = {

	_Data_menubutton       => '',
	_Flow_menubutton       => '',
	_SaveAs_menubutton     => '',
	_add2flow_button_grey  => '',
	_add2flow_button_pink  => '',
	_add2flow_button_green => '',
	_add2flow_button_blue  => '',
	#	_big_stream_name_in          => '',
	#	_big_stream_name_out         => '',
	_check_code_button           => '',
	_check_buttons_settings_aref => '',
	_check_buttons_w_aref        => '',
	_delete_from_flow_button     => '',
	_dialog_type                 => '',
	_dnd_token_grey              => '',
	_dnd_token_pink              => '',
	_dnd_token_green             => '',
	_dnd_token_blue              => '',
	_dropsite_token_grey         => '',
	_dropsite_token_pink         => '',
	_dropsite_token_green        => '',
	_dropsite_token_blue         => '',
	_file_menubutton             => '',
	_flowNsuperflow_name_w       => '',
	_flow_color                  => '',
	_flow_item_down_arrow_button => '',
	_flow_item_up_arrow_button   => '',
	_flow_listbox_grey_w         => '',
	_flow_listbox_pink_w         => '',
	_flow_listbox_green_w        => '',
	_flow_listbox_blue_w         => '',
	_flow_listbox_color_w        => '',
	_flow_name_in                => '',
	#	_flow_name_in_blue                     => '',
	#	_flow_name_in_grey                     => '',
	#	_flow_name_in_green                    => '',
	#	_flow_name_in_pink                     => '',
	_flow_name_out => '',
	#	_flow_name_out_blue                    => '',
	#	_flow_name_out_grey                    => '',
	#	_flow_name_out_green                   => '',
	#	_flow_name_out_pink                    => '',
	_flow_type                             => '',
	_flow_widget_index                     => '',
	_gui_history_aref                      => '',
	_has_used_check_code_button            => '',
	_has_used_open_perl_file_button        => '',
	_has_used_run_button                   => '',
	_has_used_Save_button                  => '',
	_has_used_Save_superflow               => '',
	_has_used_SaveAs_button                => '',
	_is_add2flow                           => '',
	_is_add2flow_button                    => '',
	_is_check_code_button                  => '',
	_is_delete_from_flow_button            => '',
	_is_dragNdrop                          => '',
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
	_is_SaveAs_file_button                 => '',
	_is_SaveAs_button                      => '',
	_is_Save_button                        => '',
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
	#		_vacant_listbox_aref                 => '',
	_values_aref       => '',
	_values_w_ref      => '',
	_wipe_plots_button => '',

};

=head2 sub _get_add2flow


=cut 

sub _get_add2flow {
	my ($self) = @_;
	my $color;
	my $correct_add2flow_button;

	$color = $conditions4big_streams->{_flow_color};

	if ( $color eq 'grey' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_grey};

	} elsif ( $color eq 'pink' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_pink};

	} elsif ( $color eq 'green' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_green};

	} elsif ( $color eq 'blue' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_blue};

	} else {
		print("conditions4big_streams,  _get_add2flow_button, missing color,missing color, color:$color\n");
	}

	return ($correct_add2flow_button);
}

=head2 sub _get_add2flow_button


=cut 

sub _get_add2flow_button {
	my ($self) = @_;
	my $color;
	my $correct_add2flow_button;

	$color = $conditions4big_streams->{_flow_color};

	if ( $color eq 'grey' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_grey};

	} elsif ( $color eq 'pink' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_pink};

	} elsif ( $color eq 'green' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_green};

	} elsif ( $color eq 'blue' ) {
		$correct_add2flow_button = $conditions4big_streams->{_add2flow_button_blue};

	} else {
		print("conditions4big_streams,  _get_add2flow_button, missing color,missing color, color:$color\n");
	}

	return ($correct_add2flow_button);
}

=head2 sub _get_flow_color


=cut 

sub _get_flow_color {
	my ($self) = @_;
	my $color;

	if ( $conditions4big_streams->{_flow_color} ) {

		$color = $conditions4big_streams->{_flow_color};
		return ($color);

	} else {
		print("conditions4big_streams,_get_flow_color  missing conditions4big_streams->{_flow_color}\n");

	}

}

=head2 sub _get_flow_listbox_color_w


=cut 

sub _get_flow_listbox_color_w {
	my ($self) = @_;
	my $correct_flow_listbox_color_w;

	if ( $conditions4big_streams->{_flow_listbox_color_w} ) {

		my $correct_flow_listbox_color_w = $conditions4big_streams->{_flow_listbox_color_w};
		return ($correct_flow_listbox_color_w);

	} else {
		print("conditions4big_streams, _get_flow_listbox_color_w, unassigned flow listbox w for current color\n");
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

	$conditions4big_streams->{_is_Save_button}                 = $false;
	$conditions4big_streams->{_is_SaveAs_file_button}          = $false;
	$conditions4big_streams->{_is_SaveAs_button}               = $false;
	$conditions4big_streams->{_has_used_check_code_button}     = $false;
	$conditions4big_streams->{_has_used_run_button}            = $false;
	$conditions4big_streams->{_is_add2flow_button}             = $false;
	$conditions4big_streams->{_is_check_code_button}           = $false;
	$conditions4big_streams->{_is_delete_from_flow_button}     = $false;
	$conditions4big_streams->{_is_dragNdrop}                   = $false;
	$conditions4big_streams->{_is_flow_item_down_arrow_button} = $false;
	$conditions4big_streams->{_is_flow_item_up_arrow_button}   = $false;
	$conditions4big_streams->{_is_flow_listbox_grey_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_pink_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_green_w}        = $false;
	$conditions4big_streams->{_is_flow_listbox_blue_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_color_w}        = $false;
	$conditions4big_streams->{_is_moveNdrop_in_flow}           = $false;
	$conditions4big_streams->{_is_open_file_button}            = $false;
	$conditions4big_streams->{_is_select_file_button}          = $false;
	$conditions4big_streams->{_is_sunix_listbox}               = $false;
	$conditions4big_streams->{_is_new_listbox_selection}       = $false;
	$conditions4big_streams->{_is_superflow_select_button}     = $false;
	$conditions4big_streams->{_is_run_button}                  = $false;
	$conditions4big_streams->{_is_pre_built_superflow}         = $false;
	$conditions4big_streams->{_is_superflow}                   = $false;
	$conditions4big_streams->{_is_user_built_flow}             = $false;
	$conditions4big_streams->{_is_wipe_plots_button}           = $false;

	#  	 		$conditions4big_streams->{_has_used_check_code_button   	 	}   			= $false;
	#	   	 	$conditions4big_streams->{_has_used_open_perl_file_button}   			= $false;
	#	   	 	$conditions4big_streams->{_has_used_run_button}   			= $false;
	#	   	 	$conditions4big_streams->{_has_used_SaveAs_button}   			= $false;
	#	   	 	$conditions4big_streams->{_has_used_Save_button}   			= $false;
	#	   	 	$conditions4big_streams->{_has_used_Save_superflow}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_add2flow}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_add2flow_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_check_code_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_delete_from_flow_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_dragNdrop}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_item_down_arrow_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_item_up_arrow_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_listbox_grey_w}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_listbox_pink_w}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_listbox_green_w	}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_listbox_blue_w}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_flow_listbox_color_w}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_flow_index_touched_grey }   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_flow_index_touched_pink}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_flow_index_touched_green}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_flow_index_touched_blue}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_flow_index_touched}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_parameter_index_touched_grey}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_parameter_index_touched_pink}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_parameter_index_touched_green}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_parameter_index_touched_blue}   			= $false;
	#	   	 	$conditions4big_streams->{_is_last_parameter_index_touched_color}   			= $false;
	#	   	 	$conditions4big_streams->{_is_moveNdrop_in_flow}   			= $false;
	#  	   	 	$conditions4big_streams->{_is_new_listbox_selection}   			= $false;
	#  	   	 	$conditions4big_streams->{_is_open_file_button}   			= $false;
	#  	   	 	$conditions4big_streams->{_is_pre_built_superflow}   			= $false;
	#  	   	 	$conditions4big_streams->{_is_run_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_select_file_button}   			= $false;
	#       	 	$conditions4big_streams->{_is_selected_file_name}   			= $false;
	#       	 	$conditions4big_streams->{_is_selected_path}   			= $false;
	#   	   	 	$conditions4big_streams->{_is_Save_button}   			= $false;
	#   	   	 	$conditions4big_streams->{_is_SaveAs_button}   			= $false;
	#  	   	 	$conditions4big_streams->{_is_SaveAs_file_button}   			= $false;
	# 	   	 	$conditions4big_streams->{_is_sunix_listbox}   			= $false;
	#   	   	 	$conditions4big_streams->{_is_superflow_select_button}   			= $false;
	#   	   	 	$conditions4big_streams->{_is_superflow}   			= $false;  # for deprecation
	#  	   	 	$conditions4big_streams->{_is_user_built_flow}   			= $false;
	#

}

=head2 sub _reset_is_flow_listbox_color_w


=cut

sub _reset_is_flow_listbox_color_w {
	my ($self) = @_;

	if (   $conditions4big_streams->{_flow_color} eq 'grey'
		|| $conditions4big_streams->{_flow_color} eq 'pink'
		|| $conditions4big_streams->{_flow_color} eq 'green'
		|| $conditions4big_streams->{_flow_color} eq 'blue'
		|| $conditions4big_streams->{_flow_color} eq 'neutral' ) {

		$conditions4big_streams->{_is_flow_listbox_grey_w}  = $false;
		$conditions4big_streams->{_is_flow_listbox_pink_w}  = $false;
		$conditions4big_streams->{_is_flow_listbox_green_w} = $false;
		$conditions4big_streams->{_is_flow_listbox_blue_w}  = $false;

		# for export
		$is_flow_listbox_grey_w  = $false;
		$is_flow_listbox_pink_w  = $false;
		$is_flow_listbox_green_w = $false;
		$is_flow_listbox_blue_w  = $false;

	} else {
		print(" conditions4big_streams, _reset_is_flow_listbox_color_w ,missing flow color \n");
	}

	return ();
}

=head2 sub _set_flow_color


=cut 

sub _set_flow_color {
	my ($color) = @_;

	if ($color) {

		# print("conditions4big_streams, _set_flow_color , color:$color\n");
		$conditions4big_streams->{_flow_color} = $color;
	} else {

		print("conditions4big_streams, set_flow_color, missing color\n");
	}
	return ();
}

=head2 sub _set_flow_listbox_color_w


=cut 

sub _set_flow_listbox_color_w {
	my ($color) = @_;

	if ( $color eq 'grey' ) {
		$conditions4big_streams->{_flow_listbox_color_w}   = $conditions4big_streams->{_flow_listbox_grey_w};
		$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;
		$flow_listbox_color_w = $conditions4big_streams->{_flow_listbox_grey_w};  # for possible export via get_hash_ref
		$is_flow_listbox_grey_w = $true;                                          # for possible export via get_hash_ref

	} elsif ( $color eq 'pink' ) {
		$conditions4big_streams->{_flow_listbox_color_w}   = $conditions4big_streams->{_flow_listbox_pink_w};
		$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;
		$flow_listbox_color_w = $conditions4big_streams->{_flow_listbox_pink_w};  # for possible export via get_hash_ref
		$is_flow_listbox_pink_w = $true;                                          # for possible export via get_hash_ref

	} elsif ( $color eq 'green' ) {
		$conditions4big_streams->{_flow_listbox_color_w}    = $conditions4big_streams->{_flow_listbox_green_w};
		$conditions4big_streams->{_is_flow_listbox_green_w} = $true;
		$flow_listbox_color_w = $conditions4big_streams->{_flow_listbox_green_w}; # for possible export via get_hash_ref
		$is_flow_listbox_green_w = $true;                                         # for possible export via get_hash_ref

	} elsif ( $color eq 'blue' ) {
		$conditions4big_streams->{_flow_listbox_color_w}   = $conditions4big_streams->{_flow_listbox_blue_w};
		$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;
		$flow_listbox_color_w = $conditions4big_streams->{_flow_listbox_blue_w};  # for possible export via get_hash_ref
		$is_flow_listbox_blue_w = $true;                                          # for possible export via get_hash_ref

	} else {
		print("conditions4big_streams, _set_flow_listbox_color_w, missing color, color:$color\n");
	}

	return ();
}

=head2 sub _set_flow_listbox_last_touched_txt

	keep track of whcih listbox was last chosen

=cut

sub _set_flow_listbox_last_touched_txt {
	my ($last_flow_lstbx_touched) = @_;

	if ($last_flow_lstbx_touched) {
		$conditions4big_streams->{_last_flow_listbox_touched} = $last_flow_lstbx_touched;

		# print("conditions4big_streams,_set_flow_listbox_touched left listbox = $conditions4big_streams->{_last_flow_listbox_touched}\n");

		# for possible export via get_hash_ref
		$last_flow_listbox_touched = $last_flow_lstbx_touched;

	} else {
		print("conditions4big_streams,set_flow_listbox_touched_txt, missing listbox name\n");
	}

	return ();
}

=head2 sub _set_flow_listbox_last_touched_w


=cut

sub _set_flow_listbox_last_touched_w {
	my ($flow_listbox_color_w) = @_;

	_set_gui_widgets();

	# print("1 conditions4big_streams, _set_flow_listbox_last_touched_w; flow_listbox_color_w: $flow_listbox_color_w \n");

	if ($flow_listbox_color_w) {

		# print("1 conditions4big_streams, _set_flow_listbox_last_touched_w; $flow_listbox_color_w\n");
		$conditions4big_streams->{_last_flow_listbox_touched_w} = $flow_listbox_color_w;
		$last_flow_listbox_touched_w = $flow_listbox_color_w;                              # for export via get_hash-ref

	} else {
		print("conditions4big_streams,_set_flow_listbox_touched_w, missing listbox widget\n");
	}
	return ();
}

=head2 sub _set_gui_widgets

	 spread important widget addresses
	 privately for convenience using abbreviated names,
	 i.e. in scalar instead of hash notaion
	 print("1 conditions4big_streams,_set_gui_widgets, delete_from_flow_button: $delete_from_flow_button\n");
	 print("conditions4big_streams,_set_gui_widgets,flow_listbox_grey_w : $flow_listbox_grey_w \n");
	
	25 off
	
=cut

sub _set_gui_widgets {
	my ($self) = @_;

	$add2flow_button_grey        = $conditions4big_streams->{_add2flow_button_grey};
	$add2flow_button_pink        = $conditions4big_streams->{_add2flow_button_pink};
	$add2flow_button_green       = $conditions4big_streams->{_add2flow_button_green};
	$add2flow_button_blue        = $conditions4big_streams->{_add2flow_button_blue};
	$check_buttons_w_aref        = $conditions4big_streams->{_check_buttons_w_aref};
	$check_code_button           = $conditions4big_streams->{_check_code_button};
	$delete_from_flow_button     = $conditions4big_streams->{_delete_from_flow_button};
	$file_menubutton             = $conditions4big_streams->{_file_menubutton};
	$flowNsuperflow_name_w       = $conditions4big_streams->{_flowNsuperflow_name_w};
	$flow_item_down_arrow_button = $conditions4big_streams->{_flow_item_down_arrow_button};
	$flow_item_up_arrow_button   = $conditions4big_streams->{_flow_item_up_arrow_button};
	$flow_listbox_grey_w         = $conditions4big_streams->{_flow_listbox_grey_w};
	$flow_listbox_pink_w         = $conditions4big_streams->{_flow_listbox_pink_w};
	$flow_listbox_green_w        = $conditions4big_streams->{_flow_listbox_green_w};
	$flow_listbox_blue_w         = $conditions4big_streams->{_flow_listbox_blue_w};
	$flow_listbox_color_w        = $conditions4big_streams->{_flow_listbox_color_w};
	$flow_widget_index           = $conditions4big_streams->{_flow_widget_index};
	$labels_w_aref               = $conditions4big_streams->{_labels_w_aref};
	$message_w                   = $conditions4big_streams->{_message_w};
	$mw                          = $conditions4big_streams->{_mw};
	$parameter_values_frame      = $conditions4big_streams->{_parameter_values_frame};
	$parameter_value_index       = $conditions4big_streams->{_parameter_value_index};
	$run_button                  = $conditions4big_streams->{_run_button};
	$save_button                 = $conditions4big_streams->{_save_button};
	$values_w_aref               = $conditions4big_streams->{_values_w_aref};
	$wipe_plots_button           = $conditions4big_streams->{_wipe_plots_button};

	return ();
}

=head2 sub get_flow_color

	return flow color if it exists
	
=cut

sub get_flow_color {
	my ($self) = @_;
	my $flow_color;

	if ( $conditions4big_streams->{_flow_color} ) {

		$flow_color = $conditions4big_streams->{_flow_color};

		# print("conditions4big_streams, conditions4big_streams->{_flow_color}: $conditions4big_streams->{_flow_color}\n");
		return ($flow_color);

	} else {
		print("conditions4big_streams, get_flow_color , missing flow color value \n");
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
	
	 
=cut

sub get_hash_ref {
	my ($self) = @_;

	if ($conditions4big_streams) {

		$conditions4big_streams->{_Data_menubutton}       = $Data_menubutton;
		$conditions4big_streams->{_Flow_menubutton}       = $Flow_menubutton;
		$conditions4big_streams->{_SaveAs_menubutton}     = $SaveAs_menubutton;
		$conditions4big_streams->{_add2flow_button_grey}  = $add2flow_button_grey;
		$conditions4big_streams->{_add2flow_button_pink}  = $add2flow_button_pink;
		$conditions4big_streams->{_add2flow_button_green} = $add2flow_button_green;
		$conditions4big_streams->{_add2flow_button_blue}  = $add2flow_button_blue;
			#		$conditions4big_streams->{_big_stream_name_in}                    = $big_stream_name_in;
			#		$conditions4big_streams->{_big_stream_name_out}                   = $big_stream_name_out;
		$conditions4big_streams->{_check_buttons_w_aref}        = $check_buttons_w_aref;
		$conditions4big_streams->{_check_buttons_settings_aref} = $check_buttons_settings_aref;
		$conditions4big_streams->{_check_code_button}           = $check_code_button;
		$conditions4big_streams->{_delete_from_flow_button}     = $delete_from_flow_button;
		$conditions4big_streams->{_file_menubutton}             = $file_menubutton;
		$conditions4big_streams->{_flowNsuperflow_name_w}       = $flowNsuperflow_name_w;
		$conditions4big_streams->{_flow_item_down_arrow_button} = $flow_item_down_arrow_button;
		$conditions4big_streams->{_flow_item_up_arrow_button}   = $flow_item_up_arrow_button;
		$conditions4big_streams->{_flow_listbox_grey_w}         = $flow_listbox_grey_w;
		$conditions4big_streams->{_flow_listbox_pink_w}         = $flow_listbox_pink_w;
		$conditions4big_streams->{_flow_listbox_green_w}        = $flow_listbox_green_w;
		$conditions4big_streams->{_flow_listbox_blue_w}         = $flow_listbox_blue_w;
		$conditions4big_streams->{_flow_listbox_color_w}        = $flow_listbox_color_w;
		$conditions4big_streams->{_flow_widget_index}           = $flow_widget_index;
		$conditions4big_streams->{_labels_w_aref}               = $labels_w_aref;
		$conditions4big_streams->{_message_w}                   = $message_w;
		$conditions4big_streams->{_mw}                          = $mw;
		$conditions4big_streams->{_parameter_values_frame}      = $parameter_values_frame;
		$conditions4big_streams->{_parameter_value_index}       = $parameter_value_index;
		$conditions4big_streams->{_run_button}                  = $run_button;
		$conditions4big_streams->{_save_button}                 = $save_button;
		$conditions4big_streams->{_values_w_aref}               = $values_w_aref;
		$conditions4big_streams->{_dialog_type}                 = $dialog_type;
		$conditions4big_streams->{_flow_color}                  = $flow_color;
		$conditions4big_streams->{_flow_name_in}                = $flow_name_in;

		#		$conditions4big_streams->{_flow_name_in_blue}                     = $flow_name_in_blue;
		#		$conditions4big_streams->{_flow_name_in_grey}                     = $flow_name_in_grey;
		#		$conditions4big_streams->{_flow_name_in_green}                    = $flow_name_in_green;
		#		$conditions4big_streams->{_flow_name_in_pink}                     = $flow_name_in_pink;
		$conditions4big_streams->{_flow_name_out} = $flow_name_out;

		#		$conditions4big_streams->{_flow_name_out_blue}                    = $flow_name_out_blue;
		#		$conditions4big_streams->{_flow_name_out_grey}                    = $flow_name_out_grey;
		#		$conditions4big_streams->{_flow_name_out_green}                   = $flow_name_out_green;
		#		$conditions4big_streams->{_flow_name_out_pink}                    = $flow_name_out_pink;
		$conditions4big_streams->{_flow_type}                             = $flow_type;
		$conditions4big_streams->{_flow_widget_index}                     = $flow_widget_index;
		$conditions4big_streams->{_gui_history_ref}                       = $gui_history_ref;
		$conditions4big_streams->{_has_used_SaveAs_button}                = $has_used_SaveAs_button;
		$conditions4big_streams->{_has_used_Save_button}                  = $has_used_Save_button;
		$conditions4big_streams->{_has_used_Save_superflow}               = $has_used_Save_superflow;
		$conditions4big_streams->{_has_used_check_code_button}            = $has_used_check_code_button;
		$conditions4big_streams->{_has_used_open_perl_file_button}        = $has_used_open_perl_file_button;
		$conditions4big_streams->{_has_used_run_button}                   = $has_used_run_button;
		$conditions4big_streams->{_is_add2flow_button}                    = $is_add2flow_button;
		$conditions4big_streams->{_is_check_code_button}                  = $is_check_code_button;
		$conditions4big_streams->{_is_delete_from_flow_button}            = $is_delete_from_flow_button;
		$conditions4big_streams->{_is_dragNdrop}                          = $is_dragNdrop;
		$conditions4big_streams->{_is_flow_item_up_arrow_button}          = $is_flow_item_up_arrow_button;
		$conditions4big_streams->{_is_flow_item_down_arrow_button}        = $is_flow_item_down_arrow_button;
		$conditions4big_streams->{_is_flow_listbox_grey_w}                = $is_flow_listbox_grey_w;
		$conditions4big_streams->{_is_flow_listbox_pink_w}                = $is_flow_listbox_pink_w;
		$conditions4big_streams->{_is_flow_listbox_green_w}               = $is_flow_listbox_green_w;
		$conditions4big_streams->{_is_flow_listbox_blue_w}                = $is_flow_listbox_blue_w;
		$conditions4big_streams->{_is_flow_listbox_color_w}               = $is_flow_listbox_color_w;
		$conditions4big_streams->{_is_future_flow_listbox_grey}           = $is_future_flow_listbox_grey;
		$conditions4big_streams->{_is_future_flow_listbox_pink}           = $is_future_flow_listbox_pink;
		$conditions4big_streams->{_is_future_flow_listbox_green}          = $is_future_flow_listbox_green;
		$conditions4big_streams->{_is_future_flow_listbox_blue}           = $is_future_flow_listbox_blue;
		$conditions4big_streams->{_is_last_flow_index_touched}            = $is_last_flow_index_touched;
		$conditions4big_streams->{_is_last_flow_index_touched_grey}       = $is_last_flow_index_touched_grey;
		$conditions4big_streams->{_is_last_flow_index_touched_pink}       = $is_last_flow_index_touched_pink;
		$conditions4big_streams->{_is_last_flow_index_touched_green}      = $is_last_flow_index_touched_green;
		$conditions4big_streams->{_is_last_flow_index_touched_blue}       = $is_last_flow_index_touched_blue;
		$conditions4big_streams->{_is_last_parameter_index_touched_grey}  = $is_last_parameter_index_touched_grey;
		$conditions4big_streams->{_is_last_parameter_index_touched_pink}  = $is_last_parameter_index_touched_pink;
		$conditions4big_streams->{_is_last_parameter_index_touched_green} = $is_last_parameter_index_touched_green;
		$conditions4big_streams->{_is_last_parameter_index_touched_blue}  = $is_last_parameter_index_touched_blue;
		$conditions4big_streams->{_is_last_parameter_index_touched_color} = $is_last_parameter_index_touched_color;
		$conditions4big_streams->{_is_open_file_button}                   = $is_open_file_button;
		$conditions4big_streams->{_is_run_button}                         = $is_run_button;
		$conditions4big_streams->{_is_moveNdrop_in_flow}                  = $is_moveNdrop_in_flow;
		$conditions4big_streams->{_is_user_built_flow}                    = $is_user_built_flow;
		$conditions4big_streams->{_is_select_file_button}                 = $is_select_file_button;
		$conditions4big_streams->{_is_selected_file_name}                 = $is_selected_file_name;
		$conditions4big_streams->{_is_selected_path}                      = $is_selected_path;
		$conditions4big_streams->{_is_Save_button}                        = $is_Save_button;
		$conditions4big_streams->{_is_SaveAs_button}                      = $is_SaveAs_button;
		$conditions4big_streams->{_is_SaveAs_file_button}                 = $is_SaveAs_file_button;
		$conditions4big_streams->{_is_sunix_listbox}                      = $is_sunix_listbox;
		$conditions4big_streams->{_is_new_listbox_selection}              = $is_new_listbox_selection;
		$conditions4big_streams->{_is_pre_built_superflow}                = $is_pre_built_superflow;
		$conditions4big_streams->{_is_superflow_select_button}            = $is_superflow_select_button;
		$conditions4big_streams->{_is_superflow}                          = $is_superflow;        # for deprecation TODO
		$conditions4big_streams->{_is_moveNdrop_in_flow}                  = $is_moveNdrop_in_flow;
		$conditions4big_streams->{_is_wipe_plots_button}                  = $is_wipe_plots_button;

		#		$conditions4big_streams->{_last_flow_color}      = $last_flow_color;
		$conditions4big_streams->{_last_flow_index_touched_grey}       = $last_flow_index_touched_grey;
		$conditions4big_streams->{_last_flow_index_touched_pink}       = $last_flow_index_touched_pink;
		$conditions4big_streams->{_last_flow_index_touched_green}      = $last_flow_index_touched_green;
		$conditions4big_streams->{_last_flow_index_touched_blue}       = $last_flow_index_touched_blue;
		$conditions4big_streams->{_last_parameter_index_touched_grey}  = $last_parameter_index_touched_grey;
		$conditions4big_streams->{_last_parameter_index_touched_pink}  = $last_parameter_index_touched_pink;
		$conditions4big_streams->{_last_parameter_index_touched_green} = $last_parameter_index_touched_green;
		$conditions4big_streams->{_last_parameter_index_touched_blue}  = $last_parameter_index_touched_blue;
		$conditions4big_streams->{_last_parameter_index_touched_color} = $last_parameter_index_touched_color;
		$conditions4big_streams->{_last_flow_index_touched}            = $last_flow_index_touched;
		$conditions4big_streams->{_names_aref}                         = $names_aref;
		$conditions4big_streams->{_occupied_listbox_aref}              = $occupied_listbox_aref;
		$conditions4big_streams->{_parameter_values_frame}             = $parameter_values_frame;
		$conditions4big_streams->{_path}                               = $path;
		$conditions4big_streams->{_prog_name_sref}                     = $prog_name_sref;
		$conditions4big_streams->{_sub_ref}                            = $sub_ref;

		#				$conditions4big_streams->{_vacant_listbox_aref}   = $vacant_listbox_aref;
		$conditions4big_streams->{_values_aref}       = $values_aref;
		$conditions4big_streams->{_wipe_plots_button} = $wipe_plots_button;

		# print("conditions4big_streams, get_hash_ref , conditions4big_streams->{_flowNsuperflow_name_w: $conditions4big_streams->{_flowNsuperflow_name_w}\n");

		return ($conditions4big_streams);

	} else {
		print("conditions4big_streams, get_hash_ref , missing hconditions4big_streams hash_ref\n");
	}
}

=head2

 25 off  only reset the conditional parameters, not the widgets and other information

=cut

sub reset {
	my ($self) = @_;

	# location within GUI
	$conditions4big_streams->{_has_used_check_code_button}     = $false;
	$conditions4big_streams->{_has_used_run_button}            = $false;
	$conditions4big_streams->{_is_Save_button}                 = $false;
	$conditions4big_streams->{_is_add2flow_button}             = $false;
	$conditions4big_streams->{_is_check_code_button}           = $false;
	$conditions4big_streams->{_is_delete_from_flow_button}     = $false;
	$conditions4big_streams->{_is_dragNdrop}                   = $false;
	$conditions4big_streams->{_is_flow_item_down_arrow_button} = $false;
	$conditions4big_streams->{_is_flow_item_up_arrow_button}   = $false;
	$conditions4big_streams->{_is_flow_listbox_grey_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_pink_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_green_w}        = $false;
	$conditions4big_streams->{_is_flow_listbox_blue_w}         = $false;
	$conditions4big_streams->{_is_flow_listbox_color_w}        = $false;
	$conditions4big_streams->{_is_open_file_button}            = $false;
	$conditions4big_streams->{_is_select_file_button}          = $false;
	$conditions4big_streams->{_is_SaveAs_file_button}          = $false;
	$conditions4big_streams->{_is_sunix_listbox}               = $false;
	$conditions4big_streams->{_is_new_listbox_selection}       = $false;
	$conditions4big_streams->{_is_superflow_select_button}     = $false;
	$conditions4big_streams->{_is_run_button}                  = $false;
	$conditions4big_streams->{_is_pre_built_superflow}         = $false;
	$conditions4big_streams->{_is_superflow}                   = $false;    # for deprecation TODO
	$conditions4big_streams->{_is_user_built_flow}             = $false;
	$conditions4big_streams->{_is_moveNdrop_in_flow}           = $false;
	$conditions4big_streams->{_is_wipe_plots_button}           = $false;

}

=head2 sub set_flow_color


=cut 

sub set_flow_color {
	my ( $self, $color ) = @_;

	if ($color) {

		$conditions4big_streams->{_flow_color} = $color;
		$flow_color = $color;                               # export via get_hash_ref

	} else {

		# my $parameter					 			= '_is_flow_listbox_'.$color.'_w';
		# $conditions4big_streams->{$parameter} 				 = $true;
		print("conditions4big_streams, set_flow_color, missing color\n");
	}
	return ();
}

=head2 sub set_gui_widgets

	bring it important widget addresses
	
	29 and 29
	
=cut

sub set_gui_widgets {
	my ( $self, $widget_hash_ref ) = @_;

	if ($widget_hash_ref) {

		$conditions4big_streams->{_Data_menubutton}             = $widget_hash_ref->{_Data_menubutton};
		$conditions4big_streams->{_Flow_menubutton}             = $widget_hash_ref->{_Flow_menubutton};
		$conditions4big_streams->{_SaveAs_menubutton}           = $widget_hash_ref->{_SaveAs_menubutton};
		$conditions4big_streams->{_add2flow_button_grey}        = $widget_hash_ref->{_add2flow_button_grey};
		$conditions4big_streams->{_add2flow_button_pink}        = $widget_hash_ref->{_add2flow_button_pink};
		$conditions4big_streams->{_add2flow_button_green}       = $widget_hash_ref->{_add2flow_button_green};
		$conditions4big_streams->{_add2flow_button_blue}        = $widget_hash_ref->{_add2flow_button_blue};
		$conditions4big_streams->{_check_buttons_w_aref}        = $widget_hash_ref->{_check_buttons_w_aref};
		$conditions4big_streams->{_check_code_button}           = $widget_hash_ref->{_check_code_button};
		$conditions4big_streams->{_delete_from_flow_button}     = $widget_hash_ref->{_delete_from_flow_button};
		$conditions4big_streams->{_file_menubutton}             = $widget_hash_ref->{_file_menubutton};
		$conditions4big_streams->{_flowNsuperflow_name_w}       = $widget_hash_ref->{_flowNsuperflow_name_w};
		$conditions4big_streams->{_flow_color}                  = $widget_hash_ref->{_flow_color};
		$conditions4big_streams->{_flow_item_down_arrow_button} = $widget_hash_ref->{_flow_item_down_arrow_button};
		$conditions4big_streams->{_flow_item_up_arrow_button}   = $widget_hash_ref->{_flow_item_up_arrow_button};
		$conditions4big_streams->{_flow_listbox_grey_w}         = $widget_hash_ref->{_flow_listbox_grey_w};
		$conditions4big_streams->{_flow_listbox_pink_w}         = $widget_hash_ref->{_flow_listbox_pink_w};
		$conditions4big_streams->{_flow_listbox_green_w}        = $widget_hash_ref->{_flow_listbox_green_w};
		$conditions4big_streams->{_flow_listbox_blue_w}         = $widget_hash_ref->{_flow_listbox_blue_w};
		$conditions4big_streams->{_flow_listbox_color_w}        = $widget_hash_ref->{_flow_listbox_color_w};
		$conditions4big_streams->{_flow_widget_index}           = $widget_hash_ref->{_flow_widget_index};
		$conditions4big_streams->{_labels_w_aref}               = $widget_hash_ref->{_labels_w_aref};
		$conditions4big_streams->{_message_w}                   = $widget_hash_ref->{_message_w};
		$conditions4big_streams->{_mw}                          = $widget_hash_ref->{_mw};
		$conditions4big_streams->{_parameter_values_frame}      = $widget_hash_ref->{_parameter_values_frame};
		$conditions4big_streams->{_parameter_value_index}       = $widget_hash_ref->{_parameter_value_index};
		$conditions4big_streams->{_run_button}                  = $widget_hash_ref->{_run_button};
		$conditions4big_streams->{_save_button}                 = $widget_hash_ref->{_save_button};
		$conditions4big_streams->{_values_w_aref}               = $widget_hash_ref->{_values_w_aref};
		$conditions4big_streams->{_wipe_plots_button}           = $widget_hash_ref->{_wipe_plots_button};

		$Data_menubutton             = $conditions4big_streams->{_Data_menubutton};
		$Flow_menubutton             = $conditions4big_streams->{_Flow_menubutton};
		$SaveAs_menubutton           = $conditions4big_streams->{_SaveAs_menubutton};
		$add2flow_button_grey        = $conditions4big_streams->{_add2flow_button_grey};
		$add2flow_button_pink        = $conditions4big_streams->{_add2flow_button_pink};
		$add2flow_button_green       = $conditions4big_streams->{_add2flow_button_green};
		$add2flow_button_blue        = $conditions4big_streams->{_add2flow_button_blue};
		$check_buttons_w_aref        = $conditions4big_streams->{_check_buttons_w_aref};
		$check_code_button           = $conditions4big_streams->{_check_code_button};
		$delete_from_flow_button     = $conditions4big_streams->{_delete_from_flow_button};
		$file_menubutton             = $conditions4big_streams->{_file_menubutton};
		$flowNsuperflow_name_w       = $conditions4big_streams->{_flowNsuperflow_name_w};
		$flow_color                  = $conditions4big_streams->{_flow_color};
		$flow_item_down_arrow_button = $conditions4big_streams->{_flow_item_down_arrow_button};
		$flow_item_up_arrow_button   = $conditions4big_streams->{_flow_item_up_arrow_button};
		$flow_listbox_grey_w         = $conditions4big_streams->{_flow_listbox_grey_w};
		$flow_listbox_pink_w         = $conditions4big_streams->{_flow_listbox_pink_w};
		$flow_listbox_green_w        = $conditions4big_streams->{_flow_listbox_green_w};
		$flow_listbox_blue_w         = $conditions4big_streams->{_flow_listbox_blue_w};
		$flow_listbox_color_w        = $conditions4big_streams->{_flow_listbox_color_w};
		$flow_widget_index           = $conditions4big_streams->{_flow_widget_index};
		$labels_w_aref               = $conditions4big_streams->{_labels_w_aref};
		$message_w                   = $conditions4big_streams->{_message_w};
		$mw                          = $conditions4big_streams->{_mw};
		$parameter_values_frame      = $conditions4big_streams->{_parameter_values_frame};
		$parameter_value_index       = $conditions4big_streams->{_parameter_value_index};
		$run_button                  = $conditions4big_streams->{_run_button};
		$save_button                 = $conditions4big_streams->{_save_button};
		$values_w_aref               = $conditions4big_streams->{_values_w_aref};
		$wipe_plots_button           = $conditions4big_streams->{_wipe_plots_button};

		# print("conditions4big_streams, set_gui_widgets , conditions4big_streams->{_delete_from_flow_button: $conditions4big_streams->{_delete_from_flow_button}\n");
		# print("conditions4big_streams,  set_gui_widgets, conditions4big_streams->{_flowNsuperflow_name_w: $conditions4big_streams->{_flowNsuperflow_name_w}\n");

	} else {

		print("conditions4big_streams, set_gui_widgets , missing hash_ref\n");
	}
	return ();
}

=head2 sub set_hash_ref

	bring in important (1) last flow index, (1) prog name and (22) conditions
	does not include widgets
	widgets are boruught in with set_gui_widgets
	
=cut

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {

		#		$conditions4big_streams->{_big_stream_name_in}               = $hash_ref->{_big_stream_name_in};
		#		$conditions4big_streams->{_big_stream_name_out}              = $hash_ref->{_big_stream_name_out};
		$conditions4big_streams->{check_buttons_settings_aref}  = $hash_ref->{_check_buttons_settings_aref};
		$conditions4big_streams->{_dialog_type}                 = $hash_ref->{_dialog_type};
		$conditions4big_streams->{_flow_color}                  = $hash_ref->{_flow_color};
		$conditions4big_streams->{_flow_item_down_arrow_button} = $hash_ref->{_flow_item_down_arrow_button};
		$conditions4big_streams->{_flow_item_up_arrow_button}   = $hash_ref->{_flow_item_up_arrow_button};
		$conditions4big_streams->{_flow_name_in}                = $hash_ref->{_flow_name_in};

		#		$conditions4big_streams->{_flow_name_in_blue}                = $hash_ref->{_flow_name_in_blue};
		#		$conditions4big_streams->{_flow_name_in_grey}                = $hash_ref->{_flow_name_in_grey};
		#		$conditions4big_streams->{_flow_name_in_green}               = $hash_ref->{_flow_name_in_green};
		#		$conditions4big_streams->{_flow_name_in_pink}                = $hash_ref->{_flow_name_in_pink};
		$conditions4big_streams->{_flow_name_out} = $hash_ref->{_flow_name_out};

		#		$conditions4big_streams->{_flow_name_out_blue}               = $hash_ref->{_flow_name_out_blue};
		#		$conditions4big_streams->{_flow_name_out_grey}               = $hash_ref->{_flow_name_out_grey};
		#		$conditions4big_streams->{_flow_name_out_green}              = $hash_ref->{_flow_name_out_green};
		#		$conditions4big_streams->{_flow_name_out_pink}               = $hash_ref->{_flow_name_out_pink};
		$conditions4big_streams->{_flow_type}                        = $hash_ref->{_flow_type};
		$conditions4big_streams->{_flow_widget_index}                = $hash_ref->{_flow_widget_index};
		$conditions4big_streams->{_gui_history_ref}                  = $hash_ref->{_gui_history_ref};
		$conditions4big_streams->{_has_used_check_code_button}       = $hash_ref->{_has_used_check_code_button};
		$conditions4big_streams->{_has_used_open_perl_file_button}   = $hash_ref->{_has_used_open_perl_file_button};
		$conditions4big_streams->{_has_used_run_button}              = $hash_ref->{_has_used_run_button};
		$conditions4big_streams->{_has_used_SaveAs_button}           = $hash_ref->{_has_used_SaveAs_button};
		$conditions4big_streams->{_has_used_Save_button}             = $hash_ref->{_has_used_Save_button};
		$conditions4big_streams->{_has_used_Save_superflow}          = $hash_ref->{_has_used_Save_superflow};
		$conditions4big_streams->{_is_add2flow_button}               = $hash_ref->{_is_add2flow_button};
		$conditions4big_streams->{_is_check_code_button}             = $hash_ref->{_is_check_code_button};
		$conditions4big_streams->{_is_delete_from_flow_button}       = $hash_ref->{_is_delete_from_flow_button};
		$conditions4big_streams->{_is_dragNdrop}                     = $hash_ref->{_is_dragNdrop};
		$conditions4big_streams->{_is_flow_item_down_arrow_button}   = $hash_ref->{_is_flow_item_down_arrow_button};
		$conditions4big_streams->{_is_flow_item_up_arrow_button}     = $hash_ref->{_is_flow_item_up_arrow_button};
		$conditions4big_streams->{_is_flow_listbox_grey_w}           = $hash_ref->{_is_flow_listbox_grey_w};
		$conditions4big_streams->{_is_flow_listbox_pink_w}           = $hash_ref->{_is_flow_listbox_pink_w};
		$conditions4big_streams->{_is_flow_listbox_green_w}          = $hash_ref->{_is_flow_listbox_green_w};
		$conditions4big_streams->{_is_flow_listbox_blue_w}           = $hash_ref->{_is_flow_listbox_blue_w};
		$conditions4big_streams->{_is_future_flow_listbox_grey}      = $hash_ref->{_is_future_flow_listbox_grey};
		$conditions4big_streams->{_is_future_flow_listbox_pink}      = $hash_ref->{_is_future_flow_listbox_pink};
		$conditions4big_streams->{_is_future_flow_listbox_green}     = $hash_ref->{_is_future_flow_listbox_green};
		$conditions4big_streams->{_is_future_flow_listbox_blue}      = $hash_ref->{_is_future_flow_listbox_blue};
		$conditions4big_streams->{_is_last_flow_index_touched}       = $hash_ref->{_is_last_flow_index_touched};
		$conditions4big_streams->{_is_last_flow_index_touched_grey}  = $hash_ref->{_is_last_flow_index_touched_grey};
		$conditions4big_streams->{_is_last_flow_index_touched_pink}  = $hash_ref->{_is_last_flow_index_touched_pink};
		$conditions4big_streams->{_is_last_flow_index_touched_green} = $hash_ref->{_is_last_flow_index_touched_green};
		$conditions4big_streams->{_is_last_flow_index_touched_blue}  = $hash_ref->{_is_last_flow_index_touched_blue};
		$conditions4big_streams->{_is_last_parameter_index_touched_color}
			= $hash_ref->{_is_last_parameter_index_touched_color};
		$conditions4big_streams->{_is_last_parameter_index_touched_grey}
			= $hash_ref->{_is_last_parameter_index_touched_grey};
		$conditions4big_streams->{_is_last_parameter_index_touched_pink}
			= $hash_ref->{_is_last_parameter_index_touched_pink};
		$conditions4big_streams->{_is_last_parameter_index_touched_green}
			= $hash_ref->{_is_last_parameter_index_touched_green};
		$conditions4big_streams->{_is_last_parameter_index_touched_blue}
			= $hash_ref->{_is_last_parameter_index_touched_blue};
		$conditions4big_streams->{_is_lightning} = $hash_ref->{_is_lightning};
		$conditions4big_streams->{_is_last_parameter_index_touched_blue}
			= $hash_ref->{_is_last_parameter_index_touched_blue};
		$conditions4big_streams->{_is_open_file_button}        = $hash_ref->{_is_open_file_button};
		$conditions4big_streams->{_is_run_button}              = $hash_ref->{_is_run_button};
		$conditions4big_streams->{_is_moveNdrop_in_flow}       = $hash_ref->{_is_moveNdrop_in_flow};
		$conditions4big_streams->{_is_user_built_flow}         = $hash_ref->{_is_user_built_flow};
		$conditions4big_streams->{_is_select_file_button}      = $hash_ref->{_is_select_file_button};
		$conditions4big_streams->{_is_selected_file_name}      = $hash_ref->{_is_selected_file_name};
		$conditions4big_streams->{_is_selected_path}           = $hash_ref->{_is_selected_path};
		$conditions4big_streams->{_is_Save_button}             = $hash_ref->{_is_Save_button};
		$conditions4big_streams->{_is_SaveAs_button}           = $hash_ref->{_is_SaveAs_button};
		$conditions4big_streams->{_is_SaveAs_file_button}      = $hash_ref->{_is_SaveAs_file_button};
		$conditions4big_streams->{_is_sunix_listbox}           = $hash_ref->{_is_sunix_listbox};
		$conditions4big_streams->{_is_new_listbox_selection}   = $hash_ref->{_is_new_listbox_selection};
		$conditions4big_streams->{_is_pre_built_superflow}     = $hash_ref->{_is_pre_built_superflow};
		$conditions4big_streams->{_is_superflow_select_button} = $hash_ref->{_is_superflow_select_button};
		$conditions4big_streams->{_is_superflow}         = $hash_ref->{_is_superflow};           # for deprecation TODO
		$conditions4big_streams->{_is_moveNdrop_in_flow} = $hash_ref->{_is_moveNdrop_in_flow};
		$conditions4big_streams->{_is_wipe_plots_button} = $hash_ref->{_is_wipe_plots_button};

		#		$conditions4big_streams->{_last_flow_color} =
		#			$hash_ref->{_last_flow_color};    # used in flow_select
		$conditions4big_streams->{_last_flow_index_touched}           = $hash_ref->{_last_flow_index_touched};
		$conditions4big_streams->{_last_flow_index_touched_grey}      = $hash_ref->{_last_flow_index_touched_grey};
		$conditions4big_streams->{_last_flow_index_touched_pink}      = $hash_ref->{_last_flow_index_touched_pink};
		$conditions4big_streams->{_last_flow_index_touched_green}     = $hash_ref->{_last_flow_index_touched_green};
		$conditions4big_streams->{_last_flow_index_touched_blue}      = $hash_ref->{_last_flow_index_touched_blue};
		$conditions4big_streams->{_last_parameter_index_touched_grey} = $hash_ref->{_last_parameter_index_touched_grey};
		$conditions4big_streams->{_last_parameter_index_touched_pink} = $hash_ref->{_last_parameter_index_touched_pink};
		$conditions4big_streams->{_last_parameter_index_touched_green}
			= $hash_ref->{_last_parameter_index_touched_green};
		$conditions4big_streams->{_last_parameter_index_touched_blue} = $hash_ref->{_last_parameter_index_touched_blue};
		$conditions4big_streams->{_last_parameter_index_touched_color}
			= $hash_ref->{_last_parameter_index_touched_color};
		$conditions4big_streams->{_occupied_listbox_aref} = $hash_ref->{_occupied_listbox_aref};
		$conditions4big_streams->{_path}                  = $hash_ref->{_path};
		$conditions4big_streams->{_prog_name_sref}        = $hash_ref->{_prog_name_sref};
		$conditions4big_streams->{_sub_ref}               = $hash_ref->{_sub_ref};
		$conditions4big_streams->{_names_aref}            = $hash_ref->{_names_aref};

		#				$conditions4big_streams->{_vacant_listbox_aref} =
		#			$hash_ref->{_vacant_listbox_aref};
		$conditions4big_streams->{_values_aref}       = $hash_ref->{_values_aref};
		$conditions4big_streams->{_wipe_plots_button} = $hash_ref->{_wipe_plots_button};
		$check_buttons_settings_aref                  = $hash_ref->{_check_buttons_settings_aref};
		$dialog_type                                  = $hash_ref->{_dialog_type};
		$flow_color                                   = $hash_ref->{_flow_color};
		$flow_item_down_arrow_button                  = $hash_ref->{_flow_item_down_arrow_button};
		$flow_item_up_arrow_button                    = $hash_ref->{_flow_item_up_arrow_button};
		$flow_type                                    = $hash_ref->{_flow_type};
		$flow_widget_index                            = $hash_ref->{_flow_widget_index};
		$gui_history_ref                              = $hash_ref->{_gui_history_ref};
		$has_used_check_code_button                   = $hash_ref->{_has_used_check_code_button};
		$has_used_open_perl_file_button               = $hash_ref->{_has_used_open_perl_file_button};
		$has_used_run_button                          = $hash_ref->{_has_used_run_button};
		$has_used_SaveAs_button                       = $hash_ref->{_has_used_SaveAs_button};
		$has_used_Save_button                         = $hash_ref->{_has_used_Save_button};
		$has_used_Save_superflow                      = $hash_ref->{_has_used_Save_superflow};
		$is_add2flow_button                           = $hash_ref->{_is_add2flow_button};
		$is_check_code_button                         = $hash_ref->{_is_check_code_button};
		$is_dragNdrop                                 = $hash_ref->{_is_dragNdrop};
		$is_delete_from_flow_button                   = $hash_ref->{_is_delete_from_flow_button};
		$is_flow_item_down_arrow_button               = $hash_ref->{_is_flow_item_down_arrow_button};
		$is_flow_item_up_arrow_button                 = $hash_ref->{_is_flow_item_up_arrow_button};
		$is_flow_listbox_grey_w                       = $hash_ref->{_is_flow_listbox_grey_w};
		$is_flow_listbox_pink_w                       = $hash_ref->{_is_flow_listbox_pink_w};
		$is_flow_listbox_green_w                      = $hash_ref->{_is_flow_listbox_green_w};
		$is_flow_listbox_blue_w                       = $hash_ref->{_is_flow_listbox_blue_w};
		$is_flow_listbox_color_w                      = $hash_ref->{_is_flow_listbox_color_w};
		$is_future_flow_listbox_grey                  = $hash_ref->{_is_future_flow_listbox_grey};
		$is_future_flow_listbox_pink                  = $hash_ref->{_is_future_flow_listbox_pink};
		$is_future_flow_listbox_green                 = $hash_ref->{_is_future_flow_listbox_green};
		$is_future_flow_listbox_blue                  = $hash_ref->{_is_future_flow_listbox_blue};
		$is_last_flow_index_touched_grey              = $hash_ref->{_is_last_flow_index_touched_grey};
		$is_last_flow_index_touched_pink              = $hash_ref->{_is_last_flow_index_touched_pink};
		$is_last_flow_index_touched_green             = $hash_ref->{_is_last_flow_index_touched_green};
		$is_last_flow_index_touched_blue              = $hash_ref->{_is_last_flow_index_touched_blue};
		$is_last_flow_index_touched                   = $hash_ref->{_is_last_flow_index_touched};
		$is_last_parameter_index_touched_grey         = $hash_ref->{_is_last_parameter_index_touched_grey};
		$is_last_parameter_index_touched_pink         = $hash_ref->{_is_last_parameter_index_touched_pink};
		$is_last_parameter_index_touched_green        = $hash_ref->{_is_last_parameter_index_touched_green};
		$is_last_parameter_index_touched_blue         = $hash_ref->{_is_last_parameter_index_touched_blue};
		$is_open_file_button                          = $hash_ref->{_is_open_file_button};
		$is_run_button                                = $hash_ref->{_is_run_button};
		$is_moveNdrop_in_flow                         = $hash_ref->{_is_moveNdrop_in_flow};
		$is_user_built_flow                           = $hash_ref->{_is_user_built_flow};
		$is_select_file_button                        = $hash_ref->{_is_select_file_button};
		$is_selected_file_name                        = $hash_ref->{_is_selected_file_name};
		$is_selected_path                             = $hash_ref->{_is_selected_path};
		$is_Save_button                               = $hash_ref->{_is_Save_button};
		$is_SaveAs_button                             = $hash_ref->{_is_SaveAs_button};
		$is_SaveAs_file_button                        = $hash_ref->{_is_SaveAs_file_button};
		$is_sunix_listbox                             = $hash_ref->{_is_sunix_listbox};
		$is_new_listbox_selection                     = $hash_ref->{_is_new_listbox_selection};
		$is_pre_built_superflow                       = $hash_ref->{_is_pre_built_superflow};
		$is_superflow_select_button                   = $hash_ref->{_is_superflow_select_button};
		$is_superflow                                 = $hash_ref->{_is_superflow};           # for deprecation TODO
		$is_moveNdrop_in_flow                         = $hash_ref->{_is_moveNdrop_in_flow};
		$is_wipe_plots_button                         = $hash_ref->{_is_wipe_plots_button};

		#		$last_flow_color      = $hash_ref->{_last_flow_color};
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

		#		$occupied_listbox_aref = $hash_ref->{_vacant_listbox_aref};
		$path              = $hash_ref->{_path};
		$prog_name_sref    = $hash_ref->{_prog_name_sref};
		$sub_ref           = $hash_ref->{_sub_ref};
		$names_aref        = $hash_ref->{_names_aref};          # equiv labels
		$values_aref       = $hash_ref->{_values_aref};
		$wipe_plots_button = $hash_ref->{_wipe_plots_button};

	} else {

		print("conditions4big_streams, set_hash_ref , missing hash_ref\n");
	}
	return ();
}

=head2


=cut

sub set4_check_code_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4big_streams, set4end_of_check_code_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_has_used_check_code_button} = $true;

	# for potential export via get_hash_ref
	$has_used_check_code_button = $true;

	return ();
}

#=head2
#
#
#=cut
#
#
# sub  set4FileDialog_select_start {
#	my ($self) = @_;
#	#_reset();
#	 #  ERROR if _reset() the param_widgets table is reset;
#	 #  ERROR if _reset() the 	 #  f
#    $conditions4big_streams->{_is_select_file_button}					= $true;
#    # print("conditions4big_streams,set4FileDialog_select_start  $conditions4big_streams->{_is_select_file_button} 	\n");
#    #print("conditions4big_streams,set4FileDialog_open_start,listbox_l listbox_r  $conditions4big_streams->{_is_flow_listbox_grey_w} 	$conditions4big_streams->{_is_flow_listbox_green_w}\n");
#
#	return();
# }
#
#=head2
#
#
#=cut
#
#
#sub  set4FileDialog_select_end {
#	my ($self) = @_;
#    $conditions4big_streams->{_is_select_file_button}		= $false;
#    # print("conditions4big_streams,set4FileDialog_select_end  $conditions4big_streams->{_is_select_file_button}\n");
#    #print("conditions4big_streams,set4FileDialog_open_start,listbox_l listbox_r  $conditions4big_streams->{_is_flow_listbox_grey_w} 	$conditions4big_streams->{_is_flow_listbox_green_w}\n");
#
#	return();
#}

=head2 sub  set4FileDialog_SaveAs_end 


=cut

sub set4FileDialog_SaveAs_end {
	my ($self) = @_;

	$conditions4big_streams->{_is_SaveAs_file_button}  = $false;
	$conditions4big_streams->{_has_used_SaveAs_button} = $true;

	# for potential export via get_hash_ref
	$is_SaveAs_file_button  = $false;
	$has_used_SaveAs_button = $true;

	# clean path
	# $conditions4big_streams->{_path}						= '';
	# print("conditions4big_streams,set4FileDialog_SaveAs_end
	# $conditions4big_streams->{_is_SaveAs_file_button}\n");
	return ();
}

=head2 sub  set4FileDialog_open_end


=cut

sub set4FileDialog_open_end {
	my ($self) = @_;

	$conditions4big_streams->{_is_open_file_button} = $false;

	# for potential export via get_hash_ref
	$is_open_file_button = $false;

	# print("conditions4big_streams,set4FileDialog_open_end  $conditions4big_streams->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_perl_file_end


=cut

sub set4FileDialog_open_perl_file_end {
	my ($self) = @_;

	$conditions4big_streams->{_is_open_file_button}            = $false;
	$conditions4big_streams->{_has_used_open_perl_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button            = $false;
	$has_used_open_perl_file_button = $true;

	# print("conditions4big_streams,set4FileDialog_open_perl_file_end  $conditions4big_streams->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_start


=cut

sub set4FileDialog_open_start {

	my ($self) = @_;

	$conditions4big_streams->{_is_open_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button = $true;

	# print("conditions4big_streams,set4FileDialog_open_start _is_open_file_button}:  $conditions4big_streams->{_is_open_file_button}\n");

	return ();
}

=head2 sub  set4FileDialog_open_perl_file_start


=cut

sub set4FileDialog_open_perl_file_start {

	my ($self) = @_;

	$conditions4big_streams->{_is_open_file_button} = $true;

	# for potential export via get_hash_ref
	$is_open_file_button = $true;

	# print("conditions4big_streams,set4FileDialog_open_perl_file_start _is_open_file_button}:  $conditions4big_streams->{_is_open_file_button}\n");

	return ();
}

=head2


=cut

sub set4FileDialog_SaveAs_start {
	my ($self) = @_;

	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	$conditions4big_streams->{_is_SaveAs_file_button} = $true;
	$conditions4big_streams->{_is_SaveAs_button}      = $true;

	# for potential export via get_hash_ref
	$is_SaveAs_file_button = $true;
	$is_SaveAs_button      = $true;

	if ( $conditions4big_streams->{_flow_type} eq $flow_type_h->{_user_built} ) {
		$conditions4big_streams->{_is_user_built_flow}     = $true;
		$conditions4big_streams->{_is_pre_built_superflow} = $false;

		# for potential export via get_hash_ref
		$is_user_built_flow     = $true;
		$is_pre_built_superflow = $false;

	} elsif ( $conditions4big_streams->{_flow_type} eq $flow_type_h->{_pre_built_superflow} ) {

		$conditions4big_streams->{_user_built_flow}        = $false;
		$conditions4big_streams->{_is_pre_built_superflow} = $true;

		# for potential export via get_hash_ref
		$is_user_built_flow     = $false;
		$is_pre_built_superflow = $true;
	}

	# print("conditions4big_streams,set4FileDialog_SaveAs_start
	# $conditions4big_streams->{_is_SaveAs_file_button}\n");
	return ();
}

=head2


=cut

sub set4_Save_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4big_streams, set4end_of_save_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_has_used_Save_button} = $true;

	return ();
}

=head2 sub set4_end_of_SaveAs_button


=cut

sub set4_end_of_SaveAs_button {
	my ($self) = @_;

	$conditions4big_streams->{_has_used_SaveAs_button} = $true;
	$conditions4big_streams->{_is_SaveAs_button}       = $false;

	_reset_is_flow_listbox_color_w();

	if ( $conditions4big_streams->{_flow_color} eq 'grey' ) {
		$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'pink' ) {
		$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'green' ) {
		$conditions4big_streams->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'blue' ) {
		$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4big_streams->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4big_streams,set4start_of_run_button Running a pre-built superflow\n");
		# NADA

	} else {
		print("2 conditions4big_streams,set4start_of_run_button missing color \n");
	}
	return ();

}

=head2 sub set4_start_of_SaveAs_button


=cut

sub set4_start_of_SaveAs_button {
	my ($self) = @_;

	$conditions4big_streams->{_is_SaveAs_button} = $true;

	return ();
}

=head2


=cut

sub set4end_of_check_code_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4big_streams, set4end_of_check_code_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_is_check_code_button} = $false;

	return ();
}

=head2


=cut

sub set4end_of_SaveAs_button {
	my ($self) = @_;

	$conditions4big_streams->{_is_SaveAs_button}       = $false;
	$conditions4big_streams->{_has_used_SaveAs_button} = $true;
	return ();
}

=head2


=cut

sub set4start_of_check_code_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4big_streams, set4start_of_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_is_check_code_button}       = $true;
	$conditions4big_streams->{_has_used_check_code_button} = $false;

	return ();
}

=head2 sub set4end_of_flow_item_up_arrow_button 

	when the arrow that moves flow items up a list is clicked

=cut

sub set4end_of_flow_item_up_arrow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		$conditions4big_streams->{_is_flow_item_up_arrow_button} = $true;
		_set_flow_color($color);

		# from color create general keys and assign values to those keys (text names)
		# from color generalize which colored flow is being used and set it true
		# save copies of values for reassignment during get_hash_ref call from outside modules
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';

		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;
		$conditions4big_streams->{_is_user_built_flow} = $true;

		$conditions4big_streams->{_flow_listbox_color_w} = $conditions4big_streams->{$flow_listbox_color_w_key};
		$flow_listbox_color_w = $conditions4big_streams->{$flow_listbox_color_w_key};

	} else {
		print("conditions4big_streams, set4end_of_flow_item_up_arrow_button, no color: $color\n");
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
#		$conditions4big_streams->{_is_wipe_plots_button} = $true;
#		_set_flow_color($color);
#
## from color create general keys and assign values to those keys (text names)
## from color generalize which colored flow is being used and set it true
## save copies of values for reassignment during get_hash_ref call from outside modules
#		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
#		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
#
#		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;
#		$conditions4big_streams->{_is_user_built_flow} = $true;
#
#		$conditions4big_streams->{_flow_listbox_color_w} =
#			$conditions4big_streams->{$flow_listbox_color_w_key};
#		$flow_listbox_color_w = $conditions4big_streams->{$flow_listbox_color_w_key};
#
#	}
#	else {
#		print(
#			"conditions4big_streams, set4end_of_wipe_plots_button, no color: $color\n"
#		);
#	}
#
#	return ();
#}

=head2

   location within GUI
   
   foreach my $key (sort keys %$conditions4big_streams) {
     print ("conditions4big_streams user,set4end_of_flow_select,key is $key, value is $conditions4big_streams->{$key}\n");
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
		# print("conditions4big_streams, set4end_of_flow_select, color:$color\n");
		# print("1. conditions4big_streams, set4end_of_flow_select,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
		# print("1. conditions4big_streams, set4end_of_flow_select, is_flow_listbox_color_w: $is_flow_listbox_color_w \n");
		# $conditions4big_streams->{$is_flow_listbox_color_w_key}			= $true;
		# my $ans = $conditions4big_streams->{$is_flow_listbox_color_w_key};
		# print("1. conditions4big_streams, set4end_of_flow_select, is_flow_listbox_color_w: $ans is EMPTY\n");

		$conditions4big_streams->{_flow_color}                 = $color;
		$conditions4big_streams->{_is_delete_from_flow_button} = $true;
		$conditions4big_streams->{_is_flow_listbox_color_w}    = $true;

		$conditions4big_streams->{_flow_item_down_arrow_button} = $true;
		$conditions4big_streams->{_flow_item_up_arrow_button}   = $true;

		# Because the flow is selected automatically without user clicking,
		# as the case of when a perl flow has been read in, then
		# at least the grey flow listbox will have been touched
		# which is not the case when flow_select is directly chosen
		# Note that _flow_select points to flow_select, so do not complicate yourself
		# and place these requirements into _flow_select
		if ( $color eq 'grey' ) {

			$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;

			$conditions4big_streams->{_is_last_flow_index_touched_grey}      = $true;
			$conditions4big_streams->{_is_last_parameter_index_touched_grey} = $true;

			# for export
			$is_flow_listbox_grey_w                = $true;
			$is_last_flow_index_touched_grey       = $true;
			$is_last_parameter_index_touched_grey  = $true;
			$is_last_parameter_index_touched_color = $true;

			# print("conditions4big_streams, set4end_of_flow_select,is_last_parameter_index_touched_grey=$is_last_parameter_index_touched_grey\n");
			# print("conditions4big_streams, set4end_of_flow_select,is_last_flow_index_touched_grey=$is_last_flow_index_touched_grey\n");

		} elsif ( $color eq 'pink' ) {

			$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;

			# for export
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {

			$conditions4big_streams->{_is_flow_listbox_green_w} = $true;

			# for export
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {

			$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;

			# for export
			$is_flow_listbox_blue_w = $true;

		} else {
			print("conditions4big_streams, set4end_of_flow_select , color missing: $color\n");
		}

	} else {
		print("conditions4big_streams, set4end_of_flow_select , color missing: $color\n");
	}

	#		my $ans = $conditions4big_streams->{$is_flow_listbox_color_w};
	#	   	print("conditions4big_streams, set4end_of_flow_select, color:$color\n");
	#   		print("conditions4big_streams, set4end_of_flow_select, is_flow_listbox_color_w 'grey pink green or blue'_w: $ans \n");

	return ();
}

=head2 sub set4end_of_run_button

location within GUI 

	sets 
	conditions4big_streams

=cut

sub set4end_of_run_button {
	my ($self) = @_;

	# location within GUI
	$conditions4big_streams->{_is_run_button}           = $false;
	$conditions4big_streams->{_has_used_run_button}     = $false;
	$conditions4big_streams->{_has_used_Save_button}    = $false;
	$conditions4big_streams->{_has_used_Save_superflow} = $false;
	$conditions4big_streams->{_last_flow_index_touched} = -1;

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
	conditions4big_streams

=cut

sub set4end_of_run_superflow {

	# location within GUI
	$conditions4big_streams->{_is_run_button}           = $false;
	$conditions4big_streams->{_has_used_Save_superflow} = $true;

	# for potential export
	$is_run_button           = $false;
	$has_used_Save_superflow = $true;    # allows re-use of run_button

	return ();
}

=head2


=cut

sub set4start_of_Save_button {
	my ($self) = @_;

	# print("1. conditions4big_streams, set4start_of_Save_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_is_Save_button}       = $true;
	$conditions4big_streams->{_has_used_Save_button} = $false;

	# for potential export
	$is_Save_button       = $true;
	$has_used_Save_button = $false;

	return ();
}

=head2


=cut

sub set4start_of_SaveAs_button {
	my ($self) = @_;

	# print("1. conditions4big_streams, set4start_of_Save_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_is_SaveAs_button}       = $true;
	$conditions4big_streams->{_has_used_SaveAs_button} = $false;

	# for potential export
	$is_SaveAs_button       = $true;
	$has_used_SaveAs_button = $false;

	return ();
}

sub set4end_of_sunix_select {
	my ($self) = @_;

	_set_gui_widgets();

	$add2flow_button_grey->configure( -state => 'normal', );
	$add2flow_button_pink->configure( -state => 'normal', );
	$add2flow_button_green->configure( -state => 'normal', );
	$add2flow_button_blue->configure( -state => 'normal', );

	#   	$conditions4big_streams->{_is_flow_listbox_grey_w}			= $false;
	#   	$conditions4big_streams->{_is_flow_listbox_pink_w}			= $false;
	#   	$conditions4big_streams->{_is_flow_listbox_green_w}			= $false;
	#   	$conditions4big_streams->{_is_flow_listbox_blue_w}			= $false;
	#   	$conditions4big_streams->{_is_flow_listbox_color_w}			= $false;
	$conditions4big_streams->{_is_add2flow_button} = $true;

	# for export
	#   	$is_flow_listbox_grey_w								= $false;
	#   	$is_flow_listbox_pink_w								= $false;
	#   	$is_flow_listbox_green_w							= $false;
	#   	$is_flow_listbox_blue_w								= $false;
	#   	$is_flow_listbox_color_w							= $false;
	$is_add2flow_button = $true;

	# $conditions4big_streams->{_is_sunix_listbox} = $false;
}

=head2


=cut

sub set4end_of_Save_button {
	my ($self) = @_;

	# _conditions	->reset();
	# print("1. conditions4big_streams, set4end_of_save_button,last left listbox flow program touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
	# location within GUI
	$conditions4big_streams->{_is_Save_button}                 = $false;
	$conditions4big_streams->{_has_used_Save_button}           = $true;
	$conditions4big_streams->{_has_used_SaveAs_button}         = $false;
	$conditions4big_streams->{_has_used_open_perl_file_button} = $false;

	# for export
	$is_Save_button       = $false;    # a reset
	$has_used_Save_button = $true;

	# N.B. Save can only be used if SaveAs is true
	# But, after Save is used, reset SaveAs to false
	$has_used_SaveAs_button         = $false;
	$has_used_open_perl_file_button = $false;

	_reset_is_flow_listbox_color_w();

	if ( $conditions4big_streams->{_flow_color} eq 'grey' ) {
		$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'pink' ) {
		$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'green' ) {
		$conditions4big_streams->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'blue' ) {
		$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4big_streams->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4big_streams,set4end_of_save_button Running a pre-built superflow NADA\n");

	} else {
		print("2 conditions4big_streams,set4start_of_run_button missing color \n");
	}
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
	$conditions4big_streams->{_is_run_button}       = $true;
	$conditions4big_streams->{_has_used_run_button} = $true;

	# reset save and SaveAs options because
	# file must be saved before running, always
	$conditions4big_streams->{_has_used_SaveAs_button}         = $false;
	$conditions4big_streams->{_has_used_Save_button}           = $false;
	$conditions4big_streams->{_has_used_Save_superflow}        = $false;
	$conditions4big_streams->{_has_used_open_perl_file_button} = $false;

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
		$conditions4big_streams
		
		legacy?
		look at set4start_of_run_button and set4end_of_run_button

=cut

sub set4run_button_end {
	my ($self) = @_;

	# location within GUI
	$conditions4big_streams->{_is_run_button}       = $false;
	$conditions4big_streams->{_has_used_run_button} = $false;

	$is_run_button       = $false;
	$has_used_run_button = $false;

	return ();
}

=head2

	location within GUI on first clicking delete button

=cut

sub set4start_of_delete_from_flow_button {
	my ( $self, $color ) = @_;

	if ($color) {
		_reset();

		# print("conditions4big_streams, set4start_of_delete_from_flow_button, color: $color\n");
		$conditions4big_streams->{_is_delete_from_flow_button} = $true;
		$is_delete_from_flow_button = $true;
		_set_flow_color($color);

		# from color generalize which colored flow is being used and set it true
		# from color create general keys and assign values to those keys (text names)
		# save copies of values for reassignment during get_hash_ref call from outside modules

		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';    # true or false
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';       # value a widget hash
		$conditions4big_streams->{_flow_listbox_color_w} = $conditions4big_streams->{$flow_listbox_color_w_key};
		$conditions4big_streams->{_is_user_built_flow}   = $true;

		# set treu or false values for a colored flow ( the reset are assumed = 0)
		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;

		# set up for get_hash_ref call from outside module
		$is_user_built_flow      = $true;
		$is_flow_listbox_color_w = $true;

		if ( $color eq 'grey' ) {
			$flow_listbox_grey_w    = $conditions4big_streams->{$flow_listbox_color_w_key};
			$is_flow_listbox_grey_w = $true;

		} elsif ( $color eq 'pink' ) {
			$flow_listbox_pink_w    = $conditions4big_streams->{$flow_listbox_color_w_key};
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {
			$flow_listbox_green_w    = $conditions4big_streams->{$flow_listbox_color_w_key};
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {
			$flow_listbox_blue_w    = $conditions4big_streams->{$flow_listbox_color_w_key};
			$is_flow_listbox_blue_w = $true;
		}

		#   				print("conditions4big_streams, set4start_of_delete_from_flow_button, conditions4big_streams->$is_flow_listbox_color_w_key: $is_flow_listbox_color_w\n");
		#   				print("conditions4big_streams, set4start_of_delete_from_flow_button, conditions4big_streams->$flow_listbox_color_w_key: $flow_listbox_color_w\n");
		#   				print("conditions4big_streams, set4start_of_delete_from_flow_button, _is_flow_listbox_color_w_key: $is_flow_listbox_color_w_key\n");
		#   				print("conditions4big_streams, set4start_of_delete_from_flow_button, flow_listbox_color_w_key: $flow_listbox_color_w_key\n");

	} else {
		print("conditions4big_streams, set4start_of_delete_from_flow_button, no color: $color\n");
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

		$conditions4big_streams->{_is_flow_item_up_arrow_button} = $true;
		_set_flow_color($color);
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;
		$conditions4big_streams->{_is_user_built_flow} = $true;

		# set up for get_hash_ref call from outside module
		$is_user_built_flow      = $true;
		$is_flow_listbox_color_w = $true;

	} else {
		print("conditions4big_streams, set4start_of_flow_item_up_arrow_button, no color: $color\n");
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
#		$conditions4big_streams->{_is_wipe_plots_button} = $true;
#		_set_flow_color($color);
#		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';
#		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;
#		$conditions4big_streams->{_is_user_built_flow} = $true;
#
#		# set up for get_hash_ref call from outside module
#		$is_user_built_flow      = $true;
#		$is_flow_listbox_color_w = $true;
#
#	}
#	else {
#		print(
#			"conditions4big_streams, set4start_of_wipe_plots_button, no color: $color\n"
#		);
#	}
#
#	return ();
#}

=head2

take focus of the first Entry button/Value
for all listboxes
returns only a few parameters
All others have been reset to false

WARNING, _reset may make color disappear

=cut

sub set4start_of_flow_select {
	my ( $self, $color ) = @_;

	_reset();

	if ($color) {
		_set_flow_color($color);
		my $flow_listbox_color_w_key = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt = 'flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w     = $conditions4big_streams->{$flow_listbox_color_w_key};

		# print("conditions4big_streams, set4start_of_flow_select, color:$color; flow_listbox_color_w =$conditions4big_streams->{$flow_listbox_color_w_key}\n");

		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);
		_set_gui_widgets();
		_set_flow_listbox_last_touched_w($flow_listbox_color_w);

		# print("conditions4big_streams, set4start_of_flow_select, _set_flow_listbox_last_touched_w\n");

		# location within GUI
		if ( $color eq 'grey' ) {

			$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;

			# for export to calling module via get_hash_ref
			$is_flow_listbox_grey_w = $true;

		} elsif ( $color eq 'pink' ) {
			$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;

			# for export to calling module via get_hash_ref
			$is_flow_listbox_pink_w = $true;

		} elsif ( $color eq 'green' ) {

			$conditions4big_streams->{_is_flow_listbox_green_w} = $true;

			# for export to calling module via get_hash_ref
			$is_flow_listbox_green_w = $true;

		} elsif ( $color eq 'blue' ) {

			$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;

			# for export to calling module via get_hash_ref
			$is_flow_listbox_blue_w = $true;

		} else {
			print("conditions4big_streams, set4start_of_flow_select, missing color\n");
		}

		$conditions4big_streams->{_is_flow_listbox_color_w}    = $true;
		$conditions4big_streams->{_is_pre_built_superflow}     = $false;
		$conditions4big_streams->{_is_superflow}               = $false;
		$conditions4big_streams->{_is_superflow_select_button} = $false;
		$conditions4big_streams->{_is_user_built_flow}         = $true;

		$delete_from_flow_button->configure( -state => 'active', );
		$flow_item_down_arrow_button->configure( -state => 'active', );
		$flow_item_up_arrow_button->configure( -state => 'active', );
		$flow_listbox_grey_w->configure( -state => 'normal', );
		$flow_listbox_pink_w->configure( -state => 'normal', );
		$flow_listbox_green_w->configure( -state => 'normal', );
		$flow_listbox_blue_w->configure( -state => 'normal', );
		$check_code_button->configure( -state => 'normal', );

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
		$flow_item_up_arrow_button->configure( -state => 'active', );
		$flow_item_down_arrow_button->configure( -state => 'active', );

		#	$entry_button->focus
	} else {
		print("conditions4big_streams, set4start_of_flow_select, no color:$color\n");

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
	$conditions4big_streams->{_is_run_button} = $true;

	# for export to calling module via get_hash_ref
	$is_run_button = $true;

	return ();

}

=head2 sub set4end_of_add2flow

		sets 
			$conditions4big_streams
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

	# print("2 conditions4big_streams,set4end_of_add2flow  color: $color\n");

	if ($color) {
		_set_gui_widgets();
		_set_flow_color($color);

		my $add2flow_button_color       = _get_add2flow_button();
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt    = 'flow_listbox_' . $color . '_w';
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';

		my $flow_listbox_color_w = $conditions4big_streams->{$flow_listbox_color_w_key};

		# print("2 conditions4big_streams,set4end_of_add2flow  flow_listbox_color_w: $flow_listbox_color_w\n");

		_set_flow_listbox_last_touched_w($flow_listbox_color_w);
		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);

		# highlight new index
		$flow_listbox_color_w->selectionSet("end");

		# note the last program that was touched
		$conditions4big_streams->{_is_add2flow} = $false;
		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;

		# for potential export via get_hash-ref
		$is_add2flow             = $false;
		$is_flow_listbox_color_w = $true;

		# keep track of which listbox was just chosen
		# for possible export
		if ( $conditions4big_streams->{_flow_color} eq 'grey' ) {
			$is_flow_listbox_grey_w = $conditions4big_streams->{_is_flow_listbox_grey_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'pink' ) {
			$is_flow_listbox_pink_w = $conditions4big_streams->{_is_flow_listbox_pink_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'green' ) {
			$is_flow_listbox_green_w = $conditions4big_streams->{_is_flow_listbox_green_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'blue' ) {
			$is_flow_listbox_blue_w = $conditions4big_streams->{_is_flow_listbox_blue_w};

		} else {
			print("2 conditions4big_streams,set4end_of_add2flow_of_run_button missing color \n");
		}

		# disable All Add-to-flow buttons
		# regardless of only one button having been clicked
		# For all listboxes
		$add2flow_button_grey->configure( -state => 'disabled' );
		$add2flow_button_pink->configure( -state => 'disabled' );
		$add2flow_button_green->configure( -state => 'disabled' );
		$add2flow_button_blue->configure( -state => 'disabled' );

		# print("1 conditions4big_streams,set4end_of_add2flow_button color: $color\n");

		# set flow color back to neutral after add2flow ends
		_set_flow_color('neutral');

		# print("2 conditions4big_streams,set4end_of_add2flow color: $color\n");
		return ();

	} else {
		print("2 conditions4big_streams,set4end_of_add2flow reset color: $color\n");
	}

}

=head2 sub set4end_of_add2flow_button

		sets 
			$conditions4big_streams
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

	#	print("2 conditions4big_streams,set4end_of_add2flow_button  color: $color\n");

	if ($color) {
		_set_gui_widgets();
		_set_flow_color($color);

		my $add2flow_button_color       = _get_add2flow_button();
		my $flow_listbox_color_w_key    = '_flow_listbox_' . $color . '_w';
		my $flow_listbox_color_w_txt    = 'flow_listbox_' . $color . '_w';
		my $is_flow_listbox_color_w_key = '_is_flow_listbox_' . $color . '_w';

		my $flow_listbox_color_w = $conditions4big_streams->{$flow_listbox_color_w_key};

		# print("2 conditions4big_streams,set4end_of_add2flow_button  flow_listbox_color_w: $flow_listbox_color_w\n");

		_set_flow_listbox_last_touched_w($flow_listbox_color_w);
		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);

		# highlight new index
		$flow_listbox_color_w->selectionSet("end");

		# note the last program that was touched
		$conditions4big_streams->{_is_add2flow} = $false;
		$conditions4big_streams->{$is_flow_listbox_color_w_key} = $true;

		# for potential export via get_hash-ref
		$is_add2flow             = $false;
		$is_flow_listbox_color_w = $true;

		# keep track of which listbox was just chosen
		if ( $conditions4big_streams->{_flow_color} eq 'grey' ) {
			$is_flow_listbox_grey_w = $conditions4big_streams->{_is_flow_listbox_grey_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'pink' ) {
			$is_flow_listbox_pink_w = $conditions4big_streams->{_is_flow_listbox_pink_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'green' ) {
			$is_flow_listbox_green_w = $conditions4big_streams->{_is_flow_listbox_green_w};

		} elsif ( $conditions4big_streams->{_flow_color} eq 'blue' ) {
			$is_flow_listbox_blue_w = $conditions4big_streams->{_is_flow_listbox_blue_w};

		} else {
			print("2 conditions4big_streams,set4end_of_add2flow_button_of_run_button missing color \n");
		}

		# disable All Add-to-flow buttons
		# regardless of only one button having been clicked
		# For all listboxes
		$add2flow_button_grey->configure( -state => 'disabled' );
		$add2flow_button_pink->configure( -state => 'disabled' );
		$add2flow_button_green->configure( -state => 'disabled' );
		$add2flow_button_blue->configure( -state => 'disabled' );

		# print("1 conditions4big_streams,set4end_of_add2flow_button color: $color\n");

		# set flow color back to neutral after add2flow_button is clicked
		_set_flow_color('neutral');

		# print("2 conditions4big_streams,set4end_of_add2flow_button color: $color\n");
		return ();

	} else {
		print("2 conditions4big_streams,set4end_of_add2flow_button reset color: $color\n");
	}
}

=head2 sub set4end_of_superflow_Save 
	

=cut

sub set4end_of_superflow_Save {
	my ($self) = @_;

	# print("conditions4big_streams, set4end_of_superflow_Save OK \n");
	$conditions4big_streams->{_has_used_Save_superflow}    = $true;
	$conditions4big_streams->{_is_pre_built_superflow}     = $false;
	$conditions4big_streams->{_is_superflow}               = $false;
	$conditions4big_streams->{_is_superflow_select_button} = $false;

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
	$conditions4big_streams->{_is_run_button}       = $false;
	$conditions4big_streams->{_has_used_run_button} = $true;

	# reset save and SaveAs options because
	# file must be saved before running, always
	$conditions4big_streams->{_has_used_SaveAs_button}  = $false;
	$conditions4big_streams->{_has_used_Save_superflow} = $false;

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

	# print("conditions4big_streams, set4end_of_superflow_select OK \n");
	$conditions4big_streams->{_is_superflow}               = $false;
	$conditions4big_streams->{_is_superflow_select_button} = $false;
	$conditions4big_streams->{_is_pre_built_superflow}     = $false;

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
	$conditions4big_streams->{_is_run_button} = $true;
	$is_run_button = $true;
	_reset_is_flow_listbox_color_w();

	if ( $conditions4big_streams->{_flow_color} eq 'grey' ) {
		$conditions4big_streams->{_is_flow_listbox_grey_w} = $true;
		$is_flow_listbox_grey_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'pink' ) {
		$conditions4big_streams->{_is_flow_listbox_pink_w} = $true;
		$is_flow_listbox_pink_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'green' ) {
		$conditions4big_streams->{_is_flow_listbox_green_w} = $true;
		$is_flow_listbox_green_w = $true;

	} elsif ( $conditions4big_streams->{_flow_color} eq 'blue' ) {
		$conditions4big_streams->{_is_flow_listbox_blue_w} = $true;
		$is_flow_listbox_blue_w = $true;

	} elsif ( $conditions4big_streams->{_flow_type} eq 'pre_built_superflow' ) {

		# print("2 conditions4big_streams,set4start_of_run_button Running a pre-built superflow\n");
		# NADA

	} else {
		print("2 conditions4big_streams,set4start_of_run_button missing color \n");
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

	# print("conditions4big_streams, set4start_of_add2flow flow_listbox_color_w $flow_listbox_color_w\n");

	_set_flow_listbox_last_touched_w($flow_listbox_color_w);

	$conditions4big_streams->{_is_add2flow}              = $true;
	$conditions4big_streams->{_is_new_listbox_selection} = $true;

	# null some user dialogs
	$conditions4big_streams->{_has_used_Save_button}    = $false;
	$conditions4big_streams->{_has_used_SaveAs_button}  = $false;
	$conditions4big_streams->{_has_used_Save_superflow} = $false;

	# for potential later export
	$is_add2flow              = $true;
	$is_new_listbox_selection = $true;
	$has_used_SaveAs_button   = $false;
	$has_used_Save_button     = $false;
	$has_used_Save_superflow  = $false;

	#turn on the following buttons
	# print("conditions4big_streams, set4start_of_add2flow file_menubutton $file_menubutton\n");
	$file_menubutton->configure( -state => 'normal' );
	$Data_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'normal' );
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );
	$check_code_button->configure( -state => 'normal' );

	# turn on delete button
	$delete_from_flow_button->configure( -state => 'active', );

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

	# print("conditions4big_streams, set4start_of_add2flow, color is: $color \n");
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

	$conditions4big_streams->{_is_add2flow_button}       = $true;
	$conditions4big_streams->{_is_sunix_listbox}         = $true;
	$conditions4big_streams->{_is_new_listbox_selection} = $true;

	# null some user dialogs
	$conditions4big_streams->{_has_used_Save_button}    = $false;
	$conditions4big_streams->{_has_used_Save_superflow} = $false;
	$conditions4big_streams->{_has_used_SaveAs_button}  = $false;

	# for potential later export
	$is_add2flow_button       = $true;
	$is_sunix_listbox         = $true;
	$is_new_listbox_selection = $true;
	$has_used_SaveAs_button   = $false;
	$has_used_Save_button     = $false;
	$has_used_Save_superflow  = $false;

	#turn on the following buttons
	$file_menubutton->configure( -state => 'normal' );
	$Data_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'normal' );
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );
	$check_code_button->configure( -state => 'normal' );

	#$parameter_names_frame ->configure(
	#							-state=>'disabled');
	# 	$parameter_values_button_frame ->configure(
	#							-state=>'disabled');

	# turn on delete button
	$delete_from_flow_button->configure( -state => 'active', );

	# turn on flow list item move up and down arrow buttons
	$flow_item_up_arrow_button->configure( -state => 'active', );
	$flow_item_down_arrow_button->configure( -state => 'active', );

	# turn on All ListBox(es) for possible later use
	$flow_listbox_grey_w->configure( -state => 'normal', );
	$flow_listbox_pink_w->configure( -state => 'normal', );
	$flow_listbox_green_w->configure( -state => 'normal', );
	$flow_listbox_blue_w->configure( -state => 'normal', );

	# print("conditions4big_streams, set4start_of_add2flow_button, color is: $color \n");
	return ();
}

=head2 sub set4start_of_sunix_select 


=cut

sub set4start_of_sunix_select {
	my ($self) = @_;

	_reset();
	$conditions4big_streams->{_is_sunix_listbox} = $true;
	_set_gui_widgets();

	# print("conditions4big_streams, set4start_of_sunix_select, $conditions4big_streams->{_is_sunix_listbox}\n");
	$delete_from_flow_button->configure( -state => 'disabled', );
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
	$conditions4big_streams->{_is_run_button} = $true;
	$is_run_button = $true;

	return ();
}

=head2 sub set4start_of_superflow_Save 


=cut

sub set4start_of_superflow_Save {
	my ($self) = @_;

	#		# print("conditions4big_streams, set4superflow_Save OK \n");
	#	use App::SeismicUnixGui::misc::L_SU_global_constants;
	#	my $get											= L_SU_global_constants->new();
	#	my $flow_type_h									= $get->flow_type_href();
	#	my $alias_FileDialog_button_label				= $get->alias_FileDialog_button_label_aref;
	#        		# location within GUI
	#	$conditions4big_streams->{_is_new_listbox_selection} 	= $true;
	$conditions4big_streams->{_is_Save_button} = $true;

	# 	$conditions4big_streams->{_is_pre_built_superflow}		= $true;
	# 	$conditions4big_streams	->{_flow_type}					= $flow_type_h->{_pre_built_superflow};
	#
	# for re-export via get_hash-ref
	# 	$is_new_listbox_selection 						= $true;
	$is_Save_button = $true;

	# 	$is_pre_built_superflow							= $true;
	# 	$flow_type										= $flow_type_h->{_pre_built_superflow}; # see set_hash_ref
	#
	#    $delete_from_flow_button	->configure(-state => 'disabled',);
	#    $flow_item_up_arrow_button	->configure(-state => 'disabled',);
	#    $flow_item_down_arrow_button->configure(-state => 'disabled',);
	#
	#					# turn off Flow label
	#    $flow_listbox_grey_w			->configure(-state => 'disabled'); 	# turn off top left flow listbox
	#    $flow_listbox_pink_w			->configure(-state => 'disabled'); 	# turn off top-right flow listbox
	#    $flow_listbox_green_w			->configure(-state => 'disabled'); 	# turn off bottom-left flow listbox
	#    $flow_listbox_blue_w			->configure(-state => 'disabled'); 	# turn off bottom-right flow listbox
	#    $add2flow_button_grey			->configure(-state => 'disable',); 	# turn off Flow label
	#    $add2flow_button_pink			->configure(-state => 'disable',); 	# turn off Flow label
	#    $add2flow_button_green			->configure(-state => 'disable',); 	# turn off Flow label
	#    $add2flow_button_blue			->configure(-state => 'disable',); 	# turn off Flow label
	#    $run_button						->configure(-state => 'normal');
	#    $save_button					->configure(-state => 'normal');
	#
	#    $Data_menubutton				->configure(-state => 'normal');
	#    $Flow_menubutton				->configure(-state => 'disable');
	#    $SaveAs_menubutton				->configure(-state => 'disable');
	#
	#    $check_code_button				->configure(-state => 'disable');
}

=head2 sub set4start_of_superflow_select 


=cut

sub set4start_of_superflow_select {
	my ($self) = @_;

	# print("conditions4big_streams, set4superflow_open_data_file_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	#	my $alias_FileDialog_button_label =
	#		$get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4big_streams->{_flow_type}                  = $flow_type_h->{_pre_built_superflow};
	$conditions4big_streams->{_is_new_listbox_selection}   = $true;
	$conditions4big_streams->{_is_pre_built_superflow}     = $true;
	$conditions4big_streams->{_is_superflow}               = $true;
	$conditions4big_streams->{_is_superflow_select_button} = $true;
	$conditions4big_streams->{_is_user_built_flow}         = $false;

	# for re-export via get_hash-ref
	$flow_type                  = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection   = $true;
	$is_pre_built_superflow     = $true;
	$is_superflow               = $true;
	$is_superflow_select_button = $true;
	$is_user_built_flow         = $false;

	$delete_from_flow_button->configure( -state => 'disabled', );
	$flow_item_up_arrow_button->configure( -state => 'disabled', );
	$flow_item_down_arrow_button->configure( -state => 'disabled', );

	# turn off Flow label
	$flow_listbox_grey_w->configure( -state => 'disabled' );               # turn off top left flow listbox
	$flow_listbox_pink_w->configure( -state => 'disabled' );               # turn off top-right flow listbox
	$flow_listbox_green_w->configure( -state => 'disabled' );              # turn off bottom-left flow listbox
	$flow_listbox_blue_w->configure( -state => 'disabled' );               # turn off bottom-right flow listbox
	$add2flow_button_grey->configure( -state => 'disable', );              # turn off Flow label
	$add2flow_button_pink->configure( -state => 'disable', );              # turn off Flow label
	$add2flow_button_green->configure( -state => 'disable', );             # turn off Flow label
	$add2flow_button_blue->configure( -state => 'disable', );              # turn off Flow label
	$run_button->configure( -state => 'normal' );
	$save_button->configure( -state => 'normal' );

	$Data_menubutton->configure( -state => 'normal' );
	$Flow_menubutton->configure( -state => 'normal' );
	$SaveAs_menubutton->configure( -state => 'disable' );

	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_close_data_file_end 

=cut

sub set4superflow_close_data_file_end {
	my ($self) = @_;

	# print("conditions4big_streams, set4superflow_close_data_file_end OK \n");
	# Forces a Save before the next Run
	$conditions4big_streams->{_has_used_Save_superflow} = $false;

	# for potential export
	$has_used_Save_superflow = $false;

	# Allows user to open a user-built perl flow
	$Flow_menubutton->configure( -state => 'normal', );

	return ();
}

=head2 sub set4superflow_close_path_end 

=cut

sub set4superflow_close_path_end {
	my ($self) = @_;

	# print("conditions4big_streams, set4superflow_close_path_end OK \n");
	# Forces a Save before the next Run
	$conditions4big_streams->{_has_used_Save_superflow} = $false;

	# for potential export
	$has_used_Save_superflow = $false;

	# Allows user to open a user-built perl flow
	$Flow_menubutton->configure( -state => 'normal', );

	return ();
}

=head2 sub set4superflow_open_data_file_end 

=cut

sub set4superflow_open_data_file_end {
	my ($self) = @_;

	# print("conditions4big_streams, set4end_of_superflow_select OK \n");
	$conditions4big_streams->{_is_pre_built_superflow} = $true;
	$conditions4big_streams->{_is_superflow}           = $true;

	#  	$conditions4big_streams->{_is_superflow_select_button}	= $true;

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

	# print("conditions4big_streams, set4superflow_open_data_file_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	#	my $alias_FileDialog_button_label =
	#		$get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4big_streams->{_flow_type}                = $flow_type_h->{_pre_built_superflow};
	$conditions4big_streams->{_is_new_listbox_selection} = $true;
	$conditions4big_streams->{_is_pre_built_superflow}   = $true;
	$conditions4big_streams->{_is_superflow}             = $true;

	#	$conditions4big_streams->{_is_superflow_select_button}	= $true;

	# for re-export via get_hash-ref
	$flow_type                = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection = $true;
	$is_superflow             = $true;
	$is_pre_built_superflow   = $true;

	#	$is_superflow_select_button						= $true;

	$delete_from_flow_button->configure( -state => 'disabled', );
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

	$Data_menubutton->configure( -state => 'normal' );
	$Flow_menubutton->configure( -state => 'disable', );
	$SaveAs_menubutton->configure( -state => 'disable' );

	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_open_path_end 

=cut

sub set4superflow_open_path_end {

	my ($self) = @_;

	# print("conditions4big_streams, set4superflow_open_path_end OK \n");
	$conditions4big_streams->{_is_pre_built_superflow} = $true;
	$conditions4big_streams->{_is_superflow}           = $true;

	# for potential export
	$is_pre_built_superflow = $true;
	$is_superflow           = $true;

	return ();
}

=head2 sub set4superflow_open_path_start 

=cut

sub set4superflow_open_path_start {
	my ($self) = @_;

	# print("conditions4big_streams, set4superflow_open_path_start OK \n");
	use App::SeismicUnixGui::misc::L_SU_global_constants;
	my $get         = L_SU_global_constants->new();
	my $flow_type_h = $get->flow_type_href();

	# my $alias_FileDialog_button_label				= $get->alias_FileDialog_button_label_aref;

	# For location within GUI
	$conditions4big_streams->{_flow_type}                = $flow_type_h->{_pre_built_superflow};
	$conditions4big_streams->{_is_new_listbox_selection} = $true;
	$conditions4big_streams->{_is_pre_built_superflow}   = $true;
	$conditions4big_streams->{_is_superflow}             = $true;

	# for re-export via get_hash-ref
	$flow_type                = $flow_type_h->{_pre_built_superflow};    # see set_hash_ref
	$is_new_listbox_selection = $true;
	$is_superflow             = $true;
	$is_pre_built_superflow   = $true;

	$delete_from_flow_button->configure( -state => 'disabled', );
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

	$Data_menubutton->configure( -state => 'normal' );
	$Flow_menubutton->configure( -state => 'disable', );
	$SaveAs_menubutton->configure( -state => 'disable' );

	$check_code_button->configure( -state => 'disable' );
}

=head2 sub set4superflow_Save 


=cut

sub set4superflow_Save {
	my ($self) = @_;

	$conditions4big_streams->{_has_used_Save_superflow} = $true;
	$conditions4big_streams->{_has_used_Save_button}    = $false;

	#for possible export

	$has_used_Save_superflow = $true;
	$has_used_Save_button    = $false;

	return ();

}

=head2 sub set_flow_index_last_touched


=cut

sub set_flow_index_last_touched {
	my ( $self, $index ) = @_;

	if ($index) {    # if defined

		if ( $index >= 0 ) {    # -1 does exist in conditions4big_streams thru default definition
			$conditions4big_streams->{_last_flow_index_touched_grey}  = $index;    # internal
			$conditions4big_streams->{_last_flow_index_touched_pink}  = $index;    # internal
			$conditions4big_streams->{_last_flow_index_touched_green} = $index;    # internal
			$conditions4big_streams->{_last_flow_index_touched_blue}  = $index;    # internal
			$conditions4big_streams->{_last_flow_index_touched}       = $index;    # internal
			$last_flow_index_touched_grey                             = $index;    # for get_hash-ref
			$last_flow_index_touched_pink                             = $index;    # for get_hash-ref
			$last_flow_index_touched_green                            = $index;    # for get_hash-ref
			$last_flow_index_touched_blue                             = $index;    # for get_hash-ref
			$last_flow_index_touched                                  = $index;    # for get_hash-ref
			$is_last_flow_index_touched_grey                          = $true;     # for get_hash-ref
			$is_last_flow_index_touched_pink                          = $true;     # for get_hash-ref
			$is_last_flow_index_touched_green                         = $true;     # for get_hash-ref
			$is_last_flow_index_touched_blue                          = $true;     # for get_hash-ref
			$is_last_flow_index_touched                               = $true;     # for get_hash-ref

			#print("1. conditions4big_streams, set_flow_index_last_touched had index = $conditions4big_streams->{_last_flow_index_touched}\n");
		} else {
			print("conditions4big_streams,set_flow_index_touched, missing index\n");
		}

	} else {

		#print("conditions4big_streams,set_flow_index_touched, index is undefined but needed, so assume index=0\n");
		$index                                                    = 0;
		$conditions4big_streams->{_last_flow_index_touched_grey}  = $index;        # internal
		$conditions4big_streams->{_last_flow_index_touched_pink}  = $index;        # internal
		$conditions4big_streams->{_last_flow_index_touched_green} = $index;        # internal
		$conditions4big_streams->{_last_flow_index_touched_blue}  = $index;        # internal
		$conditions4big_streams->{_last_flow_index_touched}       = $index;        # internal
		$last_flow_index_touched_grey                             = $index;        # for get_hash-ref
		$last_flow_index_touched_pink                             = $index;        # for get_hash-ref
		$last_flow_index_touched_green                            = $index;        # for get_hash-ref
		$last_flow_index_touched_blue                             = $index;        # for get_hash-ref
		$last_flow_index_touched                                  = $index;        # for get_hash-ref
		$is_last_flow_index_touched_grey                          = $true;         # for get_hash-ref
		$is_last_flow_index_touched_pink                          = $true;         # for get_hash-ref
		$is_last_flow_index_touched_green                         = $true;         # for get_hash-ref
		$is_last_flow_index_touched_blue                          = $true;         # for get_hash-ref
		$is_last_flow_index_touched                               = $true;         # for get_hash-ref
	}

	# print("1. conditions4big_streams, set_flow_index_last_touched had index = $index\n");
	return ();
}

1;
