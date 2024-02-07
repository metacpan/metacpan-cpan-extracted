package App::SeismicUnixGui::misc::green_flow;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PERL PROGRAM NAME: green_flow.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 8 2018 

 DESCRIPTION 
     

 BASED ON:
 previous versions of the main userBuiltFlow.pl
  

=cut

=head2 USE

=head3 NOTES

   Provides in-house macros/superflows
   1. Find widget you have selected

  if widget_name= frame then we have flow
              $var->{_flow}
              
  if widget_name= menubutton we have superflow 
              $var->{_tool}

   2. Set the new program name 

     3. Make widget states active for:
       run_button
       save_button

     4. Disable the following widgets:
       delete_from_flow_button
      (sunix) flow_listbox

    sunix_listbox   		-choice of listed sunix modules in a listbox
    gui_history records updates to GUI selections
    but color_flow_href points to the changed has reference and senses
    the change as well.
    
=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
 refactoring of 2017 version of L_SU.pl
 V 0.0.2 removed unused methods in comments
 
 V 0.0.3 2021 allows for better color listbox control
 
 V 0.0.4 7.10.21 allows control to handle non-numeric
 names for input files

=cut 

=head2 Notes 

sub sunix_select (subroutine is only active in neutral_flow.pm)
 
 
=cut 

use Moose;
our $VERSION = '0.0.4';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::gui_history';

use App::SeismicUnixGui::misc::param_widgets_green '0.0.2';
use aliased 'App::SeismicUnixGui::misc::param_widgets_green';

use App::SeismicUnixGui::misc::param_flow_green '0.0.5';
use aliased 'App::SeismicUnixGui::misc::param_flow_green';

use aliased 'App::SeismicUnixGui::misc::binding';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

use App::SeismicUnixGui::misc::decisions '1.0.0';
use aliased 'App::SeismicUnixGui::misc::decisions';

use aliased 'App::SeismicUnixGui::misc::dirs';
use aliased 'App::SeismicUnixGui::misc::file_dialog';
use aliased 'App::SeismicUnixGui::misc::files_LSU';
use aliased 'App::SeismicUnixGui::misc::flow_widgets';
use aliased 'App::SeismicUnixGui::misc::help';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::perl_flow';
use aliased 'App::SeismicUnixGui::misc::param_sunix';

use Carp;
use Clone 'clone';

=head2 Instantiation

=cut

my $Project               = Project_config->new();
my $L_SU_global_constants = L_SU_global_constants->new();
my $control               = control->new();
my $decisions             = decisions->new();
my $dirs                  = dirs->new();
my $file_dialog           = file_dialog->new();
my $flow_widgets          = flow_widgets->new();
my $gui_history           = gui_history->new();
my $manage_files_by2      = manage_files_by2->new();
my $message_director      = message_director->new();

my $param_flow_color_pkg = param_flow_green->new();
my $param_widgets        = param_widgets_green->new();
my $flow_type            = $L_SU_global_constants->flow_type_href();
my $var                  = $L_SU_global_constants->var();
my $empty_string         = $var->{_empty_string};
my $this_color           = 'green';
my $color_flow_href      = $gui_history->get_defaults();
my $neutral              = $var->{_neutral};
my $sunix_select         = $var->{_sunix_select};
my $number_from_color    = $L_SU_global_constants->number_from_color_href();

my $_is_last_parameter_index_touched_color =
  '_is_last_parameter_index_touched_' . $this_color;
my $_flow_listbox_color_w = '_flow_listbox_' . $this_color . '_w';
my $_flow_name_color_w    = '_flow_name_' . $this_color . '_w';
my $_number_from_color    = $number_from_color->{ ( '_' . $this_color ) };
my $_flow_name_in_color   = '_flow_name_in_' . $this_color;
my $_flow_name_out_color  = '_flow_name_out_' . $this_color;

=head2

 share the following parameters in same name 
 space
 
=cut

my $flow_color;
my $flow_name_color_w;
my $flowNsuperflow_name_w;
my $last_flow_color;
my $message_w;
my $occupied_listbox_aref;
my $vacant_listbox_aref;
my $parameter_values_button_frame;
my $parameter_values_frame;

my $user_built = $flow_type->{_user_built};
my $true       = $var->{_true};
my $false      = $var->{_false};

#my @empty_array      = (0);                         # length=1

=head2 memory leak saviors

=cut

my @save_last_param_widget_values;
my $save_last_param_widget_value;
my $save_last_param_widget_index;
my $memory_leak4save_button_fixed = $false;
my $memory_leak4flow_select_fixed = $false;
my $min_clicks4save_button        = $var->{_min_clicks4save_button};
my $min_clicks4flow_select        = $var->{_min_clicks4flow_select};
my $first_opening = $true;    # don't touch, but commented out below

=head2 private anonymous hash
to share variable values easily

=cut

my $color_flow = {

	_Flow_file_exists => $false,
	_perl_flow_errors => $true,

};

=head2 sub _add2flow

When automatically reading a user-built perl flow and not directed 
to do so by a user's click of the mouse.
As when a file is opened
Incorporate new program parameter values and labels into the gui
and save the values, labels and checkbuttons setting in the param_flow
namespace

foreach my $key (sort keys %$color_flow_href) {
   print (" color_flow _add2flow,key is $key, value is $color_flow_href->{$key}\n");
  }
	
_flow_select is run from _perl_flow

=cut

sub _add2flow {

	my ( $self, $value ) = @_;

	my $message = $message_director->null_button(0);

	my $here;
	my $flow_color = _get_flow_color();
	$gui_history->set_add2flow_color($flow_color);
	$gui_history->set_button('add2flow_button');
	$gui_history->set_flow_type($user_built);

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set4start_of_add2flow_button($flow_color);
	$color_flow_href = $gui_history->get_hash_ref();

	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	# add the most recently selected program
	# name (scalar reference) to the
	# end of the list inside flow_listbox
	_local_set_flow_listbox_color_w($flow_color);    # in "color"_flow namespace

 # append new program names to the end of the list but this item is NOT selected
 # selection occurs inside gui_history, conditions_gui
	$color_flow_href->{_flow_listbox_color_w}
	  ->insert( "end", ${ $color_flow_href->{_prog_name_sref} }, );

	# display default paramters in the GUI
	# same as for sunix_select
	# can not get program name from the item selected in the sunix list box
	# because focus is transferred to a flow list box  ($this_color)

	# widgets are initialized in a super class
	# Assign program parameters in the GUI
	# See: L_SU_global_constants.pl

	$param_widgets->set_labels_w_aref( $color_flow_href->{_labels_w_aref} );
	$param_widgets->set_values_w_aref( $color_flow_href->{_values_w_aref} );
	$param_widgets->set_check_buttons_w_aref(
		$color_flow_href->{_check_buttons_w_aref} );

	$param_widgets->range($color_flow_href);
	$param_widgets->set_labels( $color_flow_href->{_names_aref} );
	$param_widgets->set_values( $color_flow_href->{_values_aref} );
	$param_widgets->set_check_buttons(
		$color_flow_href->{_check_buttons_settings_aref} );

# print(" 22. color_flow, _add2flow, color_flow_href->{_values_aref}=@{$color_flow_href->{_values_aref}}\n");

	# wipe out values labels and checkbuttons from the gui
	# strange memory leak inside param_widgets
	# TODO  check it this is still true?
	#    my $save1 = clone( $color_flow_href->{_check_buttons_settings_aref} );
	#    $param_widgets->gui_full_clear();
	#    @{ $color_flow_href->{_check_buttons_settings_aref} } = @$save1;
	#
	#	$param_widgets->redisplay_labels();
	#	$param_widgets->redisplay_values();
	#	$param_widgets->redisplay_check_buttons();

	#	@{ $color_flow_href->{_names_aref} } = @$save2;
	#	@{ $color_flow_href->{_values_aref} } = @$save3;

	# Collect and store prog versions changed in list box
	_stack_versions();

	# Add a single_program to the growing stack
	# store one program name, its associated parameters and their values
	# as well as the checkbuttons settings (on or off) in another namespace
	_stack_flow();

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set4end_of_add2flow($flow_color);

	my $index = $flow_widgets->get_flow_selection(
		$color_flow_href->{_flow_listbox_color_w} );

	$gui_history->set_flow_index_last_touched($index); # flow color is not reset
	$color_flow_href = $gui_history->get_hash_ref();

	# switch between the correct index of the last parameter that was touched
	# as a function of the flow's color
	# These data are encapsulated
	$color_flow_href->{_last_parameter_index_touched_color} = 0;    # initialize
	$color_flow_href->{$_is_last_parameter_index_touched_color} = $true;

	$param_widgets->set_check_buttons(
		$color_flow_href->{_check_buttons_settings_aref} );

#	print(
#" 2. color_flow, END _add2flow, color_flow_href->{_values_aref}=@{$color_flow_href->{_values_aref}}\n"
#	);

# print(" 2. color_flow, END _add2flow, widget values =@{$param_widgets->get_values_aref()} \n");

	_flow_select_director('_add2flow');

	$param_widgets->set_entry_change_status($false);

	return ();

}

=head2 sub _clear_color_flow

	wipe out color-flow list box with programs
	wipe out param_widgets_color
	wipe out parameters stored for color flow

=cut

sub _clear_color_flow {
	my ($self) = @_;

	# my $number = $param_flow_color_pkg->get_num_items();

	#clear all stored parameters and versions in the param_flow
	$param_flow_color_pkg->clear();
	my $number = $param_flow_color_pkg->get_num_items();

	my $test = $color_flow_href->{_check_buttons_settings_aref};

	# clear the parameter values and labels belonging to the gui
	# strange memory leak inside param_widgets
	my $save = clone( $color_flow_href->{_check_buttons_settings_aref} );
	$param_widgets->gui_full_clear();

	# print("color_flow,_clear_color_flow: print gui_history.txt \n");
	# $gui_history->view();
	@{ $color_flow_href->{_check_buttons_settings_aref} } = @$save;

	# remove all sunix program names from the flow listbox
	# in "color"_flow namespace
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();
	$flow_widgets->clear($_flow_listbox_color_w);

}

=head2 sub _FileDialog_button

Only cases with MB binding use this private ('_') subroutine
e.g., sunix programs displayed in the parameter boxes during
flow construction.
sub binding is responsible
Other cases that select the GUI file buttons directly (user click) use: FileDialog_button instead.
Once the file name is selected the parameter value is updated in the GUI

	 	 foreach my $key (sort keys %$color_flow) {
   			print (" color_flowkey is $key, value is $color_flow->{$key}\n");
  		}
  	print ("color_flow,_FileDialog_button(binding), _is_flow_listbox_color_w: $color_flow_href->{_is_flow_listbox_color_w} \n");
  	
=cut 

sub _FileDialog_button {

	my ( $self, $flow_dialog_type_sref ) = @_;

	if ($flow_dialog_type_sref) {

		# flow dialog type can be
		# 'Open' or Data_PL_SEISMIC

		# provide values in the current widget
		$color_flow_href->{_values_aref} = $param_widgets->get_values_aref();

		my $most_recent_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};

		# establish which program is active in the flow
		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();
		$control->set_flow_prog_names_aref(
			$color_flow_href->{_prog_names_aref} );
		$control->set_flow_prog_name_index($most_recent_flow_index_touched);

		# clean all quotes upon input
		$color_flow_href->{_values_aref} =
		  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

		# restore string quotes to values that need them
		# e.g., character strings as well as fnumeric file names
		$color_flow_href->{_values_aref} = $control->get_string_or_number4aref(
			$color_flow_href->{_values_aref} );

		# dereference scalar
		$color_flow_href->{_dialog_type} = $$flow_dialog_type_sref;

		$file_dialog->set_flow_color( $color_flow_href->{_flow_color} );
		$file_dialog->set_hash_ref($color_flow_href);
		$file_dialog->set_dialog_type($$flow_dialog_type_sref);
		$file_dialog->FileDialog_director();

		# updates to parameter values
		# changed within file_dialog are retrieved
		$color_flow_href->{_values_aref} = $file_dialog->get_values_aref();

# print("color flow, _FileDialog_button: color_flow_href->{_values_aref}=@{$color_flow_href->{_values_aref}}\n");

# assume that after selection to open of a data file, while using file-dialog button, the
# GUI has been updated
# Assume we are still dealing with the current flow item selected
# Update the value of the Entry widget (in GUI) with the selected file name
# Also update the parameter_widgets with the updated value

		my $current_index         = $file_dialog->get_current_index();
		my $selected_Entry_widget = $file_dialog->get_selected_Entry_widget();
		@{ $param_widgets->{_values_aref} }[$current_index] =
		  $file_dialog->get_selected_file_name();
		@{ $color_flow_href->{_values_aref} }[$current_index] =
		  $file_dialog->get_selected_file_name();

		$param_widgets->redisplay_values();

# Make sure to place focus again on the updated widget so other modules can find the selection
		$selected_Entry_widget->focus;    # from above

#print("13 color_flow, _FileDialog_button,color_flow selected_file_name: @{ $param_widgets->{_values_aref} }[$current_index]\n");
#print("13 color_flow, _FileDialog_button,color_flow values: @{ $color_flow_href->{_values_aref} }\n");
# print("9. color_flow, _FileDialog_button, last_flow_color:$color_flow_href->{_last_flow_color}\n");
# print("1. color_flow, _FileDialog_button, last_flow_index_touched $color_flow_href->{_last_flow_index_touched}\n");

		# set up this flow listbox item as the last item touched
		# user-built_flow in current use
		my $_flow_listbox_color_w = _get_flow_listbox_color_w();
		my $current_flow_listbox_index =
		  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

# print("2. color_flow, _FileDialog_button, last_flow_index_touched $color_flow_href->{_last_flow_index_touched}\n");
# print("10. color_flow, _FileDialog_button, last_flow_color:$color_flow_href->{_last_flow_color}\n");
# Changes made with another instance of param_widgets (in file_dialog) will require
# that we update the namespace of the current param_flow
# We make this change inside _save_most_recent_param_flow
		_save_most_recent_param_flow();

	}
	else {
		print("color_flow,_FileDialog_button (binding),option type missing ");
	}
	return ();
}

=head2 sub _clear_items_version_aref 

	clear items_versions_aref
	used when last item is removed from the listbox

=cut

sub _clear_items_version_aref {

	my ($self) = @_;

	if ($color_flow_href) {

		$color_flow_href->{_items_versions_aref} = '';
		return ();

	}
	else {
		print("color_flow, _clear_items_version_aref, missing color_flow \n");
		return ();
	}

}

=head2 sub _clear_stack_versions 

	clear items_versions_aref
	when last flow item is deleted
	in the listbox

=cut

sub _clear_stack_versions {

	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

	$flow_widgets->clear_flow_item($_flow_listbox_color_w);
	$flow_widgets->clear_items_versions_aref();

	# with hash value = ''
	_clear_items_version_aref();

	$param_flow_color_pkg->clear_flow_items_version_aref();

}

=head2 sub _flow_select_director

Private alias for flow_select
both color and button are set as
per the flow_select called by an active click
from Main, in_L_SU_flow_bindings

=cut

