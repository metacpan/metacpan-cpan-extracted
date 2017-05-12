
# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::FieldList;

use strict;
use Class::Std;
use Data::Dumper;
use DBR::Config::Trans;
use DBR::Config::Field;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;
use DBR::Admin::Window::RelationshipList;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);



{
    my %fields_of : ATTR( :get<fields> :set<fields>);
    my %field_listbox_of : ATTR( :get<field_listbox> :set<field_listbox>);
    my %table_id_of : ATTR( :get<table_id> :set<table_id>);
    my %schema_id_of : ATTR( :get<schema_id> :set<schema_id>);

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	$self->set_table_id($_args->{table_id});
	$self->set_schema_id($_args->{schema_id});

	my $listbox = $self->get_win->add(
					  'fieldlistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {$self->listbox_item_options(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_field_listbox($listbox);
	$self->load_field_list();
	$self->get_field_listbox->layout();
	$self->get_field_listbox->focus();
	$self->get_win->set_focusorder('fieldlistbox', 'close');
    }

    #######################
    # get the list from the database
    sub get_field_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_fields',
				 -fields => 'field_id table_id name data_type is_nullable is_signed max_value display_name is_pkey index_type trans_id',
				 -where => {table_id => $self->get_table_id()},
				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_fields $!",
						       root_window => $self->get_win->root()
						      );

	#print STDERR Dumper $data;

	my %menu_list;
	my %fields;

	foreach my $e (@$data) {
	    $menu_list{$e->{field_id}} = $e->{name};
	    $fields{$e->{field_id}} = $e;
	}

	$self->set_fields(\%fields);
	return \%menu_list;
    }

    #################
    # load the field list into the
    # field listbox
    sub load_field_list{

	my ($self,  %_args) = @_;

	my $field_listbox = $self->get_field_listbox();
	my $menu_list = $self->get_field_list();
	my @menu_values = sort {$menu_list->{$a} cmp $menu_list->{$b} } keys %{$menu_list};
	$field_listbox->values(\@menu_values);
	$field_listbox->labels($menu_list);
	$self->set_field_listbox($field_listbox);
    }

    ##########################
    # this is the options listbox that appears when a 
    # field is chosen
    sub listbox_item_options {

	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('fieldlistbox_options')) {
	    $self->get_win->delete('fieldlistbox_options');
	}

	

	my $listbox_options = $self->get_win->add(
						  'fieldlistbox_options', 'Listbox',
						  -y => ($_args{listbox}->get_active_id() + 2) - $_args{listbox}->{-vscrollpos} ,
						  -x => 30,
						  -width => 25,
						  -values    => ['Edit', 'Relations'],
						  -onchange => sub { $self->listbox_option_select(
												  listbox => shift, 
												  field_id => $_args{listbox}->get(), 
												  field_listbox => $_args{listbox}
												 );  },
						  -onblur => sub {$self->get_win->delete('fieldlistbox_options');}
						 );
	# $self->get_fields is the fields lookup hash
	# $_args{listbox}->get() is the field_id
	# 1 is an enum type
	if ($self->get_fields->{$_args{listbox}->get()}->{trans_id} == 1) {
	    $listbox_options->insert_at(3, 'Enum Map');
	}

	$listbox_options->focus();
	$listbox_options->onFocus(sub {$listbox_options->clear_selection});
    }

    ##########################
    # called when an option is selected
    sub listbox_option_select {

	my ($self,  %_args) = @_;

	#print STDERR $_args->get();
	

	if  ($_args{listbox}->get eq 'Edit'){
	    $self->edit_field(%_args);
	}
	elsif  ($_args{listbox}->get eq 'Relations'){
	    DBR::Admin::Window::RelationshipList->new(
					    {id => 'relationships', 
					     parent => $self->get_win, 
					     parent_title => ucfirst($self->get_id),
					     field_id => $_args{field_id}, 
					     schema_id => $self->get_schema_id(),
					     table_id => $self->get_table_id(),
					    }
					     );
	}
	elsif  ($_args{listbox}->get eq 'Enum Map'){
	    $self->edit_enum_map(%_args);
	}

    }

    
    #####################
     sub add_new_enum {

 	my ($self,  %_args) = @_;

	my %existing_enums;
	my $max_sortval = 0;
	foreach my $e (@{$_args{current_enums}}) {
	    $existing_enums{$e->{enum_id}} = 1;
	    if ($e->{sortval} > $max_sortval) {
		$max_sortval = $e->{sortval};
	    }
	}

	my $edit_window = $self->get_win->add(
					      'new_enum_window', 'Window',
					      -border => 1,
					      -y    => 1,
					      -bfg  => 'blue',
					      -title => 'New Enum',
					      -titlereverse => 0,
					     );

	my $x = 5;
	my $y = 1;

	# get available enums (not already used) in dropdown

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'enum',
				 -fields => 'enum_id handle name override_id',
				) or  throw DBR::Admin::Exception(
						       message => "failed to select from enum $!",
						       root_window => $self->get_win->root()
						       );

	my $labels;
	my $values;


	foreach my $e (sort { $a->{name} cmp $b->{name} } @$data) {
	    next if $existing_enums{$e->{enum_id}};
	    push @{$values}, $e->{enum_id};
	    $labels->{$e->{enum_id}} = "$e->{name} (handle: $e->{handle}, id: $e->{enum_id}, override: $e->{override_id})";
	}
	my $label = $edit_window->add(
				      "enum_popup_label", 'Label',
				      -text => 'Add Enum: ',
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	my $enum_popup = $edit_window->add(
					 "type_popup", 'Popupmenu',
					 -y => $y,
					 -x => ($x + 16) ,
					 -values => $values,
					 -labels => $labels,
					);
					 
	
	$enum_popup->focus();
	
	$y += 3;


	# submit - cancel
	my $submit_button = $edit_window->add(
					      'submit', 'Buttonbox',
					      -buttons   => [
							   { 
							    -label => '< Submit >',
							    -value => 1,
							    -shortcut => 1 ,
							    -onpress => sub {
								$self->submit_new_enum(original_args => $_args{original_args},
										       enum_id => $enum_popup->get(),
										       name => 'new_enum_window',
										       edit_window => $edit_window,
										       max_sortval => $max_sortval,
										      );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window, name => 'new_enum_window')}
							   }
							       	
							    ],
					      -x => 6,
					      -y => $y,
								
					     );

	 $submit_button->draw();

    }


     ####################
    sub submit_new_enum {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;

	# insert

	$ret = $dbrh->insert(
			     -table => 'enum_map',
			     -fields => {
					 field_id => $_args{original_args}->{field_id},
					 enum_id => $_args{enum_id},
					 sortval => $_args{max_sortval} + 1,
					},
			    ) or throw DBR::Admin::Exception(
						   message => "failed to insert into enum_map",
						   root_window => $self->get_win->root()
						      );
	


	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "The enum has been successfully added",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# close window
	$self->close_edit_window(%_args);
	$self->edit_enum_map(%{$_args{original_args}});
	
    }

    #####################
     sub edit_enum_map {

 	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('emun_map_editwindow')) {
	    $self->get_win->delete('emun_map_editwindow');
	}

 	my $edit_window = $self->get_win->add(
 					       'emun_map_editwindow', 'Window',
 					       -border => 1,
 					       -y    => 1,
 					       -bfg  => 'blue',
 					       -title => 'Edit Enum Map',
 					       -titlereverse => 0,
 					      );




	my $enum_map_aref = _get_enum_map(%_args);
 	my $x = 5;
 	my $y = 1;
	my $enum_map_textboxes;
	my $first_index;

	my $add_button = $edit_window->add(
					      'add', 'Buttonbox',
					      -buttons   => [
							   { 
							    -label => '< Add New Enum >',
							    -onpress => sub { $self->add_new_enum(original_args => \%_args, 
												  current_enums => $enum_map_aref) }
							   }
							       	
							    ],
					      -x => $x,
					      -y => $y,
								
					     );

	$y += 3;

	my $delete_button;
	foreach my $e (sort { $a->{sortval} <=> $b->{sortval}  } @$enum_map_aref) {

	    if (!defined $first_index) {
		$first_index = $e->{row_id};
	    }

	    my $label = $edit_window->add(
					  "enum_map_label" . $e->{row_id}, 'Label',
					  -text => $e->{name},
					  -x => $x,
					  -y => $y
					 );

	    $label->draw;

	    $enum_map_textboxes->{$e->{row_id}} = $edit_window->add(
								    "enum_map_text_box" . $e->{row_id}, 'TextEditor',
								    -sbborder => 1,
								    -y => $y,
								    -x => ($x + 30) ,
								    -readonly => 0,
								    -singleline => 1,
								    -width => 10,
								    -text => $e->{sortval}
								   );
	    $enum_map_textboxes->{$e->{row_id}}->draw();

	    
	    $delete_button->{$e->{row_id}} = $edit_window->add(
					      'delete' . $e->{row_id}, 'Buttonbox',
					      -buttons   => [
							   { 
							    -label => '< Delete this enum >',
							    -onpress => sub { $self->delete_enum(original_args => \%_args, 
												 row_id => $e->{row_id}) }
							   }
							       	
							    ],
					      -x => $x + 40,
					      -y => $y,
								
					     );

	    $y += 1;
	}

	$y += 2;
	#####
	# buttons
	my $submit_button = $edit_window->add(
					      'submit', 'Buttonbox',
					      -buttons   => [
							   { 
							    -label => '< Submit >',
							    -value => 1,
							    -shortcut => 1 ,
							    -onpress => sub {
								$self->submit_edit_enum_map(
											    textboxes => $enum_map_textboxes,
											    name => 'emun_map_editwindow',
											    edit_window => $edit_window,
											   );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window, name => 'emun_map_editwindow')}
							   }
							       	
							    ],
					      -x => 6,
					      -y => $y,
								
					     );
	$submit_button->draw();
	$edit_window->focus();
