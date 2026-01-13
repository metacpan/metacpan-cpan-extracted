[![CI](https://github.com/haxmeister/perl-algorithm-slidingwindow/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-algorithm-slidingwindow/actions/workflows/ci.yml)

# Algorithm::SlidingWindow

A **fixed-capacity sliding window** (overwrite-oldest) implemented with an **array-backed circular buffer**.

When the window is full and you add new items, the **oldest** items are automatically evicted. This is designed for streaming, metrics, logging, and sliding-window workloads where you want to keep only the most recent *N* values.

## Features

- O(1) insertion (`add`) per element
- O(1) random access (`get`)
- O(n) snapshot (`values`)
- Handles **any Perl scalar**: numbers, strings, refs, objects
- Evicted / cleared slots are set to `undef` so references are released promptly
- Minimal method call overhead and predictable behavior

## Install

### From CPAN
```sh
cpanm Algorithm::SlidingWindow
```

### From source (this repository)
```sh
perl Makefile.PL
make
make test
make install
```

## Quick start

```perl
use Algorithm::SlidingWindow;

my $w = Algorithm::SlidingWindow->new(capacity => 5);

$w->add(1, 2, 3);
$w->add(4, 5);

my @vals = $w->values;  # (1, 2, 3, 4, 5)

$w->add(6);             # evicts 1
@vals = $w->values;     # (2, 3, 4, 5, 6)

print "oldest=", $w->oldest, " newest=", $w->newest, "\n";
```

## Eviction callback (`on_evict`)

You may provide an optional callback that receives each evicted element:

```perl
my @evicted;

my $w = Algorithm::SlidingWindow->new(
    capacity => 3,
    on_evict => sub {
        my ($old) = @_;
        push @evicted, $old;
    },
);

$w->add(qw(a b c d e));   # evicts a, then b
# @evicted = ('a', 'b')
```

## API

### Constructor

#### `new(capacity => INT, on_evict => CODEREF?)`

Creates a new sliding window.

- `capacity` (required): positive integer greater than zero
- `on_evict` (optional): called as `on_evict->($old_value)` on eviction

### Methods

#### `add(@items) -> $self`
Adds one or more scalars as newest elements.  
If the window is full, the oldest elements are evicted.

#### `values() -> @items`
Returns a snapshot of the window from **oldest to newest**.

#### `get($index) -> $item | undef`
Random access by logical index:

- index `0` is the **oldest**
- index `size - 1` is the **newest**

Returns `undef` if the index is invalid or out of range.

> Negative indices are intentionally not supported.

#### `clear() -> $self`
Removes all elements and clears storage slots immediately.

#### `capacity() -> INT`
Returns the fixed capacity of the window.

#### `size() -> INT`
Returns the number of elements currently stored.

#### `is_empty() -> BOOL`
True if the window contains no elements.

#### `is_full() -> BOOL`
True if the window is at full capacity.

#### `oldest() -> $item | undef`
Returns the oldest element without removing it.

#### `newest() -> $item | undef`
Returns the newest element without removing it.

## Behavior notes

- Eviction policy is deterministic: **overwrite-oldest**
- Order is preserved at all times
- Slots are cleared on eviction and `clear()` to help free references promptly
- This module does **not** attempt to emulate Perl array semantics

## Development

### Run tests
```sh
prove -l
```

or CPAN-style:
```sh
perl Makefile.PL
make test
```

## License

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.
