package CORBA::MICO::BGQueue;

#--------------------------------------------------------------------
# Queue for background processing
#--------------------------------------------------------------------
use Gtk2 '1.140';
use Carp;

use strict;

use vars qw($DEBUG);
#$DEBUG=1;

#--------------------------------------------------------------------
# Create new queue
# In: $interval - time interval (miliseconds)
#--------------------------------------------------------------------
sub new {
  my ($type, $interval) = @_;
  my $class = ref($type) || $type;
  my $self = { 'TAG'       => undef,
               'QUEUE'     => [],
               'INTERVAL'  => $interval,
               'ACTIVE'    => undef };
  bless $self, $class;
  return $self;
}

#--------------------------------------------------------------------
sub close {
  my $self = shift;
  $self->deactivate();
  foreach my $k (keys %$self) {
    $self->{$k} = undef;
  }
}

#--------------------------------------------------------------------
sub DESTROY {
  my $self = shift;
  carp "DESTROYING $self" if $DEBUG;
  $self->deactivate();
}

#--------------------------------------------------------------------
# Activate timeout handler
#--------------------------------------------------------------------
sub activate {
  my $self = shift;
  if( not defined($self->{'TAG'}) ) {
    my $interval = $self->{'INTERVAL'};
    $interval = 20 if  $interval == 0;
    $self->{'TAG'} = Glib::Timeout->add($interval, \&timeout_hnd, $self);
  }
}

#--------------------------------------------------------------------
# Deactivate timeout handler
#--------------------------------------------------------------------
sub deactivate {
  my $self = shift;
  warn  "deactivate" if $DEBUG;
  if( defined($self->{'TAG'}) ) {
    Glib::Source->remove($self->{'TAG'});
  }
  $self->{'TAG'} = undef;
}

#--------------------------------------------------------------------
# Add queue entry: an object supporting method 'do_iteration'
# Return values expected from do_iteration():
#     true  - keep object in the queue
#     false - remove object from the queue
#--------------------------------------------------------------------
sub add_entry {
  my($self, $entry_object) = @_;
  $self->activate();
  push(@{$self->{'QUEUE'}}, $entry_object);
}

#--------------------------------------------------------------------
# Remove queue entry
#--------------------------------------------------------------------
sub remove_entry {
  my($self, $entry_object) = @_;
  if( defined($self->{'ACTIVE'}) and $self->{'ACTIVE'} == $entry_object ) {
    $self->remove_active_object();
  }
  my $queue = $self->{'QUEUE'};
  foreach my $i (0..$#$queue) {
    if( $queue->[$i] == $entry_object ) {
      # remove the entry from the queue
      splice(@$queue, $i, 1);
      return;
    }
  }
}

#--------------------------------------------------------------------
# Set active object. Control will be passed to active object
# (if any) and then, only when if active object is removed, other objects
# from queue may be served
#--------------------------------------------------------------------
sub set_active_object {
  my($self, $entry_object) = @_;
  $self->activate();
  $self->{'ACTIVE'} = $entry_object;
}

#--------------------------------------------------------------------
# Remove active object
#--------------------------------------------------------------------
sub remove_active_object {
  my($self) = @_;
  $self->set_active_object(undef);
}

#--------------------------------------------------------------------
# Background processing: do an iteration.
# 1. Do an iteration for active object and return if it is defined.
# 2. Do an iteration from the first object from the queue and move it
#    to the end of the queue
#--------------------------------------------------------------------
sub timeout_hnd {
  my ($self) = @_;
  my $active_object = $self->{'ACTIVE'};
  if( defined($active_object) ) {
    $active_object->do_iteration() || ($self->{'ACTIVE'} = undef);
  }
  else {
    my $queue = $self->{'QUEUE'};
    if( $#$queue >= 0 ) {
      my $obj = shift @$queue;
      $obj->do_iteration() && push(@$queue, $obj);
    }
    else {
      # the queue is empty -> deactivate
      $self->{'TAG'} = undef;
      return 0;
    }
  }
  return 1;
}

1;
