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

package App::Chart::Gtk2::Graph::Plugin::Alerts;
use 5.010;
use strict;
use warnings;
use Gtk2;
use App::Chart::Annotation;
use List::Util qw(min max);

use App::Chart::Gtk2::Ex::GtkGCBits;
use base 'App::Chart::Gtk2::Graph::Plugin';

# uncomment this to run the ### lines
#use Smart::Comments;

use constant ALERTS_COLOUR => 'red';

use constant { ELEM_PRICE => 0,
               ELEM_ABOVE => 1 };

use constant { ALERT_COLOUR => 'red',
               ALERT_WIDTH => 20,
               ALERT_HEIGHT => 8 };

sub draw_t {
  my ($graph) = @_;
  my $series = $graph->get('series_list')->[0] || return undef;
  my $timebase = $series->timebase;
  return 1 + min ($timebase->today, $series->hi);
}

sub draw {
  my ($class, $graph, $region, $alerts) = @_;
  ### Graph-Alerts draw()

  $alerts ||= do {
    require App::Chart::Annotation;
    # FIXME: series autoloads not so good
    # $series->isa('App::Chart::Series::Database') || return;
    # $series->Alerts_arrayref;
    my @alerts = _alerts_for_series_list($graph->{'series_list'});
    \@alerts
  };
  if (! @$alerts) {
    ### none
    return;
  }

  my $win     = $graph->window;
  my $scale_y = $graph->scale_y_proc;

  my $gc = ($graph->{'alert_gc'} ||= do {
    my ($colour_str, $color_obj)
      = App::Chart::Gtk2::GUI::color_object ($graph, ALERT_COLOUR);
    my $bg_color = $graph->get_style->bg('normal');
    my $xor_color = Gtk2::Gdk::Color->new
      (0,0,0, $color_obj->pixel ^ $bg_color->pixel);

    App::Chart::Gtk2::Ex::GtkGCBits->get_for_widget ($graph, { function   => 'xor',
                                                   foreground => $xor_color });
  });

  my $t = draw_t ($graph);
  my $x = $graph->scale_x ($t);

  $gc->set_clip_region ($region);
  foreach my $elem (@$alerts) {
    my $y = $scale_y->($elem->{'price'});
    my $y_offset = ($elem->{'above'} ? - ALERT_HEIGHT : ALERT_HEIGHT);
    ### price: $elem->{'price'}
    ### y: $y
    $win->draw_lines ($gc,
                      $x - ALERT_WIDTH, $y,
                      $x, $y,
                      $x, $y + $y_offset);
  }
  $gc->set_clip_region (undef);
}

sub vrange {
  my ($class, $graph, $series_list) = @_;
  ### Graph-Alerts vrange(): "@$series_list"
  ### values: map {$_->price} _alerts_for_series_list($series_list)
  return map {$_->price} _alerts_for_series_list($series_list);
}

sub _alerts_for_series_list {
  my ($series_list) = @_;
  my @alerts;
  foreach my $series (@$series_list) {
    if (my $func = $series->can('Alerts_arrayref')) {
      push @alerts, @{$series->$func};
    }
  }
  return @alerts;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::Alerts -- graph drawing of a latest quote
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::Alerts;
#  App::Chart::Gtk2::Graph::Plugin::Alerts->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
