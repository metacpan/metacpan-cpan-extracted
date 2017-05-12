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
BEGIN { plan (tests => 1); }

use Gtk2;
use Gtk2::Ex::TimerObject;
use Scalar::Util;

my $if_no_display = Gtk2->init_check ? 0 : 'Skip due to no DISPLAY available';

sub noop { }
sub main_quit { Gtk2->main_quit; }

my $main_where = 'nowhere';
$SIG{ALRM} = sub {
  die "main loop hung: $main_where";
};
my $attempts = 0;
sub attempts {
  if (--$attempts < 0) { Gtk2->main_quit; }
  return 1;
}
sub main {
  $attempts = 10;
  my $id = Glib::Timeout->add (1, \&attempts);
  alarm(5);
  Gtk2->main;
  alarm(0);
  ($main_where) = 'nowhere';
  Glib::Source->remove ($id);
  
}

skip ($if_no_display, sub {
        my $timer = Gtk2::Ex::TimerObject->new (1000, \&noop);
        Scalar::Util::weaken ($timer);
        return defined $timer ? 'defined' : 'not defined';
      },
      'not defined', 'should be garbage collected when weakened');

# skip ($if_no_display, sub {
#         my $userdata = [ 'foo' ];
#         my $timer = Gtk2::Ex::TimerObject->new_weak (1, \&noop, $userdata);
#         Scalar::Util::weaken ($userdata);
#         main ('new_weak');
#         return $timer->is_running ? 'running' : 'not running';
#       },
#       'not running', 'should stop on weakened userdata');

exit 0;
