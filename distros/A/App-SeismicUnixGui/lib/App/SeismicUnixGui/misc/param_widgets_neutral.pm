package App::SeismicUnixGui::misc::param_widgets_neutral;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: param_widgets_neutral
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE: V 0.0.1 May 6 2018


=head2 DESCRIPTION

   manages the parameter labels, values and their
   checkboxes in the guis

=head2 USE

=head2 Examples

=head2 

=head2 STEPS


=head2 NOTES
	V 0.0.2 Sept. 24 2019 uses gui_history 

=cut

use Moose;
our $VERSION = '0.0.2';
use Tk;
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::check_buttons';


extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::gui_history';

use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';

use aliased 'App::SeismicUnixGui::misc::label_boxes';
use aliased 'App::SeismicUnixGui::misc::value_boxes';

use aliased 'App::SeismicUnixGui::misc::wipe';

my $check_buttons = check_buttons->new();
my $gui_history   = gui_history->new();

my $get                 = L_SU_global_constants->new();
my $default_param_specs = $get->param();
my $var                 = $get->var();
my $on                  = $var->{_on};
my $off                 = $var->{_off};
my $true                = $var->{_true};
my $false               = $var->{_false};
my $nu                  = $var->{_nu};
my $no                  = $var->{_no};
my $empty_string        = $var->{_empty_string};
my $entry_in_switch     = $off;
my $this_color          = 'neutral';

=head2 Declare 
local variables

=cut

my $param_widgets_color_href = $gui_history->get_defaults();
# print("param_widgets_neutral, default_param_specs,first entry num=$default_param_specs->{_first_entry_num}\n");

=head2 sub get_hash_ref

 bring gui history parameters in to share
 and update
 # initialize default parameter values from gui_history
# needed herein
 	
=cut

sub get_hash_ref {

	my ($self) = @_;

	if ($param_widgets_color_href) {

		my $result = $param_widgets_color_href;
		return ($result);

	}
	else {
		print("param_widgets_color,get_hash_ref, missing hash ref\n");
	}

	# print("param_widgets_color,_update_hash_ref: $gui_history->get_defaults()\n");
}

=head2 sub set_hash_ref

 bring gui history parameters in to share
 and update
 	
=cut

sub set_hash_ref {

	my ( $self, $new_hash_ref ) = @_;

	$gui_history->set_defaults($new_hash_ref);
	$param_widgets_color_href = $gui_history->get_defaults();

	#		 print("1. param_widgets_color,_update_hash_ref: ENTERING\n");
	#		 $gui_history->view();

	# print("param_widgets_color,_update_hash_ref: $gui_history->get_defaults()\n");
}

=head2 sub _reset

	private reset of "condition" variables
	do not reset incoming widgets
	
=cut

sub _reset {
	my ($self) = @_;

	$param_widgets_color_href->{_is_flow_listbox_grey_w}     = $false;
	$param_widgets_color_href->{_is_flow_listbox_pink_w}     = $false;
	$param_widgets_color_href->{_is_flow_listbox_green_w}    = $false;
	$param_widgets_color_href->{_is_flow_listbox_blue_w}     = $false;
	$param_widgets_color_href->{_is_flow_listbox_color_w}    = $false;
	$param_widgets_color_href->{_is_add2flow}                = $false;    # needed? double confirmation?
	$param_widgets_color_href->{_is_add2flow_button}         = $false;    # needed? double confirmation?
	$param_widgets_color_href->{_is_delete_from_flow_button} = $false;
	$param_widgets_color_href->{_is_new_listbox_selection}   = $false;
	$param_widgets_color_href->{_is_superflow_select_button} = $false;
	$param_widgets_color_href->{_is_delete_from_flow_button} = $false;
	$param_widgets_color_href->{_is_moveNdrop_in_flow}       = $false;
	$param_widgets_color_href->{_is_sunix_listbox}           = $false;

	return ();
}

=head2 _changes

 to only one parameter
 some changes will be false and should be rejected

 If you are at this subroutine it means that
 a possible change has been detected in
 the Entry Widget

 Currently if we reach this subroutine we 
 will assume that changes always occur to 
 all parameters 
 Somewhere else we will have to
 forcibly check for and accept all changes
 
 changes are only allowed for those sunix programs whose spec files
 have a max_index defined
 
 currently changes in param_widgets_neutral package only works with regular flows 
 and not with pre-built superflows
 
=cut

sub _changes {
	my ( $self, $index ) = @_;
	my $idx = $index;    # individual parameter line

	my $control = control->new();

	# two cases possible
	# in general L_SU

	# print(" 1. param_widgets_neutral, _changes, entry_in_switch is $entry_in_switch\n");

	if ( $param_widgets_color_href->{_current_program_name} ) {
		my $prog_name = $param_widgets_color_href->{_current_program_name};

		if ( $entry_in_switch eq $off ) {    # =0

			$entry_in_switch = $on;

			# my $ans = $self->get_index_on_exit();
			# my $ans = $param_widgets_color_href->{_parameter_index_on_entry};
			# print(" 2. param_widgets_neutral, _changes, exit index=$ans ENTERED INDEX=$idx\n");
			$param_widgets_color_href->{_parameter_index_on_entry} = $idx;

		}
		elsif ( $entry_in_switch eq $on ) {    # i.e., on and set

			$entry_in_switch = $off;

			# my $ans = $param_widgets_color_href->{_parameter_index_on_exit};
			# print(" 3. param_widgets_neutral, _changes, entry index=$ans LEFT INDEX=$idx \n");
			$param_widgets_color_href->{_parameter_index_on_exit} = $idx;

		}
		else {
			print(" param_widgets_neutral, changes, bad switch \n");
		}

		$self->set_hash_ref($param_widgets_color_href);

		# my $ans= ($self->get_hash_ref())->{_parameter_index_on_exit};
		# print(" param_widgets_neutral, changes, prog_name: $prog_name \n");
		# print(" param_widgets_neutral, _changes, _parameter_index_on_exit: $ans \n");
		# $ans= ($self->get_hash_ref())->{_parameter_index_on_entry};
		# print(" param_widgets_neutral, _changes, _parameter_index_on_entry: $ans \n");

		my $max_idx = $control->get_max_index($prog_name);

		# print(" param_widgets_neutral,max_index, $max_idx \n");
		# cautious, index must be reasonable
		if (   $idx >= 0
			&& $idx <= $control->get_max_index($prog_name) )
		{
			_set_entry_change_status($true);
			my $changed_entry = $param_widgets_color_href->{_changed_entry};    #always

			# print("param_widgets_neutral,changes,changed 1-yes 0 -no? $changed_entry\n");
			_update_check_button_setting($idx);

			_set_index_on_entry($idx);
		}

		return ($true);                                                         # for Entry widget to say there is no error

		# second case is when we are using project_selector
		# project_selector does not yet have a max_index defined in a separate module
	}
	else {
		return ($true);    # for Entry widget to say there is no error
	}

}