sub _flow_select_director {

	my ($type) = @_;

	if ( defined $type ) {
		$gui_history->set_flow_select_color($this_color);

		if (
			$type eq '_add2flow'    # when perl flow is read
			or $type eq '_perl_flow'
			or $type eq 'delete_from_flow_button'
			or $type eq 'delete_whole_flow_button'
			or $type eq 'flow_item_down_arrow_button'
			or $type eq 'flow_item_up_arrow_button'
		  )
		{
# update most recent flow
#			print(
#" 3. color_flow,_flow_select_director,END OF LOADING INTO GUI for type=$type\n"
#			);
#			print(
#" 3. color_flow,_flow_select_director,color_flow_href->{_values_aref}=@{$color_flow_href->{_values_aref}}\n"
#			);

			_flow_select2save_most_recent_param_flow();

# print(" 3. color_flow,_flow_select_director, widget values=@{$param_widgets->get_values_aref()} \n");

			if ( $type eq '_add2flow' ) {

				# CASE of opening a perl flow
				# the last set of param_widgets opened
				@save_last_param_widget_values =
				  @{ $param_widgets->get_values_aref() };
				$save_last_param_widget_value  = $save_last_param_widget_values[-1];
				$save_last_param_widget_index  = $#save_last_param_widget_values;

			}

	   # flow loading and display is complete
	   # print("1. color_flow, _flow_select_director, print out gui_history\n");
	   # $gui_history->view();

		}
		elsif ( $type eq 'add2flow_button' ) {

			_flow_select2save_most_recent_param_flow();

			# update prior flow
			# flow_select();

		}
		else {
			print("color_flow,_flow_select_director, unexpected\n");
		}
		return ();

	}
}

=head2 sub flow_select2save_most_recent_param_flow

 select a program from the flow
 when add2flow_button is directly selected by the user
 
 archive the index
 and update any changed parameter flows
 consider prior flow-color changes
 unticked strings from GUI are corrected here
 uses _updateNsave_most_recent_param_flow();
  	
=cut

sub flow_select2save_most_recent_param_flow {
	my ($self) = @_;

	$color_flow_href->{_flow_type} = $flow_type->{_user_built};

	_local_set_flow_listbox_color_w($flow_color);

	my $message = $message_director->null_button(0);
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set_defaults_4start_of_flow_select($flow_color);
	$color_flow_href = $gui_history->get_hash_ref();

	# update the flow color as per add2flow_select2save_most_recent_param_flow
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

	$color_flow_href->{_prog_name_sref} =
	  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

	$decisions->set_hash_ref($color_flow_href);

#	print("color_flow, flow_select2save_most_recent_param_flow, view stored flow parameters BEFORE update\n");
#	$param_flow_color_pkg->view_data();

	my $pre_req_ok = $decisions->get4flow_select();

	if ($pre_req_ok) {

		my $binding = binding->new();
		my $here;

		# consider previous flow-color changes
		# unticked strings from GUI are corrected within
		_updateNsave_most_recent_param_flow();

#	print("color_flow, flow_select2save_most_recent_param_flow, view stored flow parameters AFTER update\n");
#	$param_flow_color_pkg->view_data();

#					print(
#				"4. color_flow, flow_select2save_most_recent_param_flow: writing gui_history.txt\n"
#			);
#			$gui_history->view();

		# for just-selected program name
		# get its flow parameters from storage
		# and redisplay the widgets with parameters

# Update the flow item index to the program that is currently being used, instead
# of prior program
# Warning: Flow selection gets reset if user double-clicks on a parameter value
# in another window
		$gui_history->set_button('flow_select');
		my $index = $flow_widgets->get_flow_selection($_flow_listbox_color_w);

		if ( defined($index)
			and $index >= 0 )
		{

#			print("10 color_flow, flow_select2save_most_recent_param_flow index=$index \n");

#			print("3. color_flow, flow_select2save_most_recent_param_flow: writing gui_history.txt\n");
#			$gui_history->view();

			# CASE MOST COMMON
			$param_flow_color_pkg->set_flow_index($index);
			$color_flow_href->{_names_aref} =
			  $param_flow_color_pkg->get_names_aref();
			$color_flow_href->{_values_aref} =
			  $param_flow_color_pkg->get_values_aref();

			$color_flow_href->{_check_buttons_settings_aref} =
			  $param_flow_color_pkg->get_check_buttons_settings();

# print("10 flow_select2save_most_recent_param_flow,check_buttons_settings_aref: @{color_flow_href->{_check_buttons_settings_aref}}\n");
# get stored first index and num of items
			$color_flow_href->{_param_flow_first_idx} =
			  $param_flow_color_pkg->first_idx();
			$color_flow_href->{_param_flow_length} =
			  $param_flow_color_pkg->length();

			$param_widgets->set_current_program(
				$color_flow_href->{_prog_name_sref} );

			# widgets were initialized in super class
			$param_widgets->set_labels_w_aref(
				$color_flow_href->{_labels_w_aref} );
			$param_widgets->set_values_w_aref(
				$color_flow_href->{_values_w_aref} );
			$param_widgets->set_check_buttons_w_aref(
				$color_flow_href->{_check_buttons_w_aref} );

			$color_flow_href->{_prog_name_sref} =
			  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

			$param_widgets->range($color_flow_href);

			# strange memory leak inside param_widgets
			my $save1 =
			  clone( $color_flow_href->{_check_buttons_settings_aref} );
			$param_widgets->gui_full_clear();
			@{ $color_flow_href->{_check_buttons_settings_aref} } = @$save1;

			$param_widgets->set_labels( $color_flow_href->{_names_aref} );

			# test next 4 lines
			#						my $save2 =
			#						  clone( $color_flow_href->{_values_aref} );
			#						$param_widgets->gui_full_clear();
			#						@{ $color_flow_href->{_values_aref} } = @$save2;
			#			$param_widgets->set_values( $color_flow_href->{_values_aref} );

			$param_widgets->set_check_buttons(
				$color_flow_href->{_check_buttons_settings_aref} );

			$param_widgets->redisplay_labels();
			$param_widgets->redisplay_values();
			$param_widgets->redisplay_check_buttons();
			$param_widgets->set_entry_change_status($false);

	   # unxpectedly  Entry focus is delayed until the end of this method before
	   # completion;
	   # that is we get to gui_history->view before we can update the focus
	   # mysterious!!!!!
			$param_widgets->set_focus_on_Entry_w(0)
			  ;    # put focus on first entry widget, index=0

			# Here is where you rebind the different buttons depending on the
			# program name that is selected (i.e., through spec.pm)
			$binding->set_prog_name_sref( $color_flow_href->{_prog_name_sref} );
			$binding->set_values_w_aref( $param_widgets->get_values_w_aref );

			# reference to local subroutine that will be run when MB3 is pressed
			$binding->setFileDialog_button_sub_ref( \&_FileDialog_button );
			$binding->set();

			$gui_history->set_hash_ref($color_flow_href);
			$gui_history->set4end_of_flow_select($flow_color);
			$gui_history->set_flow_index_last_touched($index);
			$color_flow_href = $gui_history->get_hash_ref()
			  ;    # now color_flow= 0; flow_type=user_built

# Update the entry button value that displays the currently active
# flow or superflow name, by using the currently selected program name from the flow list
# e.g. data_in, suximage, suxgraph etc.
			( $color_flow_href->{_flowNsuperflow_name_w} )
			  ->configure( -text => ${ $color_flow_href->{_prog_name_sref} } );

			# needed in possible export via get_hash_ref to help
			my $prog_name_sref = $color_flow_href->{_prog_name_sref};

		}
		elsif ( defined $index ) {

#			if (   $index eq $empty_string
#				or $index < 0 ) {
#
#				print("color_flow,flow_select2save_most_recent_param_flow, NADA probably deleted last of flow\n");
#			}

		}
		else {

# print("color_flow,flow_select2save_most_recent_param_flow, no index, - NADA\n");
		}

	}    # end pre_ok
		 #	print("color_flow,flow_select2save_most_recent_param_flow, end\n");
	return ();
}    # end sub

=head2 sub _flow_select2save_most_recent_param_flow

 select a program from the flow
 archive the index
 and update any changed parameter flows
  	
=cut

sub _flow_select2save_most_recent_param_flow {
	my ($self) = @_;

	$color_flow_href->{_flow_type} = $flow_type->{_user_built};

# print("1. color_flow,_flow_select2save_most_recent_param_flow, last_flow_index_touched:$color_flow_href->{_last_flow_index_touched}\n");
# print("color_flow,_flow_select2save_most_recent_param_flow, last_flow_color:$color_flow_href->{_last_flow_color}\n");

	# reset residual flow_listbox_color_w of another color
	# flow_color exists in current (color_flow) namespace
	_local_set_flow_listbox_color_w($flow_color);
	$gui_history->set_flow_select_color($flow_color);

# print("1. color_flow, _flow_select2save_most_recent_param_flow, show stored flow parameters\n");
# $param_flow_color_pkg->view_data();

	my $message = $message_director->null_button(0);
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set_defaults_4start_of_flow_select($flow_color);
	$color_flow_href = $gui_history->get_hash_ref();

	# update the flow color as per add2_flow_select2save_most_recent_param_flow
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

	$color_flow_href->{_prog_name_sref} =
	  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

	$decisions->set_hash_ref($color_flow_href);

#	print("3. color_flow, _flow_select2save_most_recent_param_flow: writing gui_history.txt\n");
#	$gui_history->view();

# print("3. color_flow,_flow_select2save_most_recent_param_flow, last_flow_index_touched:$color_flow_href->{_last_flow_index_touched}\n");
#$param_flow_color_pkg->view_data();

	my $pre_req_ok = $decisions->get4flow_select();

	if ($pre_req_ok) {

		my $binding = binding->new();
		my $here;

		$gui_history->set_button('flow_select');

		# consider prior flow-color changes
		# unticked strings from GUI are corrected here

	  #		print(" 8, color_flow, before _updatenNsave_most_recent_param_flow\n");

#		$param_flow_color_pkg->view_data();
#		print(
#"8B. color_flow, _flow_select2save_most_recent_param_flow, values@{$color_flow_href->{_values_aref}}\n"
#		);

		_updateNsave_most_recent_param_flow();

# print("after 117  _updateNsave_most_recent_param_flow\n");
# print(
# "after 118  _color_flow, _flow_select2save_most_recent_param_flow, values@{$color_flow_href->{_values_aref}}\n"
# 		);

		# for just-selected program name
		# get its flow parameters from storage
		# and redisplay the widgets with parameters

# Update the flow item index to the program that is currently being used, instead
# of prior program
# Warning: Flow selection gets reset if user double-clicks on a parameter value
# in another window
		my $index = $flow_widgets->get_flow_selection($_flow_listbox_color_w);

		$param_flow_color_pkg->set_flow_index($index);
		$color_flow_href->{_names_aref} =
		  $param_flow_color_pkg->get_names_aref();

#		print("9 _flow_select2save_most_recent_param_flow,index=$index\n");
#		$param_flow_color_pkg->view_data();
#        print("9B. color_flow, _flow_select2save_most_recent_param_flow, values@{$color_flow_href->{_values_aref}}\n");

		$color_flow_href->{_values_aref} =
		  $param_flow_color_pkg->get_values_aref();
		$color_flow_href->{_check_buttons_settings_aref} =
		  $param_flow_color_pkg->get_check_buttons_settings();

		#		print("10 _flow_select2save_most_recent_param_flow,index=$index\n");
		#		$param_flow_color_pkg->view_data();

# print("10 _flow_select2save_most_recent_param_flow,check_buttons_settings_aref: @{color_flow_href->{_check_buttons_settings_aref}}\n");
# get stored first index and num of items
		$color_flow_href->{_param_flow_first_idx} =
		  $param_flow_color_pkg->first_idx();
		$color_flow_href->{_param_flow_length} =
		  $param_flow_color_pkg->length();

		$param_widgets->set_current_program(
			$color_flow_href->{_prog_name_sref} );

# print("4. color_flow, _flow_select2save_most_recent_param_flow: writing gui_history.txt\n");
# $gui_history->view();

		# widgets were initialized in super class
		$param_widgets->set_labels_w_aref( $color_flow_href->{_labels_w_aref} );
		$param_widgets->set_values_w_aref( $color_flow_href->{_values_w_aref} );
		$param_widgets->set_check_buttons_w_aref(
			$color_flow_href->{_check_buttons_w_aref} );

		$color_flow_href->{_prog_name_sref} =
		  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

		# wipes out values labels and checkbuttons from the gui

		$param_widgets->range($color_flow_href);

#		print(
#"119 color_flow, END _flow_select2save_most_recent_param_flow,color_flow_href->{_values_aref} =@{$color_flow_href->{_values_aref}}\n"
#		);

# strange memory leak inside param_widgets
#		my @save1 = clone( @{$color_flow_href->{_check_buttons_settings_aref}} );
#		$color_flow_href->{_check_buttons_settings_aref} = \@save1;
#		my @save2 = clone( @{$color_flow_href->{_values_aref}} );
#		$color_flow_href->{_values_aref} = \@save2;
#	    my @save3 = clone( @{$color_flow_href->{_names_aref}} );
#		$color_flow_href->{_names_aref} = \@save3;
#		print("120 color_flow, END _flow_select2save_most_recent_param_flow,color_flow_href->{_values_aref} =@{$color_flow_href->{_values_aref}}\n");
#
		$param_widgets->gui_full_clear();
		$param_widgets->set_labels( $color_flow_href->{_names_aref} );
		$param_widgets->set_values( $color_flow_href->{_values_aref} );
		$param_widgets->set_check_buttons(
			$color_flow_href->{_check_buttons_settings_aref} );

#		print(
#"121 color_flow, END _flow_select2save_most_recent_param_flow,color_flow_href->{_values_aref} =@{$color_flow_href->{_values_aref}}\n"
#		);

		$param_widgets->redisplay_labels();
		$param_widgets->redisplay_values();
		$param_widgets->redisplay_check_buttons();
		$param_widgets->set_entry_change_status($false);

	  # mysterious!!!!!
	  # We need to get gui_istory->view before we can update the focus
	  # Unxpectedly,  Entry focus is delayed until the end of this method before
	  # completion;
	  # put focus on first entry widget, index=0
		$param_widgets->set_focus_on_Entry_w(0);

#		print(
#"122 color_flow, END _flow_select2save_most_recent_param_flow,color_flow_href->{_values_aref} =@{$color_flow_href->{_values_aref}}\n"
#		);

# $color_flow_href->{_last_parameter_index_touched_color} = 0;
# the changed parameter value in the Entry widget should force an update of stored values
# in the current flow item (not the last flow item touched)
# _save_most_recent_param_flow(); # is only active if
# $color_flow_href->{_last_parameter_index_touched_color} >= 0
# Here is where you rebind the different buttons depending on the
# program name that is selected (i.e., through *_spec.pm)
		$binding->set_prog_name_sref( $color_flow_href->{_prog_name_sref} );
		$binding->set_values_w_aref( $param_widgets->get_values_w_aref );

		# reference to local subroutine that will be run when MB3 is pressed
		$binding->setFileDialog_button_sub_ref( \&_FileDialog_button );
		$binding->set();

		$gui_history->set_hash_ref($color_flow_href);
		$gui_history->set4end_of_flow_select($flow_color);
		$gui_history->set_flow_index_last_touched($index);
		$color_flow_href = $gui_history->get_hash_ref();

# Update the entry button value that displays the currently active
# flow or superflow name, by using the currently selected program name from the flow list
# e.g. data_in, suximage, suxgraph etc.
		( $color_flow_href->{_flowNsuperflow_name_w} )
		  ->configure( -text => ${ $color_flow_href->{_prog_name_sref} } );

		# needed in possible export via get_hash_ref to help
		my $prog_name_sref = $color_flow_href->{_prog_name_sref};

# will not reflect the Entry focus change
#		print("color_flow_href _flow_select2save_most_recent_param_flow, log view is on\n");
# $gui_history->view();
#		print("11, color_flow, END of _flow_select2save_most_recent_param_flow \n");
#		$param_flow_color_pkg->view_data();
#	    print("14.color_flow,_flow_select2save_most_recent_param_flow,widget values =@{$param_widgets->get_values_aref()} \n");

	}    # end pre_ok

	return ();
}

