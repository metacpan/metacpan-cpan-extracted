# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::SchemaList;

use strict;
use Class::Std;
use Data::Dumper;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;
use DBR::Admin::Window::TableList;
use DBR::Admin::Window::InstanceList;
use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);



{
    my %schemas_of : ATTR( :get<schemas> :set<schemas>);
    my %schema_listbox_of : ATTR( :get<schema_listbox> :set<schema_listbox>);

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	my $new_schema_button = $self->get_win->add(
						  'newschema', 'Buttonbox',
						  -buttons   => [
							       { 
								-label => '< Add New Schema >',
								-value => 1,
								-shortcut => 1 ,
								-onpress => sub {$self->add_edit_schema(add => 1)}
								
							       },
								],
						  -x => 40,
						  -y => 1,
								
						 );

	$new_schema_button->draw();


	my $listbox = $self->get_win->add(
					  'schemalistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {$self->listbox_item_options(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_schema_listbox($listbox);
	$self->load_schema_list();
	$self->get_schema_listbox->focus();
	$self->get_schema_listbox->focus();
	$self->get_win->set_focusorder('schemalistbox', 'newschema', 'close');
    }

    #######################
    # get the list from the database
    sub get_schema_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_schemas',
				 -fields => 'schema_id handle display_name',
				) or  throw DBR::Admin::Exception(
						       message => "failed to select from dbr_schema $!",
						       root_window => $self->get_win->root()
						      );

	my %menu_list;
	my %schemas;

	foreach my $e (@$data) {
	    $menu_list{$e->{schema_id}} = $e->{display_name};
	    $schemas{$e->{schema_id}} = $e;
	}

	$self->set_schemas(\%schemas);
	return \%menu_list;
    }

    #################
    # load the schema list into the
    # schema listbox
    sub load_schema_list{

	my ($self,  %_args) = @_;

	my $schema_listbox = $self->get_schema_listbox();
	my $menu_list = $self->get_schema_list();
	my @menu_values = keys %{$menu_list};
	$schema_listbox->values(\@menu_values);
	$schema_listbox->labels($menu_list);
	$self->set_schema_listbox($schema_listbox);
    }

    ##########################
    # this is the options listbox that appears when a 
    # schema is chosen
    sub listbox_item_options {

	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('schemalistbox_options')) {
	    $self->get_win->delete('schemalistbox_options');
	}

	my $listbox_options = $self->get_win->add(
						  'schemalistbox_options', 'Listbox',
						  -y => ($_args{listbox}->get_active_id() + 2) ,
						  -x => 30,
						  -width => 25,
						  -values    => ['Tables', 'Instances', 'Edit'],
						  -onchange => sub { $self->listbox_option_select(
												  listbox => shift, 
												  schema_id => $_args{listbox}->get(), 
												  schema_listbox => $_args{listbox}
												 );  },
						  -onblur => sub {$self->get_win->delete('schemalistbox_options');}
						 );
	
	$listbox_options->focus();
	$listbox_options->onFocus(sub {$listbox_options->clear_selection});
    }

    ##########################
    # called when an option is selected
    sub listbox_option_select {

	my ($self,  %_args) = @_;

	#print STDERR $_args->get();
	

	if ($_args{listbox}->get eq 'Tables') {
	    DBR::Admin::Window::TableList->new(
				     {id => 'tables', 
				      parent => $self->get_win, 
				      schema_id => $_args{schema_id}, 
				      parent_title => ucfirst($self->get_id) 
				     }
				      );
	}
	elsif  ($_args{listbox}->get eq 'Instances'){
	    DBR::Admin::Window::InstanceList->new(
					{id => 'instances', 
					 parent => $self->get_win, 
					 schema_id => $_args{schema_id}, 
					 schema => $self, 
					 parent_title => ucfirst($self->get_id) 
					}
					 );
	}

	elsif  ($_args{listbox}->get eq 'Edit'){
	    $self->add_edit_schema(schema_id => $_args{schema_id})
	}
    }


    #######################
    # add or edit window
    sub add_edit_schema {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $schemas = $self->get_schemas;

	my $edit_window =  $self->get_win->add(
					       'schemaeditwindow', 'Window',
					       -border => 1,
					       -y    => 1,
					       -bfg  => 'blue',
					       -title => $_args{add} ? 'Add New Schema' : 'Edit Schema',
					       -titlereverse => 0,
					      );
    

	my $label;
	my $schema_id_box;
	my $schema_override_id_box;

 	my $x = 5;
 	my $y = 1;

	#####
	# only show the schema_id if it's an edit
	if (!$_args{add}) {
	
	    #######
	    # schema_id
	    $label = $edit_window->add(
				       'schema_id_label', 'Label',
				       -text      => 'schema_id:',
				       -x => $x,
				       -y => $y
				      );

	    $label->draw;

	    $schema_id_box = $edit_window->add(
						'schema_id_box', 'TextEditor',
						-sbborder => 1,
						-y => $y,
						-x => $x + 30,
						-width => 6,
						-readonly => 1,
						-singleline => 1,
						-text => $_args{schema_id}
					       );
	    $schema_id_box->draw();
	    $y += 1;
    
	 
	}

	#####
	# name
	$label = $edit_window->add(
				   'schema_name_label', 'Label',
				   -text      => 'display_name: ',
				   -x => $x,
				   -y => $y
				  );

	$label->draw;

	my $schema_display_name_box = $edit_window->add(
					      'schema_name_box', 'TextEditor',
					      -sbborder => 1,
					      -y => $y,
					      -x => $x + 30,
					      -width => 25,
					      -singleline => 1,
					      -text => $schemas->{$_args{schema_id}}->{display_name}
					     );
	$schema_display_name_box->draw();
	$y += 1;

	#####
	# handle
	$label = $edit_window->add(
				   'schema_handle_label', 'Label',
				   -text      => 'handle:',
				   -x => $x,
				   -y => $y
				  );

	$label->draw;


	my $schema_handle_box = $edit_window->add(
						'schema_handle_box', 'TextEditor',
						-sbborder => 1,
						-y => $y,
						-x => $x + 30,
						-width => 25,
						-singleline => 1,
						-text => $schemas->{$_args{schema_id}}->{handle}
					       );

	$schema_handle_box->draw();
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
								$self->submit_add_edit(
										   schema_id => $_args{schema_id},
										   display_name => $schema_display_name_box->get(),
										   handle => $schema_handle_box->get(),
										   edit_window => $edit_window,
										   add => $_args{add}
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
					      -x => $x,
					      -y => $y,
								
					     );
	$submit_button->draw();



	
	#####
	$schema_display_name_box->focus();
    }

    #######################
    # called when the submit button on the
    # add/edit window is selected
    sub submit_add_edit {

	my ($self,  %_args) = @_;

	#print STDERR "submit edit:\n";
	#print STDERR Dumper \%_args;

	# check duplicate
	my $duplicate = 0;
	my $schemas = $self->get_schemas();
	foreach my $e (keys %{$schemas}) {

	    # don't check against myself
	    next if ($_args{schema_id} == $schemas->{$e}->{schema_id});

	    if  ( ($_args{display_name} eq $schemas->{$e}->{display_name}) ||
		  ($_args{handle} eq $schemas->{$e}->{handle}) ){
		$duplicate = 1;
		last;
	    }
	}

	if ($duplicate) {
		    my $confirm = $self->get_win->root->dialog(
							       -message   => "The Display Name or Handle you entered is already taken.  Please try another.",
							       -title     => "Duplicate Entry", 
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

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;
	
	if ($_args{add}) {
	    $ret = $dbrh->insert(
				 -table => 'dbr_schemas',
				 -fields => {
					     display_name => $_args{display_name},
					     handle => $_args{handle}
					    },
				) or  throw DBR::Admin::Exception(
						       message => "failed to insert into dbr_schemas $!",
						       root_window => $self->get_win->root()
						      );

	} else {
	    $ret = $dbrh->update(
				 -table => 'dbr_schemas',
				 -fields => {
					     display_name => $_args{display_name},
					     handle => $_args{handle}
					    },
				 -where => {schema_id => $_args{schema_id}}
				) or  throw DBR::Admin::Exception(
						       message => "failed to update dbr_schemas $!",
						       root_window => $self->get_win->root()
						      );
	}

	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => $_args{add} ? 'Schema successfully added'  :"This schema has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# reset the schema list
	$self->load_schema_list();

	# close window
	$self->close_edit_window(%_args);
	
    }

    #######################
    sub close_edit_window {

	my ($self,  %_args) = @_;

	$_args{edit_window}->parent->delete('schemaeditwindow');
	$_args{edit_window}->parent->draw();
	$_args{edit_window}->parent->focus();
    }
    

}

1;
