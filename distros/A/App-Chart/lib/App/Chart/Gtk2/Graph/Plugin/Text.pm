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

package App::Chart::Gtk2::Graph::Plugin::Text;
use 5.010;
use strict;
use warnings;
use Gtk2;
use List::MoreUtils;
use List::Util qw(min max);
use Math::Round qw(round);

use base 'App::Chart::Gtk2::Graph::Plugin';
use App::Chart;
use Gtk2::Ex::Units;
use Locale::TextDomain ('App-Chart');

use constant {
  X_MARGIN_EMS => 0.7,
  Y_MARGIN_LINES => 0.2,
};

sub draw {
  my ($class, $graph, $region) = @_;

  my $series_list = $graph->{'series_list'};
  my $series = $series_list->[0] || return;

  my $win = $graph->window;
  my ($win_width, $win_height) = $win->get_size;
  my $t_lo = $graph->x_to_date (-0.5 * $win_width);
  my $t_hi = $graph->x_to_date (1.5 * $win_width);

  my @array;
  {
    my $dividend_list = $series->dividends;
    foreach my $dividend (@$dividend_list) {
      my $t = $dividend->{'ex_date_t'};
      if ($t < $t_lo || $t > $t_hi) { next; }
      push @array, [$t, dividend_format ($dividend)];
    }
  }
  {
    my $split_list = $series->splits;
    foreach my $split (@$split_list) {
      my $t = $split->{'date_t'};
      if ($t < $t_lo || $t > $t_hi) { next; }
      push @array, [$t, split_format ($split)];
    }
  }
  {
    my $annotation_list = $series->annotations;
    foreach my $annotation (@$annotation_list) {
      my $t = $annotation->{'date_t'};
      if ($t < $t_lo || $t > $t_hi) { next; }
      push @array, [$t, annotation_format ($annotation)];
    }
  }
  if (! @array) { return; }

  my $cliprect = $region->get_clipbox;
  my $x_step  = $graph->scale_x_step;
  my $scale_x = $graph->scale_x_proc;
  my $style   = $graph->style;
  my $state   = $graph->state;
  my $gc      = $style->text_gc ($state);
  my $layout  = ($graph->{'layout'} ||= $graph->create_pango_layout(''));
  my $em      = Gtk2::Ex::Units::em($layout);
  my $line_height = Gtk2::Ex::Units::line_height($layout);
  my $x_margin = round (X_MARGIN_EMS * $em);
  my $y_margin = round (Y_MARGIN_LINES * $line_height);
  my $y_top    = round (1.5 * $line_height);
  my $y_str    = $y_top + $y_margin;

  foreach my $elem (@array) {
    my ($t, $str) = @$elem;
    my $x_centre = $scale_x->($t) + $x_step / 2; # centre of column
    $layout->set_text ($str);
    my ($str_width, $str_height) = $layout->get_pixel_size;
    my $x_str = $x_centre - $str_width / 2;
    my $x_left = $x_str - $x_margin;
    my $width = $str_width + 2 * $x_margin;
    my $height = $str_height + 2 * $y_margin;

    if ($region->rect_in (Gtk2::Gdk::Rectangle->new
                          ($x_left, $width, $y_top, $height)) eq 'out') {
      next;
    }

    $style->paint_layout ($win,        # window
                          $state,
                          1,  # use_text, for the text gc instead of the fg one
                          $cliprect,
                          $graph,      # widget
                          __PACKAGE__, # style detail string
                          $x_str,
                          $y_str,
                          $layout);

    $win->draw_rectangle ($gc, 0, $x_left, $y_top, $width, $height);
    $win->draw_line ($gc,
                     $x_centre, $y_top + $height,
                     $x_centre, $y_top + $height + $line_height);
  }
}

