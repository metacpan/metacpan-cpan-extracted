package App::SeismicUnixGui::misc::save_button;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PACKAGE NAME: save_button.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		May 16 2018 

 DESCRIPTION 
     
 BASED ON:
 
 previous version (V 0.2) of the main L_SU.pl (V 0.3)
 0.02 Nov. 2019  refactoring with gui_history to keep track
 of suer clicks
  
=cut

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES
 V 0.02 refactoring of 2017 version of L_SU.pl

=cut 

=head2 Notes from bash
 
=cut 

use Moose;
our $VERSION = '0.0.2';

use Tk;

#
extends 'App::SeismicUnixGui::misc::gui_history' => { -version => 0.0.2 };
use aliased 'App::SeismicUnixGui::misc::gui_history';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::save';
use aliased 'App::SeismicUnixGui::misc::files_LSU';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::config_superflows';

my $gui_history = gui_history->new();
my $get         = L_SU_global_constants->new();

my $file_dialog_type = $get->file_dialog_type_href();
my $flow_type_h      = $get->flow_type_href();

my $var             = $get->var();
my $on              = $var->{_on};
my $true            = $var->{_true};
my $false           = $var->{_false};
my $superflow_names = $get->superflow_names_h();
my $save_button     = $gui_history->get_defaults();

#print("1. save_button: writing gui_history.txt\n");
#$gui_history->view();

=head2 declare variables

	8 off

=cut

my $message_w;
my $mw;
my $parameter_values_frame;
my $parameter_value_index;
my $values_aref;
my ( $flow_listbox_grey_w, $flow_listbox_green_w );
my $sub_ref;

=head2 sub _user_built_flow_Save_perl_file 
save a unique perl flow built by the user
BUT currently does not see to do anything ?? TODO

=cut

sub _user_built_flow_Save_perl_file {
	my ($self) = @_;

	# print("save_button,_user_built_flow_Save_perl_file\n");
	return ();
}

sub set_param_flow {
	my ( $self, $param_flow_ref ) = @_;

	$save_button->{_param_flow} = &$param_flow_ref;

	# print("set_param_flow, $param_flow_ref\n");

}

#=head2 sub _user_built_flow_SaveAs_perl_file
#
#
#=cut
#
#sub _user_built_flow_SaveAs_perl_file {
#	my ($self) = @_;
#
#	if (   $save_button->{_is_flow_listbox_grey_w}
#		|| $save_button->{_is_flow_listbox_pink_w}
#		|| $save_button->{_is_flow_listbox_green_w}
#		|| $save_button->{_is_flow_listbox_blue_w} ) {
#
#		#		$param_flow						->set_good_values;
#		#		$param_flow						->set_good_labels;
#		#		$save_button->{_good_labels_aref2}		= $param_flow->get_good_labels_aref2;
#		#		$save_button->{_items_versions_aref}	= $param_flow->get_flow_items_version_aref;
#		#		$save_button->{_good_values_aref2} 	= $param_flow->get_good_values_aref2;
#		#		$save_button->{_prog_names_aref} 		= $param_flow->get_flow_prog_names_aref;
#		#
#		#		 		# print("save_button,_prog_names_aref,
#		#		 		# @{$save_button->{_prog_names_aref}}\n");
#		#		# my $num_items4flow = scalar @{$save_button->{_good_labels_aref2}};
#		#
#		#				 # for (my $i=0; $i < $num_items4flow; $i++ ) {
#		#					# print("save_button,_good_labels_aref2,
#		#				# @{@{$save_button->{_good_labels_aref2}}[$i]}\n");
#		#				# }
#		#
#		#				# for (my $i=0; $i < $num_items4flow; $i++ ) {
#		#				#	print("save_button,_good_values_aref2,
#		#				#	@{@{$save_button->{_good_values_aref2}}[$i]}\n");
#		#				#}
#		#				#   print("save_button,_prog_versions_aref,
#		#				#   @{$save_button->{_items_versions_aref}}\n");
#		#
#		# 		$files_LSU	->set_prog_param_labels_aref2($save_button);
#		# 		$files_LSU	->set_prog_param_values_aref2($save_button);
#		# 		$files_LSU	->set_prog_names_aref($save_button);
#		# 		$files_LSU	->set_items_versions_aref($save_button);
#		# 		$files_LSU	->set_data();
#		# 		$files_LSU	->set_message($save_button);
#		#		$files_LSU	->set2pl($save_button); # flows saved to PL_SEISMIC
#		#		$files_LSU	->save();
#		#		$gui_history	->set4_save_button();
#		#		$save_button 			= $gui_history->get_hash_ref();
#
#	}
#	return ();
#}