=head2 sub _get_flow_color

	get a private hash value
 
=cut

sub _get_flow_color {
	my ($self) = @_;

	if ( $color_flow_href->{_flow_color} ) {
		my $color;

		$color = $color_flow_href->{_flow_color};
		return ($color);

	}
	else {
		print("color_flow, missing flow color\n");
	}

}

=head2 sub _get_flow_listbox_color_w


=cut 

sub _get_flow_listbox_color_w {
	my ($self) = @_;
	my $this_flow_listbox_color_w;

	if ( defined $this_color
		and $this_color ne $empty_string )
	{
		my $flow_color = $this_color;

		# print("color_flow, color=$flow_color; this_color=$this_color\n");

		$this_flow_listbox_color_w = $color_flow_href->{$_flow_listbox_color_w};

	}
	else {
		print("color_flow, _get_flow_listbox_color_w, missing color\n");
	}

	return ($this_flow_listbox_color_w);

}

=head2 sub _move_in_stored_flows

  move program names,
  parameter names, values and checkbutton setttings
  --- these are stored separately (via param_flows.pm)
  from GUI widgets (via flow_widgets.pm)
  The flow-widgets is a single copy of names and values
  that constantly changes as the uses interacts with the GUI
  The param-flows stores several program (items) and their
  names and values

=cut 

sub _move_in_stored_flows {
	my ($self) = @_;

	$color_flow_href->{_index2move}        = $flow_widgets->index2move();
	$color_flow_href->{_destination_index} = $flow_widgets->destination_index();

	my $start = $color_flow_href->{_index2move};
	my $end   = $color_flow_href->{_destination_index};
	print("color_flow move_in_stored_flows,start index is the $start\n");
	print("color_flow move_in_stored_flows, insertion index is $end \n");

	$param_flow_color_pkg->set_insert_start($start);
	$param_flow_color_pkg->set_insert_end($end);
	$param_flow_color_pkg->insert_selection();

	return ();
}

=head2 sub _SaveAs_button

topic: only for 'SaveAs'
for safety, place set_hash_ref first
  	
CASE #1 considered:
Flow_selection is forced during _add2flow

CASE #2
if the previous items have not been directly selected with sub flow_select
they will not have been updated since loading into the GUI
if user made changes to the paramters but the flow was not selected
via flow_select (directly by the user) the flow parameters are not correct

=cut

sub _SaveAs_button {
	my ($topic) = @_;

	if ( $topic eq 'SaveAs' ) {

		my $files_LSU = files_LSU->new();

		# Start refocus index in flow, in case focus has been removed
		# e.g., by double-clicking in parameter values window
		my $most_recent_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};
		my $prior_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_prior};
		my $most_recent_flow_color =
		  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};
		my $last_flow_index = $most_recent_flow_index_touched;

# print("1 OLD save, last_flow_color is:  $color_flow_href->{_last_flow_color} \n");
# print("1 OLD save, last_flow_index is:  $color_flow_href->{_last_flow_index} \n");

# print("1 save_button, most_recent_flow_index is:  $most_recent_flow_index_touched\n");
# print("1 save_button, pior_flow_index is:  $prior_flow_index_touched\n");

# print("1 color_flow, _SaveAs_button, new save, last_flow_color is:  $most_recent_flow_color \n");

		#		print("_SaveAs_button, view stored data in param flow3\n");
		#		$param_flow_color_pkg->view_data();

		$gui_history->set_hash_ref($color_flow_href);
		$gui_history->set4_start_of_SaveAs_button();

		my $num_items = $param_flow_color_pkg->get_num_items();

		$color_flow_href->{_names_aref} =
		  $param_flow_color_pkg->get_names_aref();

		$param_flow_color_pkg->set_good_values();
		$param_flow_color_pkg->set_good_labels();

		# collect information to be saved in a perl flow
		$color_flow_href->{_good_labels_aref2} =
		  $param_flow_color_pkg->get_good_labels_aref2();
		$color_flow_href->{_items_versions_aref} =
		  $param_flow_color_pkg->get_flow_items_version_aref();
		$color_flow_href->{_good_values_aref2} =
		  $param_flow_color_pkg->get_good_values_aref2();
		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();

		my $num_items4flow = scalar @{ $color_flow_href->{_good_labels_aref2} };

		#				 for (my $i=0; $i < $num_items4flow; $i++ ) {
		#				 	@{@{$color_flow_href->{_good_labels_aref2}}[$i]}\n");
		#				 }

		#		for (my $i=0; $i < $num_items4flow; $i++ ) {
		#		 print("color_flow,_SaveAs_button, _good_values_aref2,
		#			@{@{$color_flow_href->{_good_values_aref2}}[$i]}\n");
		#		}
		#   print("color_flow,_prog_versions_aref,
		#   @{$color_flow_href->{_items_versions_aref}}\n");

		$files_LSU->set_prog_param_labels_aref2($color_flow_href);
		$files_LSU->set_prog_param_values_aref2($color_flow_href);
		$files_LSU->set_prog_names_aref($color_flow_href);
		$files_LSU->set_items_versions_aref($color_flow_href);
		$files_LSU->set_data();
		$files_LSU->set_message($color_flow_href);

		# listbox color assignment
		$files_LSU->set_flow_color($this_color);

		# update PL_SEISMIC in case user has recently changed project area
		$files_LSU->set_PL_SEISMIC();

		# flows saved to PL_SEISMIC
		$files_LSU->set2pl($color_flow_href);
		$files_LSU->save();

		$gui_history->set4_end_of_SaveAs_button(); # sets: _has_used_SaveAs=true
		$color_flow_href = $gui_history->get_hash_ref();

		return ();

	}
	else {
		print("color_flow,_SaveAs_button, missing topic\n");
	}
}

=head2 sub _perl_flow_errors
Based on _perl_flow
Parse (while reading) perl flows

=cut

sub _perl_flow_errors {

	my ($self) = @_;

	my $result;

	# instantiate modules
	my $perl_flow   = perl_flow->new();
	my $param_sunix = param_sunix->new();

	# messages
	my $message = $message_director->null_button(0);
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	# should be at start of color_flow
	$color_flow_href->{_flow_type} = $flow_type->{_user_built};
	my $flow_name_in_color = $color_flow_href->{$_flow_name_in_color};

	my $flow_color = $color_flow_href->{_flow_color};

	# read in variables from the perl flow file
	$perl_flow->set_perl_file_in($flow_name_in_color);
	my $is_error = $perl_flow->get_parse_errors();

	$result = $is_error;

	return ($result);
}

=head2 sub _perl_flow
  Parse (while reading) perl flows

  foreach my $key (sort keys %$color_flow_href) {
   print (" color_flowkey is $key, value is $color_flow_href->{$key}\n");
  }   
   		my $length = scalar @{$all_values_aref};
   		print("color_flow,perl_flow, length = $length\n");
   		
   		for (my $j=0; $j <$length; $j++) {
   			   	print("color_flow,perl_flow,name & value:@{$all_names_aref}[$j] = @{$all_values_aref}[$j]\n");

   		}     
 
=cut 

sub _perl_flow {
	my ($self) = @_;

	# instantiate modules
	my $perl_flow   = perl_flow->new();
	my $param_sunix = param_sunix->new();

	# messages
	my $message = $message_director->null_button(0);
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	# should be at start of color_flow
	$color_flow_href->{_flow_type} = $flow_type->{_user_built};
	my $flow_name_in_color = $color_flow_href->{$_flow_name_in_color};

	my $flow_color = $color_flow_href->{_flow_color};

	# read in variables from the perl flow file
	$perl_flow->set_perl_file_in($flow_name_in_color);
	$perl_flow->parse();

	# clear all signs in GUI and wipe all the memory spaces
	# associated with the contents in the flow listbox that is about to
	# be occupied
	_clear_color_flow();

	my $num_prog_names = $perl_flow->get_num_prog_names();

	if ( length $num_prog_names ) {

		for ( my $prog_idx = 0 ; $prog_idx < $num_prog_names ; $prog_idx++ ) {

			# collect info. from perl file
			$perl_flow->set_prog_index($prog_idx);
			$color_flow_href->{_prog_name_sref} =
			  $perl_flow->get_prog_name_sref();
			$color_flow_href->{_names_aref} = $perl_flow->get_all_names_aref();
			$color_flow_href->{_values_aref} =
			  $perl_flow->get_all_values_aref();
			$color_flow_href->{_check_buttons_settings_aref} =
			  $perl_flow->get_check_buttons_settings_aref();

			# establish which program is active in the flow  7.10.21
			$control->set_flow_program_name_sref(
				$color_flow_href->{_prog_name_sref} );
			$control->set_flow_prog_name_index(0);

			# remove quotes upon input
			$color_flow_href->{_values_aref} =
			  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

			# add single quotes upon input only to strings
			$color_flow_href->{_values_aref} =
			  $control->get_string_or_number4aref(
				$color_flow_href->{_values_aref} );

			$perl_flow->set_prog_index($prog_idx);
			my $number_of_values = scalar @{ $color_flow_href->{_values_aref} };

			$color_flow_href->{_param_sunix_length} =
			  $perl_flow->get_param_sunix_length();

			my $values_aref = $color_flow_href->{_values_aref};

			# print("2. color_flow,_perl_flow, values = @$values_aref \n");

		  # Populate GUI with the parameter values and labels of the first item
		  # _add2flow will call _flow_select to select the last flow item loaded
		  # _flow select marks the gui history and calls
		  # flow_select which will detect any parameter changes
		  # and will store
		  # upload variables into the param_flow for each program

			_add2flow();
		}

		_flow_select_director('_perl_flow');

		# flow loading and display is complete
		# print("1. color_flow, _perl_flow, print out gui_history\n");
		# $gui_history->view();

		return ();

	}
	else {
		print("$this_color flow is missing the number of programs in a flow\n");
	}

}

=head2 sub _set_flow_color


=cut 

sub _set_flow_color {
	my ($flow_color) = @_;

	if ($flow_color) {

		$color_flow_href->{_flow_color} = $flow_color;

	}
	else {
		print("color_flow, set_flow_color, missing color\n");
	}
	return ();
}

=head2 sub _local_set_flow_listbox_color_w


=cut 

sub _local_set_flow_listbox_color_w {
	my ($flow_color) = @_;

	if ( $flow_color eq $this_color ) {

		$color_flow_href->{_flow_listbox_color_w} =
		  $color_flow_href->{$_flow_listbox_color_w};

	}
	else {
		print(
"color_flow,_local_set_flow_listbox_color_w, _local_set_flow_listbox_color_w, missing color\n"
		);
	}

	return ();
}

=head2 sub _set_flow_name_color_w

=cut

sub _set_flow_name_color_w {
	my ($flow_color) = @_;

#	print(
#		"color_flow,_set_flow_name_color_w, flow_color,this_color: $flow_color,$this_color \n"
#	);
	if ( $flow_color eq $this_color ) {

		$flow_name_color_w = $color_flow_href->{$_flow_name_color_w};

		# do not export
		$flow_name_color_w = $color_flow_href->{$_flow_name_color_w};

	}
	else {
		print(
"color_flow,_set_flow_name_color_w, _set_flow_name_color_w, missing color \n"
		);
	}

	return ();
}

=head2 sub _set_flowNsuperflow_name_w

	displays superflow name at top of gui
	
=cut

sub _set_flowNsuperflow_name_w {
	my ($flowNsuperflow_name) = @_;

	if (   $flowNsuperflow_name
		&& $color_flow_href->{_flowNsuperflow_name_w} )
	{

		( $color_flow_href->{_flowNsuperflow_name_w} )
		  ->configure( -text => $flowNsuperflow_name, );
	}
	else {
		print(
"color_flow, set_flowNsuperflow_name_w, missing widget or program name\n"
		);
	}

	return ();
}

=head2 sub _set_user_built_flow_name_w

 place and show the user-built flow name

=cut

sub _set_user_built_flow_name_w {
	my ($user_built_flow_name) = @_;

	if ($user_built_flow_name) {

		if ($flow_name_color_w) {

			# do not export
			$flow_name_color_w = $flow_name_color_w;

			# display name in widget
			$flow_name_color_w->configure( -text => $user_built_flow_name, );

		}
		elsif ( not $flow_name_color_w ) {

			_set_flow_name_color_w($flow_color);

			# do not export
			$flow_name_color_w = $flow_name_color_w;

			# display name in widget
			$flow_name_color_w->configure( -text => $user_built_flow_name, );

		}
		else {
			print(
"color_flow, set_user_built_flow_name_w, missing flow_name_color_w \n"
			);
		}
	}
	else {
		print("color_flow, set_user_built_flow_name_w, missing program name\n");
	}

	return ();
}

=head2 sub _stack_flow

  store an initial version of the parameters in a 
  namespace different to the one belonging to param_widgets 
  
  The initial version comes from default parameter files
  i.e., the same code as for sunix_select
  
  print("color_flow,_stack_flow, color_flow_href->{_values_aref} =@{$color_flow_href->{_values_aref}} \n");
 
=cut

sub _stack_flow {
	my ($self) = @_;

	# my $num_items = $param_flow_color_pkg->get_num_items();
	# print("color_flow,_stack_flow, data before stack num_items=$num_items\n");
	# $param_flow_color_pkg->view_data();

	$param_flow_color_pkg->stack_flow_item(
		$color_flow_href->{_prog_name_sref} );

	$param_flow_color_pkg->stack_names_aref2( $color_flow_href->{_names_aref} );

# print("color_flow,_stack_flow, color_flow_href->{_names_aref} =@{$color_flow_href->{_names_aref}} \n");

	# when used for very first time in a GUI the index can be < 0
	# control->set_flow_prog_name_index takes care of this situation
	my $most_recent_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};

#	 print("color_flow,_stack_flow,  most_recent_flow_index_touched = $most_recent_flow_index_touched\n");

	$color_flow_href->{_prog_names_aref} =
	  $param_flow_color_pkg->get_flow_prog_names_aref();
	$control->set_flow_prog_names_aref( $color_flow_href->{_prog_names_aref} );
	$control->set_flow_prog_name_index($most_recent_flow_index_touched);

	# restore strings to have terminal strings
	# remove quotes upon input
	$color_flow_href->{_values_aref} =
	  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

	# in case parameter values have been displayed stringless
	$color_flow_href->{_values_aref} =
	  $control->get_string_or_number4aref( $color_flow_href->{_values_aref} );

# print("color_flow,_stack_flow, color_flow_href->{_names_aref} =@{$color_flow_href->{_values_aref}} \n");

	$param_flow_color_pkg->stack_values_aref2(
		$color_flow_href->{_values_aref} );

	$param_flow_color_pkg->stack_checkbuttons_aref2(
		$color_flow_href->{_check_buttons_settings_aref} );

	# my $num_items = $param_flow_color_pkg->get_num_items();
	# print("color_flow,_stack_flow, data after stack num_items=$num_items\n");
	# $param_flow_color_pkg->view_data();

	return ();

}    # end _stack_flow

=head2 sub _stack_versions 

   Collect and store latest program versions from changed list 
   
   Will update listbox variables inside flow_widgets.pm
   Therefore pop is not needed on the array
   Use after data have been stored, deleted, or 
   suffered an insertion event

