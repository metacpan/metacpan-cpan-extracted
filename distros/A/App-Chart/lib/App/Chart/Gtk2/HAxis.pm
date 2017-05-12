# Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

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

package App::Chart::Gtk2::HAxis;
use 5.008;
use strict;
use warnings;
use Glib::Ex::SignalIds;
use Gtk2 1.220;
use POSIX ();
use POSIX::Wide;
use List::Util qw(min max);
use List::MoreUtils;
# use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Series;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  signals => { expose_event       => \&_do_expose_event,
               button_press_event => \&_do_button_press_event,
               size_request       => \&_do_size_request,
               configure_event    => \&_do_configure_event,
               style_set          => \&_do_style_set,
               set_scroll_adjustments =>
               { param_types => ['Gtk2::Adjustment',
                                 'Gtk2::Adjustment'],
                 return_type => undef,
                 class_closure => \&_do_set_scroll_adjustments },
               start_drag =>
               { param_types => ['Glib::Int'],
                 return_type => undef,
                 class_closure => \&_do_start_drag,
                 flags => ['run-first','action'] },
             },
  properties => [Glib::ParamSpec->object
                 ('adjustment',
                  'adjustment',
                  '',
                  'Gtk2::Adjustment',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('timebase',
                  'timebase',
                  'A perl App::Chart::Timebase object.',
                  Glib::G_PARAM_READWRITE),
                ];
App::Chart::Gtk2::GUI::chart_style_class (__PACKAGE__);

use constant {
              # height of small and medium tick marks, as a fraction of line_height, and
              # then the gap between the medium tick and the labels similarly
              SMALL_TICK_LINE_FRAC  => 0.2,
              MEDIUM_TICK_LINE_FRAC => 0.4,
              MEDIUM_GAP_LINE_FRAC  => 0.1,

              # space at the left and right of the labels, in "em"s
              LABEL_LEFT_SPACE_EMS => 0.7,
              LABEL_RIGHT_SPACE_EMS => 1.2,
             };

# strftime() is a bit slow, so do this with some private functions just
# concatenating bits.  Each function is called like B_Y($year,$month,$day)
# and returns a string.
#
my @fullmonth;
my @shortmonth;
sub B_Y { return $fullmonth[$_[1]]  . ' ' . $_[0]; }
sub b_Y { return $shortmonth[$_[1]] . ' ' . $_[0]; }
sub b_y { return sprintf '%s %02d', $shortmonth[$_[1]], $_[0] % 100; }
sub by  { return sprintf '%s%02d',  $shortmonth[$_[1]], $_[0] % 100; }
sub Y   { return $_[0]; }
sub y   { return sprintf '%02d', $_[0] % 100; }

# Possible format string func and timebase interval.  The first one whose
# string output fits in the display in those timebase interval steps is
# used.
my @format_list = ([ \&B_Y,  'App::Chart::Timebase::Months'   ], # "March 2007"
                   [ \&b_Y,  'App::Chart::Timebase::Months'   ], # "Mar 2007"
                   [ \&b_y,  'App::Chart::Timebase::Months'   ], # "Mar 07"
                   [ \&by,   'App::Chart::Timebase::Months'   ], # "Mar07"
                   [ \&B_Y,  'App::Chart::Timebase::Quarters' ], # "March 2007"
                   [ \&b_Y,  'App::Chart::Timebase::Quarters' ], # "Mar 2007"
                   [ \&b_y,  'App::Chart::Timebase::Quarters' ], # "Mar 07"
                   [ \&by,   'App::Chart::Timebase::Quarters' ], # "Mar07"
                   [ \&Y,    'App::Chart::Timebase::Years'    ], # "2007"
                   [ \&y,    'App::Chart::Timebase::Years'    ], # "07"
                   [ \&Y,    'App::Chart::Timebase::Decades'  ], # "2007"
                   [ \&y,    'App::Chart::Timebase::Decades'  ]);# "07"

# possible timebases to use for drawing the marks
# the base $timebase is expected to be among these, then the medium marks
# are drawn in the one after that
my @marks_timebase_list = qw(App::Chart::Timebase::Days
                             App::Chart::Timebase::Weeks
                             App::Chart::Timebase::Months
                             App::Chart::Timebase::Quarters
                             App::Chart::Timebase::Years
                             App::Chart::Timebase::Decades);

Gtk2::Rc->parse_string (<<'HERE');
binding "App__Chart__Gtk2__HAxis_keys" {
  bind "Pointer_Button1" { "start_drag" (1) }
}
# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
class "App__Chart__Gtk2__HAxis" binding:gtk "App__Chart__Gtk2__HAxis_keys"
HERE

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->add_events (['button-press-mask',
                      'button-motion-mask',
                      'button-release-mask']);
  $self->{'layout'} = $self->create_pango_layout ('');

  if (! @fullmonth) {
    my $fill = sub {
      my ($fmt, $aref) = @_;
      foreach my $mon (0 .. 11) {
        $aref->[$mon+1]
          = POSIX::Wide::strftime ($fmt,
                                   0,0,0,     # midnight
                                   1,$mon,80, # 1st $mon 1980
                                   0,0,0);
      }
    };
    $fill->('%B', \@fullmonth);
    $fill->('%b', \@shortmonth);
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'adjustment') {
    my $adj = $newval;
    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak ($self);
    $self->{'adjustment_ids'} = $adj && Glib::Ex::SignalIds->new
      ($adj,
       $adj->signal_connect (value_changed => \&_do_adj_value_changed,
                             $ref_weak_self),
       $adj->signal_connect (changed => \&_do_adj_other_changed,
                             $ref_weak_self));
  }
  _reset_scale ($self);
  $self->queue_draw;
}

