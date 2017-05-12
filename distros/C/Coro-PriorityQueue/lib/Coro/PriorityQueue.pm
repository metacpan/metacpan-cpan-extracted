package Coro::PriorityQueue;

use strict;
use warnings;
use Carp;
use Coro;
use Coro::Semaphore;
use POSIX qw(floor);

our $VERSION = 1.1;

sub new {
    my ($class, $max) = @_;
    croak 'expected positive int for $max'
        unless defined $max && $max > 0;

    # Pre-allocate array
    my @arr;
    $#arr = $max - 1;

    return bless [
        \@arr,                      # data
        0,                          # item count
        $max,                       # max items
        Coro::Semaphore->new($max), # slots available
        Coro::Semaphore->new(0),    # items ready
        0,                          # shutdown
    ], $class;
}

sub count       { $_[0]->[1] }
sub max         { $_[0]->[2] }
sub is_empty    { $_[0]->count == 0 }
sub is_full     { $_[0]->count >= $_[0]->max }
sub peek        { $_[0]->[0][$_[1]] }
sub is_shutdown { $_[0]->[5] };

sub slots_up    { Coro::Semaphore::up   $_[0]->[3] }
sub slots_down  { Coro::Semaphore::down $_[0]->[3] }
sub items_up    { Coro::Semaphore::up   $_[0]->[4] }
sub items_down  { Coro::Semaphore::down $_[0]->[4] }

sub shutdown {
    my $self = shift;
    $self->[5] = 1;
    Coro::Semaphore::adjust $self->[3], 999_999_999;
    Coro::Semaphore::adjust $self->[4], 999_999_999;
}

sub insert {
    my ($self, $item) = @_;
    croak 'cannot insert undef' unless defined $item;

    # Wait for an available slot
    $self->slots_down;
    croak 'queue shut down' if $self->is_shutdown;

    ++$self->[1];

    # Place item at the bottom of the heap and sift up
    my $arr    = $self->[0];
    my $idx    = $self->[1] - 1;
    my $parent = $idx == 0 ? undef : floor(($idx - 1) / 2);

    $self->[0][$idx] = $item;

    while (defined $parent && $arr->[$idx] < $arr->[$parent]) {
        @$arr[$idx, $parent] = @$arr[$parent, $idx];
        $idx    = $parent;
        $parent = $idx == 0 ? undef : floor(($idx - 1) / 2);
    }

    # Signal waiters
    $self->items_up;

    return $self->[1];
}

sub remove {
    my $self = shift;

    # Wait for an item to be available
    $self->items_down;
    return if $self->is_shutdown && $self->is_empty;

    my $item = shift @{$self->[0]};
    --$self->[1];

    # Move the last item to the root
    unshift @{$self->[0]}, pop @{$self->[0]};

    # Sift down
    my $idx  = 0;
    my $last = $self->[1] - 1;
    my $arr  = $self->[0];

    while (1) {
        my $l = $idx * 2 + 1;
        my $r = $idx * 2 + 2;

        last if $l > $last && $r > $last;

        my $least;
        if ($r > $last) {
            $least = $l;
        } else {
            $least = $arr->[$l] <= $arr->[$r] ? $l : $r;
        }

        if ($arr->[$idx] > $arr->[$least]) {
            @$arr[$idx, $least] = @$arr[$least, $idx];
            $idx = $least;
        } else {
            last;
        }
    }

    # Signal waiters
    $self->slots_up;

    return $item;
}

sub dump {
    my $self = shift;
    printf "Heap (%d/%d)\n", $self->count, $self->max;
    $self->_dump(0, 0);
}

sub _dump {
    my ($self, $idx, $indent) = @_;
    return unless defined $self->peek($idx);

    if ($indent > 0) {
        print '  ' for (1 .. $indent);
    }

    print '-' . $self->peek($idx);
    print "\n";

    my $l = $idx * 2 + 1;
    my $r = $idx * 2 + 2;
    $self->_dump($l, $indent + 1);
    $self->_dump($r, $indent + 1);
}

1;
__END__
=head1 NAME

Coro::PriorityQueue

=head1 SYNOPSIS

    use Coro::PriorityQueue;
    use Coro;

    my $queue = Coro::PriorityQueue->new(10);

    my $producer = async {
        foreach my $i (1 .. 10) {
            $queue->insert($i);
        }

        $queue->shutdown;
    };

    my $consumer = async {
        while (1) {
            my $i = $queue->remove or last;
            printf("%d * 2 = %d\n", $i, $i * 2);
        }
    };

    $producer->join, $consumer->join;

=head1 DESCRIPTION

Priority queues automatically order their contents according to the inserted
item's priority. Calling code must ensure that their queue items are comparable
via this strategy (e.g. by overloading the <=> operator).

Underneath, this is implemented as a simple array heap, using
L<Coro::Semaphore> to control access.

=head1 METHODS

=head2 new($max)

Creates a new queue that can store C<$max> items.

=head2 insert($item)

Inserts an item into the queue. Will block the thread until a slot is available
if necessary. If the queue has been shut down, croaks.

It is an error to insert undef into the queue.

=head2 remove

Removes and returns an item from the queue. Blocks until an item becomes
available if necessary. If the queue is shutdown, returns undefined
immediately.

=head2 count

Returns the number of items currently stored.

=head2 is_empty

Returns true if the queue is empty.

=head2 is_full

Returns true if the queue is full.

=head2 shutdown

Shuts down the queue, after which no items may be inserted. Items already in
the queue can be pulled normally until empty, after which further calls to
C<remove> will return undefined.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>
