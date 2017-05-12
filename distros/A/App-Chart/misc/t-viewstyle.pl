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
use App::Chart::Gtk2::ViewStyleDialog;

use FindBin;
my $progname = $FindBin::Script;

my $viewstyle = App::Chart::Gtk2::ViewStyleDialog->instance;
$viewstyle->signal_connect (destroy => sub { Gtk2->main_quit });

sub print_viewstyle {
  my ($viewstyle) = @_;
  require Data::Dumper;
  my $dumper = Data::Dumper->new([$viewstyle],['viewstyle']);
  $dumper->Sortkeys(1)->Indent(1);
  print $dumper->Dump;
}

$viewstyle->signal_connect
  (notify => sub {
     my ($viewstyle, $pspec) = @_;
     my $pname = $pspec->get_name;
     if ($pname eq 'viewstyle') {
       print "$progname: viewstyle notify $pname\n";
       print_viewstyle ($viewstyle->get_viewstyle);
     }
   });

print "initial ";
print_viewstyle($viewstyle->get_viewstyle);

App::Chart::chart_dirbroadcast()->listen;
$viewstyle->show;
Gtk2->main;

require Scalar::Util;
Scalar::Util::weaken ($viewstyle);
# $viewstyle->destroy;
if ($viewstyle) {
  require Devel::FindRef;
  print Devel::FindRef::track($viewstyle);
} else {
  print "$progname: viewstyle destroyed by weakening ok\n";
}

exit 0;
