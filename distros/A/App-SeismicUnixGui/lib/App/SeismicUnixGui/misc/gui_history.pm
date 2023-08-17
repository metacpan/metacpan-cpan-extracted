package App::SeismicUnixGui::misc::gui_history;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: gui_history 
 AUTHOR: 	Juan Lorenzo
 DATE: 		September 1 2019


 DESCRIPTION 
   Global inventory of user interactions with the gui.

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head2 CHANGES and their DATES
			9-1-19 0.0.1   dabbling with refs
 			9-12-19 0.0.2
 			7.20.21 initialize some hashes

=cut 

=head2 Notes from bash
 
=cut 

#use namespace::autoclean; for later
use Moose;
our $VERSION = '0.0.2';

=head2 Import modules
potentially, all packages contain L_SU_global_constants

=cut

my $path;
my $SeismicUnixGui;

extends 'App::SeismicUnixGui::misc::conditions4flows' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::conditions4flows';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::flow_widgets';

=head2 Instantiation

=cut

my $flow_widgets = flow_widgets->new();
my $get          = L_SU_global_constants->new();

=head2 Declare Special Variables

=cut

my $var                 = $get->var();
my $default_param_specs = $get->param();
my $on                  = $var->{_on};
my $true                = $var->{_true};
my $false               = $var->{_false};
my $empty_string        = $var->{_empty_string};
my $flow_type           = $get->flow_type_href();
my @array_ref;
my @empty_array = (0);    # length=1

my $index_start          = -1;
my $earliest_index_start = -3;
my $prior_index_start    = -2;
my $current_index_start  = -1;
my $next_index_start     = 0;

my $no_color             = 'no_color';
my $neutral              = 'neutral';
my $earliest_color_start = $no_color;
my $current_color_start  = $no_color;
my $next_color_start     = $no_color;
my $prior_color_start    = $no_color;

my $count_start = -1;

has '_count' => (
	default   => $count_start,
	is        => 'ro',
	isa       => 'Int',
	reader    => 'get_count',
	writer    => 'set_count',
	predicate => 'has_count',
);

=head2 Declare attributes

=cut

has 'FileDialog_type' => (
	default   => '',
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_FileDialog_type',
	writer    => 'set_FileDialog_type',
	predicate => 'has_FileDialog_type',
	trigger   => \&_update_FileDialog_type,
);

has 'button' => (
	default   => 'no_button',
	is        => 'rw',
	isa       => 'Str',
	reader    => 'get_button',
	writer    => 'set_button',
	predicate => 'has_button',
	trigger   => \&_update_button,
);

has 'clear' => (
	default   => 'no_clear',
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_clear',
	writer    => 'set_clear',
	predicate => 'has_clear',
	trigger   => \&_clear,
);

has 'flow_select_color' => (
	default   => $no_color,
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_flow_select_color',
	writer    => 'set_flow_select_color',
	predicate => 'has_flow_select_color',
	trigger   => \&_update_flow_select_color,

);

has 'add2flow_color' => (
	default   => $no_color,
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_add2flow_color',
	writer    => 'set_add2flow_color',
	predicate => 'has_add2flow_color',
	trigger   => \&_update_add2flow_color,

);

has 'defaults' => (

	is        => 'ro',
	isa       => 'HashRef',
	reader    => 'get_defaults',
	writer    => 'set_defaults',
	predicate => 'has_defaults',

);

has 'flow_listbox' => (

	is        => 'ro',
	isa       => 'HashRef',
	reader    => 'get_flow_listbox',
	writer    => 'set_flow_listbox',
	predicate => 'has_flow_listbox',
	trigger   => \&_update_flow_listbox_color_w,

);

has 'flow_type' => (
	default   => $empty_string,
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_flow_type',
	writer    => 'set_flow_type',
	predicate => 'has_flow_type',
	trigger   => \&_update_flow_type,
);

has 'help_menubutton_type' => (
	default   => '',
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_help_menubutton_type',
	writer    => 'set_help_menubutton_type',
	predicate => 'has_help_menubutton_type',
	trigger   => \&_update_help_menubutton_type,
);

has 'parameter_color_on_entry' => (
	default   => $count_start,
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_parameter_color_on_entry',
	writer    => 'set_parameter_color_on_entry',
	predicate => 'has_parameter_color_on_entry',
	trigger   => \&_update_parameter_color_on_entry,

);

has 'parameter_color_on_exit' => (
	default   => $count_start,
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_parameter_color_on_exit',
	writer    => 'set_parameter_color_on_exit',
	predicate => 'has_parameter_color_on_exit',
	trigger   => \&_update_parameter_color_on_exit,
);

has 'parameter_index_on_entry' => (
	default   => $count_start,
	is        => 'ro',
	isa       => 'Int',
	reader    => 'get_parameter_index_on_entry',
	writer    => 'set_parameter_index_on_entry',
	predicate => 'has_parameter_index_on_entry',
	trigger   => \&_update_parameter_index_on_entry,

);

has 'parameter_index_on_exit' => (
	default   => $count_start,
	is        => 'ro',
	isa       => 'Int',
	reader    => 'get_parameter_index_on_exit',
	writer    => 'set_parameter_index_on_exit',
	predicate => 'has_parameter_index_on_exit',
	trigger   => \&_update_parameter_index_on_exit,
);

has 'sunix_prog_group' => (

	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_sunix_prog_group',
	writer    => 'set_sunix_prog_group',
	predicate => 'has_sunix_prog_group',
	trigger   => \&_update_sunix_prog_group,

);

has 'subtract' => (
	default   => 'no_subtract',
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_subtract',
	writer    => 'set_subtract',
	predicate => 'has_subtract',
	trigger   => \&_subtract,
);

has 'sunix_prog_group_color' => (

	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_sunix_prog_group_color',
	writer    => 'set_sunix_prog_group_color',
	predicate => 'has_sunix_prog_group_color',
	trigger   => \&_update_sunix_prog_group_color,

);

has 'superflow_tool' => (
	default   => '',
	is        => 'ro',
	isa       => 'Str',
	reader    => 'get_superflow_tool',
	writer    => 'set_superflow_tool',
	predicate => 'has_superflow_tool',
	trigger   => \&_update_superflow_tool,
);

=head2 private anonymous hashes containing 
sequential history

=cut

my $FileDialog_type_href = {
	_item        => $empty_string,
	_index       => $empty_string,
	_name        => 'FileDialog_type',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $FileDialog_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'FileDialog_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $add2flow_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'add2flow_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

=head2 private anonymous hashes containing history

=cut

my $add2flow_button_color_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'add2flow_button_color',
	_most_recent => $current_color_start,
	_earliest    => $earliest_color_start,
	_next        => $next_color_start,
	_prior       => $prior_color_start,
};

