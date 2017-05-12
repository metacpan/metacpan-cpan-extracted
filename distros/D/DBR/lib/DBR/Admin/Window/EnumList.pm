# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::EnumList;



use strict;
use Class::Std;
use Data::Dumper;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);




{

    my %enums_of : ATTR( :get<enums> :set<enums>);
    my %enum_listbox_of : ATTR( :get<enum_listbox> :set<enum_listbox>);

    ####################
    # called on new()
    # populates initial window
    sub BUILD {

	# build has a special args list
	my ($self, $ident, $_args) = @_;

	my $new_enum_button = $self->get_win->add(
						  'newenum', 'Buttonbox',
						  -buttons   => [
							       { 
								-label => '< Add New Enum >',
								-value => 1,
								-shortcut => 1 ,
								-onpress => sub {$self->add_edit_enum(add => 1)},
								-ipadbottom => 3,
								
							       },
								],
						  -x => 40,
						  -y => 1,
								
						 );

	$new_enum_button->draw();
	
	####

	my $listbox = $self->get_win->add(
					  'enumlistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {$self->listbox_item_options(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});

	$self->set_enum_listbox($listbox);
	$self->load_enum_list();
	$self->get_enum_listbox->layout();
	$self->get_enum_listbox->focus();
	$self->get_win->set_focusorder('enumlistbox', 'newenum', 'close');

    }

    ##########################
    # this is the options listbox that appears when a 
    # enum is chosen
    sub listbox_item_options {

	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('enumlistbox_options')) {
	    $self->get_win->delete('enumlistbox_options');
	}

	#print STDERR $_args{listbox}->{-vscrolllen} . "-" . $_args{listbox}->{-vscrollpos} . "\n";

	my $listbox_options = $self->get_win->add(
						  'enumlistbox_options', 'Listbox',
						  -y => ($_args{listbox}->get_active_id() + 2) - $_args{listbox}->{-vscrollpos},
						  -x => 30,
						  -width => 25,
						  -values    => ['Edit', 'Delete'],
						  -onchange => sub { $self->listbox_option_select(
												  listbox => shift, 
												  enum_id => $_args{listbox}->get(), 
												  enum_listbox => $_args{listbox}
												 );  },
						  -onblur => sub {$self->get_win->delete('enumlistbox_options');}
						 );
	
	$listbox_options->focus();
	$listbox_options->onFocus(sub {$listbox_options->clear_selection});
    }

    ##########################
    # called when an option is selected
    sub listbox_option_select {

	my ($self,  %_args) = @_;

	#print STDERR $_args->get();
	

	if ($_args{listbox}->get eq 'Delete') {
	    $self->delete_enum(%_args);
	}
	else {
	    $self->add_edit_enum(%_args);
	}
    }

    #######################
    # get the list if enums from the database
    sub get_enum_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'enum',
				 -fields => 'enum_id handle name override_id',
				) or  throw DBR::Admin::Exception(
						       message => "failed to select from enum $!",
						       root_window => $self->get_win->root()
						      );

	my %menu_list;
	my %enums;

	foreach my $e (sort {$a->{name} cmp $b->{name} } @$data) {
	    $menu_list{$e->{enum_id}} = $e->{name};
	    $enums{$e->{enum_id}} = $e;
	}

	$self->set_enums(\%enums);
	return \%menu_list;
    }
    
    #######################
    # add or edit window
    sub add_edit_enum {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $enums = $self->get_enums;

	my $edit_window =  $self->get_win->add(
					       'enumeditwindow', 'Window',
					       -border => 1,
					       -y    => 1,
					       -bfg  => 'blue',
					       -title => $_args{add} ? 'Add New Enum' : 'Edit Enum',
					       -titlereverse => 0,
					      );
    

	my $label;
	my $enum_id_box;
	my $enum_override_id_box;

 	my $x = 5;
 	my $y = 1;


	#####
	# only show the enum_id & override_id if it's an edit
	if (!$_args{add}) {
	
	    #######
	    # enum_id
	    $label = $edit_window->add(
				       'enum_id_label', 'Label',
				       -text      => 'enum_id:',
				       -x => $x,
				       -y => $y
				      );

	    $label->draw;

	    $enum_id_box = $edit_window->add(
						'enum_id_box', 'TextEditor',
						-sbborder => 1,
						-y => $y,
						-x => $x + 16,
						-width => 6,
						-readonly => 1,
						-singleline => 1,
						-text => $_args{enum_id}
					       );
	    $enum_id_box->draw();

	    $y += 1;

	    #####
	    # override_id
	    $label = $edit_window->add(
				       'enum_override_id_label', 'Label',
				       -text      => 'override_id:',
				       -x => $x,
				       -y => $y
				      );

	    $label->draw;
	    $enum_override_id_box = $edit_window->add(
							 'enum_override_id_box', 'TextEditor',
							 -sbborder => 1,
							 -y => $y,
							 -x => $x + 16,
							 -width => 6,
							 -readonly => 1,
							 -singleline => 1,
							 -text => $enums->{$_args{enum_id}}->{override_id}
							);
	    $enum_override_id_box->draw();

	    $y += 1;
	}

	

	#####
	# name
	$label = $edit_window->add(
				   'enum_name_label', 'Label',
				   -text      => 'name:',
				   -x => $x,
				   -y => $y
				  );

	$label->draw;

	my $enum_name_box = $edit_window->add(
					      'enum_name_box', 'TextEditor',
					      -sbborder => 1,
					      -y => $y,
					      -x => $x + 16,
					      -width => 25,
					      -singleline => 1,
					      -text => $enums->{$_args{enum_id}}->{name}
					     );
	$enum_name_box->draw();

	$y += 1;

	#####
	# handle
	$label = $edit_window->add(
				   'enum_handle_label', 'Label',
				   -text      => 'handle:',
				   -x => $x,
				   -y => $y
				  );

	$label->draw;

	# not editable if this enum is mapped
	my $readonly = 0;
	if (!$_args{add} && $self->enum_is_mapped(enum_id => $_args{enum_id})) {
	    $readonly = 1;
	}
	my $enum_handle_box = $edit_window->add(
						'enum_handle_box', 'TextEditor',
						-sbborder => 1,
						-y => $y,
						-x => $x + 16,
						-width => 25,
						-singleline => 1,
						-readonly => $readonly,
						-text => $enums->{$_args{enum_id}}->{handle}
					       );

	$enum_handle_box->draw();
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
										   enum_id => $_args{enum_id},
										   name => $enum_name_box->get(),
										   handle => $enum_handle_box->get(),
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

	$y += 3;

	####
	# show mapped fields if an edit
	if (!$_args{add}) {
	    my $mapped_fields = $self->find_mapped_fields(%_args);



	    $label = $edit_window->add(
				       'mapped_fields_label', 'Label',
				       -text      => 'Mapped Fields:',
				       -bold => 1,
				       -x => $x,
				       -y => $y
				      );

	    $label->draw;

	    my $enum_mappings = $edit_window->add(
					      'enum_mappings', 'TextViewer',
					      -sbborder => 0,
					      -y => $y,
					      -x => $x + 16,
					      -width => 25,
					      -wrapping => 1,
					      -text => join(',', @$mapped_fields)
					     );
	    $enum_mappings->draw();

	}
	#####
	$enum_name_box->focus();
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
	my $enums = $self->get_enums();
	foreach my $e (keys %{$enums}) {

	    # don't check against myself
	    next if ($_args{enum_id} == $enums->{$e}->{enum_id});

	    if  ( ($_args{name} eq $enums->{$e}->{name}) ||
		  ($_args{handle} eq $enums->{$e}->{handle}) ){
		$duplicate = 1;
		last;
	    }
	}

	if ($duplicate) {
		    my $confirm = $self->get_win->root->dialog(
							       -message   => "The Name or Handle you entered is already taken.  Please try another.",
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
				 -table => 'enum',
				 -fields => {
					     name => $_args{name},
					     handle => $_args{handle}
					    },
				) or  throw DBR::Admin::Exception(
						       message => "failed to insert into enum $!",
						       root_window => $self->get_win->root()
						      );

	} else {
	    $ret = $dbrh->update(
				 -table => 'enum',
				 -fields => {
					     name => $_args{name},
					     handle => $_args{handle}
					    },
				 -where => {enum_id => $_args{enum_id}}
				) or  throw DBR::Admin::Exception(
						       message => "failed to update enum $!",
						       root_window => $self->get_win->root()
						      );
	}

	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => $_args{add} ? 'Enum successfully added'  :"This enum has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# reset the enum list
	$self->load_enum_list();

	# close window
	$self->close_edit_window(%_args);
	
    }

    #######################
    sub close_edit_window {

	my ($self,  %_args) = @_;

	$_args{edit_window}->parent->delete('enumeditwindow');
	$_args{edit_window}->parent->draw();
	$_args{edit_window}->parent->focus();
    }

    #################
    # load the enum list into the
    # enum listbox
    sub load_enum_list{

	my ($self,  %_args) = @_;

	my $enum_listbox = $self->get_enum_listbox();
	my $menu_list = $self->get_enum_list();
	my @menu_values = sort { $menu_list->{$a} cmp $menu_list->{$b} }  keys %{$menu_list};
	$enum_listbox->values(\@menu_values);
	$enum_listbox->labels($menu_list);
	$self->set_enum_listbox($enum_listbox);
    }

    #######################
    sub delete_enum {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $enums = $self->get_enums;
	my $enum_name = $self->get_enums->{$_args{enum_id}}->{name};

	# check if it's Ok to delete
	# 1) if fields are mapped to it, don't delete
	my $delete_ok = !($self->enum_is_mapped(enum_id => $_args{enum_id}));

	# lets' do it
	if ($delete_ok) {
	    my $confirm = $self->get_win->root->dialog(
						       -message   => "Enum '" . $enum_name  . "' is safe to delete.  Do you really want to delete it?",
						       -title     => "Confirm Delete", 
						       -buttons   => ['yes', 'no'],
						      );
	    if ($confirm) {

		# delete it

		my $ret = $dbrh->delete(
					-table => 'enum',
					-where => {enum_id => $_args{enum_id}}
				       ) or  throw DBR::Admin::Exception(
						       message => "failed to delete from enum $!",
						       root_window => $self->get_win->root()
						      );



		
		    my $confirm = $self->get_win->root->dialog(
							       -message   => "Enum '" . $enum_name . "' has been deleted",
							       -title     => "Enum Deleted", 
							       -buttons   => [
									    { 
									     -label => '< OK >',
									     -value => 1,
									     -shortcut => 1 
									    }
									     ]
							      );

		    # reset the enum list (since we just deleted one)
		    $self->load_enum_list();
		    $self->get_enum_listbox->focus();



	    } # end if confirm
	    
	} else {
	    # delete not OK
	    my $confirm = $self->get_win->root->dialog(
						       -message   => "Enum '" . $enum_name . "' is in use and cannot be deleted",
						       -title     => "Delete Forbidden", 
						       -buttons   =>  [
								     { 
								      -label => '< OK >',
								      -value => 1,
								      -shortcut => 1 
								     }
								      ]
						      );
	}

    }

    ##############
    sub enum_is_mapped {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $data = $dbrh->select(
				 -table => 'enum_map',
				 -fields => 'row_id',
				 -where => {enum_id => $_args{enum_id}}
				) or  throw DBR::Admin::Exception(
						       message => "failed to select from enum_map $!",
						       root_window => $self->get_win->root()
						      );

	if ($data && ref($data) eq 'ARRAY' && $data->[0]) {
	    return 1;
	}
	return 0;

    }

    #############
    sub find_mapped_fields {
	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $field_ret = $dbrh->select(
				      -table => {
						 'm' => 'enum_map',
						 'f' => 'dbr_fields',
						},
				      -fields => 'f.table_id f.name m.enum_id',
				      -where => {
						 'm.field_id' => ['j', 'f.field_id'],
						 'm.enum_id' => $_args{enum_id}
						}

				     ) or  throw DBR::Admin::Exception(
						       message => "failed to select from enum_mao $!",
						       root_window => $self->get_win->root()
						      );

	my $table_ret = $dbrh->select(
				      -table => {
						 't' => 'dbr_tables',
						 's' => 'dbr_schemas',
						 },
				      -fields => 't.table_id t.name s.handle',
				      -where => {
						 's.schema_id' => ['j', 't.schema_id']
						}

				     ) or  throw DBR::Admin::Exception(
						       message => "failed to select from dbr_tables $!",
						       root_window => $self->get_win->root()
						      );

	my %table_lookup;

	foreach my $t (@$table_ret) {
	    $table_lookup{$t->{table_id}} = $t->{handle} . '.' . $t->{name};
	}



	my @return;
	foreach my $f (@$field_ret) {
	    push @return, $table_lookup{$f->{table_id}} . '.' . $f->{name};
	}

	#print STDERR Dumper \@return;

	return \@return;

    }
}

1;
