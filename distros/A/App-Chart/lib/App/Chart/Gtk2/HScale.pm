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

package App::Chart::Gtk2::HScale;
use 5.008;
use strict;
use warnings;
use Glib::Ex::SignalIds;
use Gtk2;
use Gtk2::Ex::AdjustmentBits 47; # v.47 for set_empty()
use List::Util qw(min max);
use POSIX ();

use App::Chart;
use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Glib::Ex::TieWeakNotify;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Adjustment',
  signals => { },
  properties => [Glib::ParamSpec->double
                 ('pixel-per-value',
                  'pixel-per-value',
                  'Blurb',
                  0, POSIX::DBL_MAX(), 0,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->double
                 ('value-per-pixel',
                  'value-per-pixel',
                  'Blurb',
                  0, POSIX::DBL_MAX(), 0,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('widget',
                  'widget',
                  'Blurb',
                  'Gtk2::Widget',
                  Glib::G_PARAM_READWRITE),
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'value_per_pixel'} = 0;
  $self->{'pixel_per_value'} = 0;

  ### INIT_INSTANCE gives
  ### $self
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### HScale SET_PROPERTY(): $pname, $newval
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'value_per_pixel') {
    $self->set_value_per_pixel ($newval);

  } elsif ($pname eq 'pixel_per_value') {
    $self->set_pixel_per_value ($newval);

  } elsif ($pname eq 'widget') {
    my $widget = $newval;
    App::Chart::Glib::Ex::TieWeakNotify->set ($self, $pname, $widget);
    $self->{'widget_ids'} = $widget && Glib::Ex::SignalIds->new
      ($widget,
       $widget->signal_connect (size_allocate => \&_do_size_allocate,
                                App::Chart::Glib::Ex::MoreUtils::ref_weak ($self)));
    _update_page_size ($self);
  }

  ### SET_PROPERTY gives
  ### $self
}

sub set_value_per_pixel {
  my ($self, $vpp) = @_;
  ### HScale set_value_per_pixel(): $vpp
  $self->{'value_per_pixel'} = $vpp;
  $self->{'pixel_per_value'} = ($vpp == 0 ? 0 : 1.0 / $vpp);
  _update_page_size ($self);
  $self->notify ('value-per-pixel');
  $self->notify ('pixel-per-value');
}
sub set_pixel_per_value {
  my ($self, $ppv) = @_;
  ### HScale set_pixel_per_value(): $ppv
  $self->{'pixel_per_value'} = $ppv;
  $self->{'value_per_pixel'} = ($ppv == 0 ? 0 : 1.0 / $ppv);
  _update_page_size ($self);
  $self->notify ('value-per-pixel');
  $self->notify ('pixel-per-value');
}
sub set_value_range {
  my ($self, $lo, $hi) = @_;
  $self->value ($lo);
  my $width = ($self->{'widget'}
               ? $self->{'widget'}->allocation->width
               : 0);
  $self->set_pixel_per_value ($width / ($hi - $lo));
  $self->notify ('value');
  $self->value_changed;
}

sub get_value_per_pixel {
  my ($self) = @_;
  return $self->{'value_per_pixel'};
}
sub get_pixel_per_value {
  my ($self) = @_;
  return $self->{'pixel_per_value'};
}

sub value_range_inc {
  my ($self) = @_;
  my $value = $self->value;
  return (POSIX::floor ($value),
          POSIX::ceil ($value + $self->page_size));
}

sub value_to_pixel {
  my ($self, $v) = @_;
  return POSIX::floor
    (($v - $self->value) * $self->{'pixel_per_value'});
}
sub value_to_pixel_proc {
  my ($self) = @_;
  my $value = $self->value;
  my $ppv = $self->{'pixel_per_value'};
  return sub {
    return POSIX::floor (($_[0] - $value) * $ppv);
  };
}

sub pixel_to_value {
  my ($self, $pixel) = @_;
  return POSIX::floor ($self->value + $pixel * $self->{'value_per_pixel'});
}
sub pixel_to_value_proc {
  my ($self) = @_;
  my $value = $self->value;
  my $vpp = $self->{'value_per_pixel'};
  return sub {
    return POSIX::floor ($value + $_[0] * $vpp);
  };
}

# 'size-allocate' on widget
sub _do_size_allocate {
  my ($widget, $allocation, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _update_page_size ($self);
}

sub _update_page_size {
  my ($self) = @_;
  my %adjvalues;

  # whether currently showing the end, or roughly so
  my $at_end = ($self->value >= $self->upper - $self->page_size * 1.01);

  my $width = ($self->{'widget'}
               ? $self->{'widget'}->allocation->width
               : 0);
  my $page = $width * $self->{'value_per_pixel'};
  $adjvalues{'page_size'} = $page;
  $adjvalues{'page_increment'} = ($page * 0.8);
  $adjvalues{'step_increment'} = $page * 0.2;

  # if upper-lower smaller than new page size then extend lower
  if ($self->upper - $self->lower < $page) {
    $adjvalues{'lower'} = $self->upper - $page;
  }

  # if bigger page size pushes value+page above upper then reduce value to max;
  # if we were showing the end and a smaller page size means we no longer
  # are then increase value to its max
  my $max_value = $self->upper - $page;
  if ($self->value > $max_value || $at_end) {
    $adjvalues{'value'} = $max_value;
  }

  ### HScale: "page=$page vpp=$self->{'value_per_pixel'} ppv=$self->{'pixel_per_value'}"
  Gtk2::Ex::AdjustmentBits::set_maybe ($self, %adjvalues);
}

sub empty {
  my ($self) = @_;
  Gtk2::Ex::AdjustmentBits::set_empty($self);
}

# scroll by $count many steps
sub scroll_step {
  my ($self, $count) = @_;
  Gtk2::Ex::AdjustmentBits::set_maybe
      ($self, value => $self->value + $self->step_increment * $count);
}

1;
__END__