# 'set-scroll-adjustments' class closure
sub _do_set_scroll_adjustments {
  my ($self, $hadj, $vadj) = @_;
  $self->set (adjustment => $hadj);
}

# mark that the scale has somehow changed, so the label_timebase and format
# should be recalculated (on the next draw)
sub _reset_scale {
  my ($self) = @_;
  $self->{'sizes'} = undef;
}

sub _establish_bases {
  my ($self) = @_;
  $self->{'sizes'} = undef; # if no adj etc
  my $adj       = $self->{'adjustment'} || return;
  my $timebase  = $self->{'timebase'}   || return;
  # my $page_size = $adj->page_size       || return;
  # my $win       = $self->window         || return;

  my $sizes = $self->{'sizes'} = {};
  my $layout = $self->{'layout'};
  my $em     = Gtk2::Ex::Units::em($layout);
  my $line_height = Gtk2::Ex::Units::line_height ($layout);
  # my ($win_width, $win_height) = $win->get_size;
  my $x_step = $adj->get_pixel_per_value;

  $sizes->{'small_y'}  = POSIX::ceil (SMALL_TICK_LINE_FRAC * $line_height);
  $sizes->{'medium_y'} = POSIX::ceil (MEDIUM_TICK_LINE_FRAC * $line_height);
  $sizes->{'text_y'}
    = $sizes->{'medium_y'} + POSIX::ceil (MEDIUM_GAP_LINE_FRAC * $line_height);

  # establish $medium_timebase as the entry in @marks_timebase_list which
  # is one above $timebase
  {
    my @a = List::MoreUtils::after {$timebase->isa($_)}
      @marks_timebase_list;
    if (@a) {
      my $medium_timebase_class = $a[0];
      require Module::Load;
      Module::Load::load ($medium_timebase_class);

      # medium_timebase from the class name, with an arbitrary start base
      $sizes->{'medium_timebase'}
        = $medium_timebase_class->new_from_ymd (1970,1,5);
    }
  }

  my $label_x_offset = $sizes->{'label_x_offset'}
    = POSIX::ceil ($em * LABEL_LEFT_SPACE_EMS);
  foreach my $elem (@format_list) {
    my ($format_func, $timebase_class) = @$elem;

    require Module::Load;
    Module::Load::load ($timebase_class);

    # label_timebase from the class name, with an arbitrary start base
    my $label_timebase = $timebase_class->new_from_ymd (1970,1,5);
    my $t_width = $x_step
      * ($timebase->convert_from_floor ($label_timebase, 1)
         - $timebase->convert_from_floor ($label_timebase, 0));
    my $label_width = $label_x_offset
      + format_func_width ($layout, $format_func)
        + POSIX::ceil ($em * LABEL_RIGHT_SPACE_EMS);
    if (DEBUG) {
      print "$label_timebase label $label_width versus $t_width\n"; }

    if ($label_width < $t_width || $elem == $format_list[-1]) {
      $sizes->{'label_timebase'} = $label_timebase;
      $sizes->{'format_func'} = $format_func;
      last;
    }
  }

  if (DEBUG) { require Data::Dumper;
               print "HAxis sizes ", Data::Dumper::Dumper($sizes);
               print "  em=$em\n";
               print "  x_step=$x_step\n";
             }
  return $sizes;
}