=cut

sub _stack_versions {

	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

	$flow_widgets->set_flow_items($_flow_listbox_color_w);
	$color_flow_href->{_items_versions_aref} =
	  $flow_widgets->items_versions_aref;
	$param_flow_color_pkg->set_flow_items_version_aref(
		$color_flow_href->{_items_versions_aref} );

}

=head2  _updateNsave_most_recent_param_flow

update parameter values of the most recently touched
program in the flow

			print(
				"1. START color_flow, _updateNsave_most_recent_param_flow, prior_flow_index=$prior, most_recent=$most_recent\n"
			);
			print(
"color_flow, START _updateNsave_most_recent_param_flow, view param flow stored data:\n"
			);


=cut 

sub _updateNsave_most_recent_param_flow {

	my ($self) = @_;

	my $last_parameter_index_on_entry;
	my $last_parameter_index_touched_color;
	my $most_recent_flow_index_touched;
	my $prior_flow_index_touched;

	$prior_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_prior};
	$most_recent_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

=pod

hash remains partially undefined in gui_history.pm

=cut

	if (
		not(
			defined(
				(
					$color_flow_href->{_parameter_index_on_entry_click_seq_href}
				)->{_most_recent}
			)
		)
	  )
	{
		( $color_flow_href->{_parameter_index_on_entry_click_seq_href} )
		  ->{_most_recent} = -1;
		my $value =
		  ( $color_flow_href->{_parameter_index_on_entry_click_seq_href} )
		  ->{_most_recent};

	}
	if (
		not(
			defined(
				( $color_flow_href->{_parameter_index_on_exit_click_seq_href} )
				->{_most_recent}
			)
		)
	  )

	{
		( $color_flow_href->{_parameter_index_on_exit_click_seq_href} )
		  ->{_most_recent} = -1;
		my $value =
		  ( $color_flow_href->{_parameter_index_on_exit_click_seq_href} )
		  ->{_most_recent};

# print("color_flow,_updateNsave_most_recent_param_flow, undefined 2 is: $value\n");
	}

=pod

 The following two values = -1 (default) until a
 second program is placed in the flow
 
=cut

	$last_parameter_index_on_entry =
	  ( $color_flow_href->{_parameter_index_on_entry_click_seq_href} )
	  ->{_most_recent};
	$last_parameter_index_touched_color =
	  ( $color_flow_href->{_parameter_index_on_exit_click_seq_href} )
	  ->{_most_recent};

	my $prior_flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_prior};
	my $most_recent_flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};

	my $storage_flow_index = $most_recent_flow_index_touched;

=pod To update parameters in the most recent flow
	at least one program item must exist
=cut

	my $num_flow_items = $flow_widgets->get_num_items($_flow_listbox_color_w);

# print("color_flow, _updateNsave_most_recent_param_flow, num flow items= $num_flow_items\n");

	if (
		(
			   $most_recent_flow_index_touched >= 0
			or $last_parameter_index_touched_color >= 0
		)
		and $num_flow_items > 0
	  )
	{

		# prior flow must have the same color as the current one or
		# we have just clicked an sunix program (neutral-flow case)
		if (   $prior_flow_color eq $neutral
			or $prior_flow_color eq $most_recent_flow_color )
		{
			my $most_recent =
			  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )
			  ->{_most_recent};
			my $prior =
			  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )
			  ->{_prior};

			# the checkbuttons, values and names of ONLY the last program used
			# are stored in param_widgets at any ONE time
			$color_flow_href->{_values_aref} =
			  $param_widgets->get_values_aref();

			# establish which program is active in the flow-- for control
			$color_flow_href->{_prog_names_aref} =
			  $param_flow_color_pkg->get_flow_prog_names_aref();
			$control->set_flow_prog_names_aref(
				$color_flow_href->{_prog_names_aref} );
			$control->set_flow_prog_name_index($most_recent);

			# restore terminal ticks in strings after reading from the GUI
			# remove  possible terminal strings
			$color_flow_href->{_values_aref} =
			  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

			# in case parameter values have been displayed stringless
			$color_flow_href->{_values_aref} =
			  $control->get_string_or_number4aref(
				$color_flow_href->{_values_aref} );
			$color_flow_href->{_names_aref} = $param_widgets->get_labels_aref();
			$color_flow_href->{_check_buttons_settings_aref} =
			  $param_widgets->get_check_buttons_settings_aref();

			$param_flow_color_pkg->set_flow_index($storage_flow_index);

  # The following 3 lines save old changed values and names but not the versions
			$param_flow_color_pkg->set_values_aref(
				$color_flow_href->{_values_aref} );

			#			print(
			#				"99. color flow,leaving _updateNsave_most_recent_param_flow \n"
			#			);
			#			$param_flow_color_pkg->view_data();

			$param_flow_color_pkg->set_names_aref(
				$color_flow_href->{_names_aref} );
			$param_flow_color_pkg->set_check_buttons_settings_aref(
				$color_flow_href->{_check_buttons_settings_aref} );

			$param_widgets->set_entry_change_status($false)
			  ;    # changes are now complete, needwd??
			$color_flow_href->{_last_flow_color} =
			  $color_flow_href->{_flow_color};

			$most_recent =
			  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )
			  ->{_most_recent};
			$prior =
			  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )
			  ->{_prior};

#			print(
#				"1. END color_flow, _updateNsave_most_recent_param_flow, prior_flow_index=$prior, most_recent=$most_recent\n"
#			);

		}
		else {

			#NADA
		}
	}
	else {
	}

	return ();
}

=head2  _update_prior_param_flow

	Updates the values for parameters stored via param_flow
	param-flow takes uses parameters from param_widgets
	BUT param_widgets needs to have been updated by _update_most_recent_flow? or 
	user changes on the screen will not have been updated

	Apply every time that a flow item is selected 
	1. Assume that selection of a flow item implies pre-existing parameter values were changed/added
	
	2. Opening a file dialog assumes parameter values were also changed (Entry widget) 
	-- this means that a prior program must have been touched and that the color must change 
	from either neutral to the current color or be overwritten by the same color
		 
	Exceptions include the 
	(1) case when you have just left a flow of a different color 
	and are returning to previous settings.
	(2) case when you are using the first item in a flow for the first time, i.e. it has never been
	used before
	
	Find out the previous color, then ... there are
	2 possible CASES
		 CASE 1
		 The current color is the same as the previously touched color
		 i.e., if the last color-flow box touched was of the current flow color
		 i.e., consider situation when we are still using the same colored list box
		 
		 in which case...		
		 1. Find out which index was touched in "color"-flow box
		 2. Find out which program was previously touched
		 3. Assume the touched program had its parameter values modified
		 4. Update all the previously touched program's values in storage via param_flow
		 
		 CASE 2
		 If the current color is different to the previously touched color, then 		
		 2. ELIMINATE all the previous changes
  		 
  	Clicking Save will activate _update_prior_param_flow.  
  			Before Save is clicked:
  			 the 
  			_last_parameter_index_touched_color = 0
         	_last_flow_index_touched 			= -1
         	_last_flow_color 					= current flow color
 
 
			 print("1. color_flow, _update_prior_param_flow, start\n");
			$param_flow_color_pkg->view_data();

			# print("2. color_flow, _update_prior_param_flow, print gui_history.txt\n");
			# $gui_history->view();
			
					 deprecated 1.23.23
				if (   $prior_flow_color eq $neutral
				       or $prior_flow_color eq $most_recent_flow_color )

  
  
		print(
"color_flow,_update_prior_param_flow,prior_color_flow = $prior_flow_color\n"
		);
		print("2 color_flow, _update_prior_param_flow, start\n");
		$param_flow_color_pkg->view_data();

		print(
"3. color_flow,_update_prior_param_flow,names, color_flow: @{$color_flow_href->{_names_aref}}\n"
		);
		print(
"3.color_flow,_update_prior_param_flow,values, color_flow: @{$color_flow_href->{_values_aref}}\n"
		);
		print(
"3.color_flow,_update_prior_param_flow,n, param_widgets:@{$param_widgets->get_labels_aref()}\n"
		);
		print(
"3.color_flow,_update_prior_param_flow,values, param_widgets:@{$param_widgets->get_values_aref()}\n"
		);
			print("1. color_flow,_update_prior_param_flow, prior_flow and storage index=$storage_flow_index\n");
	print("color_flow,_update_prior_param_flow,most_recent_flow_index=$most_recent_flow_index_touched\n");
		
   		print("4.color flow,_update_prior_param_flow \n");
		$param_flow_color_pkg->view_data();
=cut 

sub _update_prior_param_flow {

	my ($self) = @_;

	my $prior_item_exists = $false;
	my $_flow_listbox_color_w =
	  _get_flow_listbox_color_w();    # user-built_flow in current use

	my $prior_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_prior};
	my $most_recent_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};

   # following two values are empty until a second program is placed in the flow
	my $last_parameter_index_on_entry =
	  ( $color_flow_href->{_parameter_index_on_entry_click_seq_href} )
	  ->{_most_recent};
	my $last_parameter_index_touched_color =
	  ( $color_flow_href->{_parameter_index_on_exit_click_seq_href} )
	  ->{_most_recent};
	my $prior_flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_prior};
	my $most_recent_flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};
	my $storage_flow_index = $prior_flow_index_touched;
	my $prior_flow_select  = ( $color_flow_href->{_button_href} )->{_prior};

	# get number of items in the flow listbox
	# prior program must exist
	if ( $prior_flow_index_touched <=
		$flow_widgets->get_num_items($_flow_listbox_color_w) )
	{

		$prior_item_exists = $true;

	}
	else {
		print("color_flow,_update_prior_param_flow, missing prior item\n");
	}

	if (
		(
			   $most_recent_flow_index_touched >= 0
			or $last_parameter_index_touched_color >= 0
		)
		and $prior_item_exists
	  )
	{

		if (    $prior_flow_select eq $sunix_select
			and $prior_flow_color eq $most_recent_flow_color )
		{

			print(
"4.color flow,_update_prior_param_flow, prior_flow_select=$prior_flow_select \n"
			);

			# CASE 1 prior flow must have been an sunix program
			# so ignore the param_widgets that were just displayed
			# NADA

		}
		elsif ( $prior_flow_color eq $most_recent_flow_color ) {

			# CASE 2 prior flow must have the same color as the current one
			# but sunix_select was not previously selected

			# the checkbuttons, values and names of ONLY the last program used
			# are stored in param_widgets at any ONE time
			$color_flow_href->{_values_aref} =
			  $param_widgets->get_values_aref();

			# establish which program is active in the flow--for control
			$color_flow_href->{_prog_names_aref} =
			  $param_flow_color_pkg->get_flow_prog_names_aref();
			$control->set_flow_prog_names_aref(
				$color_flow_href->{_prog_names_aref} );
			$control->set_flow_prog_name_index($most_recent_flow_index_touched);

			# restore terminal ticks in strings after reading from the GUI
			# remove  possible terminal strings
			$color_flow_href->{_values_aref} =
			  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

			# correct parameter values that have been displayed stringless
			$color_flow_href->{_values_aref} =
			  $control->get_string_or_number4aref(
				$color_flow_href->{_values_aref} );

			# collect checkbuttons, names from what is currently in the gui
			$color_flow_href->{_names_aref} = $param_widgets->get_labels_aref();
			$color_flow_href->{_check_buttons_settings_aref} =
			  $param_widgets->get_check_buttons_settings_aref();

  # The following 3 lines save old changed values and names but not the versions
			$param_flow_color_pkg->set_values_aref(
				$color_flow_href->{_values_aref} );
			$param_flow_color_pkg->set_names_aref(
				$color_flow_href->{_names_aref} );
			$param_flow_color_pkg->set_check_buttons_settings_aref(
				$color_flow_href->{_check_buttons_settings_aref} );
			$param_flow_color_pkg->set_flow_index($storage_flow_index);

			$param_widgets->set_entry_change_status($false)
			  ;    # changes are now complete, needwd??
			$color_flow_href->{_last_flow_color} =
			  $color_flow_href->{_flow_color};

		}
		else {
			#NADA
		}
	}
	else {
	}

	return ();
}

=head2  _save_most_recent_param_flow
	
	Force to save flow parameters to param_flow
	 
	We assume that the program of interest within an active flow stays the same.
	Nevertheless that a parameter within a fixed program has changed so that
	the stored parameters for that program need to be updated. (TODO??)
	That is, param_flow will update the stored parameters for a member of the flow
	without having to change the flow item/program with which we interact.
	
	The checkbuttons, values and names of only the present program in use 
  	are stored in param_widgets at any one time
  	
  	After selecting  a data file name, the file name is automatically inserted
  	into the GUI. Following, we update the data file name into the stored parameters via param_flow
  	
	$last_parameter_index_touched_color must =0 or > 0
	but does exist and means the parameters are untouched
	
=cut 

sub _save_most_recent_param_flow {

	my ($self) = @_;

	my $prior_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_prior};
	my $most_recent_flow_index_touched =
	  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};
	my $storage_flow_index = $most_recent_flow_index_touched;

# The following two values are empty until a second program is placed in the flow
	my $last_parameter_index_on_entry =
	  ( $color_flow_href->{_parameter_index_on_entry_href} )->{_most_recent};
	my $last_parameter_index_touched_color =
	  ( $color_flow_href->{_parameter_index_on_exit_href} )->{_most_recent};

#    print("color_flow _save_most_recent_param_flow ,last changed entry index was $last_parameter_index_touched_color \n");
#	print("2. color_flow, _save_most_recent_param_flow , print gui_history.txt\n");
#	$gui_history->view();

#	my $prior_flow_color       = ( $color_flow_href->{_flow_select_color_href} )->{_prior};
#	my $most_recent_flow_color = ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};

	if ( $last_parameter_index_touched_color >= 0 ) {

# Update names and check_buttons again, while reading in from the GUI ( via param_widgets)
		$color_flow_href->{_names_aref} = $param_widgets->get_labels_aref();
		$color_flow_href->{_check_buttons_settings_aref} =
		  $param_widgets->get_check_buttons_settings_aref();
		$color_flow_href->{_values_aref} = $param_widgets->get_values_aref();

		# establish which program is active in the flow
		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();
		$control->set_flow_prog_names_aref(
			$color_flow_href->{_prog_names_aref} );
		$control->set_flow_prog_name_index($most_recent_flow_index_touched);

		# restore terminal ticks in strings after reading from the GUI
		# remove  possible terminal strings
		$color_flow_href->{_values_aref} =
		  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

#		print(
#			"color_flow, _save_most_recent_param_flow, param_widgets->get_values_aref():@{$color_flow_href->{_values_aref}}\n"
#		);
# in case parameter values have been displayed stringless
		$color_flow_href->{_values_aref} = $control->get_string_or_number4aref(
			$color_flow_href->{_values_aref} );

#		print(
#			"3B. color_flow, _save_most_recent_param_flow,color_flow_href->{_values_aref}=
#			@{$color_flow_href->{_values_aref}}\n");

# Use flow item index of the program in the color-flow listbox that is currently being used,
# i.e., not the index of the last-used program  ut the current
# user-built_flow.
		my $_flow_listbox_color_w = _get_flow_listbox_color_w();

		if ( $storage_flow_index >= 0 ) {

			# select an item from which to extract data
			$param_flow_color_pkg->set_flow_index($storage_flow_index);

			# save current values, names and check buttons BUT not the versions
			$param_flow_color_pkg->set_values_aref(
				$color_flow_href->{_values_aref} );
			$param_flow_color_pkg->set_names_aref(
				$color_flow_href->{_names_aref} );
			$param_flow_color_pkg->set_check_buttons_settings_aref(
				$color_flow_href->{_check_buttons_settings_aref} );
			$param_widgets->set_entry_change_status($false)
			  ;    # changes are now complete

#			print(
#				"1912 End of $this_color _save_most_recent_param_flow: _last_parameter_index_touched reset:
#				$color_flow_href->{_last_parameter_index_touched_color}\n"
#			);

		}
		else {

			# Look for the last flow index that was touched
			my $last_idx_chng = $storage_flow_index;
			$param_flow_color_pkg->set_flow_index($last_idx_chng);

			# save current values, names and check buttons BUT not the versions
			$param_flow_color_pkg->set_values_aref(
				$color_flow_href->{_values_aref} );
			$param_flow_color_pkg->set_names_aref(
				$color_flow_href->{_names_aref} );
			$param_flow_color_pkg->set_check_buttons_settings_aref(
				$color_flow_href->{_check_buttons_settings_aref} );
			$param_widgets->set_entry_change_status($false)
			  ;    # changes are now complete

#			print(
#				"1656 End of $this_color _save_most_recent_param_flow: _last_parameter_index_touched reset: $color_flow_href->{_last_parameter_index_touched_color}\n"
#			);

		}

	}
	else {

		#		print("color_flow,_save_most_recent_param-flow,NADA \n");
	}

	return ();
}

