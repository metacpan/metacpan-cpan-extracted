package Argon::Tracker;
# ABSTRACT: Internal class used to track node capacity
$Argon::Tracker::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use Moose;
use List::Util  qw(sum0);
use Time::HiRes qw(time);
use Argon::Util qw(param);


has length => (
  is      => 'rw',
  isa     => 'Int',
  default => 20,
);


has capacity => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
  traits  => ['Counter'],
  handles => {
    add_capacity    => 'inc',
    remove_capacity => 'dec',
  },
);

has started => (
  is      => 'rw',
  isa     => 'HashRef[Num]',
  default => sub {{}},
  traits  => ['Hash'],
  handles => {
    track      => 'set',
    untrack    => 'delete',
    start_time => 'get',
    is_tracked => 'exists',
    assigned   => 'count',
  },
);

has history => (
  is      => 'rw',
  isa     => 'ArrayRef[Num]',
  default => sub {[]},
  traits  => ['Array'],
  handles => {
    record        => 'push',
    record_count  => 'count',
    prune_records => 'shift',
  },
);

has avg_time => (
  is      => 'rw',
  isa     => 'Num',
  default => 0,
);


sub available_capacity { $_[0]->capacity - $_[0]->assigned }
sub has_capacity { $_[0]->available_capacity > 0 }
sub load { ($_[0]->assigned + 1) * $_[0]->avg_time }


sub age {
  my ($self, $msg) = @_;
  return unless $self->is_tracked($msg->id);
  time - $self->start_time($msg->id);
}


sub start {
  my ($self, $msg) = @_;
  croak 'no capacity' unless $self->has_capacity;
  croak "msg id $msg->id is already tracked" if $self->is_tracked($msg->id);
  $self->track($msg->id, time);
  $self->assigned;
}


sub finish {
  my ($self, $msg) = @_;
  croak "msg id $msg->id is not tracked" unless $self->is_tracked($msg->id);
  --$self->{assigned};
  $self->_add_to_history(time - $self->untrack($msg->id));
  $self->_update_avg_time;
}


sub touch {
  my ($self, $msg) = @_;
  croak "msg id $msg->id is not tracked" unless $self->is_tracked($msg->id);
  $self->track($msg->id, time);
}

sub _add_to_history {
  my ($self, $taken) = @_;
  $self->record($taken);
  while ($self->record_count > $self->length) {
    $self->prune_records;
  }
}

sub _update_avg_time {
  my $self = shift;
  my $total = sum0 @{$self->{history}};
  $self->{avg_time} = $total == 0 ? 0 : $total / @{$self->{history}};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Tracker - Internal class used to track node capacity

=head1 VERSION

version 0.18

=head1 DESCRIPTION

An internally used class that tracks capacity of worker nodes.

=head1 ATTRIBUTES

=head2 length

The number of completed past transactions used to calculate load.

=head2 capacity

The capacity as the sum of tracked worker capacities.

=head1 METHODS

=head2 add_capacity

Increment capacity by the supplied value.

=head2 remove_capacity

Decrement capacity by the supplied value.

=head2 available_capacity

Returns the number of task slots available; equivalent to the total capacity
less the number of actively tracked tasks.

=head2 has_capacity

Returns true if the L</available_capacity> is greater than zero.

=head2 load

Estimates and returns the time required to complete one more than the number of
currently tracked tasks.

=head2 age

Returns the number of seconds since the tracker began tracking the supplied
L<Argon::Message>.

=head2 start

Begins tracking an L<Argon::Message>.

=head2 finish

Completes tracking on an L<Argon::Message>.

=head2 touch

Resets the start time on an L<Argon::Message>.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
