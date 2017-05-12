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
use Getopt::Long;
use Gtk2;
use App::Chart::Gtk2::IntradayDialog;

my $mode = '';
GetOptions ('mode'   => \$mode,
            'help|?' => sub {
              print 'intraday.pl [--mode=M] SYMBOL
Open a Chart intraday dialog showing SYMBOL.
';
              exit 0;
            }
           ) or exit 1;
if (@ARGV > 1) {
  print "intraday.pl: only one symbol allowed\n";
  exit 1;
}
my $symbol = $ARGV[0] || '';

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init;
my $dialog = App::Chart::Gtk2::IntradayDialog->new (symbol => $symbol,
                                              mode   => $mode);
$dialog->signal_connect (destroy => sub { Gtk2->main_quit; });
$dialog->show;
Gtk2->main;
exit 0;

__END__

=head1 NAME

intraday.pl -- run an intraday dialog

=head1 SYNOPSIS

 ./intraday.pl [--mode=M] [symbol]

=head1 DESCRIPTION

This is a simple example program running up a Chart intraday graph display
dialog.  It's the same as in the main Chart GUI, but run standalone.

=head1 SEE ALSO

L<App::Chart::Gtk2::IntradayDialog>

=cut
