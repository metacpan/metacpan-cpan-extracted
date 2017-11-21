package Argon::Queue;
# ABSTRACT: Bounded, prioritized queue class
$Argon::Queue::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose;
use Argon::Constants qw(:priorities);
use Argon::Tracker;
use Argon::Log;


has max => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
);

has tracker => (
  is      => 'ro',
  isa     => 'Argon::Tracker',
  lazy    => 1,
  builder => '_build_tracker',
  handles => {
  },
);

sub _build_tracker {
  my $self = shift;
  Argon::Tracker->new(
    capacity => $self->max,
    length   => $self->max * $self->max,
  );
}

has msgs => (
  is      => 'ro',
  isa     => 'ArrayRef[ArrayRef[Argon::Message]]',
  default => sub { [[], [], []] },
);

has count => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
  traits  => ['Counter'],
  handles => {
    inc_count => 'inc',
    dec_count => 'dec',
  }
);

has balanced => (
  is      => 'rw',
  isa     => 'Int',
  default => sub { time },
);

after max => sub {
  my $self = shift;
  if (@_) {
    $self->tracker->capacity($self->max);
    $self->tracker->length($self->max * $self->max);
  }
};


sub is_empty { $_[0]->count == 0 }
sub is_full  { $_[0]->count >= $_[0]->max }


sub put {
  my ($self, $msg) = @_;

  croak 'usage: $queue->put($msg)'
    unless defined $msg
        && (ref $msg || '') eq 'Argon::Message';

  $self->promote;

  croak 'queue full' if $self->is_full;

  push @{$self->msgs->[$msg->pri]}, $msg;

  $self->tracker->start($msg);
  $self->inc_count;
  $self->count;
}


sub get {
  my $self = shift;
  return if $self->is_empty;

  foreach my $pri ($HIGH, $NORMAL, $LOW) {
    my $queue = $self->msgs->[$pri];

    if (@$queue) {
      my $msg = shift @$queue;
      $self->tracker->finish($msg);
      $self->dec_count;

      return $msg;
    }
  }
}

sub promote {
  my $self = shift;
  my $avg  = $self->tracker->avg_time;
  my $max  = $avg * 1.5;
  return 0 unless time - $self->balanced >= $max;

  my $moved = 0;

  foreach my $pri ($LOW, $NORMAL) {
    while (my $msg = shift @{$self->msgs->[$pri]}) {
      if ($self->tracker->age($msg) > $max) {
        push @{$self->msgs->[$pri - 1]}, $msg;
        $self->tracker->touch($msg);
        ++$moved;
      } else {
        unshift @{$self->msgs->[$pri]}, $msg;
        last;
      }
    }
  }

  log_trace 'promoted %d msgs', $moved
    if $moved;

  return $moved;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Queue - Bounded, prioritized queue class

=head1 VERSION

version 0.18

=head1 SYNOPSIS

  use Argon::Queue;

  my $q = Argon::Queue->new(max => 32);

  unless ($q->is_full) {
    $q->put(...);
  }

  unless ($q->is_empty) {
    my $msg = $q->get;
  }

=head1 DESCRIPTION

The bounded priority queue used by the L<Argon::Manager> for L<Argon::Message>s
submitted to the Ar network.

=head1 ATTRIBUTES

=head2 max

The maximum number of messages supported by the queue.

=head1 METHODS

=head2 is_empty

Returns true if the queue is empty.

=head2 is_full

Returns true if there is at least one L<Argon::Message> in the queue.

=head2 put

Adds a message to the queue. Croaks if the supplied message is not an
L<Argon::Message> or if the queue is full.

Adding a message to the queue has the side effect of promoting any previously
added messages that have been stuck at a lower level priority for an overly
long time.

=head2 get

Removes and returns the next L<Argon::Message> on the queue. Returns C<undef>
if the queue is empty.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
