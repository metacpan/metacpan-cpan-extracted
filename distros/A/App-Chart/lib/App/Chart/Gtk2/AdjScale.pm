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


# gravity up,down,centre
# stick to start/end if already there
# which of upper/lower to grow
# set_page_range wait until first size_allocate to decide vpp,ppv
# choice keep vpp same and expand page, or keep page and adjust vpp
# integer ppv



package App::Chart::Gtk2::AdjScale;
use 5.008;
use strict;
use warnings;
use Glib::Ex::FreezeNotify;
use Glib::Ex::SignalIds;
use Gtk2;
use Gtk2::Ex::AdjustmentBits 47; # v.47 for set_empty()
use POSIX ();
use Scalar::Util;

use App::Chart;
use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Glib::Ex::TieWeakNotify;

use constant DEBUG => 0;

BEGIN {
  Glib::Type->register_enum ('App::Chart::Gtk2::AdjScale::Gravity',
                             'lower',
                             'upper',
                             'centre');
}

use constant {
  DEFAULT_GRAVITY     => 'centre',
  DEFAULT_ORIENTATION => 'horizontal',
};

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

                 Glib::ParamSpec->double
                 ('page-increment-fraction',
                  'page-increment-fraction',
                  'Blurb',
                  0, POSIX::DBL_MAX(), 0.85,
                  Glib::G_PARAM_READWRITE),
                 Glib::ParamSpec->double
                 ('step-increment-fraction',
                  'step-increment-fraction',
                  'Blurb',
                  0, POSIX::DBL_MAX(), 0.1,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('widget',
                  'widget',
                  'Blurb',
                  'Gtk2::Widget',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->enum
                 ('orientation',
                  'orientation',
                  'Blurb',
                  'Gtk2::Orientation',
                  DEFAULT_ORIENTATION,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->enum
                 ('gravity',
                  'gravity',
                  'Blurb',
                  'App::Chart::Gtk2::AdjScale::Gravity',
                  DEFAULT_GRAVITY,
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('inverted',
                  'inverted',
                  'Blurb',
                  0, # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('logarithmic',
                  'logarithmic',
                  'Blurb',
                  0, # default
                  Glib::G_PARAM_READWRITE),
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'value_per_pixel'} = 0;
  $self->{'pixel_per_value'} = 0;
  $self->{'gravity'} = DEFAULT_GRAVITY;
  $self->{'orientation'} = DEFAULT_ORIENTATION;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if (DEBUG) { print "AdjScale set $pname $newval\n"; }
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
                                App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
    _update_page_size ($self);
  }
}

sub set_page_range {
  my ($self, $p_lo, $p_hi) = @_;
  if (DEBUG) { print "AdjScale set_page_range $p_lo $p_hi\n"; }

  my $page = $p_hi - $p_lo;
  my $pixels = _widget_pixels ($self);
  my $ppv = $self->{'pixel_per_value'} = ($page == 0 ? 0 : $pixels / $page);
  $self->{'value_per_pixel'} = ($ppv == 0 ? 0 : 1.0 / $ppv);
  if (DEBUG) { print "AdjScale set_page_range $p_lo, $p_hi ",
                 "is $page in pixels $pixels, ppv $ppv vpp ",
                   $self->{'value_per_pixel'},"\n"; }

  Gtk2::Ex::AdjustmentBits::set_maybe
      ($self,
       lower          => $p_lo,
       upper          => $p_hi,
       page_size      => $page,
       page_increment => $self->get('page-increment-fraction') *$page,
       step_increment => $self->get('step-increment-fraction') *$page,
       value          => $p_lo);
  $self->notify ('pixel-per-value');
  $self->notify ('value-per-pixel');
}

sub set_value_per_pixel {
  my ($self, $vpp) = @_;
  if (DEBUG) { print "AdjScale set_value_per_pixel $vpp\n"; }
  $self->{'value_per_pixel'} = $vpp;
  $self->{'pixel_per_value'} = ($vpp == 0 ? 0 : 1.0 / $vpp);
  _update_page_size ($self);
  $self->notify ('value-per-pixel');
  $self->notify ('pixel-per-value');
}
sub set_pixel_per_value {
  my ($self, $ppv) = @_;
  if (DEBUG) { print "AdjScale set_pixel_per_value $ppv\n"; }
  $self->{'pixel_per_value'} = $ppv;
  $self->{'value_per_pixel'} = ($ppv == 0 ? 0 : 1.0 / $ppv);
  _update_page_size ($self);
  $self->notify ('value-per-pixel');
  $self->notify ('pixel-per-value');
}
sub set_value_range {
  my ($self, $lo, $hi) = @_;
  $self->value ($lo);
  my $pixels = _widget_pixels ($self);
  $self->set_pixel_per_value ($pixels / ($hi - $lo));
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

sub value_range {
  my ($self) = @_;
  my $value = $self->value;
  return ($self->exp ($value),
          $self->exp ($value + $self->page_size));
}
sub value_range_inc {
  my ($self) = @_;
  my $value = $self->value;
  return (POSIX::floor ($self->exp ($value)),
          POSIX::ceil  ($self->exp ($value + $self->page_size)));
}

sub value_to_pixel {
  my ($self, $v) = @_;
  my $value = $self->value;
  my $ppv = $self->{'pixel_per_value'};
  if ($self->{'inverted'}) {
    $ppv = -$ppv;
    $value += $self->page_size - $self->{'value_per_pixel'};
  }
  return POSIX::floor (($self->log($v) - $value) * $ppv);
}
sub value_to_pixel_proc {
  my ($self) = @_;
  my $value = $self->value;
  my $ppv = $self->{'pixel_per_value'};
  if ($self->{'inverted'}) {
    $ppv = -$ppv;
    $value += $self->page_size - $self->{'value_per_pixel'};
  }
  if ($self->{'logarithmic'}) {
    return sub {
      return POSIX::floor ((log($_[0]) - $value) * $ppv);
    };
  } else {
    return sub {
      return POSIX::floor (($_[0] - $value) * $ppv);
    };
  }
}

sub pixel_to_value {
  my ($self, $pixel) = @_;
  my $vpp = $self->{'value_per_pixel'};
  my $base = 0;
  if ($self->{'inverted'}) {
    $vpp = -$vpp;
    $base = _widget_pixels($self) - 1;
  }
  return $self->exp ($self->value + ($pixel - $base) * $vpp);
}
sub pixel_to_value_proc {
  my ($self) = @_;
  my $value = $self->value;
  my $vpp = $self->{'value_per_pixel'};
  my $base = 0;
  if ($self->{'inverted'}) {
    $vpp = -$vpp;
    $base = _widget_pixels($self) - 1;
  }
  if ($self->{'logarithmic'}) {
    return sub {
      return exp ($value + ($_[0] - $base) * $vpp);
    };
  } else {
    return sub {
      return ($value + ($_[0] - $base) * $vpp);
    };
  }
}

sub exp {
  my ($self, $x) = @_;
  return ($self->{'logarithmic'} ? exp($x) : $x);
}
sub log {
  my ($self, $x) = @_;
  return ($self->{'logarithmic'} ? log($x) : $x);
}
sub exp_proc {
  my ($self) = @_;
  return ($self->{'logarithmic'} ? \&exp : \&identity);
}
sub log_proc {
  my ($self) = @_;
  return ($self->{'logarithmic'} ? \&log : \&identity);
}
sub identity { return $_[0]; }

# 'size-allocate' signal on widget
sub _do_size_allocate {
  my ($widget, $alloc, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if (DEBUG) { print "AdjScale size_allocate\n"; }
  _update_page_size ($self);
}

sub _update_page_size {
  my ($self) = @_;
  if (DEBUG) { print "  _update_page_size\n"; }
  my %values;

  # whether currently showing the end, or roughly so
  my $upper = $self->upper;
  my $at_end = ($self->value >= $upper - $self->page_size * 1.01);
  if (DEBUG) { print "  at_end ",$at_end?"yes":"no"," with upper $upper\n"; }

  my $height = ($self->{'widget'}
                ? $self->{'widget'}->allocation->height
                : 0);
  my $page = $height * $self->{'value_per_pixel'};
  $values{'page_size'} = $page;
  $values{'page_increment'} = $self->get('page-increment-fraction') * $page;
  $values{'step_increment'} = $self->get('step-increment-fraction') * $page;
  if (DEBUG) { print "  page $page on $height pixels and value_per_pixel ",
                 $self->{'value_per_pixel'},"\n"; }

  # if upper-lower smaller than new page size then extend upper
  my $lower = $self->lower;
  if ($upper - $lower < $page) {
    $upper = $lower + $page;
    $values{'upper'} = $upper;
  }

  # if bigger page pushes value+page above upper then reduce value to max;
  # if we were showing the end and a smaller page size means we no longer
  # are then increase value to its max
  my $max_value = $upper - $page;
  if ($self->value > $max_value || $at_end) {
    if (DEBUG) { print "  bigger page pushes value down to $max_value\n"; }
    $values{'value'} = $max_value;
  }

  if (DEBUG) { print "  page $page",
                 " vpp ",$self->{'value_per_pixel'},
                   " ppv ",$self->{'pixel_per_value'},"\n"; }
  Gtk2::Ex::AdjustmentBits::set_maybe ($self, %values);
}

sub empty {
  my ($self) = @_;
  Gtk2::Ex::AdjustmentBits::set_empty($self);
}
sub is_empty {
  my ($self) = @_;
  return ($self->page_size == 0);
}

sub _widget_pixels {
  my ($self) = @_;
  my $widget = $self->{'widget'} || return 0;
  my $alloc = $widget->allocation;
  return ($self->{'orientation'} eq 'horizontal'
          ? $alloc->width : $alloc->height);
}

# scroll by $count many steps
sub scroll_step {
  my ($self, $count) = @_;
  Gtk2::Ex::AdjustmentBits::set_maybe
      ($self,
       value => $self->value + $self->step_increment * $count);
}

1;
__END__