sub dividend_format {
  my ($dividend) = @_;
  return ($dividend->{__PACKAGE__.'.formatted'} ||= do {
    ### $dividend

    my @parts;
    if (defined $dividend->{'amount'}) {
      push @parts, $dividend->{'amount'};
    }
    if (defined $dividend->{'imputation'}) {
      push @parts, '+ ' . $dividend->{'imputation'};
    }
    if (my $type = $dividend->{'type'}) {
      push @parts, $type;
    }
    if (my $qualifier = $dividend->{'qualifier'})  {
      push @parts, dividend_qualifier_str ($qualifier);
    }
    if (! @parts) {
      my $note = $dividend->{'note'};
      if (defined $note && $note ne '')  {
        push @parts, $note;
      }
    }
    ### @parts

    join ' ',@parts
  });
}

sub dividend_qualifier_str {
  my ($qualifier) = @_;
  if ($qualifier eq 'TBA')       { return __('T.B.A.'); }
  if ($qualifier eq 'estimated') { return __('Est'); }
  if ($qualifier eq 'unknown')   { return __('Unknown'); }
  return $qualifier;
}

sub split_format {
  my ($split) = @_;
  return ($split->{__PACKAGE__.'.formatted'} ||= do {
    ($split->{'note'}
     ? __x('{newnum} for {oldnum}, {note}',
           newnum => $split->{'new'},
           oldnum => $split->{'old'},
           note   => $split->{'note'})
     : __x('{newnum} for {oldnum}',
           newnum => $split->{'new'},
           oldnum => $split->{'old'}))
  });
}

sub annotation_format {
  my ($annotation) = @_;
  return ($annotation->{__PACKAGE__.'.formatted'} ||= $annotation->{'note'});
}

sub elem_sizes {
  my ($elem_list, $graph) = @_;
  my $layout  = ($graph->{'layout'} ||= $graph->create_pango_layout(''));
  my $em      = Gtk2::Ex::Units::em ($layout);
  my $line_height = Gtk2::Ex::Units::line_height($layout);
  my $x_margin = round (X_MARGIN_EMS * $em);
  my $y_margin = round (Y_MARGIN_LINES * $line_height);

  foreach my $elem (@$elem_list) {
    $layout->set_text ($elem->{__PACKAGE__.'.formatted'});
    my ($str_width, $str_height) = $layout->get_pixel_size;
    my $x_str = $elem->{'x_str'} = - $str_width / 2;
    $elem->{'x_left'} = $x_str - $x_margin;
    $elem->{'width'} = $str_width + 2 * $x_margin;
    $elem->{'height'} = $str_height + 2 * $y_margin;
  }
}

sub hrange {
  my ($class, $graph, $series_list) = @_;
  ### Graph-Text hrange on: "$graph $series_list"
  $graph || return;
  my $series = $series_list->[0] || return;

  my @ret;
  {
    my $dividend_list = $series->dividends;
    foreach my $dividend (@$dividend_list) {
      dividend_format ($dividend);
    }
    push @ret, @$dividend_list;
  }
  {
    my $split_list = $series->splits;
    foreach my $split (@$split_list) {
      split_format ($split);
    }
    push @ret, @$split_list;
  }
  {
    my $annotation_list = $series->annotations;
    foreach my $annotation (@$annotation_list) {
      annotation_format ($annotation);
    }
    push @ret, @$annotation_list;
  }
  elem_sizes (\@ret, $graph);

  my $x_step = $graph->scale_x_step;
  @ret = map { my $elem = $_;
               my $t = $elem->{'date_t'};
               if (! defined $t) { $t = $elem->{'ex_date_t'}; }
               my $t_extra = int ($elem->{'width'} / 2 / $x_step) + 1;
               ($t - $t_extra, $t + $t_extra) } @ret;
  ### Text range: join(' ',@ret)
  if (@ret) {
    return List::MoreUtils::minmax (@ret);
  } else {
    return ();
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::Graph::Plugin::Text -- graph drawing of annotations across top
# 
# =for test_synopsis my ($graph, $region)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::Graph::Plugin::Text;
#  App::Chart::Gtk2::Graph::Plugin::Text->draw ($graph, $region);
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
