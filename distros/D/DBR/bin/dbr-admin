#!/usr/bin/perl

# the contents of this file are Copyright (c) 2004-2009 David Blood
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

use strict;
use Curses::UI;

use lib qw'../lib ../../lib';
use DBR::Admin::Window::MainMenu;
use DBR::Admin::Utility;



my $conf = shift;
my $logfile = shift || '/tmp/dbr-admin_lastrun_debug.txt';

# stderr gets messed up by curses, so put stuff in a logfile for easier reading
open STDERR, ">$logfile";

if (!$conf) {
    print "you must supply the path to the dbr config file as the first argument\n";
    exit;
}

DBR::Admin::Utility::get_dbrh($conf);

my $cui = new Curses::UI( 
			 -color_support => 1,
			 -mouse_support => 1,
			);

DBR::Admin::Window::MainMenu->new({ id => 'DBR Admin Main Menu', parent => $cui});

$cui->set_binding( \&exit_dialog , "\cQ");
$cui->set_binding( \&exit_dialog , "\cC");

$cui->mainloop();

################################
sub exit_dialog
{
    my $return = $cui->dialog(
			      -message   => "Do you really want to quit?",
			      -title     => "Are you sure???", 
			      -buttons   => ['yes', 'no'],

			     );

    exit(0) if $return;
}



