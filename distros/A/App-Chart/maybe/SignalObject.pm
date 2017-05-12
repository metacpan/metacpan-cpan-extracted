# Copyright 2007, 2008, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::SignalObject;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;

use constant DEBUG => 0;


# sub _do_callback {
#   my $self = pop @_;
#   if ($
#   &{$self->{'callback'}} (@_, $self->{'userdata'});
# }

sub _ensure_connect {
  my ($self) = @_;
  $self->{'id'} ||= $self->{'object'}->signal_connect
    ($self->{'name'}, $self->{'callback'}, $self->{'userdata'});
  if (DEBUG) { print "$self signal id ", $self->{'id'}, "\n"; }
}

sub _ensure_disconnect {
  my ($self) = @_;
  my $object = $self->{'object'};
  my $id = delete $self->{'id'};
  if ($object && $id) { $object->signal_handler_disconnect ($id); }
}

sub _establish {
  my ($self) = @_;
  if ($self->{'object'} && $self->{'name'} && $self->{'connect'}) {
    _ensure_connect ($self);
  } else {
    _ensure_disconnect ($self);
  }
}

sub new {
  my ($class, %args) = @_;
  if (! exists $args{'connect'}) { $args{'connect'} = 1; }
  my $self = bless \%args, $class;
  Scalar::Util::weaken ($self->{'object'});
  if ($self->{'weak_userdata'}) {
    if (ref $self->{'userdata'}) {
      Scalar::Util::weaken ($self->{'userdata'});
    }
  }
  _establish ($self);
  return $self;
}

sub connect {
  my ($self) = @_;
  $self->{'connect'} = 1;
  _establish ($self);
}

sub disconnect {
  my ($self) = @_;
  if (DEBUG) { print "$self disconnect\n"; }
  $self->{'connect'} = 0;
  _ensure_disconnect ($self);
}

sub set_connected {
  my ($self, $connect) = @_;
  $self->{'connect'} = $connect;
  _establish ($self);
}

sub set_object {
  my ($self, $object) = @_;
  my $old = $self->{'object'};
  $self->{'object'} = $object;
  Scalar::Util::weaken ($self->{'object'});

  if (($old||0) != ($object||0)) {
    _ensure_disconnect ($self);
    _establish ($self);
  }
}

sub set_name {
  my ($self, $name) = @_;
  my $old = $self->{'name'};
  $self->{'name'} = $name;
  if (($old||'') ne ($name||'')) {
    _ensure_disconnect ($self);
    _establish ($self);
  }
}

sub DESTROY {
  my ($self) = @_;
  if (DEBUG) { print "$self destroy\n"; }
  _ensure_disconnect ($self);
}

1;
__END__

=head1 NAME

Glib::Ex::SignalObject -- object for Glib signal connection

=head1 SYNOPSIS

 use Glib::Ex::SignalObject;
 $signal = Glib::Ex::SignalObject->new (object => $my_obj,
                                        name   => 'some-signal',
                                        callback => \&my_handler,
                                        userdata => 'some data');

 $signal->disconnect;   # explicit disconnect
 $signal->connect;      # reconnect later
 $signal->set_connected ($bool);  # or control connectedness

 $signal->set_object ($other_obj);   # change origin object
 $signal->set_name ('diff-signal');  # change signal name

 $signal = undef;       # disconnected by forgetting

=head1 DESCRIPTION

C<Glib::Ex::SignalObject> is an object-oriented way to manage a signal
connection on a Glib object (including Gtk widgets).  It features,

=over 4

=item *

Automatic disconnect by  just forgetting the object

=item *

Changable origin and name settings to move the connection to somewhere else,
including undef to have no connection for a time.

=item *

A "connect" state to have a connection not made for a time.

=item *

Optional weakening of the userdata to avoid circular references (and
disconnect when that target goes away).

=back

=head1 FUNCTIONS

=over 4

=item C<< Glib::Ex::SignalObject->new (key => value, ...) >>

Create and return a new signal object.  The following parameters are taken
in key/value style,

    object          originating object (Glib::Object etc), or undef
    name            signal name (string), or undef
    callback        handler function to call
    userdata        data passed to the callback function
    weak_userdata   flag to weaken userdata reference
    connect         flag to not immediately connect


=back

=head1 SEE ALSO

L<Glib::Object>

=cut

