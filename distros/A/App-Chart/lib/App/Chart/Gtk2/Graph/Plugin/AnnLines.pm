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

package App::Chart::Gtk2::Graph::Plugin::AnnLines;
use 5.008;
use strict;
use warnings;
use Gtk2 1.190; # auto-release Gtk2::GC
use List::MoreUtils;
use List::Util qw(min max);

use App::Chart::Gtk2::Ex::GtkGCBits;

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart;
use App::Chart::Annotation;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant { ANNLINE_COLOUR => App::Chart::GREY_COLOUR };

sub draw {
  my ($class, $graph, $region, $alines) = @_;

  $alines ||= do {
    my $series_list = $graph->{'series_list'};
    my $series = $series_list->[0] || return;
    ### Graph-AnnLines: "$series"
    my $func = $series->can('AnnLines_arrayref') || return;
    $func->($series);
  };
  ### Graph-AnnLines count: scalar(@$alines)
  if (! @$alines) { return; }

  my $win = $graph->window;
  my $scale_x = $graph->scale_x_proc;
  my $scale_y = $graph->scale_y_proc;

  my $gc = ($graph->{'annline_gc'} ||= do {
    my ($colour_str, $color_obj)
      = App::Chart::Gtk2::GUI::color_object ($graph, ANNLINE_COLOUR);
    my $bg_color = $graph->get_style->bg('normal');
    my $xor_color = Gtk2::Gdk::Color->new
      (0,0,0, $color_obj->pixel ^ $bg_color->pixel);
    App::Chart::Gtk2::Ex::GtkGCBits->get_for_widget
        ($graph, { function   => 'xor',
                   foreground => $xor_color });
  });

  $gc->set_clip_region ($region);
  $win->draw_segments
    ($gc, map { my $x1 = $scale_x->($_->{'t1'});
                my $x2 = $scale_x->($_->{'t2'});
                my $y1 = $scale_y->($_->{'price1'});
                my $y2 = ($_->{'horizontal'}
                          ? $y1 : $scale_y->($_->{'price2'}));

                #     if ($region->rect_in (Gtk2::Gdk::Rectangle->new
                #                           (min($x1,$x2), abs($x1-$x2), min($y1,$y2), abs($y1-$y2))) eq 'out') {
                #       next;
                #     }
                ($x1, $y1, $x2, $y2)

              } @$alines);
  $gc->set_clip_region (undef);
}

sub vrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0] || return;
  $series->can('AnnLines_arrayref') || return;
  my $aref = $series->AnnLines_arrayref;
  return map {; ($_->{'price1'}, $_->{'price2'}) } @$aref;
}

sub hrange {
  my ($class, $graph, $series_list) = @_;
  my $series = $series_list->[0] || return;
  $series->can('AnnLines_arrayref') || return;

  my $aref = $series->AnnLines_arrayref;
  if (! @$aref) { return (); }

  ### Graph-AnnLines hrange: map {; ($_->{'t1'}, $_->{'t2'})} @$aref
  return List::MoreUtils::minmax (map {; ($_->{'t1'}, $_->{'t2'}) } @$aref);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::AnnLines -- graph drawing of annotations across top
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::AnnLines;
#  App::Chart::Gtk2::Graph::Plugin::AnnLines->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