=head2 sub FileDialog_button

Handles Data, SaveAs and (perl) Open (in) or Delete
May provide values from the current widget if it is used.
Can also be (1) a previous pre-built superflow that is already in the GUI
or 2) empty if program is just starting

 dialog type (option_sref)  can be:
  	Data, 
  	Open (open an exisiting user-built flow, but not a pre-built
  				superflow), or
  	SaveAs
  	
  	Delete ( a file or any type, default $PL_SEISMIC)
  			
  	my $uBF      	= $file_dialog->get_hash_ref(); 
		foreach my $key (sort keys %$uBF) {
   			print (" color_flowkey is $key, value is $uBF->{$key}\n");
  		}
  		
=cut 

sub FileDialog_button {

	my ( $self, $dialog_type_sref ) = @_;

	my $file_dialog_type = $L_SU_global_constants->file_dialog_type_href();
	my $PL_SEISMIC       = $Project->PL_SEISMIC();

	if ($dialog_type_sref) {

		$color_flow_href->{_dialog_type} =
		  $$dialog_type_sref;    # dereference scalar
		my $topic = $color_flow_href->{_dialog_type};

		if ( $topic eq $file_dialog_type->{_SaveAs} ) {

			# print("color_flow, L_SU,FileDialog_button, ONLY for SaveAs\n");
			# i.e., in this module, dialog_type_sref can only be SaveAs
			# Save for 'user-built flows' is accessible via L_SU.pm

			my $most_recent_flow_index_touched =
			  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};

			$color_flow_href->{_values_aref} =
			  $param_widgets->get_values_aref();

			# establish which program is active in the flow
			$color_flow_href->{_prog_names_aref} =
			  $param_flow_color_pkg->get_flow_prog_names_aref();
			$control->set_flow_prog_names_aref(
				$color_flow_href->{_prog_names_aref} );
			$control->set_flow_prog_name_index($most_recent_flow_index_touched);

			# restore strings to have terminal strings
			# remove quotes upon input
			$color_flow_href->{_values_aref} =
			  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

			# in case parameter values have been displayed stringless
			$color_flow_href->{_values_aref} =
			  $control->get_string_or_number4aref(
				$color_flow_href->{_values_aref} );

			$color_flow_href->{_dialog_type} =
			  $$dialog_type_sref;    # dereference scalar

			$file_dialog->set_flow_color( $color_flow_href->{_flow_color} );
			$file_dialog->set_hash_ref($color_flow_href);
			$file_dialog->FileDialog_director();

			$color_flow_href->{_has_used_SaveAs_button} = $true;

			# new file name will generate a case that an index has been touched
			$color_flow_href->{_last_parameter_index_touched_color} =
			  $file_dialog->get_last_parameter_index_touched_color();

# print ("1. color_flow,FileDialog_button,_last_parameter_index_touched_color:$color_flow_href->{_last_parameter_index_touched_color} \n");
# print ("1. color_flow,FileDialog_button, color: $flow_color \n");
			$color_flow_href->{$_is_last_parameter_index_touched_color} = $true;

			_save_most_recent_param_flow();

			$color_flow_href->{$_flow_name_out_color} =
			  file_dialog->get_perl_flow_name_out();
			$color_flow_href->{_path} = file_dialog->get_file_path();

			# consider empty case, for which saving is not possible
			if (   !( $color_flow_href->{$_flow_name_out_color} )
				|| $color_flow_href->{$_flow_name_out_color} eq ''
				|| !( $color_flow_href->{_path} )
				|| $color_flow_href->{_path} eq '' )
			{

				my $message = $message_director->save_button(1);
				$message_w->delete( "1.0", 'end' );
				$message_w->insert( 'end', $message );

			}
			else {

				# CASE: NON-EMPTY and good

				# displays user-built flow name at top of color-flow gui
				_set_flowNsuperflow_name_w(
					$color_flow_href->{$_flow_name_out_color} );
				_set_user_built_flow_name_w(
					$color_flow_href->{$_flow_name_out_color} );

				# go save perl flow file
				_SaveAs_button($topic);

				# print("color_flow,FileDialog_button, saving the perl file\n");

		# restore message at the bottom of the string to blank if not already so
		# messages
				my $message = $message_director->null_button(0);
				$message_w->delete( "1.0", 'end' );
				$message_w->insert( 'end', $message );

			}    # Ends SaveAs option

		}
		elsif ( $topic eq $file_dialog_type->{_Open} ) {

# 1. Read perl flow file
# 2. Write name to the file name in the appropriate flow
# 3. populate GUI
# 4. populate hashes (color_flow)and memory spaces (param_flow)
# 5. Make sure to clean prior information from the FileDialog Button such as file names.
# 6. save moment all this is done in gui_history

			$file_dialog->set_flow_color( $color_flow_href->{_flow_color} );
			$file_dialog->set_hash_ref($color_flow_href);    # uses values_aref
			$file_dialog->set_flow_type('user_built');

			$file_dialog->FileDialog_director();

			$color_flow_href->{$_flow_name_in_color} =
			  $file_dialog->get_perl_flow_name_in();

#			print("color_flow, flow_name_in = $color_flow_href->{$_flow_name_in_color}\n");
			$color_flow_href->{$_flow_name_out_color} =
			  $color_flow_href->{$_flow_name_in_color};

#			print("color_flow,color_flow_href->{_has_used_open_perl_file_button}=$color_flow_href->{_has_used_open_perl_file_button}\n");

			# Is $flow_name_in empty?
			my $file2query =
			  $PL_SEISMIC . '/' . $color_flow_href->{$_flow_name_in_color};
			$color_flow->{_Flow_file_exists} =
			  $manage_files_by2->does_file_exist_sref( \$file2query );

			# Are there any errors when reading the perl flow file
			$color_flow->{_perl_flow_errors} = _perl_flow_errors();

			if (   $color_flow->{_Flow_file_exists}
				&& $color_flow->{_perl_flow_errors} eq $false )
			{

				_set_flow_name_color_w($flow_color);

				# Place names of the programs at the top of the color listbox
				$flow_name_color_w->configure(
					-text => $color_flow_href->{$_flow_name_in_color} );

				# Place names of the programs at the head of the GUI
				$color_flow_href->{_flowNsuperflow_name_w}->configure(
					-text => $color_flow_href->{_big_stream_name_in} );

				# populate gui, and bot param_flow and param_widgets namespaces
				_perl_flow();

			}
			else {
#				print("  color_flow,FileDialog_button, perl flow parse errors\n");
#	 print("3 color_flow,FileDialog_button, Warning: missing file. \"Cancel\" clicked by user? NADA\n");
			}

		}
		elsif ( $topic eq $file_dialog_type->{_Data} ) {

		 #	print("color_flow, FileDialog_button,option_sref $topic\n");
		 # assume that after selection to open of a data file in file-dialog the
		 # GUI has been updated
		 # See if the last parameter index has been touched (>= 0)
		 # Assume we are still dealing with the current flow item selected
			$color_flow_href->{_last_parameter_index_touched_color} =
			  $file_dialog->get_last_parameter_index_touched_color();
			$color_flow_href->{$_is_last_parameter_index_touched_color} = $true;

			# set the current listbox as the last color listbox
			$color_flow_href->{_last_flow_listbox_color_w} =
			  $color_flow_href->{_flow_listbox_color_w};

			# provide values in the current widget
			$color_flow_href->{_values_aref} =
			  $param_widgets->get_values_aref();

			my $most_recent_flow_index_touched =
			  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};

			# restore terminal ticks to strings

			# establish which program is active in the flow
			$color_flow_href->{_prog_names_aref} =
			  $param_flow_color_pkg->get_flow_prog_names_aref();
			$control->set_flow_prog_names_aref(
				$color_flow_href->{_prog_names_aref} );
			$control->set_flow_prog_name_index($most_recent_flow_index_touched);

			# restore strings to have terminal strings
			# remove quotes upon input
			$color_flow_href->{_values_aref} =
			  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

			# in case parameter values have been displayed stringless
			$color_flow_href->{_values_aref} =
			  $control->get_string_or_number4aref(
				$color_flow_href->{_values_aref} );

#			print(
#				"color_flow,FileDialog_button(binding), flow_listbox_color_w: $color_flow_href->{_flow_listbox_color_w} \n"
#			);
			$file_dialog->set_flow_color( $color_flow_href->{_flow_color} );
			$file_dialog->set_hash_ref($color_flow_href);
			$file_dialog->FileDialog_director();

#			print(
#				"color_flow,FileDialog_button(binding), last_parameter_index_touched_color: $color_flow_href->{_last_parameter_index_touched_color} \n"
#			);

			# update to parameter values occurs in file_dialog
			$color_flow_href->{_values_aref} = $file_dialog->get_values_aref();

			# set up this flow listbox item as the last item touched
			my $_flow_listbox_color_w =
			  _get_flow_listbox_color_w();    # user-built_flow in current use
			my $current_flow_listbox_index =
			  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

			#			$color_flow_href->{_last_flow_index_touched} =
			#				$current_flow_listbox_index;    # for next time
			#			$color_flow_href->{$_is_last_flow_index_touched_color} = $true;

# print("color_flow,FileDialog_button(binding), last_flow_index_touched:$color_flow_href->{_last_flow_index_touched} \n");

# Changes made with another instance of param_widgets (in file_dialog) will require
# that we also update the namespace of the current param_flow
# We make this change inside _save_most_recent_param_flow
			_save_most_recent_param_flow();

		}
		else {
			print("1. color_flow, FileDialog_button, missing topic \n");

			# Ends opt_ref
		}
	}
	else {
		print("color_flow,FileDialog_button ,option type missing\n");
	}

	return ();
}

=head2 sub add2flow_button

	When build a first-time perl flow
	Incorporate new prorgam parameter values and labels into the gui
	and save the values, labels and checkbuttons setting in the param_flow
	namespace

  		foreach my $key (sort keys %$color_flow_href) {
   			print (" color_flow key is $key, value is $color_flow_href->{$key}\n");
  		}
  		
	$ans= $color_flow_href->{_param_sunix_length};
	print("1b. color_flow, add2flow_button, _param_sunix_length= $ans\n");

=cut

sub add2flow_button {

	my ( $self, $value ) = @_;

#	$color_flow_href->{_names_aref} = $param_widgets->get_labels_aref();
#	print("start add2flow_button all label0  = @{$color_flow_href->{_names_aref}}[0]\n");
#	print("start add2flow_buttonall label1  = @{$color_flow_href->{_names_aref}}[1]\n");
#	$color_flow_href->{_values_aref} = $param_widgets->get_values_aref();
#	print("start add2flow_buttonall value0  = @{$color_flow_href->{_values_aref}}[0]\n");
#	print("start add2flow_buttonall value1  = @{$color_flow_href->{_values_aref}}[1]\n");

	# There is a case when a flow is used for the first time, when
	# a parameter value has been added or
	# modified and the flow item
	# is not selected manually after a change (using select_flow_button)
	# If a previous flow item has not been updated
	# we must force an update to save these first-time, new, parameter values
	# by using _flow_select (which calls flow_select).
	# When we are coming from selecting an sunix program
	# the flow listbox has been cleared of selections
	# The last flow listbox selection was stored in the gui history
	# We can not set flow_select button index
	# We will increment the number of clicks
	# (TODO) and that you have not changed color
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();
	my $flow_num_items        = $_flow_listbox_color_w->size();

	$color_flow_href->{_flow_type} = $flow_type->{_user_built};

	my $param_sunix = param_sunix->new();
	my $message     = $message_director->null_button(0);

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set4start_of_add2flow_button($flow_color);
	$color_flow_href = $gui_history->get_hash_ref();

	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	# add the most recently selected program
	# name (scalar reference) to the
	# end of the list inside flow_listbox
	_local_set_flow_listbox_color_w($flow_color);    # in "color"_flow namespace

 # append new program names to the end of the list but this item is NOT selected
 # selection occurs inside conditions4flow (inheritance by gui_history)
	$color_flow_href->{_flow_listbox_color_w}
	  ->insert( "end", ${ $color_flow_href->{_prog_name_sref} }, );

	# Display default paramters in the GUI,
	# as for sunix_select
	# Can not get program name from the item selected in the sunix list box
	# because focus is transferred to another list box

	my $most_recent =
	  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )
	  ->{_most_recent};
	my $prior =
	  ( ( $gui_history->get_defaults() )->{_flow_select_index_href} )->{_prior};

#	print("1. color_flow, add2flow_button, NO CHANGES within: prior_flow_index=$prior, most_recent=$most_recent\n");

	#	print("1. color_flow, add2flow_button, print out gui_history\n");
	#	$gui_history->view();

	# TBD
	# if there is  a deletion immediately before, the
	# indices for recent and prior should be reduced by -1
	# the most recent value will be correct but
	# the prior and earliest will not
	# so always check that the prior value exists before using it

	$param_sunix->set_program_name( $color_flow_href->{_prog_name_sref} );
	$color_flow_href->{_names_aref}  = $param_sunix->get_names();
	$color_flow_href->{_values_aref} = $param_sunix->get_values();
	$color_flow_href->{_check_buttons_settings_aref} =
	  $param_sunix->get_check_buttons_settings();
	$color_flow_href->{_param_sunix_first_idx} =
	  $param_sunix->first_idx();    # first index = 0
	$color_flow_href->{_first_idx} =
	  $param_sunix->first_idx();    # first index = 0

