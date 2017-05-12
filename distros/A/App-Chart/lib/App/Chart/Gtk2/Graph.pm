# Graph widget.

# Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::Gtk2::Graph;
use 5.010;
use strict;
use warnings;
use Gtk2 1.220;
use List::Util qw(min max);
use List::MoreUtils 0.24; # version 0.24 for bug fixes
use Module::Load;
use POSIX ();
use Set::IntSpan::Fast 1.10;  # 1.10 for contains_all_range()
use Locale::Messages;
use Locale::TextDomain ('App-Chart');

# alerts and lines last since they're xor based, umm, maybe
use Module::Pluggable require => 1;
my @plugins = sort __PACKAGE__->plugins;
### Graph plugins: @plugins

use Glib::Ex::SignalIds;
use Gtk2::Ex::AdjustmentBits 43; # v.43 for set_maybe()
use Gtk2::Ex::GdkBits 23;        # v.23 for window_clear_region()

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Gtk2::GUI;
use App::Chart::Series;
use App::Chart::Gtk2::Graph::Plugin::Latest;

# uncomment this to run the ### lines
#use Devel::Comments;

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  signals => { button_press_event => \&_do_button_press,
               expose_event       => \&_do_expose_event,
               # size_allocate      => \&_do_size_allocate,
               scroll_event       => \&_do_scroll_event,

               # GtkToolbar in gtk 2.14.7 has a bug in its finalize
               # provoking a ref_count>0 log error if anyone is hooked onto
               # 'parent-set', even if in an unrelated class, so use notify
               # instead
               #
               # parent_set => \&_do_parent_set,
               #
               # notify             => \&_do_notify,

               set_scroll_adjustments =>
               { param_types => ['Gtk2::Adjustment',
                                 'Gtk2::Adjustment'],
                 return_type => undef,
                 class_closure => \&_do_set_scroll_adjustments },

               start_drag => { param_types => ['Glib::Int'],
                               return_type => undef,
                               class_closure => \&_do_start_drag,
                               flags => ['run-first','action'] },
               start_lasso => { param_types => ['Glib::Int'],
                                return_type => undef,
                                class_closure => \&_do_start_lasso,
                                flags => ['run-first','action'] },
               start_annotation_drag =>
               { param_types => ['Glib::Int'],
                 return_type => undef,
                 class_closure => \&_do_start_annotation_drag,
                 flags => ['run-first','action'] },

             },
  properties => [Glib::ParamSpec->object
                 ('hadjustment',
                  Locale::Messages::dgettext('gtk20-properties',
                                             'Horizontal adjustment'),  # per Gtk2::ScrolledWindow
                  'Blurb',
                  'Gtk2::Adjustment',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('vadjustment',
                  Locale::Messages::dgettext('gtk20-properties',
                                             'Vertical adjustment'),  # per Gtk2::ScrolledWindow
                  'Blurb',
                  'Gtk2::Adjustment',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('series-list',
                  'Series list',
                  'Arrayref of perl App::Chart::Series objects.',
                  Glib::G_PARAM_READWRITE),
                ];
App::Chart::Gtk2::GUI::chart_style_class (__PACKAGE__);

# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
Gtk2::Rc->parse_string (<<'HERE');
binding "App__Chart__Gtk2__Graph_keys" {
  bind "<Shift>Pointer_Button1" { "start_lasso" (1) }
  bind "Pointer_Button1" { "start_drag" (1) }
  bind "Pointer_Button2" { "start_annotation_drag" (2) }
}
class "App__Chart__Gtk2__Graph" binding:gtk "App__Chart__Gtk2__Graph_keys"
HERE


#------------------------------------------------------------------------------

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'series_list'} = [];
  $self->set_double_buffered (0);
  $self->add_events (['button-press-mask',
                      'button-motion-mask',
                      'button-release-mask']);
  $self->{'waiting_initial_allocate'} = 1;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Graph SET_PROPERTY(): $pname
  my $oldval = $self->{$pname};
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'hadjustment') {
    my $hadj = $newval;
    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);
    $self->{'hadjustment_ids'} = $hadj && Glib::Ex::SignalIds->new
      ($hadj,
       $hadj->signal_connect(value_changed => \&_do_hadj_value_changed,
                             $ref_weak_self),
       $hadj->signal_connect(changed => \&_do_hadj_other_changed,
                             $ref_weak_self));

  } elsif ($pname eq 'vadjustment') {
    my $vadj = $newval;
    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);
    $self->{'vadjustment_ids'} = $vadj && Glib::Ex::SignalIds->new
      ($vadj,
       $vadj->signal_connect (value_changed => \&_do_vadj_changed,
                              $ref_weak_self),
       $vadj->signal_connect (changed       => \&_do_vadj_changed,
                              $ref_weak_self));

  } elsif ($pname eq 'series_list') {
    # initial page size and position when going from empty to non-empty
    ### Graph set series_list, count: scalar(@$newval)
    if (@$newval && ! @$oldval) {
      $self->initial_scale;
    }
    $self->queue_draw;
  }
}

