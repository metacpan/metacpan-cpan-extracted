#!/usr/bin/perl -w

# ----------------------------------------------------------------------
# Script: editor
#
# (c) 2001-2002 by Maurice Makaay. All rights reserved.
# This file is part of Curses::UI. Curses::UI is free software.
# You can redistribute it and/or modify it under the same terms
# as perl itself.
#
# e-mail: maurice@gitaar.net
# ----------------------------------------------------------------------

use strict;
use Curses;
use Cwd;

# Use the libraries from the distribution, instead of 
# system wide libraries.
use FindBin;
use lib "$FindBin::RealBin/../lib";

# Load an initial file if an argument given on the command line.
# If the file can't be found, assume that this is a new file.
my $text = "";
my $currentfile = shift;
if (defined $currentfile and -f $currentfile) 
{
	open F, "<$currentfile" or die "Can't read $currentfile: $!\n";
	while (<F>) { $text .= $_ }
	$currentfile = $currentfile;
	close F;
}

# We don't want STDERR output to clutter the screen.
#
# Hint: If you need STDERR, write it out to a file and put 
# a tail on that file to see the STDERR output. Example:
#open STDERR, ">>/tmp/editor_errors.$$";
open STDERR, ">/dev/null";

# ----------------------------------------------------------------------
# Menu definition
# ----------------------------------------------------------------------

my @menu = (
  { -label => 'File', 
    -submenu => [
      { -label => 'Open file ^O', -value => \&open_dialog  },
      { -label => 'Save file ^S', -value => \&save_dialog  },
      { -label => 'Exit      ^Q', -value => \&exit_dialog  }
    ]
  },
  { -label => 'Help', 
    -submenu => [
      { -label => 'About editor', -value => \&about_dialog }
    ]
  } 
);

# ----------------------------------------------------------------------
# Create widgets
# ----------------------------------------------------------------------

# Create the root. Everything else will be built up from here.
use Curses::UI;
my $cui = new Curses::UI ( 
	-clear_on_exit => 1 
);

# Add the menu to the root.
my $menu = $cui->add(
	'menu','Menubar', 
	-menu => \@menu,
);

# Create the screen for the editor.
my $screen = $cui->add(
	'screen', 'Window',
	-padtop          => 1, # leave space for the menu
	-border		 => 0,
	-ipad		 => 0,
);

# We add the editor widget to this screen.
my $editor = $screen->add(
	'editor', 'TextEditor',
	-border 	 => 1,
	-padtop		 => 0,	
	-padbottom 	 => 3,
	-showlines	 => 0,
	-sbborder	 => 0,
	-vscrollbar	 => 1,
	-hscrollbar	 => 1,
	-showhardreturns => 0,
	-wrapping        => 0, # wrapping slows down the editor :-(
	-text		 => $text,
);

# There is no need for the editor widget to loose focus, so
# the "loose-focus" binding is disabled here. This also enables the
# use of the "TAB" key in the editor, which is nice to have.
$editor->clear_binding('loose-focus');

# Help information for the user. 
$screen->add(
	'help', 'Label',
	-y 	 	 => -2,
	-width		 => -1,
	-reverse 	 => 1,
	-paddingspaces   => 1,
	-text 	 	 => 
	      " ^Q Quit from the program ^S save file"
	    . " ^W toggle wrapping\n"
	    . " ^X Open the menu         ^O open file"
	    . " ^R toggle hard returns viewing",
);

# ----------------------------------------------------------------------
# Callback routines
# ----------------------------------------------------------------------
	
sub open_dialog()
{
	my $file = $cui->loadfilebrowser( 
		-file         => $currentfile,
	);

	if (defined $file) 
	{
		if (open F, "<$file") {
		    my $text = "";
		    while (<F>) { $text .= $_ }
		    close F;
		    $editor->text($text);
		    $editor->cursor_to_home;
	 	    $currentfile = $file;
		} else { 
		    $cui->error(-message => "Can't read file \"$file\":\n$!");
		}
	}
}

sub save_dialog()
{

	my $file = $cui->savefilebrowser(
		-file         => $currentfile,
	);
	return unless defined $file;

	if (open F, ">$file") {
	    print F $editor->text;
	    if (close F) {
		$cui->dialog(-message => "File \"$file\"\nsuccessfully saved");
		$currentfile = $file;
	    } else {
		$cui->error(-message => "Error on closing file \"$file\":\n$!");
	    }
	} else {
	    $cui->error(-message => "Can't write to $file:\n$!");
	}
}

sub about_dialog()
{
	$cui->dialog(
		-title => 'About editor',
		-message => "Program : Curses::UI Editor\n"
	 		  . "Author  : Maurice Makaay\n"
			  . "\n"
			  . "The sole purpose of this editor\n"
			  . "is the demonstration of my perl\n"
		 	  . "Curses::UI widget set."
	);
}
		
sub exit_dialog()
{
	my $return = $cui->dialog(
			-title     => "Are you sure???", 
			-buttons   => ['yes', 'no'],
			-message => "Do you really want to quit?"
	);

	exit(0) if $return;
}


# ----------------------------------------------------------------------
# The main loop of the program
# ----------------------------------------------------------------------


$cui->set_binding(\&exit_dialog, "\cQ", "\cC");
$cui->set_binding(\&save_dialog, "\cS");
$cui->set_binding(\&open_dialog, "\cO");
$cui->set_binding(sub {shift()->getobj('menu')->focus}, "\cX", KEY_F(10));
$cui->set_binding(sub {
	my $cui = shift;
	$cui->layout;
	$cui->draw;
}, "\cL");


# Bring the focus to the editor widget.
$editor->focus;

$cui->mainloop;

