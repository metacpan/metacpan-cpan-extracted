#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use App::Chart::Gtk2::DownloadDialog;
use Devel::FindRef;

{
  my $dialog = App::Chart::Gtk2::DownloadDialog->popup;
  # unmap here because it's setup for hide-on-delete
  $dialog->signal_connect (unmap => sub { Gtk2->main_quit });

  App::Chart::chart_dirbroadcast()->listen;
  Gtk2->main;
  exit 0;
}

{
  my $dialog = App::Chart::Gtk2::DownloadDialog->new;
  $dialog->destroy;
  print Devel::FindRef::track ($dialog);
  Scalar::Util::weaken ($dialog);
  print defined $dialog ? "defined\n" : "not defined\n";
  exit 0;
}