# sub _do_parent_set {
#   my ($self, $parent) = @_;
#   if (! $parent) {
#     $self->{'waiting_initial_allocate'} = 1;
#   }
#   $self->signal_chain_from_overridden ($parent);
# }

# # 'size-allocate' class closure
# sub _do_size_allocate {
#   my ($self, $alloc) = @_;
#   ### Graph _do_size_allocate(): $alloc->width."x".$alloc->height
#   $self->signal_chain_from_overridden($alloc);
# 
#   # after superclass has set $alloc into $self->allocation
#   if ($alloc->width != 1 && $alloc->height != 1) {
#     if (delete $self->{'waiting_initial_allocate'}) {
#       _initial_scale ($self);
#     }
#   }
# }
# 
# sub _do_notify {
#   my ($self, $pspec) = @_;
#   if ($pspec->get_name eq 'parent') {
#     if (! $self->get_parent) {
#       $self->{'waiting_initial_allocate'} = 1;
#     }
#   }
#   return shift->signal_chain_from_overridden(@_);
# }

sub initial_scale {
  my ($self) = @_;
  $self->{'initial_scale'} = 1;
}

sub _initial_scale {
  my ($self) = @_;
  ### Graph _initial_scale(): "$self"

#   {
#     my $alloc = $self->allocation;
#     ### Graph _initial_scale() size: $alloc->width."x".$alloc->height
#     return if ($alloc->width == 1 || $alloc->height == 1);
#   }

  my $series_list = $self->{'series_list'};
  my $series = $series_list->[0] || do {
    ### no series...
    return;
  };

  my $hadj = $self->{'hadjustment'};
  my $vadj = $self->{'vadjustment'};
  my ($lo, $hi) = $hadj->value_range_inc;
  ### hadj: "$lo $hi, on ".ref($series)

  if (my ($p_lo, $p_hi) = $series->initial_range ($lo, $hi)) {
    ### series initial_range(): ($p_lo//'undef')." to ".($p_hi//'undef')." from $lo to $hi on ".ref($series)
    ($p_lo, $p_hi) = stretch_range ($p_lo, $p_hi);
    ### stretched to: ($p_lo//'undef')." to ".($p_hi//'undef')
    if (defined $p_lo) {
      $vadj->set_page_range ($p_lo, $p_hi);
    }
    $self->queue_draw;
  }
  # expanding on initial ...
  $self->{'vrange_span'} = undef;
  update_v_range ($self);
}

# 'set-scroll-adjustments' class closure
sub _do_set_scroll_adjustments {
  my ($self, $hadj, $vadj) = @_;
  $self->set (hadjustment => $hadj,
              vadjustment => $vadj);
}

sub scale_x_step {
  my ($self) = @_;
  return $self->{'hadjustment'}->get_pixel_per_value;
}

sub scale_x {
  my ($self, $t) = @_;
  return $self->{'hadjustment'}->value_to_pixel ($t);
}

sub scale_x_proc {
  my ($self) = @_;
  return $self->{'hadjustment'}->value_to_pixel_proc;
}

sub x_to_date {
  my ($self, $x) = @_;
  return POSIX::floor ($self->{'hadjustment'}->pixel_to_value ($x));
}

sub scale_y {
  my ($self, $y) = @_;
  return $self->{'vadjustment'}->value_to_pixel ($y);
}

