#!/usr/bin/perl -w

# Copyright 2008, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new ('toplevel');

my $actions = Gtk2::ActionGroup->new ("Actions");
$actions->add_actions
  ([
    [ 'FileMenu',   undef,    '_File'  ],
    [ 'Quit',     'gtk-quit',             undef,
      undef, # accelerator -- don't really want the usual Control-Q
      undef, \&_do_action_quit
    ],
   ]);
sub _do_action_quit {
  Gtk2->main_quit;
}

$actions->signal_connect (connect_proxy => \&_do_connect_proxy);
sub _do_connect_proxy {
  my ($actions, $action, $widget) = @_;
  print "connect_proxy $widget\n";
  my @widgets = $action->get_proxies;
  print @widgets,"\n";
}

my $ui = Gtk2::UIManager->new;
$ui->insert_action_group ($actions, 0);

$ui->add_ui_from_string (<<'HERE');
<ui>
  <menubar name='MenuBar'>
    <menu action='FileMenu'>
      <menuitem action='Quit'/>
    </menu>
  </menubar>
</ui>
HERE

my $menubar = $ui->get_widget('/MenuBar');
$toplevel->add ($menubar);

$toplevel->add_accel_group ($ui->get_accel_group);

$toplevel->show_all;
Gtk2->main;
exit 0;
