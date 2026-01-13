package Algorithm::SlidingWindow;

use strict;
use warnings;

use Carp 'croak';


our $VERSION = '1.002';

sub new {
    my ($class, %args) = @_;

    # --- die if extra arguments ---
    my %allowed = map { $_ => 1 } qw(capacity on_evict);
    for my $k (keys %args) {
        croak "unknown argument '$k'" unless $allowed{$k};
    }

    # --- required arguments ---
    my $capacity = $args{capacity};
    defined $capacity or croak "capacity is required";
    $capacity =~ /\A[0-9]+\z/ or croak "capacity must be a positive integer";
    $capacity > 0 or croak "capacity must be > 0";

    # --- optional arguments ---
    my $on_evict = $args{on_evict};
    if (defined $on_evict) {
        ref($on_evict) eq 'CODE' or croak "on_evict must be a CODE reference";
    }

    # --- initialize backing store ---
    my @buf;
    $#buf = $capacity - 1;   # preallocate fixed storage

    my $self = bless {
        _cap      => 0 + $capacity,
        _buf      => \@buf,
        _head     => 0,
        _size     => 0,
        _on_evict => $on_evict,
    }, $class;

    return $self;
}

sub add {
    my $self = $_[0];

    # Fast path: no items to add
    return $self if @_ == 1;

    my $cap  = $self->{_cap};
    my $buf  = $self->{_buf};
    my $head = $self->{_head};
    my $size = $self->{_size};
    my $cb   = $self->{_on_evict};

    for (my $ai = 1; $ai < @_; $ai++) {
        my $item = $_[$ai];

        if ($size == $cap) {
            my $old = $buf->[$head];
            $cb->($old) if $cb;

            # Drop references immediately
            $buf->[$head] = undef;

            $head++;
            $head = 0 if $head == $cap;
        }
        else {
            $size++;
        }

        my $tail = $head + $size - 1;
        $tail -= $cap if $tail >= $cap;

        $buf->[$tail] = $item;
    }

    $self->{_head} = $head;
    $self->{_size} = $size;

    return $self;
}

sub values {
    my $self = $_[0];

    my $size = $self->{_size};
    return () if $size == 0;

    my $cap  = $self->{_cap};
    my $buf  = $self->{_buf};
    my $i    = $self->{_head};

    my @out;
    $#out = $size - 1;

    for (my $k = 0; $k < $size; $k++) {
        $out[$k] = $buf->[$i];
        $i++;
        $i = 0 if $i == $cap;
    }

    return @out;
}

sub get {
    my $self = $_[0];
    return undef if @_ < 2;

    my $index = $_[1];
    return undef if !defined $index;
    return undef unless $index =~ /\A[0-9]+\z/;
    $index = 0 + $index;

    my $size = $self->{_size};
    return undef if $index >= $size;

    my $cap  = $self->{_cap};
    my $buf  = $self->{_buf};
    my $head = $self->{_head};

    my $i = $head + $index;
    $i -= $cap if $i >= $cap;

    return $buf->[$i];
}

sub clear {
    my $self = $_[0];

    my $size = $self->{_size};
    return $self if $size == 0;

    my $cap  = $self->{_cap};
    my $buf  = $self->{_buf};
    my $i    = $self->{_head};

    for (my $k = 0; $k < $size; $k++) {
        $buf->[$i] = undef;
        $i++;
        $i = 0 if $i == $cap;
    }

    $self->{_head} = 0;
    $self->{_size} = 0;

    return $self;
}

sub capacity { $_[0]->{_cap} }
sub size     { $_[0]->{_size} }
sub is_empty { $_[0]->{_size} == 0 }
sub is_full  { $_[0]->{_size} == $_[0]->{_cap} }

sub oldest {
    my $self = $_[0];
    return undef if $self->{_size} == 0;
    return $self->{_buf}[ $self->{_head} ];
}

sub newest {
    my $self = $_[0];

    my $size = $self->{_size};
    return undef if $size == 0;

    my $cap  = $self->{_cap};
    my $head = $self->{_head};

    my $i = $head + $size - 1;
    $i -= $cap if $i >= $cap;

    return $self->{_buf}[$i];
}

