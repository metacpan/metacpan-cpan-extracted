# Copyright 2007, 2008, 2009, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Graph::Plugin::Heading;
use 5.010;
use strict;
use warnings;
use Gtk2;

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart;
# use Locale::TextDomain ('App-Chart');

# uncomment this to run the ### lines
#use Devel::Comments;


use constant {
  X_MARGIN_SPACES => 1,
  Y_MARGIN_LINES => 0.3,
};

sub draw {
  my ($class, $graph, $region) = @_;
  ### Graph Heading draw() ...

  $graph->{'heading_in_graph'} or return;

  my $series_list = $graph->{'series_list'};
  my $series = $series_list->[0] || return;
  ### series: "$series"
  my $str = $series->name // return;
  ### $str

  my $win   = $graph->window;
  my $style = $graph->style;
  my $cliprect = $region->get_clipbox;

  my $layout  = ($graph->{'layout'} ||= $graph->create_pango_layout(''));
  my $line_height = Gtk2::Ex::Units::line_height($layout);
  my $y = $line_height * Y_MARGIN_LINES;
  $layout->set_text ((' ' x X_MARGIN_SPACES).$str);

  $style->paint_layout ($win,        # window
                        $graph->state,
                        1,  # use_text, for the text gc instead of the fg one
                        $cliprect,
                        $graph,      # widget
                        __PACKAGE__, # style detail string
                        0, $y,       # x,y
                        $layout);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::Heading -- heading within graph widget
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::Heading;
#  App::Chart::Gtk2::Graph::Plugin::Heading->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>, L<App::Chart::Gtk2::Heading>
# 
# =cut
