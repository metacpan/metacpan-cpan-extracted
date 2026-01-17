package Algorithm::SlidingWindow::Dynamic;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.900';

sub new {
    my ($class, %args) = @_;

    my $alloc = exists $args{alloc} ? $args{alloc} : 8;
    _check_alloc($alloc);
    $alloc = int($alloc);

    my $self = bless {
        buf  => [ (undef) x $alloc ],
        head => 0,
        size => 0,
    }, $class;

    if (exists $args{values}) {
        croak "values must be an arrayref" if ref($args{values}) ne 'ARRAY';
        $self->push(@{ $args{values} });
    }

    return $self;
}

sub size { $_[0]->{size} }

sub is_empty { $_[0]->{size} == 0 ? 1 : 0 }

sub oldest {
    my ($self) = @_;
    return undef if $self->{size} == 0;
    return $self->{buf}[ $self->{head} ];
}

sub newest {
    my ($self) = @_;
    return undef if $self->{size} == 0;

    my $cap = _cap($self);
    my $idx = ($self->{head} + $self->{size} - 1) % $cap;
    return $self->{buf}[$idx];
}

sub get {
    my ($self, $index) = @_;
    return undef if !defined $index;
    return undef if $index !~ /\A\d+\z/;
    return undef if $index >= $self->{size};

    my $idx = ($self->{head} + $index) % _cap($self);
    return $self->{buf}[$idx];
}

sub values {
    my ($self) = @_;
    my $n = $self->{size};
    return () if $n == 0;

    my $cap  = _cap($self);
    my $head = $self->{head};
    my $buf  = $self->{buf};

    return map { $buf->[ ($head + $_) % $cap ] } (0 .. $n - 1);
}

sub clear {
    my ($self) = @_;
    my $cap = _cap($self);

    for (my $i = 0; $i < $cap; $i++) {
        $self->{buf}[$i] = undef;
    }

    $self->{head} = 0;
    $self->{size} = 0;
    return $self;
}

sub push {
    my ($self, @items) = @_;
    return $self if !@items;

    for my $item (@items) {
        $self->_ensure_capacity_for(1);

        my $cap  = _cap($self);
        my $tail = ($self->{head} + $self->{size}) % $cap;

        $self->{buf}[$tail] = $item;
        $self->{size}++;
    }

    return $self;
}

sub shift {
    my ($self) = @_;
    return undef if $self->{size} == 0;

    my $idx = $self->{head};
    my $val = $self->{buf}[$idx];

    $self->{buf}[$idx] = undef;
    $self->{head} = ($self->{head} + 1) % _cap($self);
    $self->{size}--;

    $self->{head} = 0 if $self->{size} == 0;
    return $val;
}

sub pop {
    my ($self) = @_;
    return undef if $self->{size} == 0;

    my $cap = _cap($self);
    my $idx = ($self->{head} + $self->{size} - 1) % $cap;
    my $val = $self->{buf}[$idx];

    $self->{buf}[$idx] = undef;
    $self->{size}--;

    $self->{head} = 0 if $self->{size} == 0;
    return $val;
}

sub slide {
    my ($self, $item) = @_;

    if ($self->{size} == 0) {
        $self->push($item);
        return undef;
    }

    my $cap = _cap($self);

    my $idx = $self->{head};
    my $old = $self->{buf}[$idx];

    $self->{buf}[$idx] = $item;
    $self->{head} = ($self->{head} + 1) % $cap;

    return $old;
}

sub _cap { scalar @{ $_[0]->{buf} } }

sub _ensure_capacity_for {
    my ($self, $add) = @_;

    my $need = $self->{size} + $add;
    my $cap  = _cap($self);
    return if $need <= $cap;

    my $new_cap = $cap * 2;
    $new_cap *= 2 while $new_cap < $need;

    my @new = (undef) x $new_cap;
    for (my $i = 0; $i < $self->{size}; $i++) {
        $new[$i] = $self->{buf}[ ($self->{head} + $i) % $cap ];
    }

    $self->{buf}  = \@new;
    $self->{head} = 0;

    return;
}

sub _check_alloc {
    my ($n) = @_;
    croak "alloc must be defined" if !defined $n;
    croak "alloc must be an integer >= 1" if $n !~ /\A[1-9]\d*\z/;
    return 1;
}

1;

__END__

=pod

=head1 NAME

Algorithm::SlidingWindow::Dynamic - Generic, dynamically sized sliding window

=head1 SYNOPSIS

  use Algorithm::SlidingWindow::Dynamic;

  my $w = Algorithm::SlidingWindow::Dynamic->new;

  $w->push(1, 2, 3);        # window: 1 2 3
  my $a = $w->shift;        # removes 1, window: 2 3
  my $b = $w->pop;          # removes 3, window: 2

  $w->push(qw(a b c));      # window: 2 a b c
  my $ev = $w->slide('d');  # evicts 2, window: a b c d

  my @vals = $w->values;    # (a, b, c, d)