sub scale_y_proc {
  my ($self) = @_;
  return $self->{'vadjustment'}->value_to_pixel_proc;

#   my $price_lo = $self->{'vadjustment'}->get_value;
#   my $price_height = $self->{'vadjustment'}->page_size;
#   if ($price_height == 0) { $price_height = 1; }
#   my ($win_width, $win_height) = $self->window->get_size();
#   my $factor = $win_height / $price_height;
#
#   return sub {
#     my ($price) = @_;
#     return $win_height - $factor * ($price - $price_lo);
#   };
}

sub y_to_value {
  my ($self, $y) = @_;
  return $self->{'vadjustment'}->pixel_to_value ($y);

#   my $win_height = $self->allocation->height;
#   my $vadj = $self->{'vadjustment'};
#   my $factor = $vadj->value
#     + ($win_height - $y) * $vadj->page_size / $win_height;
}

sub draw_t_range {
  my ($self) = @_;
  my $hadj = $self->{'hadjustment'} || return (0, -1);
  my ($lo, $hi) = $hadj->value_range_inc;
  $lo = max (0, $lo);
  return ($lo, $hi);
}

# 'expose' class closure
sub _do_expose_event {
  my ($self, $event) = @_;
  ### Graph _do_expose_event()

  if (delete $self->{'initial_scale'}) {
    _initial_scale ($self);
    $self->queue_draw;
    return Gtk2::EVENT_PROPAGATE;
  }

  my $series_list = $self->get('series_list');
  if (! $self->{'vadjustment'}) { return Gtk2::EVENT_PROPAGATE; }

  my $region = $event->region;
  Gtk2::Ex::GdkBits::window_clear_region ($self->window, $region);

  if (! @$series_list) {
    App::Chart::Gtk2::GUI::draw_text_centred
        ($self, $event, __('Use File/Open to open or add a symbol'));

  } else {
    _draw_region ($self, $region);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _draw_region {
  my ($self, $region) = @_;

  my $series_list = $self->get('series_list');
  my $any = 0;
  foreach my $series (@$series_list) {
    ### Graph draw_region linestyle: $series->linestyle_class
    my $class = $series->linestyle_class // next;
    Module::Load::load ($class);
    $any |= $class->draw ($self, $series, $region);
  }
  if (! $any) {
    App::Chart::Gtk2::GUI::draw_text_centred ($self, $region, __('no data'));
  }

  foreach my $class (@plugins) {
    $class->draw ($self, $region);
  }
}

# 'changed' and 'value-changed' signals on vadjustment
sub _do_vadj_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### Graph vadj changed, redraw: "value=@{[$adj->value]} upper=@{[$adj->upper]} lower=@{[$adj->lower]}"
  #                if ($adj->value < 0) {
  #                  require Devel::StackTrace;
  #                  my $trace = Devel::StackTrace->new;
  #                  print $trace->as_string; # like carp
  #                }

  $self->queue_draw;
}

# Expand $adj so its lower/upper covers all of @values.
#
# If lower==upper==page_size==0 in the existing $adj settings it's treated
# as uninitialized and that 0 lower/upper is ignored, just @values is used.
#
# undefs in @values are ignored, and if all are undef then $adj is not
# changed.
#
sub adjustment_expand {
  my ($adj, @values) = @_;
  @values = grep {defined} @values;
  ### Graph adjustment_expand(): join(' ',@values)
  if (! @values) { return; }

  my ($new_lower, $new_upper) = List::MoreUtils::minmax (@values);
  ### base: "   new_lower $new_lower  new_upper $new_upper"
  ($new_lower, $new_upper) = stretch_range ($new_lower, $new_upper);
  ### stretch: "new_lower $new_lower  new_upper $new_upper"

  my $old_lower = $adj->lower;
  my $old_upper = $adj->upper;
  ### old: "    old_lower $old_lower  old_upper $old_upper  old_page ".$adj->page_size
  if (! ($old_lower == 0 && $old_upper == 0 && $adj->page_size == 0)) {
    ($new_lower, $new_upper) = List::MoreUtils::minmax
      ($new_lower, $new_upper, $old_lower, $old_upper);
  }

  ### new: "    new_lower $new_lower  new_upper $new_upper"
  Gtk2::Ex::AdjustmentBits::set_maybe
      ($adj,
       lower => $new_lower,
       upper => $new_upper);
}

sub stretch_range {
  my ($lo, $hi) = @_;
  my $extra = ($hi - $lo) * 0.1;
  if ($lo < 0) {
    $lo -= $extra;
  } else {
    $lo = max ($lo - $extra, $lo * 0.5);
  }
  $hi += $extra;
  return ($lo, $hi);
}

sub update_v_range {
  my ($self) = @_;
  my $vadj = $self->{'vadjustment'} || return;

  my ($lo, $hi) = $self->draw_t_range;
  my $vrange_span = ($self->{'vrange_span'} ||= do {
    require Set::IntSpan::Fast;
    Set::IntSpan::Fast->new
    });
  if ($vrange_span->contains_all_range ($lo, $hi)) { return; }

  ### Graph update_v_range for: "$lo to $hi"
  my $series_list = $self->{'series_list'};
  adjustment_expand ($vadj,
                     (map {
                       $_->vrange ($self, $series_list);
                     } @plugins),
                     (map {
                       _series_v_range($_, $lo, $hi)
                     } @$series_list));
  $vrange_span->add_range ($lo, $hi);
}
sub _series_v_range {
  my ($series, $lo, $hi) = @_;
  my @ret;
  my $min = $series->minimum;  push @ret, $min;
  my $max = $series->maximum;  push @ret, $max;
  $series->fill ($lo, $hi);

  foreach my $p ($series->filled_low, $series->filled_high) {
    $p // next;
    push @ret, $p;
#     foreach my $w ($p * 1.1, $p / 1.1) {
#       if (defined $min) { $w = max ($w, $min); }
#       if (defined $max) { $w = min ($w, $max); }
#       push @ret, $w;
#     }
  }
  return @ret;
}

# 'value-changed' signal on hadjustment
sub _do_hadj_value_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### Graph hadj changed, v_range and redraw: "value=@{[$adj->value]} upper=@{[$adj->upper]} lower=@{[$adj->lower]}"

  update_v_range ($self);
  $self->queue_draw;
}