=head2 sub error_check

 When entry values are in error 

=cut

sub error_check {
	my ($self) = @_;
	print("param_widgets_neutral,error_check return is $true\n");
	return ($true);
}

=head2 sub get_check_buttons_w_aref


=cut

sub get_check_buttons_w_aref {
	my ($self) = @_;

	if ( $param_widgets_color_href->{_check_buttons_w_aref} ) {

		my $check_buttons_w_aref = $param_widgets_color_href->{_check_buttons_w_aref};
		return ($check_buttons_w_aref);

	}
	else {
		print("param_widgets_neutral, get_check_buttons_w_aref, missing check_buttons_w_aref \n");
		return ();
	}
}

=head2 sub 

=cut

sub get_current_program {

	my ( $self, $widget_ref ) = @_;
	my @selection_index = $$widget_ref->curselection();
	my $prog_name       = $$widget_ref->get( $selection_index[0] );

	# print("param_widgets_neutral get_current_program: $prog_name,index:$selection_index[0] \n");
	return ( \$prog_name );
}

=head2 sub get_entry_change_status

=cut

sub get_entry_change_status {
	my @self   = @_;
	my $status = $param_widgets_color_href->{_changed_entry};

	# print("param_widgets_neutral, get_entry_change_status,changed_entry: $param_widgets_color_href->{_changed_entry}\n");
	return ($status);
}

=head2 sub get_labels_w_aref

=cut

sub get_labels_w_aref {
	my ($self) = @_;

	if ( $param_widgets_color_href->{_labels_w_aref} ) {

		my $labels_w_aref = $param_widgets_color_href->{_labels_w_aref};
		return ($labels_w_aref);

	}
	else {
		print("param_widgets_neutral,get_labels_w_aref, missing labels_w_aref \n");
		return ();
	}
}

=head2 sub get_length_check_buttons_on

=cut

sub get_length_check_buttons_on {
	my ($self) = @_;
	my ( $length, $count );
	my $check_buttons_aref = _get_check_buttons_settings_aref();

	# print("param_widgets_neutral,get_length_check_buttons_on, @$check_buttons_aref)\n");
	my @button_settings = @$check_buttons_aref;
	$length = scalar @button_settings;

	for ( my $i = 0, $count = 0; $i < $length; $i++ ) {
		if ( $button_settings[$i] ) {
			if ( $button_settings[$i] eq 'on' ) {
				$count++;
			}
		}
	}

	$length = $count;
	return ($length);
}

=head2 sub get_index_check_buttons_on

=cut

sub get_index_check_buttons_on {
	my ($self) = @_;
	my ( $length, $count );
	my $check_buttons_aref = _get_check_buttons_settings_aref();

	# print("param_widgets_neutral,get_length_check_buttons_on, @$check_buttons_aref)\n");
	my @button_settings = @$check_buttons_aref;
	$length = scalar @button_settings;
	my @saved_index_on;
	my $j = 0;
	for ( my $i = 0, $count = 0; $i < $length; $i++ ) {
		if ( $button_settings[$i] ) {
			if ( $button_settings[$i] eq 'on' ) {
				$saved_index_on[$j] = $i;
				$j++;
			}
		}
	}

	return ( \@saved_index_on );
}

=head2 get_values_w_aref

	return an array widget references

=cut

sub get_values_w_aref {
	my ($self) = @_;

	if ( $param_widgets_color_href->{_values_w_aref} ) {

		my $values_w_aref = $param_widgets_color_href->{_values_w_aref};
		return ($values_w_aref);

	}
	else {
		print("param_widgets_neutral,get_values_w_aref, missing values_w_aref \n");
		return ();
	}
}

sub gui_clean {
	my ($self) = @_;
	
	my $wipe = wipe->new();

	# print("param_widgets_neutral, gui_clean, _values_w_aref, $param_widgets_color_href->{_values_w_aref} \n");
	# print("param_widgets_neutral, gui_clean, _labels_w_aref, $param_widgets_color_href->{_labels_w_aref} \n");
	$wipe->range($param_widgets_color_href);
	$wipe->values();
	$wipe->labels();
	$wipe->check_buttons();

	return ();
}

=head2 sub _max_length_in_gui


=cut 

sub _max_length_in_gui {
	my ($self) = @_;

	my $get = L_SU_global_constants->new();

	my $param             = $get->param();
	my $max_length_in_gui = $param->{_length};

	$param_widgets_color_href->{_length} = $max_length_in_gui;

	return ();

}

=head2 sub _set_length_in_gui


=cut 

sub _set_length_in_gui {
	my ($new_length_in_gui) = @_;

	if ( $new_length_in_gui >= 0 ) {
		$param_widgets_color_href->{_length} = $new_length_in_gui;

	}
	else {
		print("wipe,_set_length_in_gui, unexpected result\n");
	}
	return ();

}

=head2 sub gui_full_clear

clear the gui completely of 61 parameter values
61 = current defaulted maximum number of variables in a list box

=cut

sub gui_full_clear {
	my ($self) = @_;

	my $wipe = wipe->new();

	# print("param_widgets_neutral, gui_full_clear, length used for cleaning $param_widgets_color_href->{_length} \n");
	# print("param_widgets_neutral, gui_clean, _values_w_aref, $param_widgets_color_href->{_values_w_aref} \n");
	# print("param_widgets_neutral, gui_clean, _labels_w_aref, $param_widgets_color_href->{_labels_w_aref} \n");
	# rint("4. param_widgets_neutral, gui_full_clear: writing gui_history.txt\n");
	# gui_history->view();
	
	# print("1. param_widgets_neutral,gui_full_clear, check button settings:--@{$param_widgets_color_href->{_check_buttons_settings_aref}}--\n");
	
	$wipe->full_range($param_widgets_color_href);
	# print("2. param_widgets_neutral,gui_full_clear, check button settings:--@{$param_widgets_color_href->{_check_buttons_settings_aref}}--\n");
	$wipe->values();
	# print("3. param_widgets_neutral,gui_full_clear, check button settings:--@{$param_widgets_color_href->{_check_buttons_settings_aref}}--\n");
	$wipe->labels();
	$wipe->check_buttons();
	
	# print("param_widgets_neutral, gui_full_clear, restored length $param_widgets_color_href->{_length} \n");

	return ();
}