=head2 sub _Save_pre_built_superflow 
 						
    	  foreach my $key (sort keys %$save_button) {
           print (" save_button,_Save_pre_built_superflow: key is $key, value is $save_button->{$key}\n");
          }	       	
 			print("save_button 2.built_in_flow.pm ONLY save_button superflow_select check_code_button\n");

=cut

sub _Save_pre_built_superflow {
	my ($self) = @_;

	my $save_button_messages = message_director->new();
	my $save                 = save->new();
	my $files_LSU            = files_LSU->new();
	my $config_superflows    = config_superflows->new();

	my $message = $save_button_messages->null_button(0);
	$message_w = $save_button->{_message_w};
	$message_w->delete( "1.0", 'end' );
	$message_w->insert( 'end', $message );

	$gui_history->set_hash_ref($save_button);
	$gui_history->set4start_of_superflow_Save();
	$save_button = $gui_history->get_hash_ref();

# print("1. save_button,_Save_pre_built_superflow,has_used_Save_superflow: $save_button->{_has_used_Save_superflow}\n");
# print("1. save_button,_Save_pre_built_superflow,has_used_SaveAs_button: $save_button->{_has_used_SaveAs_button}\n");
# print("1. save_button,_Save_pre_built_superflow, has_used_Save_button(only for user-built): $save_button->{_has_used_Save_button}\n");

# print("save_button,_Save_pre_built_superflow, values_aref :@{$save_button->{_values_aref}}[0]\n");
# print("2. save_button,_Save_pre_built_superflow,has_used_Save_superflow: $save_button->{_has_used_Save_superflow}\n");
# print("2. save_button,_Save_pre_built_superflow,has_used_SaveAs_button: $save_button->{_has_used_SaveAs_button}\n");
# print("2. save_button,_Save_pre_built_superflow, has_used_Save_button(only for user-built): $save_button->{_has_used_Save_button}\n");
#  print("2. save_button,_Save_pre_built_superflow,_is_Save_button: $save_button->{_is_Save_button}\n");

	if ( $save_button->{_flow_type} eq 'pre_built_superflow' )
	{    # from gui_history

#print("2. save_button, Save_pre_built_superflow,_values_aref: @{$save_button->{_values_aref}}\n");
# print("2. save_button, Save_pre_built_superflow,_labels_aref: @{$save_button->{_labels_aref}}\n");
 my $ans = ${$save_button->{_prog_name_sref}};
# print("3. save_button, _Save_pre_built_superflow, prog_name=: $ans\n");
# consider aliases
		$config_superflows->save($save_button);
		$gui_history->set4superflow_Save();
		$save_button = $gui_history->get_hash_ref();

	}
	else {    # if flow first needs a change to activate
		print(
"save_button,_Save_pre_built_superflow, _is_superflow_select_button = $save_button->{_is_superflow_select_button}\n"
		);
		#
		#		$message          	= $save_button_messages->save_button(0);
		# 	  	$message_w			->delete("1.0",'end');
		# 	  	$message_w			->insert('end', $message);
	}

	$gui_history->set4end_of_superflow_Save();
	$save_button = $gui_history->get_hash_ref();    # returns 89

	return ();
}

=head2 sub _get_dialog_type

e.g, topic can be Save 


=cut

sub _get_dialog_type {
	my ($self) = @_;

	my $topic = $save_button->{_dialog_type};

	# print("save_button, _get_dialog_type = $topic\n");

	if ($topic) {
		return ($topic);

	}
	else {
		print("save_button, _get_dialog_type , missing topic\n");
		return ();
	}
}

=head2 sub _get_flow_type

	user_built_flow
	or
	pre_built_superflow
	
	
=cut

sub _get_flow_type {
	my ($self) = @_;

	my $how_built = $save_button->{_flow_type};

	if ( $save_button->{_flow_type} ) {
		return ($how_built);

	}
	else {
		print("save_button, _get_flow_type , missing topic\n");
		return ();
	}

}

=head2 sub director


 prior to saving
 determine if we are dealing with superflow 
 (" menubutton" widget)   
 - collect and/or access flow parameters
 - default path is the current path

 TODO:
 or with GUI-made flows ("frame widget")
 - collect and/or access flow parameters
 - default path is the current path

DB:
 print("current widget is $LSU->{_current_widget}\n"); 
 
 TODO: improve ENCAPSULATION:
 
 Analysis:
 
 i/p: $parameter_values_frame
 i/p: $L_SU_messages
 i/p: $message
 i/p: $param_flow
 i/p: $L_SU
 i/p: $config_superflows
 
 o/p: $gui_history	->set4start_of_Save_button();
 o/p: $gui_history	->set4_save_button
 o/p: $gui_history	->set4end_of_save_button();
  $L_SU 			= $gui_history->get_hash_ref();
 
 o/p: $L_SU
 o/p: $files_LSU
 
 
 save can be of 3 generic types:
 
 dialog type can be save  (Main menu)
 or SaveAs (FileDialog_button function)
 
 i.e. 'either'
 
 or
 	Save  perl program of user-built flow
 or
 	SaveAs perl program of user-built flow
 or	
 	Save pre-built superflow configuration files
		