# 'changed' signal on hadjustment
*_do_hadj_other_changed = \&_do_hadj_value_changed;
#   my ($adj, $ref_weak_self) = @_;
#   my $self = $$ref_weak_self || return;
#   update_v_range ($self);
#   $self->queue_draw;
# }

# 'button-press-event' class closure
sub _do_button_press {
  my ($self, $event) = @_;
  ### Graph _do_button_press(): $event->button
  require App::Chart::Gtk2::Ex::BindingBits;
  App::Chart::Gtk2::Ex::BindingBits::activate_button_event
      ('App__Chart__Gtk2__Graph_keys', $event, $self);
  return shift->signal_chain_from_overridden(@_);
}

sub centre {
  my ($self) = @_;
  ### Graph centre()
  my $vadj = $self->{'vadjustment'};
  my $page = $vadj->page_size * 0.9; # gap at ends
  my $series_list = $self->{'series_list'};

  my ($lo, $hi) = $self->draw_t_range;
  ### Graph centre() on drawn: "$lo $hi (of ".$self->{'hadjustment'}->lower." ".$self->{'hadjustment'}->upper.")"

  my ($l, $h);
  my $accumulate = sub {
    my ($value) = @_;
    ### accumulate: $value
    if (! defined $value) { return 1; }
    if (! defined $l) { $l = $h = $value; return 1; }

    my $new_l = min ($l, $value);
    my $new_h = max ($h, $value);
    my $new_page = $new_h - $new_l;
    if ($new_page <= $page) {
      $l = $new_l;
      $h = $new_h;
      return 1;
    }

    if ($new_l < $l) {
      $l = $h - $page;
    } else {
      $h = $l + $page;
    }
    return 0;
  };

  if (my $series = $series_list->[0]) {
    if (defined (my $symbol = $series->symbol)) {
      my ($latest_lo,$latest_hi)
        = App::Chart::Gtk2::Graph::Plugin::Latest->hrange ($self, $series_list);
      ### latest hrange: $latest_lo,$latest_hi
      if (defined $lo
          && App::Chart::overlap_inclusive_p ($lo,$hi,
                                              $latest_lo,$latest_hi)) {
        my $latest = App::Chart::Latest->get($symbol);
        if ($series->isa('App::Chart::Series::Derived::Volume')) {
          $accumulate->($latest->{'volume'});
        } else {
          $accumulate->($latest->{'last'})
            and $accumulate->($latest->{'bid'})
              and $accumulate->($latest->{'offer'})
                and $accumulate->($latest->{'high'})
                  and $accumulate->($latest->{'low'});
        }
      }
    }
  }

  my @arrays;
  foreach my $series (@$series_list) {
    $series->fill ($lo, $hi);
    my $values = $series->values_array;
    push @arrays, $values;
    if (my $highs = $series->array('highs')) {
      if ($highs != $values) { push @arrays, $highs; }
    }
    if (my $lows = $series->array('lows')) {
      if ($lows != $values) { push @arrays, $lows; }
    }
  }

 OUTER: for (my $i = $hi; $i >= $lo; $i--) {
    foreach my $array (@arrays) {
      $accumulate->($array->[$i])
        or last OUTER;
    }
  }
  if (! defined $l) { return; }
  ### decided: "$l to $h"

  my $extra = $page - ($h - $l);
  $l -= $extra / 2;
  ### expand to: "low $l on page $page"
  $vadj->set_value ($l);
}


