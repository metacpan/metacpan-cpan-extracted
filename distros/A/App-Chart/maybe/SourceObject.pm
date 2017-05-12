# Copyright 2007, 2008, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::SourceObject;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;

use constant DEBUG => 0;


#------------------------------------------------------------------------------
# idle object

sub _source_callback {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self;

  if (! defined $self) {
    # Got a callback after we've been destroyed.
    # Pretty sure that shouldn't happen, but check anyway and stop the idle.
    if (DEBUG) { print "SourceObject callback after destroyed, somehow\n"; }
    return 0; # stop
  }

  if ($self->{'weak_userdata'} && ! defined $self->{'userdata'}) {
    # object has gone away
    if (DEBUG) { print "$self userdata object gone, stopping idle\n"; }
    delete $self->{'source_id'};
    return 0; # stop
  }

  &{$self->{'callback'}} ($self, $self->{'userdata'});
}

# callback from the destroy signal of a userdata widget - it's going away so
# we should stop
#
sub _userdata_destroy_callback {
  my ($widget, $ref_weak_self) = @_;
  my $self = $$ref_weak_self;
  if (! defined $self) {
    # we've been destroyed already - though probably we should have been
    # through our DESTROY and hence disconnected this callback
    return;
  }
  $self->stop;
}

sub new {
  my ($class, %params) = @_;
  my $self = bless \%params, $class;
  if ($self->{'weak_userdata'}) {
    my $userdata = $self->{'userdata'};
    if (ref $userdata) {
      Scalar::Util::weaken ($self->{'userdata'});

      if ($self->{'userdata'}->isa('Gtk2::Object')) {
        my $weak_self = $self;
        Scalar::Util::weaken ($weak_self);
        $self->{'destroy_id'} = $userdata->signal_connect
          ('destroy', \&_userdata_destroy_callback, \$weak_self);
      }
    }
  }
  return $self;
}

sub stop {
  my ($self) = @_;
  if (DEBUG) { print "$self stop\n"; }
    if (my $id = delete $self->{'source_id'}) { # always have id > 0
      Glib::Source->remove ($id);
  }
}

sub is_running {
  my ($self) = @_;
  return exists $self->{'source_id'};
}

sub DESTROY {
  my ($self) = @_;
  if (DEBUG) { print "$self destroy\n"; }
  stop ($self);

  # If we're destroyed before the widget in $self->{'userdata'} then
  # disconnect our 'destroy' callback.  But if the widget was destroyed
  # first then $self->{'userdata'} will be undef (because it's only a weak
  # reference) and there's nothing to disconnect.
  #
  if (my $id = delete $self->{'destroy_id'}) {
    if (my $widget = $self->{'userdata'}) {
      $widget->signal_handler_disconnect ($id);
    }
  }
}


1;
__END__

=head1 NAME

Gtk2::Ex::SourceObject -- code shared by main loop source ID objects

=head1 SEE ALSO

L<Gtk2::Ex::IdleObject>, L<Gtk2::Ex::TimerObject>

=cut

