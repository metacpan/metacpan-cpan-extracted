# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::TableList;

use strict;
use Class::Std;
use Data::Dumper;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;
use DBR::Admin::Window::FieldList;
use DBR::Admin::Window::FieldRelationshipList;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);

{

    my %tables_of : ATTR( :get<tables> :set<tables>);
    my %table_listbox_of : ATTR( :get<table_listbox> :set<table_listbox>);
    my %schema_id_of : ATTR( :get<schema_id> :set<schema_id>);

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	$self->set_schema_id($_args->{schema_id});

	my $listbox = $self->get_win->add(
					  'tablelistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {$self->listbox_item_options(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_table_listbox($listbox);
	$self->load_table_list();
	$self->get_table_listbox->layout();
	$self->get_table_listbox->focus();
	$self->get_win->set_focusorder('tablelistbox', 'close');
    }

    #######################
    # get the list from the database
    sub get_table_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_tables',
				 -fields => 'table_id schema_id name display_name is_cachable',
				 -where => {schema_id => $self->get_schema_id()},
				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_tables $!",
						       root_window => $self->get_win->root()
						      );

	my %menu_list;
	my %tables;

	foreach my $e (sort {$a->{name} cmp $b->{name}} @$data) {
	    $menu_list{$e->{table_id}} = $e->{name};
	    $tables{$e->{table_id}} = $e;
	}

	$self->set_tables(\%tables);
	return \%menu_list;
    }

    #################
    # load the table list into the
    # table listbox
    sub load_table_list{

	my ($self,  %_args) = @_;

	my $table_listbox = $self->get_table_listbox();
	my $menu_list = $self->get_table_list();
	my @menu_values = sort {$menu_list->{$a} cmp $menu_list->{$b} } keys %{$menu_list};
	$table_listbox->values(\@menu_values);
	$table_listbox->labels($menu_list);
	$self->set_table_listbox($table_listbox);
    }

    ##########################
    # this is the options listbox that appears when a 
    # table is chosen
    sub listbox_item_options {

	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('tablelistbox_options')) {
	    $self->get_win->delete('tablelistbox_options');
	}

	my $listbox_options = $self->get_win->add(
						  'tablelistbox_options', 'Listbox',
						  -y => ($_args{listbox}->get_active_id() + 2)  - $_args{listbox}->{-vscrollpos},
						  -x => 30,
						  -width => 25,
						  -values    => ['Fields', 'Edit', 'Relationships'],
						  -onchange => sub { $self->listbox_option_select(
												  listbox => shift, 
												  table_id => $_args{listbox}->get(), 
												  table_listbox => $_args{listbox}
												 );  },
						  -onblur => sub {$self->get_win->delete('tablelistbox_options');}
						 );
	
	$listbox_options->focus();
	$listbox_options->onFocus(sub {$listbox_options->clear_selection});
    }

    ##########################
    # called when an option is selected
    sub listbox_option_select {

	my ($self,  %_args) = @_;

	#print STDERR $_args->get();
	

	if ($_args{listbox}->get eq 'Fields') {
	    DBR::Admin::Window::FieldList->new(
				     {id => 'fields', 
				      parent => $self->get_win, 
				      table_id => $_args{table_id}, 
				      schema_id => $self->get_schema_id(), 
				      parent_title => ucfirst($self->get_id) 
				     }
				      );
	}

	elsif  ($_args{listbox}->get eq 'Edit'){
	    $self->edit_table(table_id => $_args{table_id});
	  
	}
	elsif  ($_args{listbox}->get eq 'Relationships'){
	    DBR::Admin::Window::FieldRelationshipList->new(
				     {id => 'fields', 
				      parent => $self->get_win, 
				      table_id => $_args{table_id}, 
				      schema_id => $self->get_schema_id(), 
				      parent_title => ucfirst($self->get_id) ,
				     }
				      );
	  
	}
    }

    #####################
    sub edit_table {

 	my ($self,  %_args) = @_;

 	my $edit_window =  $self->get_win->add(
 					       'tableeditwindow', 'Window',
 					       -border => 1,
 					       -y    => 1,
 					       -bfg  => 'blue',
 					       -title => 'Edit Table',
 					       -titlereverse => 0,
 					      );

	$edit_window->focus();

	############
	# readonly
	my $table_hash = $self->get_tables->{$_args{table_id}};

 	my @readonly_tables = qw(
 			        table_id schema_id name
			       );

	# display_name
	# is_cachable

 	my $x = 5;
 	my $y = 1;
 	foreach my $f (@readonly_tables) {
	
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
 					     -text => $table_hash->{$f}
 					    );
 	    $text_box->draw();
	    $y += 1;
 	}

	$y += 2;
	######
	# editable tables
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
					 -text => $table_hash->{display_name}
					);
	$y += 1;

	######
	$label = $edit_window->add(
				      "is_cachable_label", 'Label',
				      -text => "is_cachable: ",
				      -x => $x,
				      -y => $y
				     );

	$label->draw;

	my $is_cachable_text_box = $edit_window->add(
					 "is_cachable_text_box", 'TextEditor',
					 -sbborder => 1,
					 -y => $y,
					 -x => ($x + 16) ,
					 -readonly => 0,
					 -singleline => 1,
					 -text => $table_hash->{is_cachable}
					);

	$is_cachable_text_box->draw();

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
								$self->submit_edit(
										   table_id => $_args{table_id},
										   display_name => $display_text_box->get(),
										   is_cachable => $is_cachable_text_box->get(),
										   edit_window => $edit_window,
										   name => 'tableeditwindow',
										  );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window, name => 'tableeditwindow')}
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
			     -table => 'dbr_tables',
			     -fields => {
					 is_cachable => $_args{is_cachable},
					 display_name => $_args{display_name}
					},
			     -where => {table_id => $_args{table_id}}
			    ) or throw DBR::Admin::Exception(
						       message => "failed to update bdr_tables",
						       root_window => $self->get_win->root()
						      );


	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "This table has been successfully updated.",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	# reset the table list
	$self->load_table_list();

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


}

1;