#------------------------------------------------------------------------------
# scrolling

# 'scroll-event' class closure
sub _do_scroll_event {
  my ($self, $event) = @_;
  ### Graph _do_scroll_event(): "$self->{'hadjustment'}, $self->{'vadjustment'}"

  my $direction = $event->direction;
  if    ($direction eq 'up')    { $self->{'vadjustment'}->scroll_step(1); }
  elsif ($direction eq 'down')  { $self->{'vadjustment'}->scroll_step(-1); }
  elsif ($direction eq 'left')  { $self->{'hadjustment'}->scroll_step(1); }
  elsif ($direction eq 'right') { $self->{'hadjustment'}->scroll_step(-1); }

  return $self->signal_chain_from_overridden ($event);
}


#------------------------------------------------------------------------------
# action signal handlers

sub _do_start_drag {
  my ($self, $button) = @_;
  my $hadj = $self->{'hadjustment'} || return; # only when adj set
  my $vadj = $self->{'vadjustment'} || return; # only when adj set
  my $dragger = ($self->{'dragger'} ||= do {
    require Gtk2::Ex::Dragger;
    Gtk2::Ex::Dragger->new (widget => $self,
                            hadjustment => $hadj,
                            vadjustment => $vadj,
                            vinverted   => 1,
                            confine     => 1,
                            cursor      => 'fleur')
    });
  $dragger->start (Gtk2->get_current_event);
}

sub _do_start_lasso {
  my ($self, $button) = @_;
  my $lasso = ($self->{'lasso'} ||= do {
    require Gtk2::Ex::Lasso;
    my $l = Gtk2::Ex::Lasso->new (widget => $self);
    $l->signal_connect (ended => \&_do_lasso_ended);
    $l
  });
  $lasso->start (Gtk2->get_current_event);
}
sub _do_lasso_ended {
  my ($lasso, $x1,$y1, $x2,$y2) = @_;
  my $self = $lasso->get('widget') || return;

  my $hadj = $self->{'hadjustment'};
  my $t1 = $self->x_to_date ($x1);
  my $t2 = $self->x_to_date ($x2);
  $hadj->set_value_range (min($t1,$t2), max($t1,$t2));

  my $vadj = $self->{'vadjustment'};
  my $p1 = $self->y_to_value ($y1);
  my $p2 = $self->y_to_value ($y2);
  $vadj->set_value_range (min($p1,$p2), max($p1,$p2));
}

sub _do_start_annotation_drag {
  my ($self, $button) = @_;
  require App::Chart::Gtk2::AnnDrag;
  App::Chart::Gtk2::AnnDrag::start ($self, Gtk2->get_current_event);
}


1;
__END__

=head1 NAME

App::Chart::Gtk2::Graph -- graph widget

=for test_synopsis my ($series1, $series2)

=head1 SYNOPSIS

 use App::Chart::Gtk2::Graph;
 my $image = App::Chart::Gtk2::Graph->new();
 $image->set('series_list', [ $series1, $series2 ]);

=head1 DESCRIPTION

A App::Chart::Gtk2::Graph widget displays a graph of a set of
L<App::Chart::Series> objects.

=head1 FUNCTIONS

=over 4

=item C<< $graph->centre() >>

...

=back

=head1 PROPERTIES

=over 4

=item C<series_list> (arrayref)

A reference to an array of C<App::Chart::Series> objects to display.

=back

=head1 SEE ALSO

L<App::Chart::Series>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