# 'expose-event' class closure
sub _do_expose_event {
  my ($self, $event) = @_;
  if (DEBUG >= 2) { print "HAxis expose\n"; }
  my $sizes = ($self->{'sizes'} || _establish_bases($self));

  # must have an adjustment and timebase set and a non-empty page to draw
  # anything
  my $adj = $self->{'adjustment'}    || return Gtk2::EVENT_PROPAGATE;
  my $timebase = $self->{'timebase'} || return Gtk2::EVENT_PROPAGATE;
  # my $page_size = $adj->page_size    || return Gtk2::EVENT_PROPAGATE;

  my $layout = $self->{'layout'};
  my $style  = $self->style;
  my $state  = $self->state;
  my $gc     = $style->fg_gc($state);
  my $win    = $self->window;
  my $value_to_pixel_proc = $adj->value_to_pixel_proc;

  my $t_lo = POSIX::floor ($adj->value);
  my $t_hi = POSIX::ceil ($adj->value + $adj->page_size);
  if (DEBUG >= 2) { print "  values $t_lo to $t_hi  ",
                      $timebase->to_iso($t_lo), " to ",
                        $timebase->to_iso($t_hi), "\n"; }

  # small tick marks at every $timebase increment, unless that's every pixel
  #
  my $x_step = $adj->get_pixel_per_value;
  if ($x_step > 1) {
    my $small_y = $sizes->{'small_y'};
    $win->draw_segments ($gc, map { my $x = $value_to_pixel_proc->($_);
                                    ($x,0, $x,$small_y) }
                         ($t_lo .. $t_hi));
  }

  # medium tick marks at every $medium_timebase increment, if such a timebase
  #
  if (my $medium_timebase = $sizes->{'medium_timebase'}) {
    my $medium_y = $sizes->{'medium_y'};
    my $medium_t_lo
      = $medium_timebase->convert_from_floor ($timebase, $t_lo) - 1;
    my $medium_t_hi
      = $medium_timebase->convert_from_floor ($timebase, $t_hi) + 1;
    if (DEBUG >= 2) { print "  medium $medium_t_lo to $medium_t_hi  ",
                        $medium_timebase->to_iso($medium_t_lo), " to ",
                          $medium_timebase->to_iso($medium_t_hi), "\n"; }

    $win->draw_segments ($gc, map {
      my $t = $timebase->convert_from_floor ($medium_timebase, $_);
      my $x = $value_to_pixel_proc->($t);
      ($x,0, $x,$medium_y) }
                         ($medium_t_lo .. $medium_t_hi));
  }

  # label and full length tick mark at every $label_timebase increment, if
  # such a timebase
  #
  if (my $label_timebase  = $sizes->{'label_timebase'}) {
    my $label_x_offset = $sizes->{'label_x_offset'};
    my $text_y = $sizes->{'text_y'};
    my $format_func = $sizes->{'format_func'};
    my $label_t_lo
      = $label_timebase->convert_from_floor ($timebase, $t_lo) - 1;
    my $label_t_hi
      = $label_timebase->convert_from_ceil ($timebase, $t_hi) + 1;
    if (DEBUG >= 2) { print "  label $label_t_lo to $label_t_hi  ",
                        $label_timebase->to_iso($label_t_lo), " to ",
                          $label_timebase->to_iso($label_t_hi), "\n"; }
    my ($win_width, $win_height) = $win->get_size;

    foreach my $label_t ($label_t_lo .. $label_t_hi) {
      my $t = $timebase->convert_from_floor ($label_timebase, $label_t);
      my $x = $value_to_pixel_proc->($t);
      $win->draw_line ($gc, $x, 0, $x, $win_height);

      my $str = $format_func->($label_timebase->to_ymd ($label_t));
      $layout->set_text ($str);
      $style->paint_layout ($win,        # window
                            $state,
                            1,  # use_text, for text gc instead of the fg one
                            $event->area,
                            $self,       # widget
                            __PACKAGE__, # style detail string
                            $x + $label_x_offset,
                            $text_y,
                            $layout);
    }
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_adj_value_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->queue_draw;
}

sub _do_adj_other_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _reset_scale ($self);  # for new page_size
  $self->queue_draw;     # for new page_size
}