=cut

=head2 sub director 

=cut

sub director {
	my ($self) = @_;

	my $flow_type        = _get_flow_type();
	my $save_dialog_type = _get_dialog_type();

	if ( $flow_type eq $flow_type_h->{_user_built} ) {

		# print("save_button, director, is user_built flow_type:$flow_type\n");

		if ( $save_dialog_type eq $file_dialog_type->{_Save} ) {

			# does not seem to do anything
			_user_built_flow_Save_perl_file();

		}
		elsif ( $save_dialog_type eq $file_dialog_type->{_SaveAs} ) {

			# does not seem to be used
			_user_built_flow_SaveAs_perl_file();

		}
		else {
			print(
"save_button, director has a user_built Save or SaveAs problem \n"
			);
		}

	}
	elsif ( $flow_type eq $flow_type_h->{_pre_built_superflow} ) {

#		print("save_button, director, is superflow_type:$flow_type\n");

#		 print("save_button, director, save_dialog_type: $save_dialog_type\n");

		if ( $save_dialog_type eq $file_dialog_type->{_Save} ) {
			_Save_pre_built_superflow();

		}
		elsif ( $save_dialog_type eq $file_dialog_type->{_SaveAs} ) {

			# do nothing ... superflows are not saved under a pseudonym
		}
		else {
			print(
				"save_button, director has superflow Save or SaveAs problem\n");
		}

	}
	else {
		print("save_button, director has a flow-type problem\n");
	}
}

=head2 sub get_all_hash_ref

	return ALL values of the private hash, supposedly
	improtant external widgets have not been reset.. only conditions
	are reset
	TODO: perhaps it is better to have a specific method
		to return one specific widget address at a time?
	}
	
=cut

sub get_all_hash_ref {
	my ($self) = @_;

	if ($save_button) {

# print("save_button, get_hash_ref , save_button->{_flow_color}: $save_button->{_flow_color}\n");
		return ($save_button);

	}
	else {
		print("save_button, get_hash_ref , missing hsave_button hash_ref\n");
	}
}

=head2 sub _save_button_sub_ref

=cut

sub set_save_button_sub_ref {
	my ( $self, $sub_ref ) = @_;

	if ($sub_ref) {
		print("binding  set_save_button_sub_ref, $sub_ref\n");
		$save_button->{_sub_ref} = $sub_ref;

	}
	else {
		print("save_button, set_save_button_sub_ref, missing sub ref\n");
	}
	return ();
}

=head2 sub set_dialog_type

 save can be of 3 generic types:
 
 dialog type can be save  (Main menu)
 or SaveAs (FileDialog_button function)
 
 i.e. 'either'
 
 or
 	save  (perl program of user-built flow
 or
 	saveas perl program of user-built flow
 or	
 	save pre-built superflow configuration files
		
	
=cut

sub set_dialog_type {
	my ( $self, $topic ) = @_;

	if ($topic) {
		$save_button->{_dialog_type} = $topic;

	  # print("save_button, set_dialog_type , $save_button->{_dialog_type} \n");

	}
	else {
		print("save_button, set_dialog_type , missing topic\n");
	}
	return ();
}

=head2 sub set_flow_type

	user_built_flow
	or
	pre_built_superflow
	
=cut

sub set_flow_type {
	my ( $self, $how_built ) = @_;

	if ($how_built) {
		$save_button->{_flow_type} = $how_built;

		# print("save_button, set_flow_type : $save_button->{_flow_type}\n");

	}
	else {
		print("save_button, set_flow_type , missing how_built\n");
	}
	return ();
}

=head2 sub set_hash_ref
	bring in important widget addresses 
	
=cut

sub set_hash_ref {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {
		$gui_history->set_defaults($hash_ref);
		$save_button = $gui_history->get_defaults();

		# print("save_button, set_gui_widgets, missing hash_ref\n");
	}
	return ();
}

=head2 sub set_prog_name_sref

	in order to know what
	_spec file to read for
	behaviors
	
=cut

sub set_prog_name_sref {
	my ( $self, $name_sref ) = @_;

	if ($name_sref) {
		$save_button->{_prog_name_sref} = $name_sref;

# print("save_button, set_prog_name_sref , ${$save_button->{_prog_name_sref}}\n");

	}
	else {
		print("save_button, set_prog_name_sref , missing name\n");
	}
	return ();
}

1;