my $button_href = {
	_item        => $empty_string,
	_index       => $empty_string,
	_name        => 'button',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $delete_from_flow_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'delete_from_flow_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $delete_whole_flow_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'delete_whole_flow_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $flow_listbox_color_w_href = {
	_item        => $empty_string,
	_index       => $empty_string,
	_name        => 'flow_listbox_color_w',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $flow_item_down_arrow_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'flow_item_down_arrow_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $flow_item_up_arrow_button_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'flow_item_up_arrow_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $flow_select_color_href = {
	_item        => $empty_string,
	_index       => $no_color,
	_name        => 'flow_select_color',
	_most_recent => $no_color,
	_earliest    => $no_color,
	_next        => $no_color,
	_prior       => $no_color,
};

my $flow_select_index_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'flow_select_index',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $flow_select_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'flow_select_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $flow_type_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'flow_type',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $help_menubutton_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'help_menubutton_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $help_menubutton_type_href = {
	_item        => $empty_string,
	_index       => $empty_string,
	_name        => 'help_menubutton_type',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $parameter_color_on_entry_href = {
	_item        => $empty_string,
	_index       => $empty_string,
	_name        => 'parameter_color_on_entry',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $parameter_color_on_exit_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'parameter_color_on_exit',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $parameter_index_on_entry_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'parameter_index_on_entry',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $parameter_index_on_entry_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'parameter_index_on_entry_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $parameter_index_on_exit_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'parameter_index_on_exit',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $parameter_index_on_exit_click_seq_href = {
	_item        => $empty_string,
	_index       => $index_start,
	_name        => 'parameter_index_on_exit_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $run_button_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'run_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $save_button_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'save_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $save_as_button_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'save_as_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $sunix_prog_group_href = {
	_item        => '',
	_index       => $empty_string,
	_name        => 'sunix_prog_group',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $sunix_prog_group_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'sunix_prog_click_seq_group',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start
};

my $superflow_select_button_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'superflow_select_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

my $superflow_tool_href = {
	_item        => '',
	_index       => $empty_string,
	_name        => 'superflow_tool',
	_most_recent => $empty_string,
	_earliest    => $empty_string,
	_next        => $empty_string,
	_prior       => $empty_string,
};

my $wipe_plots_button_click_seq_href = {
	_item        => '',
	_index       => $index_start,
	_name        => 'wipe_plots_button_seq',
	_most_recent => $current_index_start,
	_earliest    => $earliest_index_start,
	_next        => $next_index_start,
	_prior       => $prior_index_start,
};

=head2 sub _find_button
match a clicked button name to a hash key
of the same/equivalent name

print("gui_history,_find_button, search:$search \n");
print("gui_history,_find_button, temp_key:**$temp_key** \n");

=cut

sub _find_button {

	my ( $gui_history, $search ) = @_;

	foreach my $key ( sort keys %{ $gui_history->{defaults} } ) {
		my $temp_key = $key;

		# remove a suffix: '_is_'
		$temp_key =~ s/_is_//;

		if ( $temp_key eq $search ) {

			my $found = $key;
			return ($found);
		}
		else {

			#			print("gui_history,_find_button, not found: NADA\n");
			#			print("gui_history,_find_button,key:		**$key** \n");

			# N.B. return of a $false or nothing stops search
		}
	}
}

=head2 sub _get_flow_listbox_color_w


=cut 

sub _get_flow_listbox_color_w {
	my ($gui_history) = @_;

	my $flow_color = ( $gui_history->get_defaults() )->{_flow_color};

	my $key = '_flow_listbox_' . $flow_color . '_w';

	my $this_flow_listbox_color_w = ( $gui_history->get_defaults() )->{$key};

	return ($this_flow_listbox_color_w);
}

=head2 sub _get_most_recent_color_selected_gui

Assume the last color is the color of the flow selected


=cut 

sub _get_most_recent_color_selected_in_gui {

	my ($gui_history) = @_;

	my $flow_color = $flow_select_color_href->{_most_recent};

# print("$gui_history,_get_most_recent_color_selected_gui,latest color selected is: $flow_color\n");
	my $result = $flow_color;

	return ($result);
}

=head2 sub _increment_count

 increment the counter
 counter records the click number sequence for 
 all use selections 
 Two counters exist: an attribute: _count
 and a hash (value stored)key=_count) in attribute defaults

=cut

sub _increment_count {

	my ($gui_history) = @_;

	my $old_count = ( $gui_history->get_defaults() )->{_count};

	# print("gui_history, _increment_count,main_hash old_count=$old_count\n");

	if ( defined $old_count ) {

		my $new_value = $old_count + 1;

		# increment the
		# $hash key value whose reference is stored in an attribute
		# called defaults
		# and increment the '_count' attribute
		( $gui_history->get_defaults() )->{_count} = $new_value;
		$gui_history->set_count($new_value);

		my $ans = ( $gui_history->get_defaults() )->{_count};

		# print("gui_history, _increment_count,new value: $ans\n");
	}
	else {
		print("gui_history, _increment_count, count missing \n");
	}

	# print("gui_history, _increment_count, attribute new value: $ans\n");
	return ();
}

=head2 sub _initialize
Default Tk settings
Locally scoped hash 
46 off

Overlap with 
Default L_SU settings{
133 off

=cut

sub _initialize {
	my ($gui_history) = @_;

	my $markers_href = {

		#		_Data_menubutton                         => '',
		_FileDialog_option           => '',
		_FileDialog_sub_ref          => '',
		_Flow_menubutton             => '',
		_Install_menubutton          => '',
		_SaveAs_menubutton           => '',
		_add2flow_button_grey        => '',
		_add2flow_button_pink        => '',
		_add2flow_button_green       => '',
		_add2flow_button_blue        => '',
		_big_stream_name_in          => '',
		_big_stream_name_out         => '',
		_changed_entry               => 0,
		_check_buttons_settings_aref => '',
		_check_buttons_frame_href    => '',
		_check_buttons_w_aref        => '',
		_check_code_button           => '',
		_count                       => $count_start,
		_most_recent_program_name    => '',
		_delete_from_flow_button     => '',
		_delete_whole_flow_button    => '',
		_destination_index           => '',
		_dialog_type                 => '',
		_FileDialog_type             => '',

		#		_dnd_token_grey                          => '',
		#		_dnd_token_pink                          => '',
		#		_dnd_token_green                         => '',
		#		_dnd_token_blue                          => '',
		#		_dropsite_token_grey                     => '',
		#		_dropsite_token_pink                     => '',
		#		_dropsite_token_green                    => '',
		#		_dropsite_token_blue                     => '',
		_entry_button_chosen_index  => '',
		_entry_button_chosen_widget => '',
		_file_menubutton            => '',
		_first_idx                  => $default_param_specs->{_first_entry_idx},
		_flow_color                 => '',
		_flow_item_down_arrow_button           => '',
		_flow_item_up_arrow_button             => '',
		_flow_listbox_color_w                  => '',
		_flow_listbox_grey_w                   => '',
		_flow_listbox_pink_w                   => '',
		_flow_listbox_green_w                  => '',
		_flow_listbox_blue_w                   => '',
		_flow_listbox_color_w                  => '',
		_flow_name_in                          => '',
		_flow_name_in_blue                     => '',
		_flow_name_in_grey                     => '',
		_flow_name_in_green                    => '',
		_flow_name_in_pink                     => '',
		_flow_name_out                         => '',
		_flow_name_out_blue                    => '',
		_flow_name_out_grey                    => '',
		_flow_name_out_green                   => '',
		_flow_name_out_pink                    => '',
		_flow_type                             => '',
		_flow_widget_index                     => '',
		_flow_name_grey_w                      => '',
		_flow_name_pink_w                      => '',
		_flow_name_green_w                     => '',
		_flow_name_blue_w                      => '',
		_flowNsuperflow_name_w                 => '',
		_good_labels_aref2                     => '',
		_good_values_aref2                     => '',
		_gui_history_aref                      => '',
		_gui_history_ref                       => '',
		_has_used_check_code_button            => '',
		_has_used_open_perl_file_button        => $false,
		_has_used_Save_button                  => $false,
		_has_used_Save_superflow               => $false,
		_has_used_SaveAs_button                => $false,
		_has_used_run_button                   => $false,
		_help_menubutton                       => '',
		_help_option                           => '',
		_index                                 => '',
		_index2move                            => $false,
		_index_on_entry                        => '',
		_is_FileDialog_button                  => $false,
		_is_Save_button                        => $false,
		_is_SaveAs_button                      => $false,
		_is_SaveAs_file_button                 => $false,
		_is_add2flow                           => $false,
		_is_add2flow_button                    => $false,
		_is_check_code_button                  => $false,
		_is_delete_from_flow_button            => $false,
		_is_delete_whole_flow_button           => $false,
		_is_flow_item_down_arrow_button        => $false,
		_is_flow_item_up_arrow_button          => $false,
		_is_flow_listbox_grey_w                => $false,
		_is_flow_listbox_pink_w                => $false,
		_is_flow_listbox_green_w               => $false,
		_is_flow_listbox_blue_w                => $false,
		_is_flow_listbox_color_w               => $false,
		_is_future_flow_listbox_grey           => $false,
		_is_future_flow_listbox_pink           => $false,
		_is_future_flow_listbox_green          => $false,
		_is_future_flow_listbox_blue           => $false,
		_is_help_menubutton                    => $false,
		_is_last_flow_index_touched_grey       => $false,
		_is_last_flow_index_touched_pink       => $false,
		_is_last_flow_index_touched_green      => $false,
		_is_last_flow_index_touched_blue       => $false,
		_is_last_flow_index_touched            => $false,
		_is_last_parameter_index_touched_grey  => $false,
		_is_last_parameter_index_touched_pink  => $false,
		_is_last_parameter_index_touched_green => $false,
		_is_last_parameter_index_touched_blue  => $false,
		_is_last_parameter_index_touched_color => $false,
		_is_new_listbox_selection              => '',
		_is_wipe_plots_button                  => $false,
		_is_moveNdrop_in_flow                  => $false,
		_is_pre_built_superflow                => $false,
		_is_run_button                         => $false,
		_is_save_button                        => $false,
		_is_save_as_button                     => $false,
		_is_sunix_listbox                      => $false,
		_is_superflow_select_button            => $false,
		_is_superflow                          => $false,
		_is_user_built_flow                    => $false,
		_items_checkbuttons_aref2              => '',
		_items_names_aref2                     => '',
		_items_values_aref2                    => '',
		_items_versions_aref                   => '',
		_labels_aref                           => '',
		_labels_frame_href                     => '',
		_labels_w_aref                         => '',
		_last                                  => '',
		_last_flow_color                       => '',
		_last_flow_index_touched               => -1,
		_last_flow_index_touched_grey          => -1,
		_last_flow_index_touched_pink          => -1,
		_last_flow_index_touched_green         => -1,
		_last_flow_index_touched_blue          => -1,
		_last_flow_listbox_touched             => '',
		_last_flow_listbox_touched_w           => '',
		_last_path_touched                     => './',
		_last_parameter_index_touched_color    => -1,
		_last_parameter_index_touched_grey     => -1,
		_last_parameter_index_touched_pink     => -1,
		_last_parameter_index_touched_green    => -1,
		_last_parameter_index_touched_blue     => -1,
		_length                        => $default_param_specs->{_length},
		_location_in_gui               => '',
		_message_w                     => '',
		_name_aref                     => '',
		_names_aref                    => '',
		_index2move                    => '',
		_destination_index             => '',
		_run_button                    => '',
		_mw                            => '',
		_occupied_listbox_aref         => '',                             #  new
		_param_flow_length             => '',
		_parameter_index_on_entry      => -1,
		_parameter_index_on_exit       => -1,
		_parameter_menu_frame          => '',
		_parameter_values_frame        => '',
		_parameter_names_frame         => '',
		_param_sunix_first_idx         => 0,
		_param_sunix_length            => '',
		_parameter_values_button_frame => '',
		_parameter_values_frame        => '',                             # new
		_parameter_value_index         => -1,
		_pre_built_tool_href           => '',
		_pre_built_tool_button_href    => '',
		_prog_name                     => '',
		_prog_names_aref               => '',
		_prog_name_sref => '',    # has pre-existing _spec.pm and *.pm
		_run_button     => '',
		_prog_name      => '',
		_save_button    => '',
		_save_as_button => '',
		_sunix_listbox  => '',
		_sunix_prog_group_click_seq_href => '',
		_superflow_select                => '',
		_temp_num_items_in_flow          => '',
		_this_package                    => $gui_history,
		_vacant_listbox_aref             => '',              #  new
		_values_aref                     => \@empty_array,
		_values_frame_href               => '',
		_values_w_aref                   => '',
		_wipe_plots_button               => '',
	};

	# in addition .... 7.21.21
	$markers_href->{_FileDialog_type_href} = $FileDialog_type_href;
	$markers_href->{_FileDialog_button_click_seq_href} =
	  $FileDialog_button_click_seq_href;
	$markers_href->{_add2flow_button_click_seq_href} =
	  $add2flow_button_click_seq_href;
	$markers_href->{_add2flow_button_color_href} = $add2flow_button_color_href;
	$markers_href->{_button_href}                = $button_href;
	$markers_href->{_delete_from_flow_button_click_seq_href} =
	  $delete_from_flow_button_click_seq_href;
	$markers_href->{_delete_whole_flow_button_click_seq_href} =
	  $delete_whole_flow_button_click_seq_href;
	$markers_href->{_flow_listbox_color_w_href} = $flow_listbox_color_w_href;
	$markers_href->{_flow_item_down_arrow_button_click_seq_href} =
	  $flow_item_down_arrow_button_click_seq_href;
	$markers_href->{_flow_item_up_arrow_button_click_seq_href} =
	  $flow_item_up_arrow_button_click_seq_href;
	$markers_href->{_flow_select_color_href}     = $flow_select_color_href;
	$markers_href->{_flow_select_index_href}     = $flow_select_index_href;
	$markers_href->{_flow_select_click_seq_href} = $flow_select_click_seq_href;
	$markers_href->{_flow_type_href}             = $flow_type_href;
	$markers_href->{_help_menubutton_click_seq_href} =
	  $help_menubutton_click_seq_href;
	$markers_href->{_parameter_color_on_entry_href} =
	  $parameter_color_on_entry_href;
	$markers_href->{_parameter_color_on_exit_href} =
	  $parameter_color_on_exit_href;
	$markers_href->{_parameter_index_on_entry_href} =
	  $parameter_index_on_entry_href;
	$markers_href->{_parameter_index_on_entry_click_seq_href} =
	  $parameter_index_on_entry_click_seq_href;
	$markers_href->{_parameter_index_on_exit_href} =
	  $parameter_index_on_exit_href;
	$markers_href->{_parameter_index_on_exit_click_seq_href} =
	  $parameter_index_on_exit_click_seq_href;
	$markers_href->{_run_button_click_seq_href}  = $run_button_click_seq_href;
	$markers_href->{_save_button_click_seq_href} = $save_button_click_seq_href;
	$markers_href->{_save_as_button_click_seq_href} =
	  $save_as_button_click_seq_href;
	$markers_href->{_sunix_prog_group_href} = $sunix_prog_group_href;
	$markers_href->{_sunix_prog_group_click_seq_href} =
	  $sunix_prog_group_click_seq_href;
	$markers_href->{_superflow_select_button_click_seq_href} =
	  $superflow_select_button_click_seq_href;
	$markers_href->{_superflow_tool_href} = $superflow_tool_href;
	$markers_href->{_wipe_plots_button_click_seq_href} =
	  $wipe_plots_button_click_seq_href;

	my $result = $markers_href;

	# print(" gui_history, _initialize, result = $result \n ");
	# if (ref $result) {
	# 	print(" gui_history, _initialize, result is a reference \n ");
	# 	print(" gui_history, _initialize, = $gui_history \n ");
	# } else {
	# 	print(" gui_history, _initialize, result is NOT a reference \n ");
	# }

	$gui_history->set_defaults($result);
	return ();

}

=head2 sub _reset

	private reset of "condition" variables
	do not reset incoming widgets
	
=cut

sub _reset {
	my ( $gui_history, $type ) = @_;

	# print("gui_history,_reset, gui_history=$gui_history,type = $type \n");

	if ( $type eq 'listbox_color_w' ) {

		( $gui_history->get_defaults() )->{_is_flow_listbox_grey_w}  = $false;
		( $gui_history->get_defaults() )->{_is_flow_listbox_pink_w}  = $false;
		( $gui_history->get_defaults() )->{_is_flow_listbox_green_w} = $false;
		( $gui_history->get_defaults() )->{_is_flow_listbox_blue_w}  = $false;
		( $gui_history->get_defaults() )->{_is_flow_listbox_color_w} = $false;

	}
	elsif ( $type ne 'listbox_color_w' ) {

		( $gui_history->get_defaults() )->{_is_add2flow} =
		  $false;    # needed? double confirmation?
		( $gui_history->get_defaults() )->{_is_add2flow_button} =
		  $false;    # needed? double confirmation?
		( $gui_history->get_defaults() )->{_is_delete_from_flow_button} =
		  $false;
		( $gui_history->get_defaults() )->{_is_new_listbox_selection} = $false;
		( $gui_history->get_defaults() )->{_is_superflow_select_button} =
		  $false;
		( $gui_history->get_defaults() )->{_is_delete_whole_flow_button} =
		  $false;
		( $gui_history->get_defaults() )->{_is_moveNdrop_in_flow} = $false;
		( $gui_history->get_defaults() )->{_is_sunix_listbox}     = $false;

	}
	else {
		print("gui_history,_reset, unexpected type \n");
	}
	return ();
}

#			( $gui_history->get_defaults )->{_parameter_index_on_exit_href} = $parameter_index_on_exit_href;

=head2 sub _set_click_sequence

For general case, new count will not be sequential with previous 
index value in the same $property_href
Count changes whenever the user clicks on any tool

indices for property_href should increase only if the most_recent
is different to the prior. i.e., only if there is a real change
indices only change if there is a real change

=cut

sub _set_click_sequence {

	my ( $gui_history, $property_href ) = @_;
	my $count;
	my $val;

# print("1 _set_click_sequence; gui_history,property_href->{_prior} : $gui_history, $property_href->{_prior} \n");
# print("1 _set_click_sequence; gui_history,property_href->{_earliest}: $gui_history, $property_href->{_earliest} \n");
# print("1 _set_click_sequence; gui_history,property_href->{_most_recent} : $property_href->{_most_recent} \n");

	if ( defined $property_href ) {

		# update the indices of appearance
		if ( $property_href->{_most_recent} != $property_href->{_prior} ) {
			$property_href->{_earliest} = $property_href->{_prior};
			$property_href->{_prior}    = $property_href->{_most_recent};

		}
		elsif ( $property_href->{_most_recent} == $property_href->{_prior} ) {
			print(
				"gui_history, _set_click_sequence, property is not changed\n");

		}
		else {
			print("gui_history, _set_click_sequence, unexpected value\n");
		}

		$gui_history->_increment_count();
		$property_href->{_most_recent} =
		  ( $gui_history->get_defaults() )->{_count};

# print("2 _set_click_sequence;gui_history->{_count} = $gui_history->{_count}\n");
# print("22 _set_click_sequence; property_href {_name}= $property_href->{_name}\n");

# print("2 _set_click_sequence; gui_history,property->{_prior} : $gui_history, $property_href->{_prior} \n");
# print("2 _set_click_sequence; gui_history,property->{_earliest}: $gui_history, $property_href->{_earliest} \n");
# print("2 _set_click_sequence; gui_history->{_most_recent} : $property_href->{_most_recent} \n");

		# print additional subsets: flow_select_color

	}
}

=head2 sub _set_flow_listbox_color_w


=cut 

sub _set_flow_listbox_color_w {
	my ($gui_history) = @_;

	my $color = ( $gui_history->get_defaults() )->{_flow_color};

	if ( defined $color ) {

		my $key1 = '_flow_listbox_' . $color . '_w';
		my $key2 = '_is_flow_listbox_' . $color . '_w';

		( $gui_history->get_defaults() )->{_flow_listbox_color_w} =
		  ( $gui_history->get_defaults() )->{$key1};
		( $gui_history->get_defaults() )->{$key2} = $true;

	}
	else {
		print("gui_history,_set_flow_listbox_color_w, missing color\n");
	}

	return ();
}

=head2 sub _update_FileDialog_type
Assign new FileDialog_type to private key: _FileDialog_type
Can be 'Data'
or     'Delete'
or     ' '

$gui_history = current package

=cut

sub _update_FileDialog_type {
	my ( $gui_history, $new_most_recent_FileDialog_type,
		$new_prior_FileDialog_type )
	  = @_;

	if ( defined $FileDialog_type_href ) {

	   # update the history of add2flow_button usage according to the color used
		$FileDialog_type_href->{_earliest} = $FileDialog_type_href->{_prior};
		$FileDialog_type_href->{_prior} = $FileDialog_type_href->{_most_recent};
		$FileDialog_type_href->{_most_recent} =
		  $new_most_recent_FileDialog_type;

		( $gui_history->get_defaults )->{_FileDialog_type_href} =
		  $FileDialog_type_href;
	}

	# update the history of the name usage if the current FileDialog_type
	my $current_count = ( $gui_history->get_defaults() )->{_count};
	if ( $FileDialog_button_click_seq_href->{_most_recent} == $current_count ) {

	}

	return ();

}

=head2 sub _update_button
Assign new button to private key: _XXX_button

print("gui_history, _update_button, ans= $ans\n");
print("gui_history, _update_button, button= $button\n");

=cut

sub _update_button {

	my ( $gui_history, $new_most_recent_button, $new_new_prior_button ) = @_;

	# my $button = _find_button( $gui_history, $new_most_recent_button );

	if ( $new_most_recent_button ne $empty_string ) {

		if ( defined $button_href ) {

	   # update the history of add2flow_button usage according to the color used
			$button_href->{_earliest}    = $button_href->{_prior};
			$button_href->{_prior}       = $button_href->{_most_recent};
			$button_href->{_most_recent} = $new_most_recent_button;

			( $gui_history->get_defaults() )->{_button_href} = $button_href;
		}

		if ( $new_most_recent_button eq 'FileDialog_button' ) {

			( $gui_history->get_defaults() )->{_is_FileDialog_button} = $true;

			_set_click_sequence( $gui_history,
				$FileDialog_button_click_seq_href );

		 # update the history of FileDialog_button use according  to click count
			( $gui_history->get_defaults )->{_FileDialog_button_click_seq_href}
			  = $FileDialog_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'add2flow_button' ) {

			( $gui_history->get_defaults() )->{_is_add2flow_button} = $true;
			( $gui_history->get_defaults() )->{_is_add2flow}        = $true;

			_set_click_sequence( $gui_history,
				$add2flow_button_click_seq_href );

		   # update the history of add2flow_button use according  to click count
			( $gui_history->get_defaults() )->{_add2flow_button_click_seq_href}
			  = $add2flow_button_click_seq_href;
			( $gui_history->get_defaults() )->{_is_new_listbox_selection} =
			  $true;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();
		}
		elsif ( $new_most_recent_button eq 'delete_from_flow_button' ) {

			( $gui_history->get_defaults() )->{_is_delete_from_flow_button} =
			  $true;

			_set_click_sequence( $gui_history,
				$delete_from_flow_button_click_seq_href );

   # update the history of delete_from_flow_button use according  to click count
			( $gui_history->get_defaults )
			  ->{_delete_from_flow_button_click_seq_href} =
			  $delete_from_flow_button_click_seq_href;

			_reset( $gui_history, 'listbox_color_w' );

			# find out the latest color
			# assume that flow select color is the latest color
			my $color = _get_most_recent_color_selected_in_gui($gui_history);

			my $key1 = '_is_flow_listbox_' . $color . '_w';

			( $gui_history->get_defaults() )->{$key1} = $true;
			( $gui_history->get_defaults() )->{_is_flow_listbox_color_w} =
			  $true;

			# print("gui_history, _update_button, delete_from_flow_button \n");

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'delete_whole_flow_button' ) {

			( $gui_history->get_defaults() )->{_is_delete_whole_flow_button} =
			  $true;

			_set_click_sequence( $gui_history,
				$delete_whole_flow_button_click_seq_href );

  # update the history of delete_whole_flow_button use according  to click count
			( $gui_history->get_defaults )
			  ->{_delete_whole_flow_button_click_seq_href} =
			  $delete_whole_flow_button_click_seq_href;

			_reset( $gui_history, 'listbox_color_w' );

			# find out the latest color
			# assume that flow select color is the latest color
			my $color = _get_most_recent_color_selected_in_gui($gui_history);

			my $key1 = '_is_flow_listbox_' . $color . '_w';

			( $gui_history->get_defaults() )->{$key1} = $true;
			( $gui_history->get_defaults() )->{_is_flow_listbox_color_w} =
			  $true;

# print("gui_history, _update_button, delete_whole_flow_button \n");
# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'flow_item_down_arrow_button' ) {

			( $gui_history->get_defaults() )->{_is_flow_item_down_arrow_button}
			  = $true;

			_set_click_sequence( $gui_history,
				$flow_item_down_arrow_button_click_seq_href );

# update the history of flow_item_down_arrow_button use according  to click count
			( $gui_history->get_defaults )
			  ->{_flow_item_down_arrow_button_click_seq_href} =
			  $flow_item_down_arrow_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'flow_item_up_arrow_button' ) {

			( $gui_history->get_defaults() )->{_is_flow_item_up_arrow_button} =
			  $true;

			_set_click_sequence( $gui_history,
				$flow_item_up_arrow_button_click_seq_href );

# update the history of  flow_item_up_arrow_button use according  to click count
			( $gui_history->get_defaults )
			  ->{_flow_item_up_arrow_button_click_seq_href} =
			  $flow_item_up_arrow_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'flow_select' ) {

	  #			my $ans = ( $gui_history->get_defaults() )->{_count};
	  #			print("1. gui_history, _update_button, for flow_select count=$ans\n");

			my $_flow_listbox_color_w = _get_flow_listbox_color_w($gui_history);
			my $most_recent_index =
			  $flow_widgets->get_flow_selection($_flow_listbox_color_w);

			# CASE 1: flow listbox is cleared with no highlights
			if ( not defined $most_recent_index ) {

				# no change to indices
				# increment record sequence as total number of mouse clicks
				_set_click_sequence( $gui_history,
					$flow_select_click_seq_href );

# print("2. gui_history, _update_button, for _flow_listbox_color_w=$_flow_listbox_color_w \n");
				( $gui_history->get_defaults() )->{_flow_select_click_seq_href}
				  = $flow_select_click_seq_href;
			}

   # CASE 2 flow listbox must have been selected and have highlighted an element
   # and the selected index must be different to the previous index
   # only such case among the many tracked properties of the GUI
			elsif ( $most_recent_index ne $empty_string
				and $most_recent_index ne
				$flow_select_index_href->{_most_recent} )
			{

		 # update the history of flow_select usage according to the index chosen
				$flow_select_index_href->{_earliest} =
				  $flow_select_index_href->{_prior};
				$flow_select_index_href->{_prior} =
				  $flow_select_index_href->{_most_recent};
				$flow_select_index_href->{_most_recent} = $most_recent_index;
				( $gui_history->get_defaults() )->{_flow_select_index_href} =
				  $flow_select_index_href;

# print(
# 	"2. gui_history, _update_button, for flow_select new most_recent_index=$most_recent_index \n");
# print(
# 	"2. gui_history, _update_button, for flow_select new prior_index=$flow_select_index_href->{_prior} \n"
#  );

# print("gui_history, _update_button, flow_select_click_seq_href= ($gui_history->get_defaults )->{_flow_select_click_seq_href}\n");
# print("3. gui_history, _update_button, flow_select most_recent_index=$most_recent_index \n");

# print("gui_history, _update_button, flow_select_click_seq_href= ($gui_history->get_defaults )->{_flow_select_click_seq_href}\n");
# print("3. gui_history, _update_button, button matched = $new_most_recent_button\n");

			}
			elsif ( $most_recent_index ne $empty_string
				and $most_recent_index eq
				$flow_select_index_href->{_most_recent} )
			{

# record sequence as total number of mouse clicks, when user reclicks the same location
# However in _set_click_sequence the property indices will not be updated
# only the general gui count JML 2-2020
				_set_click_sequence( $gui_history,
					$flow_select_click_seq_href );

				# not really reset ??? mystery
				( $gui_history->get_defaults() )->{_flow_select_click_seq_href}
				  = $flow_select_click_seq_href;

			}
			else {
				print(
" gui_history, set_button for flow_select, unexpected result \n"
				);
			}

			return ();

		}
		elsif ( $new_most_recent_button eq 'help_menubutton' ) {

			( $gui_history->get_defaults() )->{_is_help_menubutton} = $true;

			_set_click_sequence( $gui_history,
				$help_menubutton_click_seq_href );

			# update the history of help_menubutton use according to click count
			( $gui_history->get_defaults )->{_help_menubutton_click_seq_href} =
			  $help_menubutton_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'run_button' ) {

			( $gui_history->get_defaults() )->{_is_run_button} = $true;

			_set_click_sequence( $gui_history, $run_button_click_seq_href );

			# update the history of run_button use according  to click count
			( $gui_history->get_defaults )->{_run_button_click_seq_href} =
			  $run_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'save_button' ) {

			( $gui_history->get_defaults() )->{_is_save_button} = $true;

			_set_click_sequence( $gui_history, $save_button_click_seq_href );

			# update the history of save_button use according  to click count
			( $gui_history->get_defaults )->{_save_button_click_seq_href} =
			  $save_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'save_as_button' ) {

			( $gui_history->get_defaults() )->{_is_save_as_button} = $true;

			_set_click_sequence( $gui_history, $save_as_button_click_seq_href );

		   # update the history of  save_as_button use according  to click count
			( $gui_history->get_defaults )->{_save_as_button_click_seq_href} =
			  $save_as_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'sunix_select' ) {

			( $gui_history->get_defaults() )->{_is_sunix_select} = $true;
			( $gui_history->get_defaults() )->{_is_new_listbox_selection} =
			  $true;    # so changes not allowed
			( $gui_history->get_defaults() )->{_is_sunix_listbox} = $true;

# history and sequence is handled by sunix_prog_group_click_seq_href and sunix_select_prog_group_href

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'superflow_select_button' ) {

			( $gui_history->get_defaults() )->{_is_superflow_select_button} =
			  $true;
			( $gui_history->get_defaults() )->{_is_superflow}           = $true;
			( $gui_history->get_defaults() )->{_is_pre_built_superflow} = $true;

			_set_click_sequence( $gui_history,
				$superflow_select_button_click_seq_href );

   # update the history of superflow_select_button use according  to click count
			( $gui_history->get_defaults )
			  ->{_superflow_select_button_click_seq_href} =
			  $superflow_select_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		elsif ( $new_most_recent_button eq 'wipe_plots_button' ) {

			( $gui_history->get_defaults() )->{_is_wipe_plots_button} = $true;

			_set_click_sequence( $gui_history,
				$wipe_plots_button_click_seq_href );

		 # update the history of wipe_plots_button use according  to click count
			( $gui_history->get_defaults )->{_wipe_plots_button_click_seq_href}
			  = $wipe_plots_button_click_seq_href;

# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
			return ();

		}
		else {

			# print("gui_history,_update_button, button unmatched NADA\n");
			return ();
		}
	}
	else {
		print("gui_history,_update_button, button not found:\n");
		return ();
	}
}

=head2 sub _update_add2flow_color

Assign new color to private key: _flow_color

In this sub, flow color can be grey,pink,green or blue
but not 'neutral' or 'nada' or 'no_color'

$gui_history = current package

When there is a color change


=cut

sub _update_add2flow_color {
	my ( $gui_history, $new_most_recent_color, $new_prior_color ) = @_;

	# for safety
	if (   $new_most_recent_color ne 'nada'
		&& $new_most_recent_color ne $neutral
		&& $new_most_recent_color ne 'no_color' )
	{
		( $gui_history->get_defaults() )->{_flow_color} =
		  $new_most_recent_color;

		my $current_count = ( $gui_history->get_defaults() )->{_count};

		if ( defined $add2flow_button_color_href ) {

	   # update the history of add2flow_button usage according to the color used
			$add2flow_button_color_href->{_earliest} =
			  $add2flow_button_color_href->{_prior};
			$add2flow_button_color_href->{_prior} =
			  $add2flow_button_color_href->{_most_recent};
			$add2flow_button_color_href->{_most_recent} =
			  $new_most_recent_color;

			( $gui_history->get_defaults )->{_add2flow_button_color_href} =
			  $add2flow_button_color_href;

# print("1.gui_history,_update_add2flow_color, new_most_recent_color:$new_most_recent_color, new_prior_color=$new_prior_color\n");
		}

	}
	else {

		# print("2.gui_history,_update_add2flow_color wrong color \n");
	}

	# print("gui_history,updated color:$updated_color, old_color=$old_color\n");
}

=head2 sub _update_flow_select_color
Assign new color to private key: _flow_color

flow color can be grey,pink,green or blue
but not neutral or 'nada' or 'no_color'

$gui_history = current package

When there is a color change

=cut

sub _update_flow_select_color {
	my ( $gui_history, $new_most_recent_color, $new_prior_color ) = @_;

	# for safety
	#	if (not(   $new_most_recent_color ne 'nada'
	#			or $new_most_recent_color ne $neutral
	#			or $new_most_recent_color ne 'no_color' )
	#		)
	#	{
	( $gui_history->get_defaults() )->{_flow_color} = $new_most_recent_color;

	my $current_count = ( $gui_history->get_defaults() )->{_count};

	if ( defined $flow_select_click_seq_href ) {

		# when color is set as: gui_history->set_color('this color')
		# update the color history
		# ony if the current button is flow_select
		# also update the flow_widget object reference

# if ( $flow_select_click_seq_href->{_most_recent} == $current_count ) {    # safety

		( $gui_history->get_defaults() )->{_last_color} =
		  $new_most_recent_color;

# print("1.gui_history,updated color for flow_select:new_most_recent_color, $new_most_recent_color\n");

		# update the history of flow_select usage according to the color used
		$flow_select_color_href->{_earliest} =
		  $flow_select_color_href->{_prior};
		$flow_select_color_href->{_prior} =
		  $flow_select_color_href->{_most_recent};
		$flow_select_color_href->{_most_recent} = $new_most_recent_color;

# print("2.gui_history,updated color for flow_select:new prior_color,$flow_select_color_href->{_prior} \n\n");

		( $gui_history->get_defaults() )->{_flow_select_color_href} =
		  $flow_select_color_href;

		# _click_($new_most_recent_color);
		my $flow_listbox_color_w_key =
		  '_flow_listbox_' . $new_most_recent_color . '_w';
		my $flow_listbox_color_w_txt =
		  'flow_listbox_' . $new_most_recent_color . '_w';
		my $flow_listbox_color_w = $gui_history->{$flow_listbox_color_w_key};

		# _set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);
		# _set_flow_listbox_last_touched_w($flow_listbox_color_w);

		# dynamic location within gui
		my $value2 = '_is_flow_listbox_' . $new_most_recent_color . '_w';
		$gui_history->{$value2} = $true;
		$gui_history->{_is_flow_listbox_color_w} = $true;

#} else {
#		print("flow_select_click_seq_href->{_most_recent}=$flow_select_click_seq_href->{_most_recent} does not equal current_count=$current_count\n");
#		}
	}
	else {
		print("2.gui_history,_update_flow_select_color unexpected value \n");
	}

	# print("gui_history,updated color:$updated_color, old_color=$old_color\n");
}

=head2 sub _update_flow_listbox_color_w
'

$gui_history = current package

=cut

sub _update_flow_listbox_color_w {
	my (
		$gui_history,
		$new_most_recent_flow_listbox_color_w,
		$new_prior_flow_listbox_color_w
	) = @_;

	( $gui_history->get_defaults() )->{_flow_listbox_color_w} =
	  $new_most_recent_flow_listbox_color_w;

# print("gui_history,updated flow type :$new_most_recent_flow_listbox_color_w\n");

	if ( defined $flow_listbox_color_w_href ) {

# update the history of flow selection usage according to the flow_listbox_color_w used
		$flow_listbox_color_w_href->{_earliest} =
		  $flow_listbox_color_w_href->{_prior};
		$flow_listbox_color_w_href->{_prior} =
		  $flow_listbox_color_w_href->{_most_recent};
		$flow_listbox_color_w_href->{_most_recent} =
		  $new_most_recent_flow_listbox_color_w;

		( $gui_history->get_defaults )->{_flow_listbox_color_w_href} =
		  $flow_listbox_color_w_href;

#TODO		_set_flow_listbox_last_touched_txt($flow_listbox_color_w_txt);
#TODO		_set_flow_listbox_last_touched_w($$new_most_recent_flow_listbox_color_w);

	}
	else {

# print("gui_history,updated flow listbox_color_w :unexpected flow lsitbox \n");
	}

	return ();

# print("gui_history,updated flow_listbox_color_w:$new_most_recent_flow_listbox_color_w, new_prior_flow_listbox_color_w=$new_prior_flow_listbox_color_w\n");
}

=head2 sub _update_flow_type
Assign new flow_type to private key: _flow_type
Can be 'pre_built_superflow 'or 
'user_built'

$gui_history = current package


=cut

sub _update_flow_type {
	my ( $gui_history, $new_most_recent_flow_type, $new_prior_flow_type ) = @_;

	( $gui_history->get_defaults() )->{_flow_type} = $new_most_recent_flow_type;

	# print("1. gui_history,updated flow type :$new_most_recent_flow_type\n");

	if ( defined $flow_type_href ) {

   # update the history of add2flow_button usage according to the flow_type used
		$flow_type_href->{_earliest}    = $flow_type_href->{_prior};
		$flow_type_href->{_prior}       = $flow_type_href->{_most_recent};
		$flow_type_href->{_most_recent} = $new_most_recent_flow_type;

		( $gui_history->get_defaults() )->{_flow_type_href} = $flow_type_href;
		my $ans = ( ( $gui_history->get_defaults() )->{_flow_type_href} )
		  ->{_most_recent};

# print("2. gui_history,updated flow type, new_most_recent_flow_type: $ans \n");
	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	if ( $gui_history->get_flow_type eq 'user_built' ) {
		( $gui_history->get_defaults() )->{_is_user_built_flow} = $true;
	}
	elsif ( $gui_history->get_flow_type eq 'pre_built_superflow' ) {
		( $gui_history->get_defaults() )->{_is_pre_built_superflow} = $true;
		( $gui_history->get_defaults() )->{_is_superflow}           = $true;
	}
	else {
		print("3 gui_history,updated flow type :unexpected flow type NADA\n");
	}

# print("4 gui_history,updated flow_type:$new_most_recent_flow_type, new_prior_flow_type=$new_prior_flow_type\n\n");
	return ();
}

=head2 sub _update_help_menubutton_type
Assign new help_menubutton_type to private key: _help_menubutton_type
Can be 'Install'
or     ' '
or     ' '

$gui_history = current package

=cut

sub _update_help_menubutton_type {
	my (
		$gui_history,
		$new_most_recent_help_menubutton_type,
		$new_prior_help_menubutton_type
	) = @_;

	if ( defined $help_menubutton_type_href ) {

	   # update the history of add2flow_button usage according to the color used
		$help_menubutton_type_href->{_earliest} =
		  $help_menubutton_type_href->{_prior};
		$help_menubutton_type_href->{_prior} =
		  $help_menubutton_type_href->{_most_recent};
		$help_menubutton_type_href->{_most_recent} =
		  $new_most_recent_help_menubutton_type;

		( $gui_history->get_defaults )->{_help_menubutton_type_href} =
		  $help_menubutton_type_href;
	}

	# update the history of the name usage if the current help_menubutton_type
	my $current_count = ( $gui_history->get_defaults() )->{_count};
	if ( $help_menubutton_click_seq_href->{_most_recent} == $current_count ) {

	}

	return ();

}

=head2 sub _update_parameter_color_on_entry

$gui_history = current package


=cut

sub _update_parameter_color_on_entry {
	my (
		$gui_history,
		$new_most_recent_parameter_color_on_entry,
		$new_prior_parameter_color_on_entry
	) = @_;

# print("gui_history,updated parameter_color_on_entry :$new_most_recent_parameter_color_on_entry\n");

	if ( defined $parameter_color_on_entry_href ) {

# update the history of parameter_color_on_entry according to the parameter_color_on_entry used
		$parameter_color_on_entry_href->{_earliest} =
		  $parameter_color_on_entry_href->{_prior};
		$parameter_color_on_entry_href->{_prior} =
		  $parameter_color_on_entry_href->{_most_recent};
		$parameter_color_on_entry_href->{_most_recent} =
		  $new_most_recent_parameter_color_on_entry;

		( $gui_history->get_defaults )->{_parameter_color_on_entry_href} =
		  $parameter_color_on_entry_href;

	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	return ();

# print("gui_history,updated parameter_color_on_entry:$new_most_recent_parameter_color_on_entry, new_prior_parameter_color_on_entry=$new_prior_parameter_color_on_entry\n");
}

=head2 sub _update_parameter_color_on_exit

$gui_history = current package


=cut

sub _update_parameter_color_on_exit {
	my (
		$gui_history,
		$new_most_recent_parameter_color_on_exit,
		$new_prior_parameter_color_on_exit
	) = @_;

	( $gui_history->get_defaults() )->{_parameter_color_on_exit} =
	  $new_most_recent_parameter_color_on_exit;

# print("gui_history,updated parameter_color_on_exit :$new_most_recent_parameter_color_on_exit\n");

	if ( defined $parameter_color_on_exit_href ) {

# update the history of parameter_color_on_exit according to the parameter_color_on_exit used
		$parameter_color_on_exit_href->{_earliest} =
		  $parameter_color_on_exit_href->{_prior};
		$parameter_color_on_exit_href->{_prior} =
		  $parameter_color_on_exit_href->{_most_recent};
		$parameter_color_on_exit_href->{_most_recent} =
		  $new_most_recent_parameter_color_on_exit;

		( $gui_history->get_defaults )->{_parameter_color_on_exit_href} =
		  $parameter_color_on_exit_href;

	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	return ();
}

=head2 sub _update_parameter_index_on_entry

$gui_history = current package


=cut

sub _update_parameter_index_on_entry {
	my (
		$gui_history,
		$new_most_recent_parameter_index_on_entry,
		$new_prior_parameter_index_on_entry
	) = @_;

	( $gui_history->get_defaults() )->{_parameter_index_on_entry} =
	  $new_most_recent_parameter_index_on_entry;

# print("gui_history,updated parameter_index_on_entry :$new_most_recent_parameter_index_on_entry\n");

	if ( defined $parameter_index_on_entry_click_seq_href ) {

	   # update the history of parameter_index_on_entry according to click count
		_set_click_sequence( $gui_history,
			$parameter_index_on_entry_click_seq_href );

		( $gui_history->get_defaults )
		  ->{_parameter_index_on_entry_click_seq_href} =
		  $parameter_index_on_entry_click_seq_href;

	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	if ( defined $parameter_index_on_entry_href ) {

# update the history of parameter_index_on_entry according to the parameter_index_on_entry used
		$parameter_index_on_entry_href->{_earliest} =
		  $parameter_index_on_entry_href->{_prior};
		$parameter_index_on_entry_href->{_prior} =
		  $parameter_index_on_entry_href->{_most_recent};
		$parameter_index_on_entry_href->{_most_recent} =
		  $new_most_recent_parameter_index_on_entry;
#		print("gui_history,updated parameter_index_on_entry :$parameter_index_on_entry_href->{_most_recent}\n");
		( $gui_history->get_defaults )->{_parameter_index_on_entry_href} =
		  $parameter_index_on_entry_href;

	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	return ();

# print("gui_history,updated parameter_index_on_entry:$new_most_recent_parameter_index_on_entry, new_prior_parameter_index_on_entry=$new_prior_parameter_index_on_entry\n");
}

=head2 sub _update_parameter_index_on_exit

$gui_history = current package


=cut

sub _update_parameter_index_on_exit {
	my (
		$gui_history,
		$new_most_recent_parameter_index_on_exit,
		$new_prior_parameter_index_on_exit
	) = @_;

	if ( length $new_most_recent_parameter_index_on_exit ) {

		# CASE: A parameter is selected

		( $gui_history->get_defaults() )->{_parameter_index_on_exit} =
		  $new_most_recent_parameter_index_on_exit;

#		print("gui_history,updated parameter_index_on_exit :$new_most_recent_parameter_index_on_exit\n");

		if ( defined $parameter_index_on_exit_click_seq_href ) {

 # update the history of  parameter_index_on_exit usage according to click count
			_set_click_sequence( $gui_history,
				$parameter_index_on_exit_click_seq_href );

			( $gui_history->get_defaults )
			  ->{_parameter_index_on_exit_click_seq_href} =
			  $parameter_index_on_exit_click_seq_href;

		}
		else {
			print("gui_history, missing flow hash NADA\n");
		}

		if ( defined $parameter_index_on_exit_href ) {

# update the history of parameter_index_on_exit according to the parameter_index_on_exit used
			$parameter_index_on_exit_href->{_earliest} =
			  $parameter_index_on_exit_href->{_prior};
			$parameter_index_on_exit_href->{_prior} =
			  $parameter_index_on_exit_href->{_most_recent};
			$parameter_index_on_exit_href->{_most_recent} =
			  $new_most_recent_parameter_index_on_exit;
#		print("gui_history,updated parameter_index_on_exit :$parameter_index_on_exit_href->{_most_recent}\n");

			( $gui_history->get_defaults )->{_parameter_index_on_exit_href} =
			  $parameter_index_on_exit_href;

		}
		else {
			print("gui_history, missing flow hash NADA\n");
		}

	}
	else {

		# CASE: parameter is not selected
		if ( defined $parameter_index_on_exit_href ) {

			print(
				"gui_history, no parameter was selected; NO UPDATES to clicks\n"
			);
			( $gui_history->get_defaults )->{_parameter_index_on_exit_href} =
			  $parameter_index_on_exit_href;

			( $gui_history->get_defaults )
			  ->{_parameter_index_on_exit_click_seq_href} =
			  $parameter_index_on_exit_click_seq_href;

		}
		else {
			print(
				"gui_history, no parameter is selected and  flow hash missing\n"
			);
		}
	}

	return ();

# print("gui_history,updated parameter_index_on_exit:$new_most_recent_parameter_index_on_exit, new_prior_parameter_index_on_exit=$new_prior_parameter_index_on_exit\n");
}

=head2 sub _update_sunix_prog_group

$gui_history = current package


=cut

sub _update_sunix_prog_group {
	my ( $gui_history, $new_most_recent_sunix_prog_group,
		$new_prior_sunix_prog_group )
	  = @_;

	( $gui_history->get_defaults() )->{_sunix_prog_group} =
	  $new_most_recent_sunix_prog_group;

# print("gui_history,updated sunix_prog_group :$new_most_recent_sunix_prog_group\n");

	if ( defined $sunix_prog_group_href ) {

# update the history of sunix group programs usage according to the sunix_prog_group used
		$sunix_prog_group_href->{_earliest} = $sunix_prog_group_href->{_prior};
		$sunix_prog_group_href->{_prior} =
		  $sunix_prog_group_href->{_most_recent};
		$sunix_prog_group_href->{_most_recent} =
		  $new_most_recent_sunix_prog_group;

		( $gui_history->get_defaults )->{_sunix_prog_group_href} =
		  $sunix_prog_group_href;
		( $gui_history->get_defaults )->{_is_sunix_listbox} = $true;

	}
	else {
		print("gui_history, missing flow hash NADA\n");
	}

	if ( defined $sunix_prog_group_click_seq_href ) {
		_set_click_sequence( $gui_history, $sunix_prog_group_click_seq_href );
		( $gui_history->get_defaults )->{_sunix_prog_group_click_seq_href} =
		  $sunix_prog_group_click_seq_href;
	}
	else {
		print("gui_history, missing flow hash seq NADA\n");
	}

	return ();

# print("gui_history,updated sunix_prog_group:$new_most_recent_sunix_prog_group, new_prior_sunix_prog_group=$new_prior_sunix_prog_group\n");
}

=head2 sub _update_sunix_prog_group_color

$gui_history = current package

color is always the same (= neutral)


=cut

sub _update_sunix_prog_group_color {
	my (
		$gui_history,
		$new_most_recent_sunix_prog_group_color,
		$new_prior_sunix_prog_group_color
	) = @_;

	( $gui_history->get_defaults() )->{_flow_color} =
	  $new_most_recent_sunix_prog_group_color;

# print("gui_history,updated sunix_prog_group :$new_most_recent_sunix_prog_group_color\n");

	return ();

}

=head2 sub _update_superflow_tool
Assign new name to private key: superflow_tool

=cut

sub _update_superflow_tool {
	my ( $gui_history, $new_most_recent_tool, $new_prior_tool ) = @_;

# print("1. gui_history,updated superflow_tool:$new_most_recent_tool, new_prior_tool=$new_prior_tool\n");

	# update the history of superflow_tool usage according to the tool used
	$superflow_tool_href->{_earliest}    = $superflow_tool_href->{_prior};
	$superflow_tool_href->{_prior}       = $superflow_tool_href->{_most_recent};
	$superflow_tool_href->{_most_recent} = $new_most_recent_tool;

#	( $gui_history->delete_whole_flow)->{_superflow_tool_href} = $superflow_tool_href;
	( $gui_history->get_defaults() )->{_superflow_tool_href} =
	  $superflow_tool_href;

# print("2. gui_history,updated superflow_tool :$new_most_recent_tool, new_prior_tool=$new_prior_tool\n");

	return ();

}

=head2 BUILDARGS Initialize contents
before instantiation.
In superclass, helps avoid hash or hashref syntax

=cut

around BUILDARGS => sub {

	my ( $orig, $gui_history, @args ) = @_;

	if ( scalar @args >= 1 && not ref $args[0] ) {

		# print(" BUILDARGS initializing with args        = @args \n ");
		# print(" BUILDARGS initializing with orig        = $orig \n ");
		# print(" BUILDARGS initializing with gui_history = $gui_history \n ");

		return $gui_history->$orig( item   => $args[0] );
		return $gui_history->$orig( indexx => $args[1] );

		# my $item = $gui_history->get_item();
		# print(" 1. BUILDARGS item = $item \n ");

  #		foreach my $key ( sort keys %$orig ) {
  #			print(" gui_history, BUILDARGS, key is $key, value is $orig->{$key} \n ");
  #		}

	}
	else {

 # print(" gui_history,BUILDARGS, unexpected external default value(s) NADA\n");
		my $result = $gui_history->$orig(@_);
		return ($result);
	}
};

=head2 BUILD
Initial checking after instantiation

foreach my $key ( sort keys %$gui_history ) {
	print (" gui_history, BUILD key is $key, value is $gui_history->{$key}\n");
}

=cut

sub BUILD {
	my ($this_package_address) = @_;

	# _defaults attribute start empty
	# print("1. gui_history,BUILD,initializing with: $gui_history()\n");
	_initialize($this_package_address);

}

# print("2. gui_history,BUILD,initializing with: $gui_history->get_defaults()\n");

=head2 sub get_internal

=cut

sub get_internal {

	my ($gui_history) = @_;

	if ( defined $gui_history->get_item() ) {

		my $result = $gui_history->get_item();

		# print(" gui_history, get_math, result : $result \n ");

		return ($result);
	}

}


=head2 sub get_file_status

=cut

sub get_file_status {

	my ($gui_history) = @_;

	my $num_items_in_flow =
	  $gui_history->get_defaults()->{_temp_num_items_in_flow};
	  		my $click_count =
		  ( ( $gui_history->get_defaults() )->{_count} );

	if ( length $num_items_in_flow ) {

		my $min_click_count = ($num_items_in_flow + 1) * 3;
			# print("gui_history,get_file_status, click count =$click_count \n");
		if ( $click_count <= $min_click_count ) {

			my $result = $true;
			 #print(
 #"gui_history,get_file_status, click count: $click_count<= $min_click_count \n"
 #			);
			return ($result);
		}
		else {
			# print("gui_history,get_file_status, exceeded click count \n");
			# print("click count =$click_count > $min_click_count \n");
			my $result = $false;
			return($result);
		}

	}
	else {
		print("gui_history,get_file_status, missing inputs\n");
		return ();
	}

}

=head2 sub set_internally


=cut

sub set_internally {

	my ($gui_history) = @_;

	if ( $gui_history->get_item ) {

		$gui_history->set_item('replacement');

		my $result = $gui_history->get_item();

		# print(" gui_history, get_math, result : $result \n ");

		return ();
	}

}

=head2 sub set_file_status

=cut

sub set_file_status {

	my ( $gui_history, $num_items_in_flow ) = @_;

	if ( length $num_items_in_flow ) {

		$gui_history->get_defaults()->{_temp_num_items_in_flow} =
		  $num_items_in_flow;
#		print("gui_history,set_file_status,num_items_in_flow=$num_items_in_flow\n");		  

		return ();

	}
	else {
		print("gui_history,set_file_status, missing iputs\n");
		return ();
	}

}

=head2 sub clear

restore defaults to gui history items

=cut

sub _clear {

	my ( $gui_history, $latest_button, $prior_button ) = @_;

	if ( $latest_button eq 'delete_from_flow_button' ) {

		# the index selected should now be clean

		$flow_select_index_href = {
			_item        => $empty_string,
			_index       => $index_start,
			_name        => 'flow_select_index',
			_most_recent => $current_index_start,
			_earliest    => $earliest_index_start,
			_next        => $next_index_start,
			_prior       => $prior_index_start,
		};

		# update the hash that will be used outside the module
		( $gui_history->get_defaults() )->{_flow_select_index_href} =
		  $flow_select_index_href;

		# print("gui_history, _clear, success\n");
	}

}

=head2 sub _subtract

restore defaults to gui history items

=cut

sub _subtract {

	my ( $gui_history, $button ) = @_;

	if ( $button eq 'add2flow_button' ) {

		# the indeices should be reduced by 1
		$flow_select_index_href->{_earliest} =
		  $flow_select_index_href->{_earliest} - 1;
		$flow_select_index_href->{_prior} =
		  $flow_select_index_href->{_prior} - 1;
		$flow_select_index_href->{_most_recent} =
		  $flow_select_index_href->{_most_recent} - 1;

		# update the hash that will be used outside the module
		( $gui_history->get_defaults() )->{_flow_select_index_href} =
		  $flow_select_index_href;

		print("gui_history, _subtract, success\n");
		print(
"gui_history, _subtract, most_recent = $flow_select_index_href->{_most_recent}\n"
		);
	}

}

sub test {

	print("made it to gui_history\n");
}

=head2 sub view

Writes out internals to a file

=cut

sub view {

	my ($gui_history) = @_;

	my $key_hash_ref;

	my $filename = 'gui_history.txt';
	open( my $fh, '>:encoding(UTF-8)', $filename )
	  or die "Could not open file '$filename' $!";

	print $fh (
		" gui_history, view; 
	 contains main hash which contains all the gui history and \n "
	);

	#attribute values as well\n\n"

# print(" gui_history, view;contains main hash which contains all the gui history and
# attribute values as well\n\n");

	foreach my $key ( sort keys %$gui_history ) {

		# print(" gui_history->{$key} = $gui_history->{$key}\n");

		# print values of the main hash called defaults
		if ( $key eq 'defaults' ) {

# print $fh (" \ngui_history, view; print values of has 'stored' in defaults attribute\n");

			foreach my $sub_key ( sort keys %{ $gui_history->get_defaults() } )
			{

				my $ans = ( $gui_history->get_defaults() )->{$sub_key};

				if ( defined $ans and $ans ne $empty_string ) {
					print $fh (" gui_history->{$key}: $sub_key= $ans\n");

					# print(" gui_history->{$key}: $sub_key= $ans\n");
				}
				else {
					print $fh (" gui_history->{$key}: $sub_key= 'nada'\n");

					# print(" gui_history, view, ans is not available \n");
				}

			}

			# print values of values that are hashes
			if ( ( $gui_history->get_defaults() )->{_FileDialog_type_href} ) {

				# print additional subset: _FileDialog_type_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_FileDialog_type_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};

					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_FileDialog_type_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_FileDialog_type_href})->{$sub2_key}: $sub2_key= 'nada'\n"
						);

						# print(" gui_history, view, ans is not available \n");
					}
				}
			}

			# print values of values that are hashes
			if ( ( $gui_history->get_defaults() )
				->{_FileDialog_button_click_seq_href} )
			{

				# print additional subset: _FileDialog_button_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_FileDialog_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};

					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_FileDialog_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);

					}
					else {

						# print(" gui_history-, view, ans is not available \n");
						print $fh (
" ( (gui_history->{defaults})->{_FileDialog_button_click_seq_href})->{$sub2_key}: $sub2_key= nada \n"
						);
					}
				}
			}

			if ( ( $gui_history->get_defaults() )
				->{_add2flow_button_click_seq_href} )
			{

				# print additional subsets: _add2flow_button_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_add2flow_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};

					if ( defined $ans and $ans ne $empty_string ) {

					# print(" 2. key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_add2flow_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {

						# print(" gui_history-, view, ans is not available \n");
						print $fh (
" ( (gui_history->{defaults})->{_add2flow_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);
					}
				}
			}

			if ( ( $gui_history->get_defaults() )->{_add2flow_button_color_href}
			  )
			{

				# print additional subsets: _add2flow_button_color_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_add2flow_button_color_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					# print(" 3. key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_add2flow_button_color_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {

						# print(" gui_history-, view, ans is not available \n");
						print $fh (
" ( (gui_history->{defaults})->{_add2flow_button_color_href})->{$sub2_key}: $sub2_key= nada\n"
						);
					}
				}
			}

			if ( ( $gui_history->get_defaults() )->{_button_href} ) {

				# print additional subsets: _button_href
				$key_hash_ref = ( $gui_history->{defaults} )->{_button_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_button_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {

						# print(" gui_history-, view, ans is not available \n");
						print $fh (
" ( (gui_history->{defaults})->{_button_href})->{$sub2_key}: $sub2_key= nada\n"
						);
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_delete_from_flow_button_click_seq_href} )
			{

				# print additional subsets: delete_from_flow_button
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_delete_from_flow_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					# print(" 4. key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_delete_from_flow_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_delete_from_flow_button_click_seq_href})->{$sub2_key}: $sub2_key=  nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )
				->{_delete_whole_flow_button_click_seq_href} )
			{

				# print additional subsets: delete_whole_flow_button
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_delete_whole_flow_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					# print(" 4. key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_delete_whole_flow_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_delete_whole_flow_button_click_seq_href})->{$sub2_key}: $sub2_key=  nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )
				->{_flow_item_down_arrow_button_click_seq_href} )
			{

				# print additional subsets: flow_item_down_arrow_button
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_flow_item_down_arrow_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

				  # # print(" 5. key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_item_down_arrow_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_item_down_arrow_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_flow_item_up_arrow_button_click_seq_href} )
			{

				# print additional subsets: flow_item_up_arrow_button
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_flow_item_up_arrow_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_item_up_arrow_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_item_up_arrow_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )->{_flow_select_color_href} ) {

				# print additional subsets: flow_select_color
				$key_hash_ref =
				  ( $gui_history->get_defaults() )->{_flow_select_color_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_color_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_color_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )->{_flow_select_index_href} ) {

				# print additional subsets: flow_select
				$key_hash_ref =
				  ( $gui_history->get_defaults() )->{_flow_select_index_href};

			   # print("25 gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					# print(" 25 key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_index_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_index_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )->{_flow_select_click_seq_href}
			  )
			{

				# print additional subsets: flow_select-seq
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_flow_select_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_flow_select_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )->{_flow_type_href} ) {

				# print additional subset: _flow_type_href
				$key_hash_ref =
				  ( $gui_history->get_defaults() )->{_flow_type_href};

# my $ans =  (( $gui_history->get_defaults() )->{_flow_type_href})->{_most_recent};
# print("gui_history, msot recent flow type = $ans\n");
# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_flow_type_href})->{$sub2_key}: $sub2_key= $ans\n"
						);

# print  (" ( (gui_history->{defaults})->{_flow_type_href})->{$sub2_key}: $sub2_key= $ans\n");
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_flow_type_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )
				->{_parameter_color_on_exit_href} )
			{

			  # print additional subset: _parameter_color_on_exit_click_seq_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_parameter_color_on_exit_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_color_on_exit_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_color_on_exit_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_parameter_color_on_entry_href} )
			{

			 # print additional subset: _parameter_color_on_entry_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_parameter_color_on_entry_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_color_on_entry_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_color_on_entry_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_parameter_index_on_entry_href} )
			{

				# print additional subset: _parameter_index_on_entry_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_parameter_index_on_entry_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_entry_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_entry_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_parameter_index_on_entry_click_seq_href} )
			{

			 # print additional subset: _parameter_index_on_entry_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_parameter_index_on_entry_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_entry_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_touched_color_on_entry_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_parameter_index_on_exit_href} )
			{

			  # print additional subset: _parameter_index_on_exit_click_seq_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_parameter_index_on_exit_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_exit_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_exit_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_parameter_index_on_exit_click_seq_href} )
			{

			  # print additional subset: _parameter_index_on_exit_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_parameter_index_on_exit_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_exit_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_parameter_index_on_exit_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if (
				( $gui_history->get_defaults() )->{_run_button_click_seq_href} )
			{

				# print additional subset: _run_button_click_seq_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_run_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_run_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_run_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )->{_save_button_click_seq_href}
			  )
			{

				# print additional subset: _save_button_click_seq_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_save_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_save_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_save_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_save_as_button_click_seq_href} )
			{

				# print additional subset: _save_as_button_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_save_as_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_save_as_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_save_as_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )->{_sunix_prog_group_href} ) {

				# print additional subset: _sunix_prog_group_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_sunix_prog_group_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_sunix_prog_group_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_sunix_prog_group_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_sunix_prog_group_click_seq_href} )
			{

				# print additional subset: _sunix_prog_group_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_sunix_prog_group_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_sunix_prog_group_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_sunix_prog_group_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )
				->{_superflow_select_button_click_seq_href} )
			{

			  # print additional subset: _superflow_select_button_click_seq_href
				$key_hash_ref = ( $gui_history->{defaults} )
				  ->{_superflow_select_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_superflow_select_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_superflow_select_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}
			if ( ( $gui_history->get_defaults() )->{_superflow_tool_href} ) {

				# print additional subset: _superflow_tool_href
				$key_hash_ref =
				  ( $gui_history->{defaults} )->{_superflow_tool_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};
					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->{defaults})->{_superflow_tool_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->{defaults})->{_superflow_tool_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

			if ( ( $gui_history->get_defaults() )
				->{_wipe_plots_button_click_seq_href} )
			{

				# print additional subsets: _wipe_plots_button
				$key_hash_ref = ( $gui_history->get_defaults() )
				  ->{_wipe_plots_button_click_seq_href};

				# print("gui_history, view, key_hash_ref = $key_hash_ref \n");
				foreach my $sub2_key ( sort keys %{$key_hash_ref} ) {

					my $ans = $key_hash_ref->{$sub2_key};

					if ( defined $ans and $ans ne $empty_string ) {

					   # print(" key_hash_ref->{$sub2_key}: $sub2_key= $ans\n");
						print $fh (
" ( (gui_history->get_defaults() )->{_wipe_plots_button_click_seq_href})->{$sub2_key}: $sub2_key= $ans\n"
						);
					}
					else {
						print $fh (
" ( (gui_history->get_defaults() )->{_wipe_plots_button_click_seq_href})->{$sub2_key}: $sub2_key= nada\n"
						);

						# print(" gui_history-, view, ans is not available \n");
					}
				}
			}

		}
		else {

#			print $fh (" \nNow, print the attribute values, BUT they can not be pritned directly\n");
#			print $fh (" 1.gui_history->{$key} = $gui_history->{$key}\n");
#
#			# print (" 1.gui_history->{$key} = $gui_history->{$key}\n");
#			my $ans = ( $gui_history->get_defaults() )->{_count};
#			print $fh (" 2.gui_history->get_count() = $ans\n");
#			print $fh (" 3.gui_history->get_count() = $gui_history->{_count}\n");
#
#			# print (" 3.gui_history->get_count() = $gui_history->{_count}\n");
		}

	}
	close($fh);
}

# end sub view

__PACKAGE__->meta->make_immutable;
1;
