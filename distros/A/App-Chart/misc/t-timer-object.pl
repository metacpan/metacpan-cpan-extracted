#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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

use strict;
use warnings;
use Data::Dumper;
use Glib;
use Scalar::Util;
use Gtk2 '-init';
use Gtk2::Ex::TimerObject;

sub timer {
  my @args = @_;
  print "timer ", Dumper (\@args);
}

{
  my $timer;
  {
    my $widget = Gtk2::Label->new;
    $widget->signal_connect (destroy => sub { print "widget destroy\n"; });
    $timer = $widget->{'timer'} = Gtk2::Ex::TimerObject->new
      (period   => 1000,
       callback => \&timer,
       userdata => $widget,
       weak => 1);
  }
  Gtk2->main;
  exit 0;
}

{
  my $widget = Gtk2::Label->new;
  my $weak_widget = $widget;
  Scalar::Util::weaken ($weak_widget);
  my $id = Glib::Timeout->add (1000, \&timer, $weak_widget);
  Gtk2->main;
  exit 0;
}

__END__




{
  {
    my $widget = Gtk2::Label->new;
    $widget->signal_connect (destroy => sub { print "label destroy\n"; });
    my $id = Gtk2::Ex::TimerObject::timeout_add_weak (1000, \&timer, $widget);
  }
  Gtk2->main;
  exit 0;
}


#------------------------------------------------------------------------------
# generic weakened callback

sub _weak_callback {
  my @args = @_;
  my $wdata = $args[$#args];
  my $userdata = $wdata->[1];
  if (! defined $userdata) { return 0; }
  $args[$#args] = $userdata;
  return &{$wdata->[0]} (@args);
}
sub weak_callback {
  my ($period, $callback, $userdata, @optional_priority) = @_;
  if (ref $userdata) {
    my @wdata = ($callback, $userdata);
    Scalar::Util::weaken ($wdata[1]);
    return (\&_weak_callback, \@wdata);
  } else {
    return ($callback, $userdata);
  }
}

#   $self->{'timer_id'} = Glib::Timeout->add
#     ($period, weak_callback(\&_timer_object_callback,$self), @optional_priority);




#------------------------------------------------------------------------------
# integer ID, with weak reference to userdata

sub timeout_add_weak {
  my ($period, $callback, $userdata, @optional_priority) = @_;
  if (ref $userdata) {
    my @wdata = ($callback, $userdata);
    Scalar::Util::weaken ($wdata[1]);
    $callback = \&_timeout_weak_callback;
    $userdata = \@wdata;
  }
  return Glib::Timeout->add ($period, $callback, $userdata,
                             @optional_priority);
}
sub _timeout_weak_callback {
  my ($wdata) = @_;
  if (! defined $wdata->[1]) {
    print "userdata garbage collected, stopping\n";
    return 0;
  }
  return (&{$wdata->[0]} ($wdata->[1]));
}
