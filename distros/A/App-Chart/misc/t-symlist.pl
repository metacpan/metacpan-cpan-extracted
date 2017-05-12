#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use Data::Dumper;
use App::Chart::Gtk2::Symlist;

{
  require App::Chart::Gtk2::Symlist::Favourites;
  my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
  $symlist->append_or_elevate ('SGX.AX');
  exit 0;
}

{
  require App::Chart::Gtk2::Symlist::Favourites;
  print App::Chart::Gtk2::Symlist::Favourites->can('key'),"\n";
  my $favourites = App::Chart::Gtk2::Symlist::Favourites->instance;
  print $favourites->name,"\n";
  print $favourites->get_property('columns'),"\n";
  print $favourites->get_property('key'),"\n";
  print $favourites->get_property('name'),"\n";
  my ($symbol, $symlist) = App::Chart::Gtk2::Symlist::next (undef, $favourites);
  print "$symbol, $symlist\n";
  ($symbol, $symlist) = App::Chart::Gtk2::Symlist::next ($symbol, $symlist);
  print "$symbol, $symlist\n";
  exit 0;
}
{
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ('user-1');
  print $symlist->get_property('key'),"\n";
#  $symlist->delete_symlist;
  exit 0;
}
{
  my $key = App::Chart::Gtk2::Symlist::add_user_symlist (0, '_foo');
  print "$key\n";
  exit 0;
}
{
  require App::Chart::Gtk2::Symlist::Alerts;
  my $alerts = App::Chart::Gtk2::Symlist::Alerts->instance;
  print join(' ',$alerts->symbols),"\n";
  my $hash = $alerts->hash;
  print keys %$hash,"\n";
  print join(' ',$alerts->interested_symbols),"\n";
  exit 0;
}

{
  my ($symbol, $symlist) = App::Chart::Gtk2::Symlist::next (undef, undef);
  print "$symbol, $symlist\n";
}
{
  my ($symbol, $symlist) = App::Chart::Gtk2::Symlist::next ('BHP.AX', 'all');
  print "$symbol, $symlist\n";
}
{
  my ($symbol, $symlist) = App::Chart::Gtk2::Symlist::previous ('IPG.AX', 'historical');
  print "$symbol, $symlist\n";
}
exit 0;

# {
#   my $all = $App::Chart::Gtk2::Symlist::symlist_all;
#   print Dumper($all->symbols);
#   my $hist = $App::Chart::Gtk2::Symlist::symlist_historical;
#   print Dumper($hist->symbols);
#   exit 0;
# }