# print("color_flow,add2flow_button, check_buttons_settings_aref: @{$color_flow_href->{_check_buttons_settings_aref}}\n");

	$param_sunix->set_half_length();

	# values -- not #(values+labels)
	$color_flow_href->{_param_sunix_length} = $param_sunix->get_length();

	# widgets are initialized in a super class
	# Assign program parameters in the GUI
	$param_widgets->set_labels_w_aref( $color_flow_href->{_labels_w_aref} );
	$param_widgets->set_values_w_aref( $color_flow_href->{_values_w_aref} );
	$param_widgets->set_check_buttons_w_aref(
		$color_flow_href->{_check_buttons_w_aref} );

	#	 print(" 1. color_flow, add2flow_button, \n");
	$param_widgets->range($color_flow_href);
	$param_widgets->set_labels( $color_flow_href->{_names_aref} );
	$param_widgets->set_values( $color_flow_href->{_values_aref} );
	$param_widgets->set_check_buttons(
		$color_flow_href->{_check_buttons_settings_aref} );

	$param_widgets->redisplay_labels();
	$param_widgets->redisplay_values();
	$param_widgets->redisplay_check_buttons();

	# Collect and store prog versions changed in list box
	_stack_versions();

	# Add a single_program to the growing stack
	# store one program name, its associated parameters and their values
	# as well as the checkbuttons settings (on or off) in another namespace
	_stack_flow();

	# print("color_flow,add2flow_button, after stack flow but before update\n");
	# $param_flow_color_pkg->view_data();

	$gui_history->set_hash_ref($color_flow_href);

# last item added is highlighted and selected conditions4flows are inherited by gui_hsitory
	$gui_history->set4end_of_add2flow_button($flow_color);

	my $flow_index = $flow_widgets->get_flow_selection(
		$color_flow_href->{_flow_listbox_color_w} );

	# done in conditions4flow, flow color is not reset
	$gui_history->set_flow_index_last_touched($flow_index);
	$color_flow_href = $gui_history->get_hash_ref();

	# switch between the correct index of the last parameter that was touched
	# as a function of the flow's color
	# These data are encapsulated
	$color_flow_href->{_last_parameter_index_touched_color} = 0;    # initialize
	$color_flow_href->{$_is_last_parameter_index_touched_color} = $true;

#	print("10 color_flow,add2flow_button, after stack flow AND after update, view param_flow data:\n");
#	$param_flow_color_pkg->view_data();

	_flow_select_director('add2flow_button');

	# the following is also carried out in flow_select when  pre_ok=true
	# $color_flow_href->{_last_flow_color} = $flow_color;
	return ();
}

=head2 sub delete_from_flow_button

if flow_select was last clicked then 
$gui_history has already recorded the chosen flow color

my $flow_color = $gui_history->get_flow_color();
 	 	
=cut

sub delete_from_flow_button {

	my ($self) = @_;

	my $flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};

	if ($flow_color) {

		_set_flow_color($flow_color);

		my $message = $message_director->null_button(0);
		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );

		my $_flow_listbox_color_w = _get_flow_listbox_color_w();

		$gui_history->set_hash_ref($color_flow_href);
		$gui_history->set_defaults4start_of_delete_from_flow_button(
			$flow_color);
		$color_flow_href = $gui_history->get_hash_ref();

		$decisions->set4delete_from_flow_button($color_flow_href);
		my $pre_req_ok = $decisions->get4delete_from_flow_button();

		# confirm listboxes are active
		if ($pre_req_ok) {

			# location within GUI on first clicking delete button
			#			$gui_history->set_hash_ref($color_flow_href);

			# flow_color is in 'color'_flow namespace
			my $index =
			  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

			if (    $index == 0
				and $param_flow_color_pkg->get_num_items() == 1 )
			{

				# CASE: LAST ITEM in listbox is deleted
				# extra checking includes verifying number of items

				# For Run and Save button
				$flow_widgets->delete_selection($_flow_listbox_color_w);

				# Blank out the names of the programs in the GUI
				_set_flow_name_color_w($flow_color);
				$flow_name_color_w->configure( -text => $var->{_clear_text} );
				$color_flow_href->{_flowNsuperflow_name_w}
				  ->configure( -text => $var->{_clear_text} );

				# delete stored programs and their parameters
				my $index2delete = $flow_widgets->get_index2delete();

				# delete_from_stored_flows();
				$param_flow_color_pkg->delete_selection($index2delete);

				# collect and store latest program versions from changed list
				# clear all the versions from the changed list
				_clear_stack_versions();

				$gui_history->set_hash_ref($color_flow_href);
				$gui_history->set_defaults4last_delete_from_flow_button();
				$color_flow_href = $gui_history->get_hash_ref();

		 # Blank out all the stored parameter values and names within param_flow
				$param_flow_color_pkg->clear();

				# clear the parameter values and labels from the gui
				# strange memory leak inside param_widgets
				my $save =
				  clone( $color_flow_href->{_check_buttons_settings_aref} );
				$param_widgets->gui_full_clear();
				@{ $color_flow_href->{_check_buttons_settings_aref} } = @$save;

				# reinitialize flow_select_count
				$gui_history->set_clear('delete_from_flow_button');
				@{ $color_flow_href->{_occupied_listbox_aref} }
				  [$_number_from_color] = $false;
				@{ $color_flow_href->{_vacant_listbox_aref} }
				  [$_number_from_color] = $true;

#				print("1.color_flow, delete_from_flow_button, \n
#				 	color_flow_href->{_occupied_listbox_aref}[_number_from_color]= $color_flow_href->{_occupied_listbox_aref}[$_number_from_color]
#				 \n");
#				print("1.color_flow, delete_from_flow_button, \n
#				 	color_flow_href->{_vacant_listbox_aref}[_number_from_color]= $color_flow_href->{_vacant_listbox_aref}[$_number_from_color]
#				 \n");
#				print("1. last item deleted Shut down delete button\n");

			}
			elsif ( $index > 0 ) {

				# CASE more more than one item remains in a listbox (implied)
				# but selected index is not the first
				$flow_widgets->delete_selection($_flow_listbox_color_w);

				# delete stored programs and their parameters
				# delete_from_stored_flows();
				my $index2delete = $flow_widgets->get_index2delete();

 # print("2. color_flow deletefrom a stored flow,index2delete:$index2delete\n");
				$param_flow_color_pkg->delete_selection($index2delete);

				# keep track of flow selection clicks and colors
				$_flow_listbox_color_w->selectionSet( ( $index2delete - 1 ) );
				$gui_history->set_flow_select_color($this_color);
				$gui_history->set_button('flow_select');

				# Update the widget parameter names and values
				# to those of new selection after deletion
				# Only the chkbuttons, values and names of the last program used
				# are stored in param_widgets at any one time
				# Get parameters from storage
				my $next_idx_selected_after_deletion = $index2delete - 1;
				if ( $next_idx_selected_after_deletion == -1 ) {
					$next_idx_selected_after_deletion = 0;
				}    # NOT < 0
					 # $next_idx_selected_after_deletion\n");

				$param_flow_color_pkg->set_flow_index(
					$next_idx_selected_after_deletion);
				$color_flow_href->{_names_aref} =
				  $param_flow_color_pkg->get_names_aref();

				$color_flow_href->{_values_aref} =
				  $param_flow_color_pkg->get_values_aref();

				$color_flow_href->{_check_buttons_settings_aref} =
				  $param_flow_color_pkg->get_check_buttons_settings();

				# get stored first index and num of items
				$color_flow_href->{_param_flow_first_idx} =
				  $param_flow_color_pkg->first_idx();
				$color_flow_href->{_param_flow_length} =
				  $param_flow_color_pkg->length();
				$color_flow_href->{_prog_name_sref} =
				  $param_widgets->get_current_program(
					\$_flow_listbox_color_w );
				$param_widgets->set_current_program(
					$color_flow_href->{_prog_name_sref} );

				$param_widgets->gui_full_clear();    # formerly gui_clean
				$param_widgets->range($color_flow_href);
				$param_widgets->set_labels( $color_flow_href->{_names_aref} );
				$param_widgets->set_values( $color_flow_href->{_values_aref} );
				$param_widgets->set_check_buttons(
					$color_flow_href->{_check_buttons_settings_aref} );

				$param_widgets->redisplay_labels();
				$param_widgets->redisplay_values();
				$param_widgets->redisplay_check_buttons();

				# collect and store latest program versions from changed list
				_stack_versions();

			}
			elsif ( $index == 0
				and $param_flow_color_pkg->get_num_items() > 1 )
			{

				# CASE more than 1 item exists and selected index is first
				$flow_widgets->delete_selection($_flow_listbox_color_w);

				# delete stored programs and their parameters
				# delete_from_stored_flows();
				my $index2delete = $flow_widgets->get_index2delete();

	   # print("2. color_flow delete_from_stored,index2delete:$index2delete\n");
				$param_flow_color_pkg->delete_selection($index2delete);

				# keep track of flow selection clicks and colors
				$_flow_listbox_color_w->selectionSet( ( $index2delete - 1 ) );
				$gui_history->set_flow_select_color($this_color);
				$gui_history->set_button('flow_select');

			   # Update the widget parameter names and values
			   # to those of new selection after deletion
			   # Only the chekbuttons, values and names of the last program used
			   # are stored in param_widgets at any one time
			   # Get parameters from storage
				my $next_idx_selected_after_deletion = $index2delete - 1;

				# NOT < 0
				# $next_idx_selected_after_deletion\n");
				if ( $next_idx_selected_after_deletion == -1 ) {

					$next_idx_selected_after_deletion = 0;
				}

				$param_flow_color_pkg->set_flow_index(
					$next_idx_selected_after_deletion);
				$color_flow_href->{_names_aref} =
				  $param_flow_color_pkg->get_names_aref();

				$color_flow_href->{_values_aref} =
				  $param_flow_color_pkg->get_values_aref();

				$color_flow_href->{_check_buttons_settings_aref} =
				  $param_flow_color_pkg->get_check_buttons_settings();

				# get stored first index and num of items
				$color_flow_href->{_param_flow_first_idx} =
				  $param_flow_color_pkg->first_idx();
				$color_flow_href->{_param_flow_length} =
				  $param_flow_color_pkg->length();
				$color_flow_href->{_prog_name_sref} =
				  $param_widgets->get_current_program(
					\$_flow_listbox_color_w );
				$param_widgets->set_current_program(
					$color_flow_href->{_prog_name_sref} );

				#print(" 2. color_flow, delete_from-flow_button \n");
				$param_widgets->gui_full_clear();    # formerly gui_clean
				$param_widgets->range($color_flow_href);
				$param_widgets->set_labels( $color_flow_href->{_names_aref} );
				$param_widgets->set_values( $color_flow_href->{_values_aref} );
				$param_widgets->set_check_buttons(
					$color_flow_href->{_check_buttons_settings_aref} );

				$param_widgets->redisplay_labels();
				$param_widgets->redisplay_values();
				$param_widgets->redisplay_check_buttons();

				# collect and store latest program versions from changed list
				_stack_versions();

			}
			else {
				print("color_flow, delete_fro_flow_button unexpected result\n");
			}
		}    # if pre_req_ok

	}
	else {    # if flow_color
		print("color_flow, delete_from_flow_button, flow color missing: \n");
	}

	#	print("color_flow, END delete_from_flow_button, print gui_history.txt\n");
	#    $gui_history->view();
}

=head2 sub delete_whole_flow_button

If flow_select was last clicked then 
$gui_history has already recorded the chosen flow color
 	 	
=cut

sub delete_whole_flow_button {

	my ($self) = @_;

	my $flow_color =
	  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};

	#	print(" START color_flow, delete_whole_flow_button, \n");
	# print("color_flow, delete_whole_flow_button, print gui_history.txt\n");
	# $gui_history->view();

	if ($flow_color) {

		_set_flow_color($flow_color);

		my $message = $message_director->null_button(0);
		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );

		my $_flow_listbox_color_w = _get_flow_listbox_color_w();

		$gui_history->set_hash_ref($color_flow_href);
		$gui_history->set_defaults4start_of_delete_whole_flow_button(
			$flow_color);
		$color_flow_href = $gui_history->get_hash_ref();
		$decisions->set4delete_whole_flow_button($color_flow_href);
		my $pre_req_ok = $decisions->get4delete_whole_flow_button();

		# confirm listboxes are active
		if ($pre_req_ok) {

			# flow_color is in 'color'_flow namespace
			# index is the currently selected
			my $index =
			  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

			# print("color_flow, delete_whole_flow_button index=$index\n");

			if (    $index >= 0
				and $param_flow_color_pkg->get_num_items() >= 1 )
			{

				# CASE: DELETE ALL ITEMS in listbox
				# extra checking includes verifying number of items
				# For Run and Save button
				$flow_widgets->clear($_flow_listbox_color_w);

				# Blank out the names of the programs in the GUI
				_set_flow_name_color_w($flow_color);
				$flow_name_color_w->configure( -text => $var->{_clear_text} );
				$color_flow_href->{_flowNsuperflow_name_w}
				  ->configure( -text => $var->{_clear_text} );

				# delete stored programs and all the stored flow parameters
				my $index2delete = 'all';
				$param_flow_color_pkg->delete_selection($index2delete);

		 # Blank out all the stored parameter values and names within param_flow
				$param_flow_color_pkg->clear();

				$gui_history->set_hash_ref($color_flow_href);
				$gui_history->set_defaults4end_of_delete_whole_flow_button();
				$color_flow_href = $gui_history->get_hash_ref();

		 # Blank out all the stored parameter values and names within param_flow
				$param_flow_color_pkg->clear();

				# print("5. whole flow deleted Shut down delete button\n");
				# clear the parameter values and labels from the gui
				# strange memory leak inside param_widgets
				my $save =
				  clone( $color_flow_href->{_check_buttons_settings_aref} );
				$param_widgets->gui_full_clear();
				@{ $color_flow_href->{_check_buttons_settings_aref} } = @$save;

				# reinitialize flow_select_count
				$gui_history->set_clear('delete_whole_flow_button');

			}
			else {
				print(
					"color_flow, delete_whole_flow_button unexpected result\n");
			}    # index is >= 0

		}    # if pre_req_ok

	}
	else {    # if flow_color
		print("color_flow, delete_whole_flow_button, flow color missing: \n");
	}

}

=head2 sub flow_item_down_arrow_button

 	move items down in a flow listbox
    
=cut

sub flow_item_down_arrow_button {

	my ($self) = @_;
	my $prog_name;

	if ($flow_color) {

		_set_flow_color($flow_color);

  # $conditions_gui->set4start_of_flow_item_down_arrow_button($color_flow_href);

		my $message = $message_director->null_button(0);
		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );

		$prog_name = ${ $color_flow_href->{_prog_name_sref} };

		#  get number of items in the flow listbox
		my $_flow_listbox_color_w =
		  _get_flow_listbox_color_w();    # user-built_flow in current use
		my $num_items = $flow_widgets->get_num_items($_flow_listbox_color_w);

		# get the current index
		my $current_flow_listbox_index =
		  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

		# the destination index will be one more
		my $destination_index = $current_flow_listbox_index + 1;

		# limit max index
		if ( $destination_index >= $num_items ) {
			$destination_index = $num_items - 1;
		}

		# MEET THESE conditions, OR do NOTHING
		if (   $prog_name
			&& ( $current_flow_listbox_index >= 0 )
			&& $destination_index < $num_items )
		{

			$color_flow_href->{_index2move} = $current_flow_listbox_index;
			$color_flow_href->{_destination_index} = $destination_index;

			# get all the elements from inside the listbox
			my @elements = $_flow_listbox_color_w->get( 0, 'end' );

			# rearrange elements
			my $saved_item = $elements[ $color_flow_href->{_index2move} ];

			$color_flow_href->{_flow_listbox_color_w}
			  ->delete( $color_flow_href->{_index2move} );
			$color_flow_href->{_flow_listbox_color_w}
			  ->insert( $color_flow_href->{_destination_index}, $saved_item );
			$color_flow_href->{_flow_listbox_color_w}
			  ->selectionSet( $color_flow_href->{_destination_index} );

			# note the last program that was touched
			#			$color_flow_href->{_last_flow_index_touched} =
			#				$color_flow_href->{_destination_index};
			#			$color_flow_href->{$_is_last_flow_index_touched_color} = $true;

			# move stored data within arrays
			my $start = $color_flow_href->{_index2move};
			my $end   = $color_flow_href->{_destination_index};

			$param_flow_color_pkg->set_insert_start($start);
			$param_flow_color_pkg->set_insert_end($end);
			$param_flow_color_pkg->insert_selection();

			# update program versions if listbox changes
			# stored in param_flows
			_stack_versions();

			# update the parameter widget labels and their values

			# highlight new index
			_local_set_flow_listbox_color_w($flow_color)
			  ;    # in "color"_flow namespace
			$_flow_listbox_color_w->selectionSet(
				$color_flow_href->{_destination_index}, );

			# carry out all gui updates needed
			# keep track of flow_selection clicks
			_flow_select_director('flow_item_down_arrow_button');

		}
		else {
			print(
"color_flow, flow_item_down_arrow_button missing program or bad index\n"
			);
		}

	}
	else {
		print("color_flow, flow_item_down_arrow_button missing color \n");
	}

}

