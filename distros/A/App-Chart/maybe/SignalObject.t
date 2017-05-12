# Copyright 2007, 2008 Kevin Ryde

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
use Test;
BEGIN { plan (tests => 2); }
use Gtk2;
use Glib;
use Glib::Ex::SignalObject;

{
  my $got = 'not called';
  my $adj = Gtk2::Adjustment->new (0,0,2,1,1,1);
  my $sig = Glib::Ex::SignalObject->new (object   => $adj,
                                         name     => 'value-changed',
                                         callback => sub { $got = 'called' });
  $adj->set_value (0.5);
  ok ($got, 'called');
}
{
  my $got = 'not called';
  my $adj = Gtk2::Adjustment->new (0,0,2,1,1,1);
  my $sig = Glib::Ex::SignalObject->new (object   => $adj,
                                         name     => 'value-changed',
                                         callback => sub { $got = 'called' });
  $sig = undef;
  $adj->set_value (0.5);
  ok ($got, 'not called');
}


exit 0;