=head2 sub  _set_entry_change_status

=cut

sub _set_entry_change_status {
	my ($ans) = @_;
	$param_widgets_color_href->{_changed_entry} = $ans;

	# print("param_widgets_neutral,_set_entry_change_status,changed_entry,is: success \n");

	return ();
}

=head2 sub _update_check_button_setting

 update for one parameter index 
 in currently active program
 
 Entry widget uses textvariables

=cut

sub _update_check_button_setting {
	my ($index) = @_;
	my $idx     = $index;
	my @values  = @{ $param_widgets_color_href->{_values_aref} };
	my (@on_off);

	# apparently empty cases
	# equal to 0 or 0.0 or empty or undefined
	if ( !( $values[$idx] ) ) {

		# if value is defined and initialized
		if ( defined( $values[$idx] ) ) {

			if ( $values[$idx] eq '0' ) {

				$on_off[$idx] = $on;

				# print("1.20 param_widgets_neutral,,_update_check_button_setting index: $idx , value:$values[$idx] or '0' \n");

			}
			elsif ( $values[$idx] eq '0.0' ) {

				$on_off[$idx] = $on;

				# print("1.21 param_widgets_neutral,_update_check_button_setting, ndex: $idx , value:$values[$idx] or 0.0 \n");

			}
			elsif ( $values[$idx] eq '0' ) {

				$on_off[$idx] = $on;

				# print("1.22 param_widgets_neutral,,_update_check_button_setting index: $idx , value:$values[$idx] or '0' \n");

			}
			elsif ( $values[$idx] eq '0.0' ) {

				$on_off[$idx] = $on;

				# print("1.23 param_widgets_neutral,_update_check_button_setting, ndex: $idx , value:$values[$idx] or 0.0 \n");

			}
			else {

				# print("1.24 param_widgets_neutral,_update_check_button_setting; empty value,  :index $idx value: $values[$idx]\n");
				$on_off[$idx] = $off;
			}

		}
		else {
#			print("param_widgets_neutral,_update_check_button_setting; values not defined\n");
#			print("param_widgets_neutral, = $values[$idx]\n");
			$on_off[$idx] = $off;
		}

		# apparently non-empty cases
	}
	elsif ( $values[$idx] ) {

		if ( $values[$idx] eq "0" ) {

			$on_off[$idx] = $on;

			# print("1.11.23 1 param_widgets_neutral,_update_check_button_setting, index: $idx value: $values[$idx]\n");

		}
		elsif ( $values[$idx] eq '0.0' ) {

			$on_off[$idx] = $on;

			# print("1.12 param_widgets_neutral,_update_check_button_setting, ndex: $idx , value:$values[$idx] or 0.0 \n");

		}
		elsif ( $values[$idx] eq "" ) {

			$on_off[$idx] = $off;

			# print("1.13 param_widgets_neutral,_update_check_button_setting, \"\" \n");

		}
		elsif ( $values[$idx] eq '' ) {

			# print("1.14 param_widgets_neutral,_update_check_button_setting, \'\' \n");
			$on_off[$idx] = $off;

		}
		elsif ( $values[$idx] eq "'nu'" ) {

			$on_off[$idx] = $off;

			# print("1. param_widgets_neutral,_update_check_button_setting, \"\'nu\'\"  \n");

		}
		elsif ( $values[$idx] eq $nu ) {
			$on_off[$idx] = $off;

			# print("1.15 param_widgets_neutral,_update_check_button_setting, \$nu \n");

		}
		elsif ( $values[$idx] eq $no ) {
			$on_off[$idx] = $off;

			# print("2. param_widgets_neutral,_update_check_button_setting, \$no \n");

		}
		elsif ( $values[$idx] eq "'0'" ) {
			$on_off[$idx] = $on;

			# print("2.1 param_widgets_neutral,_update_check_button_setting, \"\'0\'\" \n");

		}
		else {
			# print("3.1 param_widgets_neutral,_update_check_button_setting, all else\n");
			$on_off[$idx] = $on;
		}

	}
	else {
		print("param-widgets,_update_check_button_setting, apparently unconsidered case\n");    # weird TODO
	}

	$check_buttons->set_index($idx);
	$check_buttons->set_switch( \@on_off );

	# update a single change in private hash
	@{ $param_widgets_color_href->{_check_buttons_settings_aref} }[$idx] =
		$on_off[$idx];

	# print("param_widgets_neutral: _update_check_button_setting :index $idx setting is: $on_off[$idx]\n");
	# print("param_widgets_neutral: update_check_buttons_settings_aref @{$param_widgets_color_href->{_check_buttons_settings_aref}}\n");

	return ();
}

=head2 sub _set_index_on_entry

=cut

sub _set_index_on_entry {
	my ($self) = @_;
	$param_widgets_color_href->{_index_on_entry} = $self;

	# print("1. param_widgets_neutral,_set_index_on_entry:  $param_widgets_color_href->{_index_on_entry} \n");
	return ();
}

=head2 sub set_check_buttons
 a widget reference

=cut

sub set_check_buttons {
	my ( $self, $check_buttons_settings_aref ) = @_;
	if ($check_buttons_settings_aref) {
		$param_widgets_color_href->{_check_buttons_settings_aref} = $check_buttons_settings_aref;

#		print("param_widgets_neutral,set_check_buttons, settings are @{$param_widgets_color_href->{_check_buttons_settings_aref}}\n");
	}
	return ();
}