# 'button-press-event' class closure
sub _do_button_press_event {
  my ($self, $event) = @_;
  require App::Chart::Gtk2::Ex::BindingBits;
  App::Chart::Gtk2::Ex::BindingBits::activate_button_event
      ('App__Chart__Gtk2__HAxis_keys', $event, $self);
  return shift->signal_chain_from_overridden(@_);
}

sub _do_start_drag {
  my ($self, $button) = @_;
  if (DEBUG) { print "HAxis _do_start_drag\n"; }
  my $adj = $self->{'adjustment'} || return; # only when an adj set
  require Gtk2::Ex::Dragger;
  my $dragger = ($self->{'dragger'} ||= Gtk2::Ex::Dragger->new
                 (widget      => $self,
                  hadjustment => $adj,
                  cursor      => 'sb-h-double-arrow',
                  confine     => 1));
  $dragger->start (Gtk2->get_current_event);
}

# 'size_request' class closure
sub _do_size_request {
  my ($self, $req) = @_;

  my $layout = $self->{'layout'};
  my $line_height = Gtk2::Ex::Units::line_height($layout);

  $req->width (0);
  $req->height ($line_height
                + POSIX::ceil ($line_height * MEDIUM_TICK_LINE_FRAC)
                + POSIX::ceil ($line_height * MEDIUM_GAP_LINE_FRAC));
}

# 'style-set' class closure
sub _do_style_set {
  my ($self, $prev_style) = @_;

  # update as advised by gtk_widget_create_pango_layout()
  $self->{'layout'}->context_changed;

  _reset_scale ($self);   # new font perhaps
  $self->queue_resize;
  $self->queue_draw;
  return shift->signal_chain_from_overridden(@_);
}

# 'configure-event' class closure
sub _do_configure_event {
  my ($self, $event) = @_;
  $self->queue_draw;
  return shift->signal_chain_from_overridden(@_);
}

# Return the width in pixels needed to draw the given $format_func string in
# $layout.
#
# This is only geared towards the month/year formats above.  It goes through
# all the months Jan to Dec to see how they come out, but assumes year 2000
# is as wide as any year will be.
#
sub format_func_width {
  my ($layout, $format_func) = @_;
  return max (map { my $str = $format_func->(2000, $_);
                    $layout->set_text ($str);
                    my ($str_width, $str_height) = $layout->get_pixel_size;
                    $str_width;
                  } 1 .. 12);
}

1;
__END__

=for stopwords undef HAxis

=head1 NAME

App::Chart::Gtk2::HAxis -- horizontal timebase axis display widget

=head1 SYNOPSIS

 my $hscale = App::Chart::Gtk2::HAxis->new();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::HAxis> is a subclass of C<Gtk2::DrawingArea>.

    Gtk2::Widget
      Gtk2::DrawingArea
        App::Chart::Gtk2::HAxis

=head1 DESCRIPTION

A C<App::Chart::Gtk2::HAxis> widget displays tick marks and dates on a
horizontal axis, for use below a C<App::Chart::Gtk2::Graph>.

=head1 PROPERTIES

=over 4

=item C<adjustment> (C<Gtk2::Adjustment>, default undef)

An adjustment object giving the range of dates to display.  The HAxis
display updates as the adjustment moves.

=item C<timebase> (C<App::Chart::Timebase> object, default undef)

The timebase for the dates displayed.  This is used to get the actual
calendar date represented by integer values from the C<adjustment>.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Graph>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

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
