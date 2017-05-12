
# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::FieldRelationshipList;

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

	my $new_relationship_button = $self->get_win->add(
						  'newrelationship', 'Buttonbox',
						  -buttons   => [
							       { 
								-label => '< Add New Relationship >',
								-value => 1,
								-shortcut => 1 ,
								-onpress => sub {
								    DBR::Admin::Window::RelationshipList->new(
									      {id => 'relationships', 
									       parent => $self->get_win, 
									       parent_title => ucfirst($self->get_id),
									       field_id => shift->get, 
									       schema_id => $self->get_schema_id(),
									       table_id => $self->get_table_id(),
									      })->add_edit_relationship(add => 1)
								}
								
							       },
								],
						  -x => 40,
						  -y => 1,
								
						 );

	$new_relationship_button->draw();

	my $listbox = $self->get_win->add(
					  'fieldlistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {
					      DBR::Admin::Window::RelationshipList->new(
									      {id => 'relationships', 
									       parent => $self->get_win, 
									       parent_title => ucfirst($self->get_id),
									       field_id => shift->get, 
									       schema_id => $self->get_schema_id(),
									       table_id => $self->get_table_id(),
									      }
									       );
					  }
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_field_listbox($listbox);
	$self->load_field_list();
	$self->get_field_listbox->layout();
	$self->get_field_listbox->focus();
	$self->get_win->set_focusorder('fieldlistbox','newrelationship', 'close');
    }

    #######################
    # get the list from the database
    sub get_field_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();



	my $data = $dbrh->select(
				      -table => {
						 'r' => 'dbr_relationships',
						 'f' => 'dbr_fields',
						},
				      -fields => 'f.table_id f.name f.field_id',
				      -where => {
						 'f.field_id' => ['j', 'r.from_field_id'],
						 'r.from_table_id' => $self->get_table_id()
						}

				     ) or  throw DBR::Admin::Exception(
						       message => "failed to select from dbr_relationship, dbr_fields $!",
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
	my @menu_values = keys %{$menu_list};
	$field_listbox->values(\@menu_values);
	$field_listbox->labels($menu_list);
	$self->set_field_listbox($field_listbox);
    }

 

    

}

1;
