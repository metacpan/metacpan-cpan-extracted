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
use Gtk2 '-init';
use App::Chart::Gtk2::Main;
use Devel::FindRef;
use Scalar::Util;

{
  sub print_destroy { my ($widget) = @_; print "destroy on $widget\n"; }
  my $main;
  $main = App::Chart::Gtk2::Main->new;
  #$main = Gtk2::Window->new ('toplevel');
  { my $ticker = $main->get_or_create_ticker;
    $ticker->signal_connect (destroy => \&print_destroy);
  }
  $main->destroy;
  Scalar::Util::weaken ($main);
  print "$main\n";
  if ($main) {
    print Devel::FindRef::track (\$main);
  }
  exit 0;
}

{
  my $x = ['hello'];
  my $y = sub { my $xx = ['hi']; print $x->[0],"\n"; };
  Scalar::Util::weaken ($x);
  print defined $x ? "defined\n" : "not defined\n";
  &$y();
  exit 0;
}


#App::Chart::Gtk2::Main->open ('BHP.AX');
#App::Chart::Gtk2::Main->open ('ZZZ.AX');

# $main->show;
# Gtk2->main();
# exit 0;
