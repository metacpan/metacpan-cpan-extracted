
package Coro::Countdown;
# ABSTRACT: a counter that signals when it reaches 0
$Coro::Countdown::VERSION = '0.02';
use strict;
use warnings;
use Coro;

sub new   { bless [$_[1] || 0, new Coro::Signal], $_[0] }
sub count { $_[0][0] }
sub up    { ++$_[0][0] }

sub join  {
  my $self = shift;
  return if $self->count == 0;
  $self->[1]->wait;
}

sub down {
  my $self = shift;

  if (--$self->[0] <= 0) {
    if ($self->[1]->awaited) {
      $self->[1]->broadcast;
      $self->[1] = new Coro::Signal;
    }

    $self->[0] = 0;
  }

  $self->[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Coro::Countdown - a counter that signals when it reaches 0

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Coro;
  use Coro::Countdown;

  my $counter = Coro::Countdown->new;
  $counter->up;
  
  async { $counter->down };

  # Block until $counter->down is called
  $counter->join;

=head1 DESCRIPTION

Oftentimes it is necessary to wait until all users of a resource have completed
before a program may continue. Examples of this include a pool of pending
network requests, etc. A countdown signal will broadcast to any waiters once
all "checked out" resources have been "returned".

=head1 METHODS

=head2 new

Optionally takes an initial value, defaulting to 0.

=head2 join

Cedes until the count decrements to 0. If the counter is already at 0, returns
immediately.

=head2 count

Returns the current counter value.

=head2 up

Increments the counter value ("checks out" a resource).

=head2 down

Decrements the counter value ("returns" the resource). If the counter reaches
0, all watchers are signaled and the counter resets. It is then ready to be
reused.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
