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

package App::Chart::Gtk2::AnnDrag;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;

use Gtk2::Ex::WidgetBits;
use App::Chart::Gtk2::Graph::Plugin::Alerts;

Gtk2->CHECK_VERSION(2,12,0)
  or die "Need Gtk 2.12 or higher";  # for ->error_bell

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::Object',
  signals => { abort => { param_types   => [],
                          return_type   => undef,
                          flags         => ['run-last','action'],
                          class_closure => \&_do_abort,
                        },
               toggle_alert => { param_types   => [],
                                 return_type   => undef,
                                 flags         => ['run-last','action'],
                                 class_closure => \&_do_toggle_alert,
                               },
               swap_ends => { param_types   => [],
                              return_type   => undef,
                              flags         => ['run-last','action'],
                              class_closure => \&_do_swap_ends,
                            },
               delete_element => { param_types   => [],
                                   return_type   => undef,
                                   flags         => ['run-last','action'],
                                   class_closure => \&_do_delete_element,
                                 },
               toggle_horizontal => { param_types   => [],
                                      return_type   => undef,
                                      flags         => ['run-last','action'],
                                      class_closure => \&_do_toggle_horizontal,
                                    },
             };

# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
Gtk2::Rc->parse_string (<<'HERE');
binding "App__Chart__Gtk2__AnnDrag_keys" {
  bind "Escape"         { "abort" () }
  bind "a"              { "toggle-alert" () }
  bind "space"          { "swap-ends" () }
  bind "d"              { "delete-element" () }
  bind "h"              { "toggle-horizontal" () }
}
class "App__Chart__Gtk2__AnnDrag" binding:gtk "App__Chart__Gtk2__AnnDrag_keys"
HERE


my $active = 0;
my $graph;
my $cursor;
my $drawn = 0;
my $wevents;
my $snooper;

my $orig_elem;  # from database, or undef for new line
my $edit_elem;

use constant::defer init => sub {
  $graph->signal_connect (motion_notify_event => \&_do_motion_notify_event);
  $graph->signal_connect (button_release_event=> \&_do_button_release_event);

  require Gtk2::Ex::WidgetCursor;
  $cursor = Gtk2::Ex::WidgetCursor->new (widget => $graph,
                                         cursor => 'left_ptr');

  require Gtk2::Ex::WidgetEvents;
  $wevents = Gtk2::Ex::WidgetEvents->new ($graph, ['key-press-mask',
                                                   'button-motion-mask',
                                                   'button-release-mask']);
  require Gtk2::Ex::KeySnooper;
  $snooper = Gtk2::Ex::KeySnooper->new;
  return; # nothing to memoize
};

# start dragging in $graph of object nearest $event
sub start {
  ($graph, my $event) = @_;  # global $graph
  if ($active) { return; }

  init ();
  my $x = $event->x;
  my $y = $event->y;
  $orig_elem = find ($x, $y);
  if ($orig_elem) {
    $edit_elem = $orig_elem->clone;
    $drawn = 1;
  } else {
    $edit_elem = App::Chart::Annotation::Line->new_for_graph ($graph, $x, $y);
    $drawn = 0;
    draw(1);
  }

  $active = 1;
  $cursor->active (1);
  $snooper->install (\&_do_key_snooper);
}

sub _stop {
  $active = 0;
  $cursor->active (0);
  $snooper->remove;
}

sub done {
  if (! $active) { return; }
  if (DEBUG) { print "done\n"; }
  _stop ();
  draw (1);
}

sub abort {
  goto &_do_abort;
}
sub _do_abort {
  my ($self) = @_;
  if (! $active) { return; }
  _stop ();
  draw (0);
  $edit_elem = $orig_elem;
  if ($edit_elem) {
    draw(1);
  }
}

sub delete_elem {
  goto &_do_delete_element;
}
sub _do_delete_element {
  my ($self) = @_;
  if (! $active) { return; }
  _stop();
  draw (0);
  if ($orig_elem) {
    $orig_elem->delete;
  }
}