=head2 sub flow_item_up_arrow_button

		move items up in a flow listbox
    
=cut

sub flow_item_up_arrow_button {

	my ($self) = @_;
	my $prog_name;

	if ($flow_color) {

		_set_flow_color($flow_color);

	# $conditions_gui->set4start_of_flow_item_up_arrow_button($color_flow_href);

		my $message = $message_director->null_button(0);
		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );

		$prog_name = ${ $color_flow_href->{_prog_name_sref} };

		#  get number of items in the flow listbox
		my $_flow_listbox_color_w =
		  _get_flow_listbox_color_w();    # user-built_flow in current use
		my $num_items = $flow_widgets->get_num_items($_flow_listbox_color_w);

		# get the current index
		my $current_flow_listbox_index =
		  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

		# the destination index will be one less
		my $destination_index = $current_flow_listbox_index - 1;
		if ( $destination_index <= 0 ) {
			$destination_index = 0;
		}                                 # limit min index

		# MEET THESE conditions, OR do NOTHING
		if (   $prog_name
			&& ( $current_flow_listbox_index > 0 )
			&& $destination_index >= 0 )
		{

			$color_flow_href->{_index2move} = $current_flow_listbox_index;
			$color_flow_href->{_destination_index} = $destination_index;

			# note the last program that was touched
			#			$color_flow_href->{_last_flow_index_touched} =
			#				$color_flow_href->{_destination_index};
			#			$color_flow_href->{$_is_last_flow_index_touched_color} = $true;

			# get all the elements from inside the listbox
			my @elements = $_flow_listbox_color_w->get( 0, 'end' );

			# rearrange elements
			my $saved_item = $elements[ $color_flow_href->{_index2move} ];

			$color_flow_href->{_flow_listbox_color_w}
			  ->delete( $color_flow_href->{_index2move} );
			$color_flow_href->{_flow_listbox_color_w}
			  ->insert( $color_flow_href->{_destination_index}, $saved_item );
			$color_flow_href->{_flow_listbox_color_w}
			  ->selectionSet( $color_flow_href->{_destination_index} );

			# note the last program that was touched
			#			$color_flow_href->{_last_flow_index_touched} =
			#				$color_flow_href->{_destination_index};
			#			$color_flow_href->{$_is_last_flow_index_touched_color} = $true;

			# move stored data within arrays
			my $start = $color_flow_href->{_index2move};
			my $end   = $color_flow_href->{_destination_index};

			$param_flow_color_pkg->set_insert_start($start);
			$param_flow_color_pkg->set_insert_end($end);
			$param_flow_color_pkg->insert_selection();

			# update program versions if listbox changes
			# stored in param_flows
			_stack_versions();

			# highlight new index
			$_flow_listbox_color_w->selectionSet(
				$color_flow_href->{_destination_index}, );

			# carry out all gui updates needed
			# keep track of flow_selection clicks
			_flow_select_director('flow_item_up_arrow_button');

		}
		else {
		}

	}
	else {
		print("color_flow, flow_item_up_arrow_button missing color \n");
	}

}

=head2 sub flow_select

Pick a Seismic Unix module
from within a (colored) flow listbox
    	     	
Always takes focus on first entry ; index = 0
If focus is on first entry then also make the
$color_flow_href->{_last_parameter_index_touched_color}  =0

print(" flow_select, view stored param flow data before update of prior\n");
$param_flow_color_pkg->view_data();
my $ans = @{$color_flow_href->{_values_w_aref}}[0]->get;		

print("color_flow,flow_select, print gui_history\n");
$gui_history->view();

 print("12color_flow, flow_select, extract saved values\n");
 $param_flow_color_pkg->view_data();
 
 								print(
"1 color_flow, flow_select, num_items_in_flow =$num_items_in_flow\n"
					);
					print(
"1 color_flow, flow_select, max_index_in_flow =$max_index_in_flow\n"
					);
					print(
"1 color_flow, flow_select, most_recent_flow_index =$most_recent_flow_index\n"
					);
					print(
"1 color_flow, flow_select, last_flow_color=$last_flow_color\n");

 								print(
"2 color_flow, flow_select, num_items_in_flow =$num_items_in_flow\n"
					);
					print(
"2 color_flow, flow_select, max_index_in_flow =$max_index_in_flow\n"
					);
					print(
"2 color_flow, flow_select, most_recent_flow_index =$most_recent_flow_index\n"
					);
			
          
=cut

sub flow_select {
	my ($self) = @_;

	my $ans;

	#	print("1. color_flow, flow_select, print out gui_history\n");
	#	 $gui_history->view();

	$color_flow_href->{_flow_type} = $flow_type->{_user_built};

	# reset residual flow_listbox_color_w of another color
	# flow_color exists in current (color_flow) namespace
	_local_set_flow_listbox_color_w($flow_color);
	$gui_history->set_flow_select_color($flow_color);

	my $message = $message_director->null_button(0);
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	$gui_history->set_hash_ref($color_flow_href);
	$gui_history->set_defaults_4start_of_flow_select($flow_color);
	$color_flow_href = $gui_history->get_hash_ref();

	# update the flow color as per add2flow_select
	my $_flow_listbox_color_w = _get_flow_listbox_color_w();

	$color_flow_href->{_prog_name_sref} =
	  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

	$decisions->set_hash_ref($color_flow_href);
	my $pre_req_ok = $decisions->get4flow_select();

	if ($pre_req_ok) {

		my $binding = binding->new();
		my ( $ans, $ans1 );

		$gui_history->set_button('flow_select');

		my $prior_flow_type =
		  ( ( $gui_history->get_defaults )->{_flow_type_href} )->{_prior};
		my $prior_flow_select_color =
		  ( ( $gui_history->get_defaults )->{_flow_select_color_href} )
		  ->{_prior};
		my $most_recent_flow_select_color =
		  ( ( $gui_history->get_defaults )->{_flow_select_color_href} )
		  ->{_most_recent};
		my $most_recent_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};
		my $max_saved_widget_index = scalar @save_last_param_widget_values;

		if (    $prior_flow_type eq $flow_type->{_user_built}
			and $most_recent_flow_select_color eq $prior_flow_select_color )
		{

			# CASE 1 last click was inside this same colored flow
			# consider prior flow-color changes
			# that have been made to param_widgets but not updated
			# unticked strings from GUI are corrected here

			_update_prior_param_flow();

			# find which flow index is selected
			my $num_items_in_flow = $param_flow_color_pkg->get_num_items();
			my $max_index_in_flow = $num_items_in_flow - 1;
			$last_flow_color = $color_flow_href->{_last_flow_color};

			#			$gui_history->set_file_status($num_items_in_flow);
			#			my $file_status = $gui_history->get_file_status();

#								  	print(
#	  "3 start.color_flow,flow_select, file_status,num_items_in_flow: $file_status,$num_items_in_flow\n"
#	);

			if ( not $memory_leak4flow_select_fixed ) {

				if ( ( $this_color eq $last_flow_color )
					&& $most_recent_flow_index_touched == $max_index_in_flow )
				{
				 #  CASE 1A- NO memory correction needed
				 #  last selected index was last in program
				 #  list and last color flow is the same as this color flow
				 #  e.g., just loaded a new flow and user clicks on last program
				 #  in flow

					$param_widgets->set_values(
						\@save_last_param_widget_values );
					$param_flow_color_pkg->set_flow_index(
						$most_recent_flow_index_touched);
					$param_flow_color_pkg->set_values_aref(
						\@save_last_param_widget_values );

				}
				elsif (
					( $this_color eq $last_flow_color )
					&& $most_recent_flow_index_touched < $max_index_in_flow

					#					&& $first_opening == $true
				  )

				{
					# CASE 1B FIX MEMORY LOSS
					# when last selected index was last in program
					# list, last color flow is the same as this color flow
					# but index of current program is less than the last index
					# of the last program in the flow

					$param_flow_color_pkg->set_flow_index($max_index_in_flow);

					#						$max_saved_widget_index);
					my $last_param_flow_values_w_strings_aref =
					  $control->get_string_or_number4aref(
						\@save_last_param_widget_values );

#						    							print(
#	  "\n10B.OK color_flow,flow_select, values:@$last_param_flow_values_w_strings_aref\n"
#	);

					$param_flow_color_pkg->set_values_aref(
						$last_param_flow_values_w_strings_aref);

				   # LOST- always enigma
				   #					print("1. flow_select, view stored param flow data\n");
				   #					$param_flow_color_pkg->view_data();

				}    # end of memory leak solution for flow_select

				$memory_leak4flow_select_fixed = $false;

				#				$first_opening                 = $false;
			}
		}

		elsif ( $prior_flow_type eq $flow_type->{_user_built}
			and $most_recent_flow_select_color ne $prior_flow_select_color )
		{
			# CASE 2 NADA
			# last click was in a differently colored flow

		}
		else {
			# CASE 3  NADA
			# undeteremined
			# print("13 color_flow, flow_select, unexpected NADA\n");
		}

		# LOST
		#		print("\nLOST flow_select, view stored param flow data");
		#		$param_flow_color_pkg->view_data();

		# FOUND
		#		my $aref = $param_flow_color_pkg->get_values_aref();
		#		print("FOUND color_flow,flow_select, values:@{$aref}\n");

		# LOST
		#		print("color_flow,flow_select, view stored param flow data\n");
		#		$param_flow_color_pkg->view_data();

		# FOUND
		#		$aref = $param_flow_color_pkg->get_values_aref();
		#		print("FOUND color_flow,flow_select, values:@{$aref}\n");

		# current selection in the flow
		my $index = $flow_widgets->get_flow_selection($_flow_listbox_color_w);

		# extract saved values and labels for the current selection
		$param_flow_color_pkg->set_flow_index($most_recent_flow_index_touched);
		$color_flow_href->{_names_aref} =
		  $param_flow_color_pkg->get_names_aref();
		$color_flow_href->{_values_aref} =
		  $param_flow_color_pkg->get_values_aref();

		#		$aref = $param_flow_color_pkg->get_values_aref();
		#		print("11a.color_flow,flow_select, values:@{$aref}\n");

		$color_flow_href->{_check_buttons_settings_aref} =
		  $param_flow_color_pkg->get_check_buttons_settings();

		# get stored first index and num of items
		$color_flow_href->{_param_flow_first_idx} =
		  $param_flow_color_pkg->first_idx();
		$color_flow_href->{_param_flow_length} =
		  $param_flow_color_pkg->length();

		$param_widgets->set_current_program(
			$color_flow_href->{_prog_name_sref} );

	   # print(
	   # "11.color_flow,flow_select, names:@{$color_flow_href->{_names_aref}}\n"
	   # );

		# widgets were initialized in super class
		# 1. prepare to update gui by assigning widgets
		# TODO are the next 3 lines needed now that we share gui_history?
		$param_widgets->set_labels_w_aref( $color_flow_href->{_labels_w_aref} );
		$param_widgets->set_values_w_aref( $color_flow_href->{_values_w_aref} );
		$param_widgets->set_check_buttons_w_aref(
			$color_flow_href->{_check_buttons_w_aref} );

		$color_flow_href->{_prog_name_sref} =
		  $flow_widgets->get_current_program( \$_flow_listbox_color_w );

		# wipes out values labels and checkbuttons from the gui
		$param_widgets->range($color_flow_href);

		# strange memory leak inside param_widgets
		my $save = clone( $color_flow_href->{_check_buttons_settings_aref} );
		$param_widgets->gui_full_clear();
		@{ $color_flow_href->{_check_buttons_settings_aref} } = @$save;

		$param_widgets->set_labels( $color_flow_href->{_names_aref} );
		$param_widgets->set_values( $color_flow_href->{_values_aref} );
		$param_widgets->set_check_buttons(
			$color_flow_href->{_check_buttons_settings_aref} );
		$param_widgets->redisplay_labels();
		$param_widgets->redisplay_values();
		$param_widgets->redisplay_check_buttons();
		$param_widgets->set_entry_change_status($false);

	   # unxpectedly  Entry focus is delayed until the end of this method becore
	   # completion;
	   # that is we get to gui_history->view before we can update the focus
	   # mysterious!!!!!
		$param_widgets->set_focus_on_Entry_w(0)
		  ;    # put focus on first entry widget, index=0

# $color_flow_href->{_last_parameter_index_touched_color} = 0;
# the changed parameter value in the Entry widget should force an update of stored values
# in the current flow item (not the last flow item touched)
# _save_most_recent_param_flow(); # is only active if
# $color_flow_href->{_last_parameter_index_touched_color} >= 0

		# Here is where you rebind the different buttons depending on the
		# program name that is selected (i.e., through spec.pm)
		$binding->set_prog_name_sref( $color_flow_href->{_prog_name_sref} );
		$binding->set_values_w_aref( $param_widgets->get_values_w_aref );

		# reference to local subroutine that will be run when MB3 is pressed
		$binding->setFileDialog_button_sub_ref( \&_FileDialog_button );
		$binding->set();
		$gui_history->set_hash_ref($color_flow_href);
		$gui_history->set4end_of_flow_select($flow_color);
		$gui_history->set_flow_index_last_touched($index);
		$color_flow_href = $gui_history->get_hash_ref();

# Update thre entry button value that displays the currently active
# flow or superflow name, by using the currently selected program name from the flow list
# e.g. data_in, suximage, suxgraph etc.
		( $color_flow_href->{_flowNsuperflow_name_w} )
		  ->configure( -text => ${ $color_flow_href->{_prog_name_sref} } );

		# needed in possible export via get_hash_ref to help
		my $prog_name_sref = $color_flow_href->{_prog_name_sref};

	}    # end pre_ok

	#		$ans = ( ( $gui_history->get_defaults )->{_flow_select_color_href} )
	#			->{_most_recent};
	#		print("7. color_flow,flow_select,most recent color: $ans\n");
	#
	#		$ans = ( ( $gui_history->get_defaults )->{_flow_select_color_href} )
	#			->{_prior};
	#		print("8. color_flow,flow_select,prior color: $ans\n");
	#	print("1. color_flow,flow_select, post _update_prior_param_flow: \n");
	# print("1. color_flow,flow_select, view stored param flow values: \n");
	# $param_flow_color_pkg->view_data();
	#	print("color_flow, END of flow_select: writing gui_history.txt\n");
	#	$gui_history->view();

	return ();
}

=head2 sub get_Flow_file_exists

=cut