#	$enum_map_textboxes->{$first_index}->focus();

    }

     ####################
    sub delete_enum {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;

	# insert

	$ret = $dbrh->delete(
			     -table => 'enum_map',
			     -where => {row_id => $_args{row_id} }
			    ) or throw DBR::Admin::Exception(
						   message => "failed to insert into enum_map",
						   root_window => $self->get_win->root()
						      );
	


	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "The enum has been successfully delete",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );


	$self->edit_enum_map(%{$_args{original_args}});
	
    }

   #######################
    # called when the submit button on the
    # add/edit window is selected
    sub submit_edit_enum_map {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;

	# validate
	my %seen;
	my $error;
	foreach my $e (keys %{$_args{textboxes}}) {
	    my $sortval = $_args{textboxes}->{$e}->get();
	    $sortval =~ s/\s//g;
	    if ($sortval =~ /\D/) {
		$error = 'Sort values can be numbers only';
		last;
	    }
	    if ($seen{$sortval}) {
		$error = "Duplicate sort value entered: $sortval";
		last;
	    }
	    $seen{$sortval} = 1;
	}
	
	if ($error) {
	    	my $oops = $self->get_win->root->dialog(
						   -message   => $error,
						   -title     => "Error", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );
		return;
	}


	#ok, it's all good, update
	foreach my $e (keys %{$_args{textboxes}}) {
	    my $sortval = $_args{textboxes}->{$e}->get();
	    $sortval =~ s/\s//g;

	
	    $ret = $dbrh->update(
				 -table => 'enum_map',
				 -fields => {
					     sortval => $sortval,
					    },
				 -where => {row_id => $e}
				) or throw DBR::Admin::Exception(
						       message => "failed to update enum_map",
						       root_window => $self->get_win->root()
						      );
	}


	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "The enum map has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# close window
	$self->close_edit_window(%_args);
	
    }

     ####################
     sub _get_enum_map {
	 my (%_args) = @_;

	 my $dbrh = DBR::Admin::Utility::get_dbrh();

	 my $data = $dbrh->select(
				  -table => {
					     'm' => 'enum_map',
					     'e' => 'enum',
					    },
				  -fields => 'm.row_id m.field_id m.enum_id m.sortval e.name',
				  -where => {
					     'm.field_id' => $_args{field_id},
					     'm.enum_id' => ['j', 'e.enum_id']
					    }

				 );

	 return $data;

     }


     #####################
     sub edit_field {

 	my ($self,  %_args) = @_;

 	my $edit_window =  $self->get_win->add(
 					       'fieldeditwindow', 'Window',
 					       -sbborder => 1,
 					       -y    => 1,
 					       -bfg  => 'blue',
 					       -title => 'Edit Field',
 					       -titlereverse => 0,
 					      );

	$edit_window->focus();

	############
	# readonly
	my $field_hash = $self->get_fields->{$_args{field_id}};

 	my @readonly_fields = qw(
 			        field_id table_id name is_nullable is_signed max_value is_pkey index_type data_type
			       );

 	my $x = 5;
 	my $y = 1;
 	foreach my $f (@readonly_fields) {
	
 	    my $label = $edit_window->add(
 					  $f . "_label", 'Label',
 					  -text => "$f: ",
 					  -x => $x,
 					  -y => $y
 					 );

 	    $label->draw;

 	    my $text_box = $edit_window->add(
 					     $f . "_text_box", 'TextEditor',
 					     -sbborder => 0,
 					     -y => $y,
 					     -x => ($x + 16) ,
 					     -readonly => 1,
 					     -singleline => 1,
 					     -text => $field_hash->{$f}
 					    );
 	    $text_box->draw();
	    $y += 1;
 	}

	$y += 2;
	######
	# editable fields
	my $label = $edit_window->add(
				      "display_name_label", 'Label',
				      -text => "display_name: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	my $display_text_box = $edit_window->add(
					 "display_name_text_box", 'TextEditor',
					 -sbborder => 1,
					 -y => $y,
					 -x => ($x + 16) ,
					 -readonly => 0,
					 -singleline => 1,
					 -text => $field_hash->{display_name}
					);
	$y += 3;

	######
	$label = $edit_window->add(
				      "trans_id_label", 'Label',
				      -text => "trans_id: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	
	my ($values, $labels, $selected) = _get_popup_menu_values(DBR::Config::Trans::list_translators(), $field_hash, 'trans_id');

	my $trans_id = $edit_window->add(
					 "trans_id_popup", 'Popupmenu',
					 -y => $y,
					 -x => ($x + 16) ,
					 -values => $values,
					 -labels => $labels,
					 -selected => $selected,
					);
					 
	
	$trans_id->draw();

	$y += 3;

	#####
	# buttons
	my $submit_button = $edit_window->add(
					      'submit', 'Buttonbox',
					      -buttons   => [
							   { 
							    -label => '< Submit >',
							    -value => 1,
							    -shortcut => 1 ,
							    -onpress => sub {
								$self->submit_edit(
										   field_id => $_args{field_id},
										   display_name => $display_text_box->get(),
										   trans_id => $trans_id->get(),
										   edit_window => $edit_window,
										   name => 'fieldeditwindow',
										  );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window, name => 'fieldeditwindow')}
							   }
							       	
							    ],
					      -x => 6,
					      -y => $y,
								
					     );
	$submit_button->draw();

	$display_text_box->focus();

     }

   #######################
    # called when the submit button on the
    # add/edit window is selected
    sub submit_edit {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;
	

	$ret = $dbrh->update(
			     -table => 'dbr_fields',
			     -fields => {
					 trans_id => $_args{trans_id},
					 display_name => $_args{display_name}
					},
			     -where => {field_id => $_args{field_id}}
			    ) or throw DBR::Admin::Exception(
						       message => "failed to update dbr_fields",
						       root_window => $self->get_win->root()
						      );


	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "This field has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# reset the field list
	$self->load_field_list();

	# close window
	$self->close_edit_window(%_args);
	
    }

    #######################
    sub close_edit_window {

	my ($self,  %_args) = @_;

	$_args{edit_window}->parent->delete($_args{name});
	$_args{edit_window}->parent->draw();
	$_args{edit_window}->parent->focus();
    }

     #############
      sub _get_popup_menu_values {
	  my ($value_ref, $lookup, $key) = @_;

	my %values;
	foreach my $t (@$value_ref) {
	    $values{$t->{id}} = $t->{name} || $t->{handle};
	}
	my @vals = keys %values;
	# find the index of the selected value in @vals
	my $index = 0;
	my $found = 0;
	foreach my $v (@vals) {
	    if ($v == $lookup->{$key}) {
		$found = 1;
		last;
	    }
	    $index++;
	}

	if (!$found) {
	    $index = undef;
	}
	  
	  return (\@vals, \%values, $index);
      }

}

1;
