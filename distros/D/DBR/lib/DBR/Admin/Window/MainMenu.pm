
# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Admin::Window::MainMenu;



use strict;
use Class::Std;
use Data::Dumper;

## fix
use lib '/drj/tools/perl-dbr/lib';
use DBR::Admin::Window;
use DBR::Admin::Window::EnumList;
use DBR::Admin::Window::SchemaList;

use vars qw($VERSION $PKG);

$VERSION = 1.0;

$PKG = __PACKAGE__;

use base qw(DBR::Admin::Window);


{

    my %menu_labels = (
		      'DBR::Admin::Window::SchemaList' => 'Schemas', 
		      'DBR::Admin::Window::EnumList' => 'Enums'
		     );
    my @menu_values = keys %menu_labels;

    ####################
    sub BUILD {

	my ($self, $ident, $_args) = @_;


	my $listbox = $self->get_win->add(
					  'mainMenulist', 'Listbox',
					  -y => 2,
					  -width => 15,
					  -height => 4,
					  -values    => \@menu_values,
					  -labels    => \%menu_labels,
					  -onchange => sub { $self->listbox_select(shift); },
					 );

	$listbox->draw();

 my $title = q# ____  ____  ____       _       _           _       
|  _ \| __ )|  _ \     / \   __| |_ __ ___ (_)_ __  
| | | |  _ \| |_) |   / _ \ / _` | '_ ` _ \| | '_ \ 
| |_| | |_) |  _ <   / ___ \ (_| | | | | | | | | | |
|____/|____/|_| \_\ /_/   \_\__,_|_| |_| |_|_|_| |_|#;

	my $label = $self->get_win->add(
				      "instructions_label", 'Label',
				      -text => "$title\n\nGlobal keys:
Control-Q: Quit   
Tab: next input widget
Enter or right-arrow: select
Up/Down arrows: previous/next item in current input widget
Mouse supported depending on OS (Linux - probably, Mac - probably not)",
				      -y => 7,
				     );

	$label->draw;




	

	$listbox->focus();
	$listbox->onFocus(sub {$listbox->clear_selection});

    }

    #######################
    sub listbox_select {
	my ($self, $_args) = @_;

	#print STDERR Dumper ':' . $_args->get() . ':';
	my $class = $_args->get();

# 	print STDERR "$class->new({ id => $menu_labels{$_args->get}, parent => $self->get_win() });\n";
# 	print STDERR Dumper $self->get_win();

	$class->new({ id => $menu_labels{$_args->get}, parent => $self->get_win, parent_title => ucfirst($self->get_id) });
	

    }

}

1;
