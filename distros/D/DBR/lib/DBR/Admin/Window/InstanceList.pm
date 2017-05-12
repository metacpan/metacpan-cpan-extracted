
# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.


package DBR::Admin::Window::InstanceList;

use strict;
use Class::Std;
use Data::Dumper;

use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Utility;
use DBR::Admin::Window::FieldList;
use DBR::Admin::Exception;
use DBR::Config::ScanDB;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);

{

    my %instances_of : ATTR( :get<instances> :set<instances>);
    my %instance_listbox_of : ATTR( :get<instance_listbox> :set<instance_listbox>);
    my %schema_id_of : ATTR( :get<schema_id> :set<schema_id>);
    my %schema_of  : ATTR( :get<schema> :set<schema>);

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	$self->set_schema_id($_args->{schema_id});
	$self->set_schema($_args->{schema});

	my $new_instance_button = $self->get_win->add(
						  'newinstance', 'Buttonbox',
						  -buttons   => [
							       { 
								-label => '< Add New Instance >',
								-value => 1,
								-shortcut => 1 ,
								-onpress => sub {$self->add_edit_instance(add => 1)}
								
							       },
								],
						  -x => 40,
						  -y => 1,
								
						 );

	my $listbox = $self->get_win->add(
					  'instancelistbox', 'Listbox',
					  -y => 2,
					  -width => 25,
					  -vscrollbar => 1,
					  -onchange => sub {$self->listbox_item_options(listbox => shift);}
					 );

	$listbox->onFocus(sub {$listbox->clear_selection});
	$self->set_instance_listbox($listbox);
	$self->load_instance_list();
	$self->get_instance_listbox->layout();
	$self->get_instance_listbox->focus();
	$self->get_win->set_focusorder('instancelistbox', 'newinstance', 'close');
    }

    #######################
    # get the list from the database
    sub get_instance_list {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();

	my $data = $dbrh->select(
				 -table => 'dbr_instances',
				 -fields => 'instance_id schema_id handle class dbname username password host dbfile module readonly',
				 -where => {schema_id => $self->get_schema_id()},
				) or throw DBR::Admin::Exception(
						       message => "failed to select from dbr_instances $!",
						       root_window => $self->get_win->root()
						      );

	my %menu_list;
	my %instances;

	foreach my $e (@$data) {
	    $menu_list{$e->{instance_id}} = $e->{handle} . "-" . $e->{class};
	    $instances{$e->{instance_id}} = $e;
	}

	$self->set_instances(\%instances);
	return \%menu_list;
    }

    #################
    # load the instance list into the
    # instance listbox
    sub load_instance_list{

	my ($self,  %_args) = @_;

	my $instance_listbox = $self->get_instance_listbox();
	my $menu_list = $self->get_instance_list();
	my @menu_values = keys %{$menu_list};
	$instance_listbox->values(\@menu_values);
	$instance_listbox->labels($menu_list);
	$self->set_instance_listbox($instance_listbox);
    }

    ##########################
    # this is the options listbox that appears when a 
    # instance is chosen
    sub listbox_item_options {

	my ($self,  %_args) = @_;

	if ($self->get_win->getobj('instancelistbox_options')) {
	    $self->get_win->delete('instancelistbox_options');
	}

	my $listbox_options = $self->get_win->add(
						  'instancelistbox_options', 'Listbox',
						  -y => ($_args{listbox}->get_active_id() + 2)  - $_args{listbox}->{-vscrollpos},
						  -x => 30,
						  -width => 25,
						  -values    => ['Scan', 'Edit'],
						  -onchange => sub { $self->listbox_option_select(
												  listbox => shift, 
												  instance_id => $_args{listbox}->get(), 
												  instance_listbox => $_args{listbox}
												 );  },
						  -onblur => sub {$self->get_win->delete('instancelistbox_options');}
						 );
	
	$listbox_options->focus();
	$listbox_options->onFocus(sub {$listbox_options->clear_selection});
    }

    ##########################
    # called when an option is selected
    sub listbox_option_select {

	my ($self,  %_args) = @_;

	#print STDERR $_args->get();
	

	if ($_args{listbox}->get eq 'Scan') {
	    $self->scan(
			handle => $self->get_instances->{$_args{instance_id}}->{handle},
			class =>  $self->get_instances->{$_args{instance_id}}->{class},
		       );
	}

	elsif  ($_args{listbox}->get eq 'Edit'){
	    $self->add_edit_instance(instance_id => $_args{instance_id});
	  
	}
    }

    ########################
    sub scan {
	my ($self,  %_args) = @_;

	my $dbr = DBR::Admin::Utility::get_dbr();

	my $conf_instance = $dbr->get_instance('dbrconf') or 
	  throw DBR::Admin::Exception(
			    message => "failed to get instance 'dbrconf' $!",
			    root_window => $self->get_win->root()
			   );

	my $scan_instance = $dbr->get_instance($_args{handle}, $_args{class}) or 
	  throw DBR::Admin::Exception(
			    message => "failed to get scan instance $_args{handle}, $_args{class}  $!",
			    root_window => $self->get_win->root()
			   );


	my $scanner = DBR::Config::ScanDB->new(
					       session => $dbr->session,
					       conf_instance => $conf_instance,
					       scan_instance => $scan_instance,
					      );


	$scanner->scan() || throw DBR::Admin::Exception(
			    message => "failed to scan: $!",
			    root_window => $self->get_win->root()
			   );

	#success dialog
	my $confirm = $self->get_win->root->dialog(
						   -message   => "This instance has been successfully scanned",
						   -title     => "Success", 
						   -buttons   => [
								{ 
								 -label => '< OK >',
								 -value => 1,
								 -shortcut => 1 
								}
								 ]
						  );

	$self->get_schema->load_schema_list();
	

    }
    
    #####################
     sub add_edit_instance {

 	my ($self,  %_args) = @_;

 	my $edit_window =  $self->get_win->add(
 					       'instanceeditwindow', 'Window',
 					       -border => 1,
 					       -y    => 1,
 					       -bfg  => 'blue',
 					       -title => 'Edit Instance',
 					       -titlereverse => 0,
 					      );

	$edit_window->focus();

	my $initial_focus;

	############
	# readonly
	my $instance_hash = $self->get_instances->{$_args{instance_id}};
	my $instance_fields;

 	my @readonly_fields = qw(
				       schema_id
				       instance_id
				  );

	my %editable_fields = (
			       handle => 0,
			       class  => 0,
			       dbname => 0, 
			       username  => 0,
			       password  => 0,
			       host  => 0,
			       dbfile  => 0,
			       module  => 0,
			       readonly => 3,
			      );

  	my $x = 5;
 	my $y = 1;

	if (!$_args{add}) {
	
	    foreach my $f (@readonly_fields) {
	
		my $label = $edit_window->add(
					      $f . "_label", 'Label',
					      -text => "$f: ",
					      -x => $x,
					      -y => $y
					     );

		$label->draw;

		$instance_fields->{$f} = $edit_window->add(
							   $f . "_text_box", 'TextEditor',
							   -sbborder => 0,
							   -y => $y,
							   -x => ($x + 16) ,
							   -readonly => 1,
							   -singleline => 1,
							   -text => $instance_hash->{$f}
							  );
		$instance_fields->{$f}->draw();
		$y += 1;
	    }
	}
	else {
	    my $label = $edit_window->add(
					  "schema_id_label", 'Label',
					  -text => "schema_id: ",
					  -x => $x,
					  -y => $y
					 );

	    $label->draw;
	    
	    $instance_fields->{schema_id} = $edit_window->add(
						       "schem_id_text_box", 'TextEditor',
						       -sbborder => 0,
						       -y => $y,
						       -x => ($x + 16) ,
						       -readonly => 1,
						       -singleline => 1,
						       -text => $self->get_schema_id(),
						      );
	    $instance_fields->{schema_id}->draw();
	    $y += 1; 


	}


	######
	# ediinstance instances
 	foreach my $f (keys %editable_fields) {
	
 	    my $label = $edit_window->add(
 					  $f . "_label", 'Label',
 					  -text => "$f: ",
 					  -x => $x,
 					  -y => $y
 					 );

 	    $label->draw;

 	    $instance_fields->{$f} = $edit_window->add(
						       $f . "_text_box", 'TextEditor',
						       -sbborder => 1,
						       -y => $y,
						       -x => ($x + 16) ,
						       -singleline => 1,
						       -width => ($editable_fields{$f} ? $editable_fields{$f} : 25),
						       -text => $instance_hash->{$f}
						      );
 	    $instance_fields->{$f}->draw();
	    if (!defined($initial_focus)) {
		$initial_focus =   $instance_fields->{$f};
	    }
	    $y += 1;
 	}

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
										   instance_id => $_args{instance_id},
										   instance_fields => $instance_fields,
										   name => 'instanceeditwindow',
										   add => $_args{add},
										   edit_window => $edit_window,
										  );
							    }
							   },
							   { 
							    -label => '< Cancel >',
							    -value => 2,
							    -shortcut => 2 ,
							    -onpress => sub {$self->close_edit_window(edit_window => $edit_window, name => 'instanceeditwindow')}
							   }
							       	
							    ],
					      -x => 6,
					      -y => $y,
								
					     );
	$submit_button->draw();

	$initial_focus->focus();

     }

   #######################
    # called when the submit button on the
    # add/edit window is selected
    sub submit_edit {

	my ($self,  %_args) = @_;

	my $dbrh = DBR::Admin::Utility::get_dbrh();
	my $ret;
	my $instance_data;


	foreach my $i (keys %{$_args{instance_fields}}) {
	    $instance_data->{$i} = $_args{instance_fields}->{$i}->get();
	}

	#print STDERR Dumper $instance_data;

	if ($_args{add}) {
	    $ret = $dbrh->insert(
				 -table => 'dbr_instances',
				 -fields => $instance_data,
				) or throw DBR::Admin::Exception(
						       message => "failed to insert into dbr_instances: $!",
						       root_window => $self->get_win->root()
						      );
	} else {
	    
	    $ret = $dbrh->update(
				 -table => 'dbr_instances',
				 -fields => $instance_data,
				 -where => {instance_id => $_args{instance_id}}
				) or throw DBR::Admin::Exception(
						       message => "failed to update dbr_instances: $!",
						       root_window => $self->get_win->root()
						      );
	}

	if ($ret) {
	
	    #success dialog
	    my $confirm = $self->get_win->root->dialog(
						       -message   => $_args{add} ? "This instance has been successfully Added"  : "This instance has been successfully updated.",
						       -title     => "Success", 
						       -buttons   => [
								    { 
								     -label => '< OK >',
								     -value => 1,
								     -shortcut => 1 
								    }
								     ]
						      );
	}

	# reset the instance list
	$self->load_instance_list();

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
