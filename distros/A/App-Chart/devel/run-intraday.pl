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

# Usage: ./run-intraday.pl [symbol]
#
# Run up the intraday dialog.

use strict;
use warnings;
use Gtk2;
use Data::Dumper;
use App::Chart;
use App::Chart::IntradayHandler;
use App::Chart::Gtk2::IntradayDialog;

use FindBin;
my $progname = $FindBin::Script;

$App::Chart::option{'verbose'} = 1;

{
  my $symbol = $ARGV[0] || '^GSPC';
  my @list = App::Chart::IntradayHandler->handlers_for_symbol($symbol);
  print "$progname: handlers for $symbol: ",Dumper (\@list);

  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init;
  my $dialog = App::Chart::Gtk2::IntradayDialog->popup ($symbol);
  print "$progname: dialog $dialog\n";
  $dialog->signal_connect_after
    (response => sub {
       my ($self, $response) = @_;
       print "$progname: response $response\n";
       if ($response eq 'close' || $response eq 'delete-event') {
         Gtk2->main_quit;
       }
     });

  require App::Chart::Gtk2::Job;
  App::Chart::Gtk2::Job->signal_add_emission_hook
      (message => sub {
         my ($invocation_hint, $parameters) = @_;
         my ($job, $str) = @$parameters;
         print $str;
         return 1; # stay connected
       });

  App::Chart::chart_dirbroadcast()->listen;
  Gtk2->main;
  exit 0;
}

{
  print defined(&App::Chart::Gtk2::Job::Intraday::find) ? 1 : 0,"\n";
  require App::Chart::Gtk2::Job::Intraday;
  print defined(&App::Chart::Gtk2::Job::Intraday::find) ? 1 : 0,"\n";
  exit 0;
}

{
  App::Chart::Intraday::download ('BHP.AX','1d');
  exit 0;
}