1;

__END__

=head1 NAME

Algorithm::SlidingWindow - Fixed-capacity sliding window (overwrite-oldest)

=head1 SYNOPSIS

    use Algorithm::SlidingWindow;

    my $w = Algorithm::SlidingWindow->new(
        capacity => 5,
        on_evict => sub {
            my ($old) = @_;
            warn "evicted $old\n";
        },
    );

    $w->add(1, 2, 3);
    $w->add(4, 5, 6);   # evicts 1

    my @vals = $w->values;   # (2, 3, 4, 5, 6)

    my $oldest = $w->oldest; # 2
    my $newest = $w->newest; # 6

    my $x = $w->get(1);      # 3

    $w->clear;

=head1 DESCRIPTION

C<Algorithm::SlidingWindow> implements a fixed-capacity sliding window
using an array-backed circular buffer.

When the window reaches capacity and new elements are added, the oldest
elements are automatically evicted. Eviction is normal behavior and is
not considered an error.

The module is designed to:

=over 4

=item *

Handle all Perl scalar types equally (numbers, strings, references, objects)

=item *

Release references immediately when elements are evicted or cleared

=item *

Avoid unnecessary method calls and minimize call stack depth

=item *

Provide predictable O(1) insertion and access behavior

=back

=head1 CONSTRUCTOR

=head2 new

    my $w = Algorithm::SlidingWindow->new(%args);

Creates a new sliding window.

=head3 Arguments

=over 4

=item capacity => INT (required)

The maximum number of elements the window can hold.
Must be a positive integer greater than zero.

=item on_evict => CODEREF (optional)

A callback invoked whenever an element is evicted due to overflow.

The callback is called as:

    $on_evict->($old_value);

where C<$old_value> is the exact scalar being evicted.

=back

=head3 Returns

A new C<Algorithm::SlidingWindow> object.

=head1 METHODS

=head2 add

    $w->add(@items);

Adds one or more elements to the window.

=head3 Arguments

=over 4

=item @items

One or more Perl scalars to add. Scalars may be numbers, strings,
references, or objects.

=back

=head3 Behavior

If the window is full, the oldest element is evicted for each new
element added. Evicted elements:

=over 4

=item *

Are passed to the C<on_evict> callback (if provided)

=item *

Have their storage slots cleared immediately to release references

=back

=head3 Returns

The window object itself (allowing method chaining).

=head2 values

    my @values = $w->values;

Returns all elements currently stored in the window.

=head3 Returns

A list of elements in logical order from oldest to newest.

The returned values are the exact scalars stored in the window; no
copying, cloning, or stringification is performed.

=head2 get

    my $value = $w->get($index);

Retrieves a single element by logical index.

=head3 Arguments

=over 4

=item $index

A non-negative integer index. Index C<0> refers to the oldest element.

=back

=head3 Returns

The stored scalar at the given index, or C<undef> if the index is out of
range or invalid.

Negative indices are not supported.

=head2 clear

    $w->clear;

Removes all elements from the window.

=head3 Returns

The window object itself.

=head2 capacity

    my $cap = $w->capacity;

=head3 Returns

The fixed capacity of the window as an integer.

=head2 size

    my $size = $w->size;

=head3 Returns

The number of elements currently stored in the window.

=head2 is_empty

    if ($w->is_empty) { ... }

=head3 Returns

True if the window contains no elements.

=head2 is_full

    if ($w->is_full) { ... }

=head3 Returns

True if the window is at full capacity.

=head2 oldest

    my $oldest = $w->oldest;

=head3 Returns

The oldest element in the window, or C<undef> if the window is empty.

=head2 newest

    my $newest = $w->newest;

=head3 Returns

The newest element in the window, or C<undef> if the window is empty.

=head1 NOTES

=over 4

=item *

Eviction is deterministic and always removes the oldest element.

=item *

Capacity is immutable after construction.

=item *

This module does not attempt to emulate Perl array semantics.

=back

=head1 AUTHOR

Joshua Day

=head1 LICENSE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
