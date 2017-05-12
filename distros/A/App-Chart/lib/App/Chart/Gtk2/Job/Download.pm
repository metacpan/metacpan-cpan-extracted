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

package App::Chart::Gtk2::Job::Download;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Gtk2::Job;
use App::Chart::Download;

use Glib::Object::Subclass
  'App::Chart::Gtk2::Job';

sub start {
  my ($class, $what, $when) = @_;
  my @when;
  my $name;
  if ($when) {
    @when = ('--backto', $when);
    $name = __x('Download {what} backto {year}',
                what => $what,
                year => $when);
  } else {
    $name = __x('Download {what}',
                what => $what);
  }
  my $job = $class->SUPER::start (args   => [ 'download', @when, $what ],
                                  name   => $name);
  return $job;
}

sub type {
  return __('Download');
}

1;
__END__