sub _do_expose_event {
  my ($graph, $event) = @_;
  $drawn = 0;
  draw (1, $event->region);
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_motion_notify_event {
  my ($graph, $event) = @_;
  my $x = $event->x;
  my $y = $event->y;
  if ($event->is_hint) {
    ($x, $y) = $event->window->get_pointer;
  }
  move ($x, $y);
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_button_release_event {
  my ($graph, $event) = @_;
  if (! $active) { # button release after Esc or D keyboard stop
    return Gtk2::EVENT_PROPAGATE;
  }
  move ($event->x, $event->y);
  done();
  $edit_elem->write;
  return Gtk2::EVENT_PROPAGATE;
}

sub draw {
  my ($want, $region) = @_;
  if (DEBUG >= 2) { print "  draw drawn=$drawn want=$want\n"; }
  if ($drawn != $want) {
    $edit_elem->draw ($graph, $region);
    $drawn = $want;
  }
}

sub move {
  my ($x, $y) = @_;
  if (! $active) { return; }
  if (DEBUG) { print "AnnDrag move $x, $y\n"; }

  my $t = $graph->x_to_date ($x);
  my $price = $graph->y_to_value ($y);
  my $scale_y = $graph->scale_y_proc;

  if (DEBUG) {
    print "  $t, $price  was ",$edit_elem->t,",",$edit_elem->price," (",
      $graph->scale_y ($edit_elem->price),")\n";
  }

  # redraw only if changed
  if ($edit_elem->t != $t
      || $scale_y->($edit_elem->price) != $scale_y->($price)) {
    if (DEBUG >= 2) { print "  redraw\n"; }
    draw (0);
    $edit_elem->t ($t);
    $edit_elem->price ($price);
    draw (1);
  } else {
    if (DEBUG >= 2) { print "  no pixel position change\n"; }
    # but store floating point price always
    $edit_elem->price ($price);
  }
}

sub _do_key_snooper {
  my ($widget, $event) = @_;

  # ignore key releases
  $event->type eq 'key-press' or return Gtk2::EVENT_PROPAGATE;

  # needing an actual self Gtk2::Object
  #   require Gtk2::Ex::BindingBits;
  #   Gtk2::Ex::BindingBits::activate_event
  #   if (App::Chart::Gtk2::GUI::bindings_activate_event ('App__Chart__Gtk2__AnnDrag_keys',
  #                                                $event, $self)) {
  #     return Gtk2::EVENT_STOP; # since handled
  #   }

  my $keyval = $event->keyval;
  my $modifiers = $event->state;
  $modifiers = $modifiers & Gtk2::Accelerator->get_default_mod_mask;
  my $key = lc (Gtk2::Gdk->keyval_name ($keyval));
  if (DEBUG) { print "keypress $key\n"; }

  if ($key eq 'escape') {
    abort ();

  } elsif ($key eq 'a') {
    toggle_alert ();

  } elsif ($key eq 'space') {
    swap_ends ();

  } elsif ($key eq 'd') {
    delete_elem ();

  } elsif ($key eq 'h') {
    toggle_horizontal ();

  } else {
    # some key not for us
    return Gtk2::EVENT_PROPAGATE;
  }

  # any of the handled keys
  return Gtk2::EVENT_STOP;
}

sub toggle_alert {
  goto &_do_toggle_alert;
}
sub _do_toggle_alert {
  my ($self) = @_;
  if ($edit_elem->isa('App::Chart::Annotation::Line')) {
    if ($edit_elem->{'id'}) {
      $graph->error_bell;
      return;
    }
    draw (0);
    $edit_elem = App::Chart::Annotation::Alert->new
      (symbol => $edit_elem->{'symbol'},
       price  => $edit_elem->{'price1'},
       above  => 1);

  } else {
    draw (0);
    $edit_elem->{'above'} = ($edit_elem->{'above'} ? 0 : 1);
  }
  draw (1);
}

sub toggle_horizontal {
  goto &_do_toggle_horizontal;
}
sub _do_toggle_horizontal {
  my ($self) = @_;
  draw (0);
  $edit_elem->{'horizontal'} = ($edit_elem->{'horizontal'} ? 0 : 1);
  draw (1);
}

sub swap_ends {
  goto &_do_swap_ends;
}
sub _do_swap_ends {
  if (DEBUG) { print "swap_ends\n"; }
  draw (0);
  $edit_elem->swap_ends;
  draw (1);
  Gtk2::Ex::WidgetBits::warp_pointer ($graph,
                                      $graph->scale_x ($edit_elem->t),
                                      $graph->scale_y ($edit_elem->price));
}

# return a line from notes, or undef
# the line ends are swapped if necessary to make t2,p2 the point near x,y
#
sub find {
  my ($x, $y) = @_;
  if (DEBUG) { print "find\n"; }

  my $series = $graph->get('series_list')->[0] || return undef;
  my $scale_x = $graph->scale_x_proc;
  my $scale_y = $graph->scale_y_proc;

  # distance in millimetres from tdate/price to X,Y
  my $tp_distance = sub {
    my ($t, $p) = @_;
    return Gtk2::Ex::WidgetBits::xy_distance_mm
      ($graph, $x,$y, $scale_x->($t), $scale_y->($p));
  };

  my $min_elem;
  my $min_dist;
  my $minproc = sub {
    my ($elem, $t, $p) = @_;
    my $dist = $tp_distance->($t, $p);
    if (DEBUG) { print "  $elem dist $dist\n"; }
    if ($dist > 5) {
      return;  # no more than 5 millimetres
    }
    if (! defined $min_dist || $dist < $min_dist) {
      $min_dist = $dist;
      $min_elem = $elem;
    }
  };

  require App::Chart::Annotation;
  foreach my $elem (@{$series->AnnLines_arrayref}) {
    $minproc->($elem, $elem->t, $elem->price);
    $elem = $elem->clone ($elem);
    $elem->swap_ends;
    $minproc->($elem, $elem->t, $elem->price);
  }
  {
    my $t = App::Chart::Gtk2::Graph::Plugin::Alerts::draw_t ($graph);
    foreach my $elem (@{$series->Alerts_arrayref}) {
      $minproc->($elem, $t, $elem->price);
    }
  }

  if (DEBUG) { print "  result ",$min_elem||'undef',
                 " dist ",$min_dist||'undef',"\n"; }
  return $min_elem;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Gtk2::AnnDrag -- annotation line or alert dragging
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Gtk2::Graph>
# 
# =cut