=head1 DESCRIPTION

This module provides a generic, count-based sliding window over a sequence of
values. The window stores arbitrary Perl scalars and supports efficient
addition and removal of elements at either end.

The API is intentionally small and is designed to support common
sliding-window and two-pointer algorithms. The window may grow or shrink
dynamically, and operations that remove elements return the removed values,
which is useful when maintaining external state such as running sums or
counts.

The module does not impose a fixed capacity or eviction policy. Instead,
window size is controlled explicitly by the caller through the use of
C<push>, C<shift>, C<pop>, and C<slide> operations. This makes the module
suitable for both variable-length windows and fixed-length rolling windows.

The window is count-based only; it does not track time or perform
time-based expiration. Any ordering, comparison, or aggregation logic is
left to user code.

All core operations run in O(1) amortized time using an internal circular
buffer.

=head1 METHODS

=head2 new(%args)

Creates a new sliding window.

Optional arguments:

=over 4

=item * C<alloc>

Initial internal allocation size (integer >= 1).

=item * C<values>

Array reference of initial values to push.

=back

=head2 push(@items)

Appends one or more items to the right (newest end) of the window.

Each call increases the window size by the number of items added.
No items are removed by this operation.

=head2 shift

Removes and returns the oldest item from the left (oldest end) of the window.

Decreases the window size by one. Returns C<undef> if the window is empty.

=head2 pop

Removes and returns the newest item from the right (newest end) of the window.

Decreases the window size by one. Returns C<undef> if the window is empty.

=head2 slide($item)

Advances the window by one position.

If the window is non-empty, removes the oldest item and appends C<$item> as
the newest item. The window size remains unchanged. The removed item is
returned.

If the window is empty, behaves like C<push($item)> and returns C<undef>.

=head2 size

Returns the number of items currently stored in the window.

=head2 is_empty

Returns true if the window is empty, false otherwise.

=head2 oldest

Returns the oldest item without removing it, or C<undef> if the window is
empty.

=head2 newest

Returns the newest item without removing it, or C<undef> if the window is
empty.

=head2 get($index)

Returns the item at logical index C<$index>, where index C<0> refers to the
oldest item and C<size - 1> refers to the newest item.

Returns C<undef> if the index is out of range.

=head2 values

Returns all items currently in the window, ordered from oldest to newest.

=head2 clear

Removes all items from the window. After this call, the window size is zero.

=head1 EXAMPLES

=head2 Shortest Subarray With Sum >= K (Non-Negative Values)

This example demonstrates the classic sliding-window technique for finding the
length of the shortest contiguous subarray whose sum is at least C<K>.

B<Important:> This algorithm assumes that all input values are non-negative.
If negative values are present, a different approach is required.

  use Algorithm::SlidingWindow::Dynamic;

  sub shortest_subarray_at_least_k {
      my ($nums, $k) = @_;

      my $w   = Algorithm::SlidingWindow::Dynamic->new;
      my $sum = 0;
      my $best;

      for my $x (@$nums) {
          die "negative values not supported" if $x < 0;

          $w->push($x);
          $sum += $x;

          while ($w->size > 0 && $sum >= $k) {
              my $len = $w->size;
              $best = $len if !defined($best) || $len < $best;

              my $removed = $w->shift;
              $sum -= $removed;
          }
      }

      return defined($best) ? $best : -1;
  }

  print shortest_subarray_at_least_k([2, 3, 1, 2, 4, 3], 7), "\n";  # prints 2

=head2 Fixed-Length Rolling Window Using slide()

  my $w = Algorithm::SlidingWindow::Dynamic->new;

  $w->push(10);
  $w->push(20);
  $w->push(30);

  my $evicted = $w->slide(40);
  my @vals    = $w->values;   # (20, 30, 40)

=head2 Removing Elements From Either End

  my $w = Algorithm::SlidingWindow::Dynamic->new;
  $w->push(qw(a b c d));

  my $left  = $w->shift;  # removes 'a'
  my $right = $w->pop;    # removes 'd'

  my @vals = $w->values;  # (b, c)

=head1 LIMITATIONS

=over 4

=item *

This module implements a count-based sliding window only. It does not provide
time-based expiration or automatic removal based on timestamps.

=item *

The module does not perform any aggregation, comparison, or ordering of values.
Such logic must be implemented by the caller.

=item *

Algorithms that require handling of negative values may require additional
data structures beyond a simple sliding window.

=back

=head1 SEE ALSO

L<Algorithm::SlidingWindow>

=head1 AUTHOR

Joshua Day

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
