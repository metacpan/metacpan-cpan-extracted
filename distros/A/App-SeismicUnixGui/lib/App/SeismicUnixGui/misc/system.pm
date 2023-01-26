package App::SeismicUnixGui::misc::system;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: system 
 AUTHOR: 	Juan Lorenzo
 DATE: 		December 1, 2020


 DESCRIPTION 
     Basic class with system attributes

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.1';

=head2 Import modules

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 Instantiation

=cut

my $get          = L_SU_global_constants->new();

=head2 Declare Special Variables

=cut

my $var                 = $get->var();
my $default_param_specs = $get->param();
my $on                  = $var->{_on};
my $true                = $var->{_true};
my $false               = $var->{_false};
my $empty_string        = $var->{_empty_string};
#my @array_ref;
#my @empty_array = (0);    # length=1
#
#my $index_start          = -1;
#my $earliest_index_start = -3;
#my $prior_index_start    = -2;
#my $current_index_start  = -1;
#my $next_index_start     = 0;
#
#my $no_color             = 'no_color';
#my $neutral              = 'neutral';
#my $earliest_color_start = $no_color;
#my $current_color_start  = $no_color;
#my $next_color_start     = $no_color;
#my $prior_color_start    = $no_color;
#
#my $count_start = -1;
#
#
#
#=head2 Declare attributes
#
#=cut
#
#has '_count' => (
#	default   => $count_start,
#	is        => 'ro',
#	isa       => 'Int',
#	reader    => 'get_count',
#	writer    => 'set_count',
#	predicate => 'has_count',
#);
#
#has 'button' => (
#	default   => 'no_button',
#	is        => 'rw',
#	isa       => 'Str',
#	reader    => 'get_button',
#	writer    => 'set_button',
#	predicate => 'has_button',
#	trigger   => \&_update_button,
#);
#
#
#=head2 private anonymous hashes containing 
#sequential history
#
#=cut
#
#my $FileDialog_type_href = {
#	_item        => $empty_string,
#	_index       => $empty_string,
#	_name        => 'FileDialog_type',
#	_most_recent => $empty_string,
#	_earliest    => $empty_string,
#	_next        => $empty_string,
#	_prior       => $empty_string,
#};
#
#
#=
#=head2 sub _update_button
#Assign new button to private key: _XXX_button
#
#print("gui_history, _update_button, ans= $ans\n");
#print("gui_history, _update_button, button= $button\n");
#
#=cut
#
#sub _update_button {
#
#	my ( $gui_history, $new_most_recent_button, $new_new_prior_button ) = @_;
#
#	# my $button = _find_button( $gui_history, $new_most_recent_button );
#
#	if ( $new_most_recent_button ne $empty_string ) {
#
#		if ( defined $button_href ) {
#
#			# update the history of add2flow_button usage according to the color used
#			$button_href->{_earliest}    = $button_href->{_prior};
#			$button_href->{_prior}       = $button_href->{_most_recent};
#			$button_href->{_most_recent} = $new_most_recent_button;
#
#			( $gui_history->get_defaults() )->{_button_href} = $button_href;
#		}
#
#		if ( $new_most_recent_button eq 'FileDialog_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_FileDialog_button} = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$FileDialog_button_click_seq_href
#			);
#
#			# update the history of FileDialog_button use according  to click count
#			( $gui_history->get_defaults )->{_FileDialog_button_click_seq_href} = $FileDialog_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'add2flow_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_add2flow_button} = $true;
#			( $gui_history->get_defaults() )->{_is_add2flow}        = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$add2flow_button_click_seq_href
#			);
#
#			# update the history of add2flow_button use according  to click count
#			( $gui_history->get_defaults() )->{_add2flow_button_click_seq_href}
#				= $add2flow_button_click_seq_href;
#			( $gui_history->get_defaults() )->{_is_new_listbox_selection} = $true;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#		} elsif ( $new_most_recent_button eq 'delete_from_flow_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_delete_from_flow_button} = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$delete_from_flow_button_click_seq_href
#			);
#
#			# update the history of delete_from_flow_button use according  to click count
#			( $gui_history->get_defaults )->{_delete_from_flow_button_click_seq_href}
#				= $delete_from_flow_button_click_seq_href;
#
#			_reset( $gui_history, 'listbox_color_w' );
#
#			# find out the latest color
#			# assume that flow select color is the latest color
#			my $color = _get_most_recent_color_selected_in_gui($gui_history);
#
#			my $key1 = '_is_flow_listbox_' . $color . '_w';
#
#			( $gui_history->get_defaults() )->{$key1} = $true;
#			( $gui_history->get_defaults() )->{_is_flow_listbox_color_w} = $true;
#
#			# print("gui_history, _update_button, delete_from_flow_button \n");
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'flow_item_down_arrow_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_flow_item_down_arrow_button}
#				= $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$flow_item_down_arrow_button_click_seq_href
#			);
#
#			# update the history of flow_item_down_arrow_button use according  to click count
#			( $gui_history->get_defaults )->{_flow_item_down_arrow_button_click_seq_href}
#				= $flow_item_down_arrow_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'flow_item_up_arrow_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_flow_item_up_arrow_button} = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$flow_item_up_arrow_button_click_seq_href
#			);
#
#			# update the history of  flow_item_up_arrow_button use according  to click count
#			( $gui_history->get_defaults )->{_flow_item_up_arrow_button_click_seq_href}
#				= $flow_item_up_arrow_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'flow_select' ) {
#
#			my $ans = ( $gui_history->get_defaults() )->{_count};
#
#			# print("1. gui_history, _update_button, for flow_select count=$ans\n");
#
#			my $_flow_listbox_color_w = _get_flow_listbox_color_w($gui_history);
#			my $most_recent_index     = $flow_widgets->get_flow_selection($_flow_listbox_color_w);
#
#			# CASE 1: flow listbox is cleared with no highlights
#			if ( not defined $most_recent_index ) {
#
#				# no change to indices
#				# increment record sequence as total number of mouse clicks
#				_set_click_sequence(
#					$gui_history,
#					$flow_select_click_seq_href
#				);
#
#				# print("2. gui_history, _update_button, for _flow_listbox_color_w=$_flow_listbox_color_w \n");
#				( $gui_history->get_defaults() )->{_flow_select_click_seq_href}
#					= $flow_select_click_seq_href;
#			}
#
#			# CASE 2 flow listbox must have been selected and have highlighted an element
#			# and the selected index must be different to the previous index
#			# only such case among the many tracked properties of the GUI
#			elsif ( $most_recent_index ne $empty_string
#				and $most_recent_index ne $flow_select_index_href->{_most_recent} ) {
#
#				# update the history of flow_select usage according to the index chosen
#				$flow_select_index_href->{_earliest}    = $flow_select_index_href->{_prior};
#				$flow_select_index_href->{_prior}       = $flow_select_index_href->{_most_recent};
#				$flow_select_index_href->{_most_recent} = $most_recent_index;
#				( $gui_history->get_defaults() )->{_flow_select_index_href} = $flow_select_index_href;
#
#				# print(
#				# 	"2. gui_history, _update_button, for flow_select new most_recent_index=$most_recent_index \n");
#				# print(
#				# 	"2. gui_history, _update_button, for flow_select new prior_index=$flow_select_index_href->{_prior} \n"
#				# );
#
#				# print("gui_history, _update_button, flow_select_click_seq_href= ($gui_history->get_defaults )->{_flow_select_click_seq_href}\n");
#				# print("3. gui_history, _update_button, flow_select most_recent_index=$most_recent_index \n");
#
#				# print("gui_history, _update_button, flow_select_click_seq_href= ($gui_history->get_defaults )->{_flow_select_click_seq_href}\n");
#				# print("3. gui_history, _update_button, button matched = $new_most_recent_button\n");
#
#			} elsif ( $most_recent_index ne $empty_string
#				and $most_recent_index eq $flow_select_index_href->{_most_recent} ) {
#
#				# record sequence as total number of mouse clicks, when user reclicks the same location
#				# However in _set_click_dequence the property indices will not be updated
#				# only the general gui count JML 2-2020
#				_set_click_sequence(
#					$gui_history,
#					$flow_select_click_seq_href
#				);
#
#				# not really reset ??? mystery
#				( $gui_history->get_defaults() )->{_flow_select_click_seq_href}
#					= $flow_select_click_seq_href;
#
#			} else {
#				print(" gui_history, set_button for flow_select, unexpected result \n");
#			}
#
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'run_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_run_button} = $true;
#
#			_set_click_sequence( $gui_history, $run_button_click_seq_href );
#
#			# update the history of run_button use according  to click count
#			( $gui_history->get_defaults )->{_run_button_click_seq_href} = $run_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'save_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_save_button} = $true;
#
#			_set_click_sequence( $gui_history, $save_button_click_seq_href );
#
#			# update the history of save_button use according  to click count
#			( $gui_history->get_defaults )->{_save_button_click_seq_href} = $save_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'save_as_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_save_as_button} = $true;
#
#			_set_click_sequence( $gui_history, $save_as_button_click_seq_href );
#
#			# update the history of  save_as_button use according  to click count
#			( $gui_history->get_defaults )->{_save_as_button_click_seq_href} = $save_as_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'sunix_select' ) {
#
#			( $gui_history->get_defaults() )->{_is_sunix_select}          = $true;
#			( $gui_history->get_defaults() )->{_is_new_listbox_selection} = $true;    # so changes not allowed
#			( $gui_history->get_defaults() )->{_is_sunix_listbox}         = $true;
#
#			# history and sequence is handled by sunix_prog_group_click_seq_href and sunix_select_prog_group_href
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'superflow_select_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_superflow_select_button} = $true;
#			( $gui_history->get_defaults() )->{_is_superflow}               = $true;
#			( $gui_history->get_defaults() )->{_is_pre_built_superflow}     = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$superflow_select_button_click_seq_href
#			);
#
#			# update the history of superflow_select_button use according  to click count
#			( $gui_history->get_defaults )->{_superflow_select_button_click_seq_href}
#				= $superflow_select_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} elsif ( $new_most_recent_button eq 'wipe_plots_button' ) {
#
#			( $gui_history->get_defaults() )->{_is_wipe_plots_button} = $true;
#
#			_set_click_sequence(
#				$gui_history,
#				$wipe_plots_button_click_seq_href
#			);
#
#			# update the history of wipe_plots_button use according  to click count
#			( $gui_history->get_defaults )->{_wipe_plots_button_click_seq_href} = $wipe_plots_button_click_seq_href;
#
#			# print("gui_history, _update_button, button matched = $new_most_recent_button\n");
#			return ();
#
#		} else {
#			print("gui_history,_update_button, button unmatched NADA\n");
#			return ();
#		}
#	} else {
#		print("gui_history,_update_button, button not found:\n");
#		return ();
#	}
#}
#=head2 sub _get_flow_listbox_color_w
#
#
#=cut 
#
#sub _get_flow_listbox_color_w {
#	my ($gui_history) = @_;
#
#	my $flow_color = ( $gui_history->get_defaults() )->{_flow_color};
#
#	my $key = '_flow_listbox_' . $flow_color . '_w';
#
#	my $this_flow_listbox_color_w = ( $gui_history->get_defaults() )->{$key};
#
#	return ($this_flow_listbox_color_w);
#}
#
#
#
#=head2 sub _increment_count
#
# increment the counter
#
#=cut
#
#sub _increment_count {
#
#	my ($gui_history) = @_;
#
#	my $old_count = ( $gui_history->get_defaults() )->{_count};
#
#	# print("gui_history, _increment_count,main_hash old_count=$old_count\n");
#
#	if ( defined $old_count ) {
#
#		my $new_value = $old_count + 1;
#
#		# increment the
#		# $hash key value whose reference is stored in an attribute
#		# called defaults
#		# and increment the '_count' attribute
#		( $gui_history->get_defaults() )->{_count} = $new_value;
#		$gui_history->set_count($new_value);
#
#		my $ans = ( $gui_history->get_defaults() )->{_count};
#
#		# print("gui_history, _increment_count,new value: $ans\n");
#	} else {
#		print("gui_history, _increment_count, count missing \n");
#	}
#
#	# print("gui_history, _increment_count, attribute new value: $ans\n");
#	return ();
#}

=head2 sub _initialize
Default Tk settings
=cut

sub _initialize {
	my ($gui_history) = @_;
	
	#** @method public _initialize ($)
    # ....
    #*   

	my $markers_href = {

		_Data_menubutton                        => '',
		_FileDialog_button_click_seq_href       => '',
		_FileDialog_option                      => '',
		_FileDialog_sub_ref                     => '',
	
	};
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

=head2 BUILDARGS 
Initialize contents
before instantiation.
so superclass  definitions

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

	} else {

		# print(" gui_history,BUILDARGS, unexpected external default value(s) NADA\n");
		my $result = $gui_history->$orig(@_);
		return ($result);
	}
};

=head2 BUILD
Initial checking after instantiation

=cut

sub BUILD {
	my ($gui_history) = @_;

	# _defaults attribute start empty
	# print("1. gui_history,BUILD,initializing with: $gui_history()\n");
	_initialize($gui_history);

	# print("2. gui_history,BUILD,initializing with: $gui_history->get_defaults()\n");

}

__PACKAGE__->meta->make_immutable;
1;
