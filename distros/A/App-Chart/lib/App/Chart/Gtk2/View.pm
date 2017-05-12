# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package App::Chart::Gtk2::View;
use 5.010;
use strict;
use warnings;
use Carp;
use Glib;
use Glib::Ex::ConnectProperties;
use Gtk2 1.220;
use Gtk2::Ex::AdjustmentBits 43; # v.43 for set_maybe()
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::Gtk2::GUI;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant DEFAULT_TIMEBASE_CLASS => 'App::Chart::Timebase::Days';

use Glib::Object::Subclass
  'Gtk2::Table',
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The stock or commodity symbol to display, or empty string for none.',
                  '', # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('timebase-class',
                  'timebase-class',
                  'Blurb.',
                  DEFAULT_TIMEBASE_CLASS,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('statusbar',
                  'statusbar',
                  'Blurb.',
                  'Gtk2::Statusbar',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('viewstyle',
                  'viewstyle',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),
                ];

# FIXME: adjust_splits breaks AnnDrag
use constant DEFAULT_VIEWSTYLE =>
  { adjust_splits     => 0,
    adjust_dividends  => 0,
    adjust_imputation => 1,
    adjust_rollovers  => 0,
    graphs => [ { size => 4,
                  linestyle => 'Candles',
                  indicators => [{ key => 'SMA', },
                                ],
                },
                { size => 1,
                  indicators => [{ key => 'Volume', }
                                ],
                },
              ],
  };

sub viewstyle_read {
  require App::Chart::DBI;
  my $str = App::Chart::DBI->read_single
    ('SELECT value FROM preference WHERE key=\'viewstyle\'');
  if (! defined $str) { return DEFAULT_VIEWSTYLE; }
  my $viewstyle = eval $str;
  if (! defined $viewstyle) {
    print "chart: oops, bad viewstyle in database, using default: $@";
    return DEFAULT_VIEWSTYLE;
  }
 return $viewstyle;
}
# viewstyle_write(DEFAULT_VIEWSTYLE);
# print viewstyle_read(DEFAULT_VIEWSTYLE);
# exit 0;
sub viewstyle_write {
  my ($viewstyle) = @_;
  require App::Chart::DBI;
  require Data::Dumper;
  my $str = Data::Dumper->new([$viewstyle],['viewstyle'])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  $dbh->do ('INSERT OR REPLACE INTO preference (key, value)
             VALUES (\'viewstyle\',?)', {}, $str);
  App::Chart::chart_dirbroadcast()->send ('viewstyle-changed');
}

#------------------------------------------------------------------------------

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'symbol'} = '';  # per property default above
  $self->{'series_list'} = [];
  $self->{'timebase_class'} = DEFAULT_TIMEBASE_CLASS;
  $self->{'graphs'} = [];
  $self->set(n_rows => 9,
             n_columns => 3);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('data-changed', \&_do_data_changed, $self);

  # FIXME: this induces a rescale at a good time, but otherwise not wanted
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('latest-changed', \&_do_data_changed, $self);

  App::Chart::Gtk2::GUI::chart_style_widget ('AppChartViewLabel');
  my $ebox = $self->{'initial'} = Gtk2::EventBox->new;
  $ebox->set_name ('AppChartViewLabel');
  my $label = Gtk2::Label->new
    (__('Use File/Open to open or add a symbol'));
  $label->set_name ('AppChartViewLabel');
  $ebox->add ($label);
  $ebox->show_all;

  $self->attach ($ebox, 0,3, 0,9,
                 ['fill','shrink','expand'],
                 ['fill','shrink','expand'], 0,0);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'viewstyle') {
    if (! $self->{'init_graphs'}) {
      return viewstyle_read();
    }
  }
  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};
  ### View SET_PROPERTY: $pname
  ### $newval

  if ($pname eq 'symbol') {
    $self->set_symbol ($newval);
    return;
  }

  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'timebase_class') {
    if ($oldval ne $newval) {
      $self->set_symbol ($self->get('symbol'));
    }

  } elsif ($pname eq 'statusbar') {
    # lose old id
    delete $self->{'crosshair_status_id'};

  } elsif ($pname eq 'viewstyle') {
    if ($self->{'init_graphs'}) {
      _update_attach ($self);
    }
    if ($self->{'symbol'}) {
      _set_symbol ($self, $self->{'symbol'});
    }
  }
}