=head2 sub get_current_widget_name

 screen location by using part of the widget name
    print(" self:$self widget: $widget\n");
    print(" currently  focus lies in: $screen_location\n");
    print(" reference: $reference\n");
   foreach my $i (@fields) {
    print(" 2. widget is $i\n");
    my $screen_location = $widget->focusCurrent;
    my $reference       = ref $screen_location;
    print(" 1. widget is $a\n");
    print ( "widget is $fields[-1]\n");
    name is in the last element of the split array 

  if widget_name= frame then we have flow
              $var->{_flow}
  if widget_name= menubutton we have superflow 
              $var->{_tool}
=cut

sub get_current_widget_name {
	my ( $self, $widget_ref ) = @_;
	my @fields = split( /\./, $widget_ref->PathName() );
	my $widget_name = $fields[-1];
	return ($widget_name);
}

=head2 sub get_check_buttons_settings_aref

=cut

sub get_check_buttons_settings_aref {
	my ($self) = @_;

	if ( defined $param_widgets_color_href->{_check_buttons_settings_aref}
		&& $param_widgets_color_href->{_check_buttons_settings_aref} ne $empty_string )
	{

		my $check_buttons_settings_aref =
			\@{ $param_widgets_color_href->{_check_buttons_settings_aref} };
		my $check_buttons_aref = $check_buttons_settings_aref;

		return ($check_buttons_aref);
	}
	else {
		my @check_buttons_aref = ();
		# print("param_widgets,get_check_buttons_settings_aref is empty NADA\n");
		return ( \@check_buttons_aref );
	}

}

#=head2 sub get_check_buttons_settings_aref
#
#=cut
#
#sub get_check_buttons_settings_aref {
#	my ($self)                      = @_;
#	my $check_buttons_settings_aref = \@{ $param_widgets_color_href->{_check_buttons_settings_aref} };
#	my $check_buttons_aref          = $check_buttons_settings_aref;
#
#	# print("param_widgets_neutral,get_check_buttons_settings_aref: @{$param_widgets_color_href->{_check_buttons_settings_aref}}\n");
#	return ($check_buttons_aref);
#}

sub set_entry_button_chosen_index {

	my ( $self, $index ) = @_;
	$param_widgets_color_href->{_entry_button_chosen_index} = $index;

	# print(" param_widgets_neutral,set_entry_button_chosen_index, #$index \n");

}

=head2 sub _get_check_buttons_settings_aref

=cut

sub _get_check_buttons_settings_aref {
	my ($self)                      = @_;
	my $check_buttons_settings_aref = \@{ $param_widgets_color_href->{_check_buttons_settings_aref} };
	my $check_buttons_aref          = $check_buttons_settings_aref;

	# print("param_widgets_neutral,get_check_buttons_settings_aref: @{$param_widgets_color_href->{_check_buttons_settings_aref}}\n");
	return ($check_buttons_aref);
}

sub set_entry_button_chosen_widget {

	my ( $self, $widget_h ) = @_;
	$param_widgets_color_href->{_entry_button_chosen_widget} = $widget_h;

	# print (" param_widgets_neutral,set_entry_button_chosen_widget, #$widget_h \n");

}

=head2 sub get_entry_button_chosen_index 


=cut

sub get_entry_button_chosen_index {

	my ($self) = @_;
	my $index;

	# first and last indices
	my $first  = $param_widgets_color_href->{_first_idx};
	my $length = $param_widgets_color_href->{_length};

	# print("param_widget,get_entry_button_chosen_index,first_index=$param_widgets_color_href->{_first_idx}\n");
	# print("param_widget,get_entry_button_chosen_index,length_=$param_widgets_color_href->{_length} \n");

	my $widget = $param_widgets_color_href->{_entry_button_chosen_widget};

	# print("param_widget,get_entry_button_chosen_index,widget,=$widget\n");

	for ( my $choice = $first; $choice < $length; $choice++ ) {
		if ( $widget eq @{ $param_widgets_color_href->{_values_w_aref} }[$choice] ) {

			$param_widgets_color_href->{_entry_button_chosen_index} = $choice;

			# print (" param_widgets_neutral,get_entry_button_chosen_index, #$choice \n");
			$index = $choice;
		}
	}

	return ($index);
}

=head2 sub get_label4entry_button_chosen

 determine which Entry Button is chosen

    print("param is $entry_param;\n");
         print ("selected widget is # $LSU->{_parameter_value_index}\");
         print ("label is  $out\n");

=cut

sub get_label4entry_button_chosen {
	my ($self) = @_;
	my $label;

	# first and last indices
	my $first  = $param_widgets_color_href->{_first_idx};
	my $length = $param_widgets_color_href->{_length};

	# print("param_widget,get_entry_button_chosen,first_index=$param_widgets_color_href->{_first_idx}\n");
	# print("param_widget,get_entry_button_chosen,length_=$param_widgets_color_href->{_length} \n");

	my $widget = $param_widgets_color_href->{_entry_button_chosen_widget};

	# print("param_widget,get_entry_button_chosen,widget,=$widget\n");

	for ( my $choice = $first; $choice < $length; $choice++ ) {
		if ( $widget eq @{ $param_widgets_color_href->{_values_w_aref} }[$choice] ) {
			my $parameter_value_index = $choice;
			my $parameter_name_index  = $choice;
			$label = @{ $param_widgets_color_href->{_labels_w_aref} }[$choice]->cget('-text');
			my $value =
				@{ $param_widgets_color_href->{_values_w_aref} }[$choice]->get;

			# print("param_widget,get_entry_button_chosen,label,=$label\n");
			# print("param_widget,get_entry_button_chosen,value,=$value\n");
			# print("param_widget,get_entry_button_chosen,index,=$choice\n");
		}
	}
	return ($label);
}

=head2 sub get_value4entry_button_chosen

 determine which Entry Button is chosen

    print("param is $entry_param;\n");
         print ("selected widget is # $LSU->{_parameter_value_index}\");
         print ("label is  $out\n");

=cut

sub get_value4entry_button_chosen {
	my ($self) = @_;
	my $value;

	# first and last indices
	my $first  = $param_widgets_color_href->{_first_idx};
	my $length = $param_widgets_color_href->{_length};

	# print("param_widgets_neutral,get_entry_button_chosen,first_index=$param_widgets_color_href->{_first_idx}\n");
	# print("param_widgets_neutral,get_entry_button_chosen,length_=$param_widgets_color_href->{_length} \n");

	my $widget = $param_widgets_color_href->{_entry_button_chosen_widget};

	# print("param_widgets_neutral,get_entry_button_chosen,widget,=$widget\n");

	for ( my $choice = $first; $choice < $length; $choice++ ) {
		if ( $widget eq @{ $param_widgets_color_href->{_values_w_aref} }[$choice] ) {
			my $parameter_value_index = $choice;
			my $parameter_name_index  = $choice;

			#$label = @{$param_widgets_color_href->{_labels_w_aref}}[$choice]->cget('-text');
			$value = @{ $param_widgets_color_href->{_values_w_aref} }[$choice]->get();

			# print("param_widgets_neutral,get_entry_button_chosen,label,=$label\n");
			# print("param_widgets_neutral,get_entry_button_chosen,value,=$value\n");

			# print("param_widgets_neutral,get_entry_button_chosen,index,=$choice\n");
		}
	}
	return ($value);
}

=head2 sub get_values_aref

	all the values for one program at a time

=cut

sub get_values_aref {
	my ($self) = @_;

	if ( $param_widgets_color_href->{_values_aref} ne $empty_string ) {

		my $values_aref = \@{ $param_widgets_color_href->{_values_aref} };

		# print("param_widgets_neutral,get_values_aref,value[0]= @{$param_widgets_color_href->{_values_aref}}[0]\n");
		return ($values_aref);

	}
	else {
		# print("param_widgets_neutral, get_values_aref,  missing values_aref\n");
	}

}

=head2 sub get_labels_aref

	equivalent to get_naems_aref

=cut

sub get_labels_aref {

	my ($self) = @_;
	my $labels_aref = \@{ $param_widgets_color_href->{_labels_aref} };

	# print("param_widgets_neutral,get_labels_aref: @{$param_widgets_color_href->{_labels_aref}}\n"); # all labels in array may not be there
	return ( $param_widgets_color_href->{_labels_aref} );
}

=head2 sub get_names_aref

	equivalent to get_labels_aref

=cut

sub get_names_aref {

	my ($self) = @_;
	my $labels_aref = \@{ $param_widgets_color_href->{_labels_aref} };

	# print("param_widgets_neutral,get_labels_aref: @{$param_widgets_color_href->{_labels_aref}}\n"); # all labels in array may not be there
	return ( $param_widgets_color_href->{_labels_aref} );
}

=head2 sub initialize_check_buttons

 same set of check buttons for all programs 

=cut

sub initialize_check_buttons {
	my ($self) = @_;
	my ( $first, $length );
	my (@off);

	$first  = $param_widgets_color_href->{_first_idx};
	$length = $param_widgets_color_href->{_length};

	for ( my $i = $first; $i < $length; $i++ ) {
		$off[$i] = 'off';
	}

	$check_buttons->specs($default_param_specs);
	$check_buttons->frame( $param_widgets_color_href->{_check_buttons_frame_href} );
	$check_buttons->make( \@off );

	$param_widgets_color_href->{_check_buttons_w_aref} = $check_buttons->get_w_aref();

	# print("param_widgets, initialize_check_buttons check_buttons_w_aref: $param_widgets_color_href->{_check_buttons_w_aref}\n");

}

=head2 sub initialize_labels


=cut

sub initialize_labels {

	my ($self) = @_;
	my ( $labels, $first, $length );
	my (@blank_labels);

	$labels = label_boxes->new();
	$first  = $param_widgets_color_href->{_first_idx};
	$length = $param_widgets_color_href->{_length};

	# print("param_widgets_neutral,initialize_labels,first:$first\n");
	# print("param_widgets_neutral,initialize_labels,length:$length\n");

	for ( my $i = $first; $i < $length; $i++ ) {
		$blank_labels[$i] = '';
	}

	$labels->specs($default_param_specs);
	$labels->frame( $param_widgets_color_href->{_labels_frame_href} );
	$labels->texts( \@blank_labels );

	$param_widgets_color_href->{_labels_w_aref} = $labels->get_w_aref();
}

=head2 sub initialize_values


=cut

sub initialize_values {
	my ($self) = @_;
	my ( $values, $first, $length );
	my @blank_values = ();

	$values = value_boxes->new();

	$first  = $param_widgets_color_href->{_first_idx};
	$length = $param_widgets_color_href->{_length};

	for ( my $i = $first; $i < $length; $i++ ) {
		$blank_values[$i] = '';
	}

	$values->specs($default_param_specs);
	$values->frame( $param_widgets_color_href->{_values_frame_href} );
	$values->texts( \@blank_values );

	$param_widgets_color_href->{_values_w_aref} = $values->get_w_aref();

}

#=head2 sub range 
#
#	establish the first and last
#    indices of the array
#  	  	 foreach my $key (sort keys %$ref_hash) {
#  			print (" param_widgets_neutral,range, key is $key, value is $ref_hash->{$key}\n");
#  		} 
#
#=cut 
#
#sub range {
#	my ( $self, $ref_hash ) = @_;
#	my $key = '_param_sunix_length';
#
#	#	my $value = $ref_hash->{$key};
#	#	print(" 0. param_widgets_neutral2,range, key is $key, value is $value\n");
#
#	# $gui_history->view();
#
#	# for adding to flows as a user-built flow
#	if (   $param_widgets_color_href->{_is_add2flow_button}
#		|| $param_widgets_color_href->{_is_add2flow} )
#	{
#
#		$param_widgets_color_href->{_param_sunix_first_idx} = $ref_hash->{_param_sunix_first_idx};
#		$param_widgets_color_href->{_first_idx}             = $ref_hash->{_first_idx};
#		$param_widgets_color_href->{_length}                = $ref_hash->{_param_sunix_length};
#
#		print("1.param_widgets_neutral2,range,  (add2flow_button and add2flow)  first idx:$param_widgets_color_href->{_first_idx}, and length:$param_widgets_color_href->{_length}\n");
#	}
#
#	# for sunix selections
#	elsif ( $param_widgets_color_href->{_is_sunix_listbox} ) {
#
#		$param_widgets_color_href->{_first_idx} = $ref_hash->{_param_sunix_first_idx};
#		$param_widgets_color_href->{_first_idx} = $ref_hash->{_first_idx};
#		$param_widgets_color_href->{_length}    = $ref_hash->{_param_sunix_length};
#
#		print("2. param_widgets_neutral,range, (sunix_listbox) first idx:$param_widgets_color_href->{_first_idx}, and length:$param_widgets_color_href->{_length}\n");
#	}
#
#	# for user-built flows, e.g. add2flow is called
#	# but list box is not set yet
#	elsif ($param_widgets_color_href->{_is_flow_listbox_grey_w}
#		|| $param_widgets_color_href->{_is_flow_listbox_pink_w}
#		|| $param_widgets_color_href->{_is_flow_listbox_green_w}
#		|| $param_widgets_color_href->{_is_flow_listbox_blue_w}
#		|| $param_widgets_color_href->{_is_flow_listbox_color_w}
#		|| $param_widgets_color_href->{_is_user_built_flow} )
#	{
#
#		$param_widgets_color_href->{_first_idx} = $ref_hash->{_param_flow_first_idx};
#		$param_widgets_color_href->{_length}    = $ref_hash->{_param_flow_length};
#
#		# bck
#		#		$param_widgets_color_href->{_first_idx} = $ref_hash->{_param_flow_first_idx};
#		#		$param_widgets_color_href->{_length}    = $ref_hash->{_param_flow_length};
#
#		print("3. param_widgets_neutral,range, (user-built-flow)  first idx:$param_widgets_color_href->{_first_idx}, and length:$param_widgets_color_href->{_length}\n");
#	}
#
#	# button for L_SU and no button for project selector
#	elsif ($ref_hash->{_is_superflow_select_button}
#		|| $ref_hash->{_is_superflow} )
#	{
#
#		$param_widgets_color_href->{_first_idx} = $ref_hash->{_superflow_first_idx};
#		$param_widgets_color_href->{_length}    = $ref_hash->{_superflow_length};
#
#		print("4. param_widgets_neutral,range, (superflows) first idx:$param_widgets_color_href->{_first_idx}, and length:$param_widgets_color_href->{_length}\n");
#
#	}
#	else {
#		# print("6. param_widgets_neutral,range, _missing ref_hash NADA\n");
#	}
#
#	# print("6. param_widgets_neutral,range, _values_w_aref:  $param_widgets_color_href->{_values_w_aref}\n");
#	return ();
#}

=head2 sub redisplay_check_buttons 
    
    update colors in check button boxes

=cut

sub redisplay_check_buttons {
	my ($self)        = @_;
	my $button_w_aref = $param_widgets_color_href->{_check_buttons_w_aref};
	my $first         = $param_widgets_color_href->{_first_idx};
	my $length        = scalar @{ $param_widgets_color_href->{_check_buttons_settings_aref} };

	# my $length 			= $param_widgets_color_href->{_length};
	my $settings_aref = $param_widgets_color_href->{_check_buttons_settings_aref};

	# print("1. param_widgets_neutral,redisplay_check_buttons,settings @{$settings_aref}[0]\n");
	# print("2. param_widgets_neutral,redisplay_check_buttons,settings @{$param_widgets_color_href->{_check_buttons_settings_aref}}[0]\n");
	# print("2. param_widgets_neutral,redisplay_check_buttons,length: $length\n");

	if ( $button_w_aref && $settings_aref ) {

		for ( my $i = $first; $i < $length; $i++ ) {

			@$button_w_aref[$i]->configure(
				-onvalue          => 'on',
				-offvalue         => 'off',
				-selectcolor      => 'green',
				-activebackground => 'red',
				-background       => 'red',
				-variable         => \@$settings_aref[$i],
			);
		}
	}
	else {
		print("param_widgets_neutral, redisplay_check_buttons missing parameters\n");
	}
	return ();
}

=head2 sub redisplay_labels 

  print("1. redisplay, resdisplay_labels, text is @{$label_array_ref}[$i]\n");
  print("redisplay, resdisplay_labels, i is $i\n");
  print("2. redisplay, resdisplay_labels, text is @{$LSU->{_label_array_ref}}[$i]\n");

=cut

sub redisplay_labels {
	my ($self)        = @_;
	my $labels_w_aref = $param_widgets_color_href->{_labels_w_aref};
	my $labels_aref   = $param_widgets_color_href->{_labels_aref};
	my $first         = $param_widgets_color_href->{_first_idx};
	my $length        = scalar @{ $param_widgets_color_href->{_labels_aref} };

#	print("param_widgets_neutral,redisplay_labels, length=$length\n");
#	print("param_widgets_neutral,redisplay_labels, first=$first\n");
	
	if (length $labels_w_aref) {
		
		for ( my $i = $first; $i < $length; $i++ ) {

#			print("i:$i   param_widgets_neutral2,redisplay_labels length:$length\n");
#			print(" text is @{$labels_aref}[$i]\n");
#            print(" label array widget $labels_w_aref\n");
            
			@$labels_w_aref[$i]->configure( -text => @$labels_aref[$i], );
		}
	}
	else {
		print("param_widgets_neutral,redisplay labels, Warning parameters or labels_w_aref missing \n");
	}
	return ();
}

=head2 sub redisplay_values 

  display parameter values without quotes
  although internally we always have quotes for strings
  and no quotes if the value looks like a number
  
  i/p: 2 array references
  o/p: array reference

  N.B. This is an ENTRY widget
  textvariables must be a reference in order
  for -validatecommand to work. BEWARE!

  DB

=cut 

sub redisplay_values {

	my ($self)        = @_;
	my $values_w_aref = $param_widgets_color_href->{_values_w_aref};
	my $values_aref   = $param_widgets_color_href->{_values_aref};
	my $first         = $param_widgets_color_href->{_first_idx};
	my $length        = scalar @{ $param_widgets_color_href->{_values_aref} };

	# my $length 				= $param_widgets_color_href->{_length};
	# print("param_widgets_neutral, redisplay_values, length is $length\n");
	if (   $values_w_aref
		&& $values_aref )
	{

		for ( my $i = $first; $i < $length; $i++ ) {

			my $control = control->new();

			# print("1. param_widgets_neutral,redisplay_values,chkbtn @{$param_widgets_color_href->{_check_buttons_settings_aref}}[$i]\n");

			# print("param_widgets_neutral, redisplay_values, i is $i\n");
			# print("1. param_widgets_neutral, redisplay_values, value is @{$values_aref}[$i]\n");

			#  &_changes is invoked if
			#  there is a new selection after an entry change
			#  or even just if redisplay is selected
			#  _changes returns a 0 to invoke an error check
			# -validate				=> 'focusout',

			# remove terminal quotes for values, only for display purposes
			# when later read again the values will be given quotes if they
			# do not look like a number-- this occurs in a superclass
			@{$values_aref}[$i] =
				$control->get_no_quotes( @{$values_aref}[$i] );

			# print("2. param_widgets_neutral, redisplay_values, quoteless value is @{$values_aref}[$i]\n");
			@$values_w_aref[$i]->configure(
				-textvariable    => \@{$values_aref}[$i],
				-validate        => 'all',
				-validatecommand => [ \&_changes, $self, $i ],
				-invalidcommand  => \&error_check,
			);

			# print("2. param_widgets_neutral,redisplay_values,chkbtn @{$param_widgets_color_href->{_check_buttons_settings_aref}}[$i]\n");
		}
	}
	else {
		print("2. param_widgets_neutral,redisplay_values,missing parameters\n");
	}

	# print("param_widgets_neutral, redisplay_values, first item's value is  @{$values_aref}[$first]\n");
	# print("param_widgets_neutral, redisplay_values, last item's values is  @{$values_aref}[($length-1)]\n");
	# print("param_widgets_neutral, redisplay_values, last values are  @{$values_aref}\n");

	return ();
}

=head2 sub set_current_program

	used in main by
	flow_select, 
	sunix_select 
	and delete_from_flow_button

=cut

sub set_current_program {

	my ( $self, $prog_name_sref ) = @_;
	if ($prog_name_sref) {
		$param_widgets_color_href->{_current_program_name} = $$prog_name_sref;

		# print("param_widgets_neutral,set_current_program, program name: $param_widgets_color_href->{_current_program_name}\n");
	}
}

=head2 sub set_first_idx

=0

=cut

sub set_first_idx {

	my ($self) = @_;
	$param_widgets_color_href->{_first_idx} = 0;

	# print("param-widgets,first_idx:$param_widgets_color_href->{_first_idx}\n");
	return ();
}

=head2 sub set_labels_frame

 a widget reference

=cut

sub set_labels_frame {
	my ( $self, $labels_frame_href ) = @_;
	$param_widgets_color_href->{_labels_frame_href} = $labels_frame_href;

}

=head2 sub set_length

 override default length values
 
=cut

sub set_length {

	my ( $self, $length ) = @_;
	if ($length) {

		$param_widgets_color_href->{_length} = $length;

		# print("param_widgets_neutral,set_length = $param_widgets_color_href->{_length}\n");

	}
	else {
		print("param_widgets_neutral,missing length\n");
	}
}

=head2 sub set_check_buttons_w_aref


=cut

sub set_check_buttons_w_aref {
	my ( $self, $check_buttons_w_aref ) = @_;

	if ($check_buttons_w_aref) {

		$param_widgets_color_href->{_check_buttons_w_aref} = $check_buttons_w_aref;

		# print("param_widgets_neutral,set_check_buttons_w_aref, $check_buttons_w_aref \n");

	}
	else {
		print("param_widgets_neutral, set_check_buttons_w_aref,missing check_buttons_w_aref \n");

	}
	return ();
}

=head2 set_labels_w_aref

=cut

sub set_labels_w_aref {
	my ( $self, $labels_w_aref ) = @_;

	if ($labels_w_aref) {

		$param_widgets_color_href->{_labels_w_aref} = $labels_w_aref;

		# print("param_widgets_neutral,set_labels_w_aref, $labels_w_aref \n");

	}
	else {
		print("param_widgets_neutral,set_labels_w_aref, missing labels_w_aref \n");

	}
	return ();
}

=head2 sub set_values_frame

 a widget reference

=cut

sub set_values_frame {

	my ( $self, $values_frame_href ) = @_;

	if ( defined $values_frame_href ) {

		$param_widgets_color_href->{_values_frame_href} = $values_frame_href;

	}
	else {
		print("param_widgets_neutral, set_values_frame, missing  values_frame_href\n");
	}

	return ();
}

=head2 set_values_w_aref

=cut

sub set_values_w_aref {
	my ( $self, $values_w_aref ) = @_;

	if ($values_w_aref) {

		$param_widgets_color_href->{_values_w_aref} = $values_w_aref;

		# print("param_widgets_neutral,set_values_w_aref,  $param_widgets_color_href->{_values_w_aref}\n");

	}
	else {
		print("param_widgets_neutral,set_values_w_aref, missing values_w_aref \n");
	}
	return ();
}

=head2 sub show_values 

packing

=cut

sub show_values {
	my ($self) = @_;
	my ( $first, $length );
	my (@values_w);

	@values_w = @{ $param_widgets_color_href->{_values_w_aref} };
	$first    = $param_widgets_color_href->{_first_idx};
	$length   = $param_widgets_color_href->{_length};

	# print("param_widgets_neutral,show_values,first:$first\n");
	# print("param_widgets_neutral,show_values,length:$length\n");

	for ( my $i = $first; $i < $length; $i++ ) {

		# print("param_widgets_neutral,show_values,values_w at $i $values_w[$i]\n");
		$values_w[$i]->pack(
			-side   => 'top',
			-anchor => 'w',
			-fill   => 'x'
		);
	}
	return ();
}

=head2 sub set_check_buttons_frame
 
 set check_buttons by user from outside 

=cut

sub set_check_buttons_frame {
	my ( $self, $check_buttons_frame_href ) = @_;
	$param_widgets_color_href->{_check_buttons_frame_href} = $check_buttons_frame_href;

	return ();
}

=head2 sub set_entry_change_status 

=cut

sub set_entry_change_status {
	my ( $self, $status ) = @_;
	$param_widgets_color_href->{_changed_entry} = $status;

	# print("param_widgets_neutral, set_entry_change_status: to $status\n");
	return ();
}

=head2 sub set_location_in_gui

 set check_buttons by user from outside 
 
	     	foreach my $key (sort keys %$here) {
   			print (" param_widgets,set_location_in_gui, key is $key, value is $here->{$key}\n");
  		} 

=cut

sub set_location_in_gui {
	my ( $self, $location_href ) = @_;
	my $here = $location_href;

	# print("param_widgets_neutral, set_location_in_gui , _values_w_aref, $param_widgets_color_href->{_values_w_aref} \n");

	if ( $here->{_is_flow_listbox_grey_w} && $here->{_is_add2flow} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_grey_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_grey_w and _is_add2flow \n");

	}
	elsif ( $here->{_is_flow_listbox_grey_w} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_grey_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_grey_w ++ true\n");

	}
	elsif ( $here->{_is_flow_listbox_pink_w} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_pink_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_pink_w ++\n");

	}
	elsif ( $here->{_is_flow_listbox_green_w} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_green_w} = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_green_w ++\n");

	}
	elsif ( $here->{_is_flow_listbox_blue_w} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_blue_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_blue_w ++\n");

	}
	elsif ( $here->{_is_flow_listbox_color_w} ) {

		_reset;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		print("param_widgets_neutral, set_location_in_gui, _is_flow_listbox_color_w\n");

	}
	elsif ( $here->{_is_add2flow} ) {

		$param_widgets_color_href->{_is_new_listbox_selection} = $true;    # so change not allowed
		                                                                   # print("param_widgets_neutral, set_location_in_gui, _is_new_listbox_selection \n");

	}
	elsif ( $here->{_is_add2flow_button} ) {

		_reset;
		$param_widgets_color_href->{_is_new_listbox_selection} = $true;    # so change not allowed
		                                                                   # print("param_widgets_neutral, set_location_in_gui, _is_new_listbox_selection \n");

	}
	elsif ( $here->{_is_sunix_listbox} ) {

		_reset();
		$param_widgets_color_href->{_is_new_listbox_selection} = $true;    # so changes not allowed
		$param_widgets_color_href->{_is_sunix_listbox}         = $true;

		# print("param_widgets_neutral, set_location_in_gui, _is_sunix_listbox and _is_new_listbox_selection\n");

	}
	elsif ( $here->{_is_moveNdrop_in_flow} ) {

		_reset();
		$param_widgets_color_href->{_is_flow_listbox_grey_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_pink_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_green_w} = $true;
		$param_widgets_color_href->{_is_flow_listbox_blue_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;
		$param_widgets_color_href->{_is_moveNdrop_in_flow}    = $true;

		# print("param_widgets_neutral, set_location_in_gui, _is_moveNdrop_in_flow ++ \n");

	}
	elsif ( $here->{_is_delete_from_flow_button} ) {

		_reset();
		$param_widgets_color_href->{_is_delete_from_flow_button} = $true;

		# TODO double check if next 2-5 lines should be flse instead
		$param_widgets_color_href->{_is_flow_listbox_grey_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_pink_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_green_w} = $true;
		$param_widgets_color_href->{_is_flow_listbox_blue_w}  = $true;
		$param_widgets_color_href->{_is_flow_listbox_color_w} = $true;

		# print("param_widgets_neutral, set_location_in_gui, _is_delete_from_flow_button ++\n");

	}
	elsif ( $here->{_is_superflow_select_button} ) {

		_reset();

		# print("param_widgets_neutral,NEW set_location_in_gui, superflow_select_button\n");
		$param_widgets_color_href->{_is_superflow_select_button} = $true;

		# print("param_widgets_neutral, set_location_in_gui, _is_superflow_select_button \n")

	}
	else {
		print("param_widgets_neutral, set_location_in_gui, missing  params \n");
	}
	return ();
}

=head2 sub set_labels 
 
 set labels by user from outside 

=cut

sub set_labels {
	my ( $self, $labels_aref ) = @_;
 #       print("param_widgets_neutral,set_labels\n");
	if ( defined $labels_aref ) {

		$param_widgets_color_href->{_labels_aref} = $labels_aref;

		# my $length = scalar @{ $param_widgets_color_href->{_labels_aref} };
		# print("param_widgets_neutral,set_labels, length=$length\n");

	}
	else {
		print("param_widgets_neutral,set_labels, missinglabels\n")
			;
	}
	return ();
}

=head2 sub set_prog_name_sref 
 set prog_name by user from outside 

=cut

sub set_prog_name_sref {
	my ( $self, $prog_name_sref ) = @_;

	if ($prog_name_sref) {
		$param_widgets_color_href->{_prog_name_sref} = $prog_name_sref;

		print("param_widgets_neutral,set_prog_name_sref, $$prog_name_sref\n");

	}
	else {
		print("param_widgets_neutral, set_prog_name_sref, missing prog name\n");
	}
	return ();
}

=head2 sub set_value4entry_button_chosen

 assign value to  Entry Button chosen

    print("param is $entry_param;\n");
         print ("selected widget is # $LSU->{_parameter_value_index}\");
         print ("label is  $out\n");

=cut

sub set_value4entry_button_chosen {
	my ( $self, $value ) = @_;

	# first and last indices
	my $first  = $param_widgets_color_href->{_first_idx};
	my $length = $param_widgets_color_href->{_length};

	# print("param_widgets_neutral,set_entry_button_chosen,length_=$param_widgets_color_href->{_length} \n");

	my $widget = $param_widgets_color_href->{_entry_button_chosen_widget};
	print("param_widgets_neutral,set_entry_button_chosen,widget,=$widget\n");

	# run through widgets until the match is made
	for ( my $choice = $first; $choice < $length; $choice++ ) {
		if ( $widget eq @{ $param_widgets_color_href->{_values_w_aref} }[$choice] ) {

			@{ $param_widgets_color_href->{_values_w_aref} }[$choice]->configure( -text => $value );

			print("param_widgets_neutral,set_entry_button_chosen,value= @{$param_widgets_color_href->{_values_w_aref}}[$choice]\n");
			print("param_widgets_neutral,set_entry_button_chosen,choice= $choice\n");

		}
	}
	return ($value);
}

=head2 sub set_values 
 
 set values by user from outside 

=cut

sub set_values {
	my ( $self, $values_aref ) = @_;

	if ( defined $values_aref ) {

		$param_widgets_color_href->{_values_aref} = $values_aref;

#		print("param_widgets_neutral,set_values,@{$param_widgets_color_href->{_values_aref}}\n");

	}
	else {
		print("param_widgets_neutral,set_values, values_aref missing\n");
	}

	return ();
}

=head2 sub show_check_buttons 

packing

=cut

sub show_check_buttons {
	my ($self)       = @_;
	my $button_w_ref = $param_widgets_color_href->{_check_buttons_w_aref};
	my $first        = $param_widgets_color_href->{_first_idx};
	my $length       = $param_widgets_color_href->{_length};

	for ( my $i = $first; $i < $length; $i++ ) {
		@$button_w_ref[$i]->pack( -anchor => 'n', -fill => 'y' );
	}
	return ();

}

=head2 sub show_labels 
 
 specs come from local private variables
 uses default specs, unless overwritten
 specs are not fed from above
 
 packing

=cut

sub show_labels {
	my ($self) = @_;
	my ( $first, $length );
	my (@labels_w);

	@labels_w = @{ $param_widgets_color_href->{_labels_w_aref} };
	$first    = $param_widgets_color_href->{_first_idx};
	$length   = $param_widgets_color_href->{_length};

	# print("param_widgets_neutral,show_labels,first:$first\n");
	# print("param_widgets_neutral,show_labels,length:$length\n");
	for ( my $i = $first; $i < $length; $i++ ) {
		$labels_w[$i]->pack(
			-side   => 'top',
			-anchor => 'w',
			-fill   => 'x'
		);
	}
	return ();
}

1;
