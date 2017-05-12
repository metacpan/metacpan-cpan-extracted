# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package App::Chart::Gtk2::Job::Intraday;
use strict;
use warnings;
use Carp;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart::Gtk2::Job;
use App::Chart::Gtk2::JobQueue;

# uncomment this to run the ### lines
#use Smart::Comments;


use Glib::Object::Subclass
  'App::Chart::Gtk2::Job',
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'Blurb.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('mode',
                   'Mode',
                   'Blurb.',
                   '',
                   Glib::G_PARAM_READWRITE),
                ];

sub type {
  return __('Intraday');
}

sub start {
  my ($class, $symbol, $mode) = @_;
  if (my $job = $class->find ($symbol, $mode)) {
    if ($job->is_stoppable) {
      ### still running: $job, $symbol, $mode
      return $job;
    }
  }
  return $class->SUPER::start (args   => [ 'intraday', $symbol, $mode ],
                               name   => __x('Intraday {symbol} {mode}',
                                             symbol => $symbol,
                                             mode => $mode),
                               symbol => $symbol,
                               mode   => $mode,
                               status => __('Downloading ...'));
}

sub find {
  my ($class, $symbol, $mode) = @_;
  require App::Chart::Gtk2::JobQueue;
  my @jobs = grep { $_->{'symbol'} eq $symbol && $_->{'mode'} eq $mode }
    App::Chart::Gtk2::JobQueue->all_jobs ($class);
  return List::Util::first { $_->is_stoppable }
    || $jobs[0];
}

1;
__END__