#------------------------------------------------------------------------------
# Crosshair

sub crosshair {
  my ($self) = @_;
  return ($self->{'crosshair_object'}
          ||= do {
            _init_graphs ($self);
            require Gtk2::Ex::CrossHair;
            my $ch = Gtk2::Ex::CrossHair->new (widgets => $self->{'graphs'},
                                               foreground => 'orange');
            $ch->signal_connect (moved => \&_do_crosshair_moved,
                                App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
            ### View created crosshair: "$ch"
            $ch;
          });
}

sub _do_crosshair_moved {
  my ($crosshair, $graph, $x, $y, $ref_weak_self) = @_;
  my $self = $$ref_weak_self or return;
  ### View _do_crosshair_moved()

  my $statusbar = $self->{'statusbar'} || return;
  my $id = $statusbar->get_context_id (__PACKAGE__ . '.crosshair');
  $statusbar->pop ($id);

  if (! defined $x) { return; }
  my $series = $graph->get('series-list')->[0] || return;

  my $t = $graph->x_to_date ($x);
  my $dstr = $series->timebase->strftime ($App::Chart::option{'d_fmt'}, $t);

  my $value = $graph->y_to_value ($y);
  my $nf = App::Chart::number_formatter();
  my $pstr = $nf->format_number ($value, $series->decimals, 0);

  my $status = $dstr . '  ' . $pstr;
  ### $id
  ### $status
  $statusbar->push ($id, $status);
}


sub _do_lasso_ended {
}

sub _do_graph_button_press {
  my ($graph, $event) = @_;
  my $self = $graph->get_ancestor (__PACKAGE__);

  if ($event->button == 3) {
    $self->crosshair->start ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

#------------------------------------------------------------------------------

sub set_symbol {
  my ($self, $symbol) = @_;
  $self->{'symbol'} = $symbol;
  if ($self->realized) {
    _set_symbol ($self, $symbol);
  } else {

    # a nasty hack to get initial pages for scaling after windows realized
    $self->{'realize_set_symbol_id'} ||=
      $self->signal_connect (realize => sub {
                               my ($self) = @_;
                               # once only
                               my $id = delete $self->{'realize_set_symbol_id'};
                               $self->signal_handler_disconnect ($id);
                               _set_symbol ($self, $self->{'symbol'});
                             });
  }
  $self->notify ('symbol');
}

sub _init_graphs {
  my ($self) = @_;
  if ($self->{'init_graphs'}) { return; }
  ### View _init_graphs()
  $self->{'init_graphs'} = 1;
  $self->{'viewstyle'} = viewstyle_read();

  require App::Chart::Gtk2::Graph;
  require App::Chart::Gtk2::HAxis;

  App::Chart::Gtk2::GUI::chart_style_class ('Gtk2::Ex::NumAxis');

  require App::Chart::Gtk2::Heading;
  $self->{'heading'} = App::Chart::Gtk2::Heading->new;

  # initial horiz scale 4 pixels per date
  require App::Chart::Gtk2::HScale;
  my $hadj = $self->{'hadjustment'}
    = App::Chart::Gtk2::HScale->new (pixel_per_value => 4);
  $self->{'haxis'}   = App::Chart::Gtk2::HAxis->new (adjustment => $hadj);
  $self->{'hscroll'} = Gtk2::HScrollbar->new ($hadj);

  _update_attach ($self);
  $self->show_all;

  #   # this is a nasty hack to force the Gtk2::Table to set its childrens'
  #   # sizes now, instead of later under the queue_resize or whatever
  #   $self->size_allocate ($self->allocation);

  if (my $ebox = delete $self->{'initial'}) {
    $self->remove ($ebox);
  }
}

#   0              1  2  3
# 0 +--------------+--+--+
#   | heading            |
# 1 +--------------+--+--+
#   |              |v |v |
#   | upper        |a |s |
#   |              |x |c |
#   |              |i |r |
#   |              |s |o |
#   |              |  |l |
#   |              |  |l |
# 5 +--------------+--+--+
#   | gap                |
# 6 +--------------+--+--+
#   |              |v |v |
#   | lower        |a |s |
#   |              |x |b |
# 7 +--------------+--+--+
#   | haxis        |     |
# 8 +--------------+     |
#   | hscroll      |     |
# 9 +--------------+--+--+
#
sub _update_attach {
  my ($self) = @_;
  require Gtk2::Ex::TableBits;

  my $y = 0;
  Gtk2::Ex::TableBits::update_attach
      ($self, $self->{'heading'}, 0,3, $y,$y+1,
       ['fill','shrink','expand'], [], 0,0);
  $y++;

  my $graphs = $self->{'graphs'};
  my @graphstyles = @{$self->{'viewstyle'}->{'graphs'}};
  while ($#$graphs > max (0, $#graphstyles)) {
    my $graph = pop @$graphs;
    $self->remove ($graph);
    $self->remove ($graph->{'noshrink'});
    $self->remove ($graph->{'vscroll'});
  }
  $graphs->[0] ||= do {
    my $upper = _make_graph($self);
    delete $upper->{'heading_in_graph'};
    $self->{'hadjustment'}->set (widget => $upper);
    Glib::Ex::ConnectProperties->new ([$upper,'series-list'],
                                      [$self->{'heading'},'series-list']);
    $upper;
  };

  for (my $i = 0; $i < @graphstyles; $i++) {
    my $graph = ($graphs->[$i] ||= _make_graph($self));
    ### now graphs: "@$graphs"

    if ($i > 0) {
      my $gap = ($graph->{'gap'} ||= Glib::Object::new ('Gtk2::DrawingArea',
                                                        height_request => 2));
      Gtk2::Ex::TableBits::update_attach
          ($self, $gap, 0,3, $y,$y+1,
           [], [], 0,0);
      $y++;
    }

    my $graphstyle = $graphstyles[$i];
    my $size = $graphstyle->{'size'};

    Gtk2::Ex::TableBits::update_attach
        ($self, $graph, 0,1, $y,$y+$size,
         ['fill','shrink','expand'],
         ['fill','shrink','expand'], 0,0);
    Gtk2::Ex::TableBits::update_attach
        ($self, $graph->{'noshrink'},
         1,2, $y,$y+$size,
         ['fill','shrink'],
         ['fill','shrink','expand'], 0,0);
    Gtk2::Ex::TableBits::update_attach
        ($self, $graph->{'vscroll'},
         2,3, $y,$y+$size,
         ['fill','shrink'],
         ['fill','shrink','expand'], 0,0);
    $y += $size;
  }

  Gtk2::Ex::TableBits::update_attach
      ($self, $self->{'haxis'}, 0,1, $y,$y+1,
       ['fill','shrink','expand'],
       ['fill','shrink'], 0,0);
  $y++;
  Gtk2::Ex::TableBits::update_attach
      ($self, $self->{'hscroll'}, 0,1, $y,$y+1,
       ['fill','shrink','expand'],
       ['fill','shrink'], 0,0);
  $y++;

  if (my $cross = $self->{'crosshair_object'}) {
    ### _update_attach() cross widgets: "@$graphs"
    $cross->set (widgets => $graphs);
  }

  $self->resize (3, $y);
}

sub _make_graph {
  my ($self) = @_;

  require App::Chart::Gtk2::Graph;
  require App::Chart::Gtk2::AdjScale;
  my $vadj = App::Chart::Gtk2::AdjScale->new (orientation => 'vertical',
                                        inverted => 1);
  my $graph = App::Chart::Gtk2::Graph->new (hadjustment => $self->{'hadjustment'},
                                      vadjustment => $vadj);
  $graph->{'heading_in_graph'} = 1;
  $vadj->set (widget => $graph);
  $graph->signal_connect (button_press_event => \&_do_graph_button_press);

  require Gtk2::Ex::NumAxis;
  my $vaxis = $graph->{'vaxis'}
    = Gtk2::Ex::NumAxis->new (adjustment => $vadj,
                              inverted   => 1);
  $vaxis->signal_connect (number_to_text => \&_vaxis_number_to_text);

  require Gtk2::Ex::NoShrink;
  $graph->{'noshrink'} = Gtk2::Ex::NoShrink->new (child => $vaxis);
  my $vscroll = $graph->{'vscroll'} = Gtk2::VScrollbar->new ($vadj);
  $vscroll->set_inverted (1);

  $vaxis->add_events (['button-press-mask',
                       'button-motion-mask',
                       'button-release-mask']);
  $vaxis->signal_connect (button_press_event => \&_do_vaxis_button_press);
  $graph->show_all;
  return $graph;
}

sub _vaxis_number_to_text {
  my ($axis, $number, $decimals) = @_;
  return App::Chart::number_formatter()->format_number ($number, $decimals, 1);
}


sub _do_vaxis_button_press {
  my ($vaxis, $event) = @_;
  if ($event->button == 1) {
    require Gtk2::Ex::Dragger;
    my $dragger = ($vaxis->{'dragger'} ||=
                   Gtk2::Ex::Dragger->new
                   (widget      => $vaxis,
                    vadjustment => $vaxis->get('adjustment'),
                    vinverted   => 1,
                    cursor      => 'sb-v-double-arrow',
                    confine     => 1));
    $dragger->start ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _set_symbol {
  my ($self, $symbol) = @_;
  if (! $symbol) { return; }

  _init_graphs ($self);

  my $hadj = $self->{'hadjustment'};
  my $haxis = $self->{'haxis'};

  if (! $symbol) {
    foreach my $graph (@{$self->{'graphs'}}) {
      $graph->set('series_list', []);
      $graph->get('vadjustment')->empty
    }
    $hadj->empty;
    return;
  }

  require App::Chart::Series::Database;
  my $series = App::Chart::Series::Database->new ($symbol);

  my $viewstyle = $self->{'viewstyle'};
  if ($viewstyle->{'adjust_splits'}
      || $viewstyle->{'adjust_dividends'}
      || $viewstyle->{'adjust_rollovers'}) {
    require App::Chart::Series::Derived::Adjust;
    $series = App::Chart::Series::Derived::Adjust->derive
      ($series,
       adjust_splits     => $viewstyle->{'adjust_splits'},
       adjust_dividends  => $viewstyle->{'adjust_dividends'},
       adjust_imputation => $viewstyle->{'adjust_imputation'},
       adjust_rollovers  => $viewstyle->{'adjust_rollovers'});
  }

  my $timebase_class = $self->{'timebase_class'};
  if (! $series->timebase->isa ($timebase_class)) {
    ### collapse to: $timebase_class
    $series = $series->collapse ($timebase_class);
  }

  my $timebase = $series->timebase;
  $haxis->set(timebase => $timebase);

  my $graphstyles = $viewstyle->{'graphs'} || [];
  my $graphs = $self->{'graphs'};

  require App::Chart::Gtk2::Graph::Plugin::Latest;
  require App::Chart::Gtk2::Graph::Plugin::Today;
  require App::Chart::Gtk2::Graph::Plugin::Text;
  require App::Chart::Gtk2::Graph::Plugin::AnnLines;
  my @hrange = (0, $series->hi);
  my @today_hrange;

  for (my $i = 0; $i < @$graphstyles; $i++) {
    my $graphstyle = $graphstyles->[$i];
    my $graph = $graphs->[$i] || die;
    my $series_list = graphstyle_to_series_list ($graphstyle, $series);

    # date range for series, latest, and perhaps today
    if ($i == 0) {
      push @hrange,
        (@today_hrange = App::Chart::Gtk2::Graph::Plugin::Today->hrange ($graph, $series_list));
      push @hrange,
        (App::Chart::Gtk2::Graph::Plugin::Latest->hrange ($graph, $series_list),
         App::Chart::Gtk2::Graph::Plugin::Text->hrange ($graph, $series_list),
         App::Chart::Gtk2::Graph::Plugin::AnnLines->hrange ($graph, $series_list));
    }

    $graph->set('series_list', []);
    $graph->set('series_list', $series_list);
    my $decimals = max (0, map {$_->decimals} @$series_list);
    $graph->{'vaxis'}->set (min_decimals => $decimals);
    ### graph: "$i decimals $decimals"
  }

  require List::MoreUtils;
  my ($lower, $upper) = List::MoreUtils::minmax (@hrange);
  $upper += 2;  # +1 for inclusive, +1 for bit of margin

  # rightmost edge
  my $value = $upper;
  my $today = $today_hrange[0];
  if (defined $today) {
    if ($upper > $today + 10) {
      $value = $today + 4;
    }
  }
  $value -= $hadj->page_size;
  $lower = min ($lower, $value);

  ### View decide hadj: "$lower to $upper, value=$value"
  Gtk2::Ex::AdjustmentBits::set_maybe ($hadj,
                                       lower => $lower,
                                       upper => $upper,
                                       value => $value);
  ### View hadj: $hadj->lower." to $upper =",$timebase->to_iso($upper)
  my ($lo, $hi) = $hadj->value_range_inc;

  foreach my $graph (@$graphs) {
    $graph->update_v_range;

    #     my $series_list = $graph->{'series_list'};
    #     my $this_series = $series_list->[0] || next;
    #
    #     my ($p_lo, $p_hi) = $this_series->range ($lo, $hi);
    #     if (! defined $p_lo) {
    #       $p_hi = $p_lo = 0;
    #     }
    #     ### View graph vrange: "$p_lo $p_hi"
    #     Gtk2::Ex::AdjustmentBits::set_maybe ($graph->get('vadjustment'),
    #                                          lower => $p_lo,
    #                                          upper => $p_hi);
  }
}

sub graphstyle_to_series_list {
  my ($graphstyle, $series) = @_;
  ### View graphstyle_to_series_list()
  my @series_list;

  # top-level series goes into upper graph only
  if (exists $graphstyle->{'linestyle'}
      && ($graphstyle->{'linestyle'}||'') ne 'None') {
    $series->linestyle($graphstyle->{'linestyle'});
    push @series_list, $series;
  }

  foreach my $indicatorstyle (@{$graphstyle->{'indicators'}}) {
    my $key = $indicatorstyle->{'key'} || next;
    if ($key eq 'None') { next; }
    ### $indicatorstyle

    if (! $series->can($key)) {
      warn "Ignoring unknown indicator '$key'";
      next;
    }

    require App::Chart::IndicatorInfo;
    my $info = App::Chart::IndicatorInfo->new ($key);
    my @params;
    foreach my $paraminfo (@{$info->parameter_info}) {
      my $paramkey = $paraminfo->{'key'};
      push @params, ($indicatorstyle->{$paramkey}
                     // $paraminfo->{'default'});
    }
    ### @params
    my $derived = $series->$key (@params);
    push @series_list, $derived;
  }
  return \@series_list;
}

# 'data-changed'
sub _do_data_changed {
  my ($self, $symbol_hash) = @_;
  my $symbol = $self->{'symbol'} // return;
  if (exists $symbol_hash->{$symbol}) {
    ### "View _do_data_changed() displayed symbol: $symbol
    _set_symbol ($self, $symbol);
  }
}

sub centre {
  my ($self) = @_;
  $self->{'graphs'}->[0]->centre;
  #  $self->{'lower'}->centre;
}

sub zoom {
  my ($self, $xfactor, $yfactor) = @_;
  if ($xfactor != 1) {
    my $hadj = $self->{'hadjustment'};
    my $ppv = $hadj->get_pixel_per_value;
    my $new_ppv = POSIX::ceil ($xfactor * $ppv);
    if ($ppv == $new_ppv) {
      if ($xfactor < 1) {
        $new_ppv = max (1, $new_ppv-1);
      } else {
        $new_ppv = $new_ppv+1;
      }
    }
    if ($ppv != $new_ppv) {
      $hadj->set_pixel_per_value ($new_ppv);
    }
  }
  if ($yfactor != 1) {
    foreach my $graph (@{$self->{'graphs'}}) {
      my $vadj = $graph->get('vadjustment');
      $vadj->set_pixel_per_value ($yfactor * $vadj->get_pixel_per_value);
    }
  }
}

1;
__END__

=for stopwords viewstyle

=head1 NAME

App::Chart::Gtk2::View -- view widget of heading, graphs, axes, scrollbars, etc

=head1 SYNOPSIS

 my $view = App::Chart::Gtk2::View->new;

=head1 DESCRIPTION

A C<App::Chart::Gtk2::View> widget displays graphs of the data from a given stock
symbol, with a "viewstyle" controlling what graphs and indicators are
presented.

=head1 FUNCTIONS

=over 4

=item C<< $view->symbol >>

Return the currently displayed stock symbol (a string), or C<undef> if none.

=item C<< $view->centre >>

Centre the displayed data within the graph windows.  This is the
"View/Centre" menu item in the main GUI.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (string, default none)

=back

=cut
