# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.



package DBR::Admin::Window::RelationshipList;

use strict;
use Class::Std;
use Data::Dumper;
use DBR::Config::Relation;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);



{
    my %relationship_of : ATTR( :get<relationship> :set<relationship>);
    my %relationship_listbox_of : ATTR( :get<relationship_listbox> :set<relationship_listbox>);
    my %field_id_of : ATTR( :get<field_id> :set<field_id>);
    my %table_id_of : ATTR( :get<table_id> :set<table_id>);
    my %schema_id_of : ATTR( :get<schema_id> :set<schema_id>);

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	$self->set_field_id($_args->{field_id});
	$self->set_schema_id($_args->{schema_id});
	$self->set_table_id($_args->{table_id});

	my $new_relationship_button = $self->get_win->add(
						  'newrelationship', 'Buttonbox',
						  -buttons   => [
							       { 
								-label => '< Add New Relationship >',
								-value => 1,
								-shortcut => 1 ,
								-onpress => sub {$self->add_edit_relationship(add => 1)}
								
							       },
								],
						  -x => 40,
						  -y => 1,
								
						 );

	$new_relationship_button->draw();

	my $listbox = $self->get_win->add(
					  'relationshiplistbox', 'Listbox',
					  -y => 2,
					  -vscrollbar => 1,
					  -onchange => sub {$self->add_edit_relationship(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_relationship_listbox($listbox);
	$self->load_relationship_list();
	$self->get_relationship_listbox->layout();
	$self->get_relationship_listbox->focus();
	$self->get_win->set_focusorder('relationshiplistbox', 'newrelationship', 'close');
    }

    #######################
    # get the list from the database
    sub get_relationship_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_relationships',
				 -fields => 'relationship_id from_name from_table_id from_field_id to_name to_table_id to_field_id type',
#				 -where => [[{to_field_id => $self->get_field_id},{from_field_id => $self->get_field_id}]]
				 -where => {from_field_id => $self->get_field_id},

				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_relationships",
						       root_window => $self->get_win->root()
						      );

	#print STDERR Dumper $data;

	my %menu_list;
	my %relationship;

	foreach my $e (@$data) {
	    $menu_list{$e->{relationship_id}} = $e->{from_name} . ' -> ' . $e->{to_name};
	    $relationship{$e->{relationship_id}} = $e;
	}

	$self->set_relationship(\%relationship);
	return \%menu_list;
    }

    #################
    # load the relationship list into the
    # relationship listbox
    sub load_relationship_list{

	my ($self,  %_args) = @_;

	my $relationship_listbox = $self->get_relationship_listbox();
	my $menu_list = $self->get_relationship_list();
	my @menu_values = keys %{$menu_list};
	$relationship_listbox->values(\@menu_values);
	$relationship_listbox->labels($menu_list);
	$self->set_relationship_listbox($relationship_listbox);
    }





    #####################
    sub add_edit_relationship {

 	my ($self,  %_args) = @_;

 	my $edit_window =  $self->get_win->add(
 					       'relationshipeditwindow', 'Window',
 					       -border => 1,
 					       -y    => 1,
 					       -bfg  => 'blue',
 					       -title => 'Edit Relationship',
 					       -titlereverse => 0,
 					      );

	$edit_window->focus();

 	my $x = 5;
 	my $y = 1;
	my $relationship_hash = {};
	if ($_args{add}) {
	    $relationship_hash = {
				  from_table_id => $self->get_table_id(),
				  from_field_id => $self->get_field_id(),
				 };
	}
	else {
	    $relationship_hash = $self->get_relationship->{$_args{listbox}->get()};
	}



	##################
	# from

	my $label = $edit_window->add(
				      "from_name_label", 'Label',
				      -text => "from_name: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	my $from_text_box = $edit_window->add(
					 "from_name_text_box", 'TextEditor',
					 -sbborder => 1,
					 -y => $y,
					 -x => ($x + 16) ,
					 -readonly => 0,
					 -singleline => 1,
					 -text => $relationship_hash->{from_name}
					);
	$y += 1;

	######
	$label = $edit_window->add(
				      "from_table_id_label", 'Label',
				      -text => "from_table: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

 	my ($values, $labels, $selected) = _get_table_popup_menu_values($relationship_hash, $self->get_schema_id(), 'from_table_id', $self->get_win->root());
 	my $from_field_id_popup; # need to declare this now and use it later
 	my $from_field_popup_x = $x+16;
 	my $from_field_popup_y = $y+1;
 	my $from_table_id_popup = $edit_window->add(
 						    "from_table_id_popup", 'Popupmenu',
 						    -y => $y,
 						    -x => ($x + 16) ,
 						    -values => $values,
 						    -labels => $labels,
 						    -selected => $selected,
 						    -onchange => sub {$from_field_id_popup =  $self->reload_field_popup(popup => $from_field_id_popup, 
 														  relationship_hash => $relationship_hash, 
 														  key => 'from_field_id',
 														  table_popup => shift,
 														  y => $from_field_popup_y,
 														  x => $from_field_popup_x,
 														  name => 'from_field_id_popup',
 														  edit_window => $edit_window,
 														 );
 								  }
 						   );
					 
	
 	$from_table_id_popup->draw();

 	$y += 1;

 	######
 	$label = $edit_window->add(
 				      "from_field_label", 'Label',
 				      -text => "from_field: ",
 				      -x => $x,
 				      -y => $y
 				     );

 	$label->draw;

	
 	my ($values, $labels, $selected) = _get_field_popup_menu_values($relationship_hash, 
 									$from_table_id_popup->get(), 
 									'from_field_id', 
 									$self->get_win->root()
 								       );

 	$from_field_id_popup = $edit_window->add(
 						 "from_field_id_popup", 'Popupmenu',
 						 -y => $y,
 						 -x => ($x + 16) ,
 						 -values => $values,
 						 -labels => $labels,
 						 -selected => $selected,
 						);
					 
	
 	$from_field_id_popup->draw();


	$y += 1;


	#################
	# to
	my $label = $edit_window->add(
				      "to_name_label", 'Label',
				      -text => "to_name: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	my $to_text_box = $edit_window->add(
					 "to_name_text_box", 'TextEditor',
					 -sbborder => 1,
					 -y => $y,
					 -x => ($x + 16) ,
					 -readonly => 0,
					 -singleline => 1,
					 -text => $relationship_hash->{to_name}
					);
	$y += 1;

	######
	$label = $edit_window->add(
				      "to_table_id_label", 'Label',
				      -text => "to_table: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	
	my ($values, $labels, $selected) = _get_table_popup_menu_values($relationship_hash, $self->get_schema_id(), 'to_table_id', $self->get_win->root());
	my $to_field_id_popup; # need to declare this now and use it later
	my $to_field_popup_x = $x+16;
	my $to_field_popup_y = $y+1;
	my $to_table_id_popup = $edit_window->add(
					      "to_table_id_popup", 'Popupmenu',
					      -y => $y,
					      -x => ($x + 16) ,
					      -values => $values,
					      -labels => $labels,
					      -selected => $selected,
					      -onchange => sub { $to_field_id_popup = $self->reload_field_popup(popup => $to_field_id_popup, 
														relationship_hash => $relationship_hash, 
														key => 'to_field_id',
														table_popup => shift,
														y => $to_field_popup_y,
														x => $to_field_popup_x,
														name => 'to_field_id_popup',
														edit_window => $edit_window,
													       );
					      }
						   );
					 
	
	$to_table_id_popup->draw();

	$y += 1;

	######
	$label = $edit_window->add(
				      "to_field_label", 'Label',
				      -text => "to_field: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	
	my ($values, $labels, $selected) = _get_field_popup_menu_values($relationship_hash, $to_table_id_popup->get(), 'to_field_id', $self->get_win->root());

	$to_field_id_popup = $edit_window->add(
					 "to_field_id_popup", 'Popupmenu',
					 -y => $y,
					 -x => ($x + 16) ,
					 -values => $values,
					 -labels => $labels,
					 -selected => $selected,
					);
					 
	
	$to_field_id_popup->draw();

	$y += 1;

	#############
	# type
	$label = $edit_window->add(
				      "type_label", 'Label',
				      -text => "type: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	
	my ($values, $labels, $selected) = _get_popup_menu_values(DBR::Config::Relation::list_types(), $relationship_hash, 'type');

	my $type_popup = $edit_window->add(
					 "type_popup", 'Popupmenu',
					 -y => $y,
					 -x => ($x + 16) ,
					 -values => $values,
					 -labels => $labels,
					 -selected => $selected,
					);
					 
	
	$to_field_id_popup->draw();
	
	$y += 1;

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
										   add => $_args{add},
										   relationship_id => $_args{listbox} ? $_args{listbox}->get() : undef,
										   edit_window => $edit_window,
										   from_name => $from_text_box->get(),
										   from_table_id => $from_table_id_popup->get(),
										   from_field_id => $from_field_id_popup->get(),
										   to_name => $to_text_box->get(),
										   to_table_id => $to_table_id_popup->get(),
										   to_field_id => $to_field_id_popup->get(),
										   type => $type_popup->get(),
										   
										  );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window)}
							   }
							       	
							    ],
					      -x => 6,
					      -y => $y,
								
					     );
	$submit_button->draw();

	$from_text_box->focus();

     }

   #######################
    # called when the submit button on the
    # add/edit window is selected
    sub submit_edit {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;

	#print STDERR "submit\n";
	#print STDERR Dumper \%_args;
	

	if ($_args{add}) {
	    $ret = $dbrh->insert(
				 -table => 'dbr_relationships',
				 -fields => {
					     from_name => $_args{from_name},
					     from_table_id => $_args{from_table_id},
					     from_field_id => $_args{from_field_id},
					     to_name => $_args{to_name},
					     to_table_id => $_args{to_table_id},
					     to_field_id => $_args{to_field_id},
					     type => $_args{type}
					    },
				) or throw DBR::Admin::Exception(
						       message => "failed to insert into dbr_relationships",
						       root_window => $self->get_win->root()
						      );
	    
	} else {
	    
	
	    $ret = $dbrh->update(
				 -table => 'dbr_relationships',
				 -fields => {
					     from_name => $_args{from_name},
					     from_table_id => $_args{from_table_id},
					     from_field_id => $_args{from_field_id},
					     to_name => $_args{to_name},
					     to_table_id => $_args{to_table_id},
					     to_field_id => $_args{to_field_id},
					     type => $_args{type}
					    },
				 -where => { relationship_id => $_args{relationship_id} }
				) or throw DBR::Admin::Exception(
						       message => "failed to update dbr_relationships",
						       root_window => $self->get_win->root()
						      );
	}

	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => $_args{add} ? "This relationship has been successfully added." : 
						   "This relationship has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# reset the relationship list
	$self->load_relationship_list();

	# close window
	$self->close_edit_window(%_args);
	
    }

    #######################
    sub close_edit_window {

	my ($self,  %_args) = @_;

	$_args{edit_window}->parent->delete('relationshipeditwindow');
	$_args{edit_window}->parent->draw();
	$_args{edit_window}->parent->focus();
    }


    #########################
    sub reload_field_popup{
	my ($self,  %_args) = @_;

	my ($values, $labels, $selected) = _get_field_popup_menu_values($_args{relationship_hash}, $_args{table_popup}->get(), $_args{key}, $self->get_win->root());


	# have to do it this way beacause Curses::UI::Popupmenu doesn't have values, labels and selected
	# methods like listbox does.  :(

	$_args{edit_window}->delete($_args{name});

	$_args{popup} = $_args{edit_window}->add(
					 $_args{name}, 'Popupmenu',
					 -y => $_args{y},
					 -x => $_args{x} ,
					 -values => $values,
					 -labels => $labels,
					 -selected => $selected,
					);
					 
	$_args{popup}->draw();


	$_args{edit_window}->set_focusorder('from_name_text_box', 
					    'from_table_id_popup', 
					    'from_field_id_popup', 
					    'to_name_text_box', 
					    'to_table_id_popup', 
					    'to_field_id_popup',
					    'type_popup',
					    'submit');
	return $_args{popup};
    }



    #############
    sub _get_table_popup_menu_values {
	my ($relationship_hash, $schema_id, $key, $root) = @_;



	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_tables',
				 -fields => 'table_id  name display_name ',
				 -where => {schema_id => $schema_id},
				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_tables",
						       root_window => $root,
						      );


	my %values;
	foreach my $t (@$data) {
	    $values{$t->{table_id}} = $t->{display_name} || $t->{name};
	}

	my @vals = keys %values;

	# find the index of the selected value in @vals
	my $index = 0;
	my $found = 0;
	foreach my $v (@vals) {
	    if ($v == $relationship_hash->{$key}) {
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




    #############
    sub _get_field_popup_menu_values {
	my ($relationship_hash, $table_id, $key, $root) = @_;



	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_fields',
				 -fields => 'field_id  name display_name ',
				 -where => {table_id => $table_id},
				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_fields",
						       root_window => $root,
						      );


	my %values;
	foreach my $t (@$data) {
	    $values{$t->{field_id}} = $t->{display_name} || $t->{name};
	}

	my @vals = keys %values;


	# find the index of the selected value in @vals
	my $index = 0;
	my $found = 0;
	foreach my $v (@vals) {
	    if ($v == $relationship_hash->{$key}) {
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

     #############
      sub _get_popup_menu_values {
	  my ($value_ref, $lookup, $key) = @_;

	my %values;
	foreach my $t (@$value_ref) {
	    $values{$t->{type_id}} = $t->{name} || $t->{handle};
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