sub get_Flow_file_exists {
	my ($self) = @_;
	my $result = $empty_string;

	if ( length $color_flow->{_Flow_file_exists} ) {

		$result = $color_flow->{_Flow_file_exists};
		return ($result);

	}
	else {
		print(" color_flow, get_Flow_file_exists, missing variable value\n");
		return ($result);
	}

}

=head2 sub get_hash_ref 
exports private hash	
46 
 
=cut

sub get_hash_ref {
	my ($self) = @_;

	return ($color_flow_href);

}

=head2 sub get_flow_color
	exports private hash value
 
=cut

sub get_flow_color {
	my ($self) = @_;

	if ( $color_flow_href->{_flow_color} ) {
		my $color;

		$color = $color_flow_href->{_flow_color};
		return ($color);

	}
	else {
		print("color_flow, missing flow color\n");
	}

}

=head2 sub get_flow_type

	exports private hash value
 
=cut

sub get_flow_type {
	my ($self) = @_;

	if ( $color_flow_href->{_flow_type} ) {
		my $flow_type;

		$flow_type = $color_flow_href->{_flow_type};
		return ($flow_type);

	}
	else {
		print("color_flow, missing flow type\n");
	}

}

=head2 sub get_perl_flow_errors

=cut

sub get_perl_flow_errors {
	my ($self) = @_;
	my $result = $empty_string;

	if ( length $color_flow->{_perl_flow_errors} ) {

		$result = $color_flow->{_perl_flow_errors};
		return ($result);

	}
	else {
		print(" color_flow, get_perl_flow_errors, missing variable value\n");
		return ($result);
	}
}

=head2 sub get_prog_name_sref 

	exports private hash value
 
=cut

sub get_prog_name_sref {
	my ($self) = @_;

	if ( $color_flow_href->{_prog_name_sref} ) {
		my $name;

		$name = $color_flow_href->{_prog_name_sref};
		return ($name);

	}
	else {
		print("color_flow, missing \n");
	}

}

=head2 sub increase_vigil_on_delete_counter

	Helps keep check of whether an item
    is deleted from the listbox
    during dragging and dropping    

=cut

sub increase_vigil_on_delete_counter {
	my ($self) = @_;
	$flow_widgets->inc_vigil_on_delete_counter;

	return ();
}

=head2 sub get_help

 Callback sequence following MB3 click 
 activation of a sunix (Listbox) item
 program name is a scalar reference
 
 Let help decide whether it is a superflow
 or a user-created flow
 
 Show a window with the perldoc to the user
 
 and length $color_flow_href->{_sunix_prog_group}

=cut 

sub get_help {

	my ($self) = @_;

	my $help = help->new();
	my $pre_req_ok;

	$decisions->set4help($color_flow_href);
	$pre_req_ok = $decisions->get4help();

	if (
			$pre_req_ok
		and length $color_flow_href->{_prog_name_sref}
		and length $color_flow_href->{_current_program_name}
		and ( $color_flow_href->{_current_program_name} eq
			${ $color_flow_href->{_prog_name_sref} } )
	  )
	{

		# it is a sunix program
		# the program category is defined

		my $current_program_name = $color_flow_href->{_current_program_name};
		my $SeismicUnixGui       = $dirs->get_path4SeismicUnixGui();
		my $module_name          = ${ $color_flow_href->{_prog_name_sref} };
		my $program_category_h =
		  $L_SU_global_constants->get_developer_sunix_category_h();
		my $key                 = '_' . $current_program_name;
		my $program_category    = $program_category_h->{$key};
		my $sunix_program_group = $program_category;

		my $PATH = $SeismicUnixGui . '/sunix' . '/' . $program_category;

		my $help    = help->new();
		my $inbound = $PATH . '/' . $module_name . $var->{_suffix_pm};

		$help->set_name( \$inbound );
		$help->tkpod();

	}
	else {
		print("color_flow, missing variable\n");
	}
	return ();
}

=head2 sub save_button

	topic: only 'Save'
  	for safety, place set_hash_ref first
  	run from L_SU.pm
  	
  	Also save new parameter values (redisplay_values)
  	for changes occurred
  	immediately before the current saving 
  	
  	param_flow_color memory leak workaround
  	
  			#		print("color_flow, save_button writing gui_history.txt\n");
		#		$gui_history->view();

		#		print("3. color_flow, save_button, param_flow view data\n"
		#				);
		#				$param_flow_color_pkg->view_data();
		
					  				print(
"5. color_flow, save_button, memory fix, click count=$click_count\n"
				); # =7 < 19 default  OK
							  				print(
"5. color_flow, save_button, most_recent_flow_index_touched=$last_flow_index\n"
				); #=2 OK
							  				print(
"5. color_flow, save_button, max_saved_widget_index=$max_saved_widget_index\n"
				);				# =1 TODO
print("5 color_flow,save_last_param_widget_values=@save_last_param_widget_values\n");

#				print("5. color_flow, save_button, Can not fix memory leak\n");
#				print(
				print(
"5. color_flow, save_button, this_color,last_flow_color are:$this_color,$last_flow_color\n"
				);
				print(
"5. color_flow, save_button, most recent flow index touched is $most_recent_flow_index_touched\n"
				);
				print(
"5. color_flow, save_button, max index in flow: $max_index_in_flow\n"
				);

#				print(
#"5. color_flow, save_button, last flow index: $last_flow_index\n"
#				);
#				print(
#"5. color_flow, save_button, max_saved_widget_index was $max_saved_widget_index\n"
#				);
#				print(
#"5. color_flow, save_button, click_count:$click_count min_clicks4save_button:$min_clicks4save_button\n"
#				);
  	

=cut

sub save_button {
	my ( $self, $topic ) = @_;

	my $num_items_in_flow = $param_flow_color_pkg->get_num_items();
	my $max_index_in_flow = $num_items_in_flow - 1;
	
	$gui_history->set_file_status($num_items_in_flow);
	my $file_prob_just_opened = $gui_history->get_file_status();
#	print("file_prob_just_opened=$true\n");

	$param_widgets->redisplay_values();

	# Double-check we are in the correct place:
	if ( $topic eq 'Save' ) {

		my $files_LSU = files_LSU->new();

		# user-built_flow in current use
		my $flow_listbox_color_w = _get_flow_listbox_color_w();

		# Start refocus index in flow, in case focus has been removed
		# e.g., by double-clicking in parameter values window
		my $most_recent_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_most_recent};
		my $prior_flow_index_touched =
		  ( $color_flow_href->{_flow_select_index_href} )->{_prior};
		my $most_recent_flow_color =
		  ( $color_flow_href->{_flow_select_color_href} )->{_most_recent};
		my $last_flow_index = $most_recent_flow_index_touched;

		$last_flow_color = $color_flow_href->{_last_flow_color};
		my $max_saved_widget_index =
		  ( scalar @save_last_param_widget_values ) - 1;

		# restore terminal ticks in strings after reading from the GUI
		# remove  possible terminal strings
		$color_flow_href->{_values_aref} =
		  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

		if (   length $last_flow_color
			&& $last_flow_index >= 1
			&& $flow_listbox_color_w )
		{

 # print("CASE 1A color_flow, save_button, last_flow_index=$last_flow_index\n");
 # One parameter index was previously selected
 # Assume that recent selection is valid for this current save

			# keep track of flow_selection clicks
			$flow_listbox_color_w->selectionSet($last_flow_index);
			$gui_history->set_flow_select_color($this_color);
			$gui_history->set_button('flow_select');

		}
		else {
	 #			print("color_flow, save_button , unexpected missing variables NADA\n");
		}

=pod

CASE common : When save_button is being used for the first time
BUT when no flow has been selected previously (_last_flow_index_touched=-1)
In other words: when a flow in the GUI  is used
for first time but no listboxes have been occupied previously
		
=cut

		_save_most_recent_param_flow();

		# find which flow index is selected
		my $num_items_in_flow = $param_flow_color_pkg->get_num_items();
		my $max_index_in_flow = $num_items_in_flow - 1;
		$last_flow_color = $color_flow_href->{_last_flow_color};

		#		$gui_history->set_file_status($num_items_in_flow);
		#		my $file_status = $gui_history->get_file_status();

#		print("color_flow, save_button: writing gui_history.txt\n");
#		$gui_history->view();

		if ( not $memory_leak4save_button_fixed ) {

			# Strange memory leak from param_flow_color_pkg
			# when first file is just opened.
			# Last element of last program disappears--
			# if either user clicks on an element different from
			# the last, or the Save button.
			# Conditions to detect the circumstance are:
			#--just having opened a file,
			# -- no changes have yet been made to the flow
			# -- $total_click_value < $very_low_click_value
			# if file has just been opened and is immediately saved
			# the set flow index is assumed = 0
			# just in total_click_value is still slow
			# and there was a change to the last parameter
			# in the last item of the flow, we detect this
			# by assuming that when the updated_parameter_index_on_exit
			# indicates the last parameter box was engaged then
			# we will not

			if (
				$this_color eq $last_flow_color
				&& ( $most_recent_flow_index_touched == $max_index_in_flow 
				&& $file_prob_just_opened == $true)
			  )
			{

				# CASE 1 FIX MEMORY LEAK
				# When last color=this_color
				#  and we are still over the last index in GUI
				# e.g., when a recently opened file is
				# saved without any changes
				# (a strange but possible case)
				# Fix param_widget memory leak that deletes the
				# last element in the last flow

#				print(
#"6 color_flow,most_recent_flow_index_touched=$most_recent_flow_index_touched\n"
#				);

#               # print("6. color_flow,@save_last_param_widget_values=$@save_last_param_widget_values\n");
				$param_flow_color_pkg->set_flow_index($max_index_in_flow);
				$param_flow_color_pkg->set_param_index($save_last_param_widget_index);
				$param_flow_color_pkg->set_param_value($save_last_param_widget_value);

# needed?			 
#                $param_widgets->set_index( $save_last_param_widget_index );
#                $param_widgets->set_value( $save_last_param_widget_value );

# deprecated
#				$param_flow_color_pkg->set_values_aref(
#					\@save_last_param_widget_values );

				$param_widgets->redisplay_values();

			}
			else {
				#NADA
			}

			# needs to be fixed each time Save is used on unchanged perl flow
			$memory_leak4save_button_fixed = $true;

		   # leak is now fixed going forward for the flow_select button as well.
			$memory_leak4flow_select_fixed = $true;

			#			$first_opening = $false; # rest

		}    # end of memory leak solution

		$param_flow_color_pkg->set_flow_index($last_flow_index);

		# collect the values from those stored data in param_flow
		# because the values from the widgets have not been updated
		$color_flow_href->{_values_aref} =
		  $param_flow_color_pkg->get_values_aref();

		# establish which program is active in the flow
		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();
		$control->set_flow_prog_names_aref(
			$color_flow_href->{_prog_names_aref} );
		$control->set_flow_prog_name_index($most_recent_flow_index_touched);

		# remove all quotes
		$color_flow_href->{_values_aref} =
		  $control->get_no_quotes4array( $color_flow_href->{_values_aref} );

		# restore so that only strings have quotes
		# for the last program name that was used
		$color_flow_href->{_values_aref} = $control->get_string_or_number4aref(
			$color_flow_href->{_values_aref} );

		$color_flow_href->{_last_parameter_index_touched_color} = 0;
		$color_flow_href->{$_is_last_parameter_index_touched_color} = $true;

	  # update changes to parameter values between 'SaveAs' and 'Save'-2
	  # assume a parameter index has been changed so that
	  # _save_most_recent_param_flow is forced to update previous changes before
	  # the current "updating""
	  # these changes occur via param_flow
	  # _update_prior_param_flow();

		$color_flow_href->{_names_aref} =
		  $param_flow_color_pkg->get_names_aref();

		$param_flow_color_pkg->set_good_values();
		$param_flow_color_pkg->set_good_labels();

		$color_flow_href->{_good_labels_aref2} =
		  $param_flow_color_pkg->get_good_labels_aref2();
		$color_flow_href->{_items_versions_aref} =
		  $param_flow_color_pkg->get_flow_items_version_aref();
		$color_flow_href->{_good_values_aref2} =
		  $param_flow_color_pkg->get_good_values_aref2();
		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();

		$color_flow_href->{_prog_names_aref} =
		  $param_flow_color_pkg->get_flow_prog_names_aref();
		$control->set_flow_prog_names_aref(
			$color_flow_href->{_prog_names_aref} );

		# One last check on quotes for strings
		# Program names help discern strings from numbers:
		# after memory leak correction -- one time only
		# and for case where file name are numeric e.g., '1000.txt'
		$color_flow_href->{_good_values_aref2} =
		  $control->get_string_or_number_aref2(
			$color_flow_href->{_good_values_aref2} );

		$files_LSU->set_prog_param_labels_aref2($color_flow_href);
		$files_LSU->set_prog_param_values_aref2($color_flow_href);
		$files_LSU->set_prog_names_aref($color_flow_href);
		$files_LSU->set_items_versions_aref($color_flow_href);
		$files_LSU->set_data();
		$files_LSU->set_message($color_flow_href);

		# listbox color assignment
		$files_LSU->set_flow_color($this_color);

		# update PL_SEISMIC in case user has recently changed project area
		$files_LSU->set_PL_SEISMIC();

		# flows saved to PL_SEISMIC
		$files_LSU->set2pl($color_flow_href);
		$files_LSU->save();

	}
	else {
		print("color_flow, missing topic Save\n");
	}
	return ();

}    # ends save_button

=head2 sub set_hash_ref
Import external hash into private settings via gui_history 
hash

Keys that used simplified names are also kept so later
	the hash can be returned to a calling module
	
print("color_flow, END of flow_select: writing gui_history.txt\n");
$gui_history->view();
 	
=cut

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	$gui_history->set_defaults($hash_ref);
	$color_flow_href = $gui_history->get_defaults();

	# REALLY?
	# set up param_widgets for later use
	# give param_widgets the needed values
	$param_widgets->set_hash_ref($color_flow_href);

	$flow_color = $color_flow_href->{_flow_color};

	# $gui_history_aref = $color_flow_href->{_gui_history_aref};

	# for local use
	$last_flow_color =
	  $color_flow_href->{_last_flow_color};    # used in flow_select
	$message_w              = $color_flow_href->{_message_w};
	$parameter_values_frame = $color_flow_href->{_parameter_values_frame};
	$parameter_values_button_frame =
	  $color_flow_href->{_parameter_values_button_frame};

	# $sunix_listbox                 = $color_flow_href->{_sunix_listbox};

# print("color_flow, set_hash_ref _check_buttons_settings_aref: @{$color_flow_href->{_check_buttons_settings_aref}}\n");

	# print("color_flow,set_hash_ref: print gui_history->view\n");
	# $gui_history->view();

	return ();
}

=head2 sub set_occupied_listbox_aref


=cut

sub set_occupied_listbox_aref {

	my ( $self, $occupied_listbox_aref ) = @_;

	if ($occupied_listbox_aref) {

		$color_flow_href->{_occupied_listbox_aref} = $occupied_listbox_aref;

	}
	else {
		print(
"color_flow,_set_occupied_listbox_aref, missing occupied_listbox_aref \n"
		);
	}

}

=head2 sub set_vacant_listbox_aref


=cut

sub set_vacant_listbox_aref {

	my ( $self, $vacant_listbox_aref ) = @_;

	if ($vacant_listbox_aref) {

		$color_flow_href->{_vacant_listbox_aref} = $vacant_listbox_aref;

	}
	else {
		print(
"color_flow,_set_vacant_listbox_aref, missing vacant_listbox_aref \n"
		);
	}

}

__PACKAGE__->meta->make_immutable;
1;
