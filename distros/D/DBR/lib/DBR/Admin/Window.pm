# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.



package DBR::Admin::Window;

use strict;
use Class::Std;
use Data::Dumper;


use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

{
    #######################
    # member data
    my %parent_of : ATTR( :get<parent> :set<parent>);
    my %id_of : ATTR( :get<id> :set<id>);
    my %win_of : ATTR( :get<win> :set<win>);

    ##########################
    sub BUILD {

	my ($self, $ident, $_args) = @_;

	my $w = $_args->{parent}->root->add(
				      $_args->{id}, 'Window',
				      -border => 1,
				      -y    => 1,
				      -bfg  => 'green',
				      -title => ucfirst($_args->{id}),
				      -titlereverse => 0,
				     );


	my $close_label = ($_args->{parent_title} ? "Back To " . $_args->{parent_title} : 'Close');
	$w->add(
		'close', 'Buttonbox',
		-buttons   => [
			     { 
			      -label => "< $close_label >",
			      -value => 1,
			      -shortcut => 1 ,
			      -onpress => sub {$self->close}
			      
			     }
			      ]
	       );

	$self->set_parent($_args->{parent}->root);
	$self->set_win($w);
	$self->set_id($_args->{id});

	$w->focus();
    }

    ###################
    sub close {

	my ($self, $_args) = @_;

	if ($self->get_id eq 'DBR Admin Main Menu') {
	    my $return = $self->get_win->root->dialog(
			      -message   => "Do you really want to quit?",
			      -title     => "Are you sure???", 
			      -buttons   => ['yes', 'no'],
				      
			     );

	    exit(0) if $return;
	}

	$self->get_parent->delete($self->get_id);
	$self->get_parent->draw();
	$self->get_parent->focus();
    }





}





1;
