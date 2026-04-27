package Data::BitSet::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::BitSet::Shared', $VERSION);

use overload
    '""'   => \&to_string,
    'bool' => sub { 1 },
    fallback => 1;

sub set_bits {
    my ($self) = @_;
    grep { $self->test($_) } 0 .. $self->capacity - 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::BitSet::Shared - Shared-memory fixed-size bitset for Linux

=head1 SYNOPSIS

    use Data::BitSet::Shared;

    my $bs = Data::BitSet::Shared->new(undef, 256);
    $bs->set(10);
    $bs->set(42);
    say $bs->test(10);        # 1
    say $bs->test(11);        # 0
    say $bs->count;           # 2
    $bs->toggle(10);          # returns 0 (new value)
    $bs->clear(42);

    say $bs->first_set;       # undef (all clear now)
    $bs->fill;                # set all 256 bits
    say $bs->count;           # 256

    $bs->zero;                # clear all
    $bs->set(0); $bs->set(2); $bs->set(4);
    say "$bs";                # "10101000..." (stringification)
    my @bits = $bs->set_bits; # (0, 2, 4)

=head1 DESCRIPTION

Fixed-size bitset in shared memory. CAS-based atomic per-bit
operations on uint64_t words. Lock-free set/clear/test/toggle
with hardware popcount.

Useful for shared flags, membership tracking, bloom filter backing,
resource allocation bitmaps.

B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $bs = Data::BitSet::Shared->new($path, $capacity);    # file-backed
    my $bs = Data::BitSet::Shared->new(undef, $capacity);    # anonymous (fork-inherited)
    my $bs = Data::BitSet::Shared->new_memfd($name, $cap);   # memfd (fd-passable)
    my $bs = Data::BitSet::Shared->new_from_fd($fd);         # attach to existing fd

=head2 Bit Operations

    my $old = $bs->set($bit);     # set to 1, returns old value
    my $old = $bs->clear($bit);   # set to 0, returns old value
    my $val = $bs->test($bit);    # read (0 or 1)
    my $new = $bs->toggle($bit);  # flip, returns new value

All bit operations are atomic (CAS-based, lock-free).

=head2 Queries

    $bs->count;          # popcount (total set bits)
    $bs->capacity;       # total bits
    $bs->any;            # true if any bit set
    $bs->none;           # true if no bits set
    $bs->first_set;      # index of first 1, or undef
    $bs->first_clear;    # index of first 0, or undef
    my @bits = $bs->set_bits;  # list of all set bit indices

=head2 Bulk

    $bs->fill;           # set all bits to 1
    $bs->zero;           # set all bits to 0

B<Not safe to call concurrently with per-bit operations> — these
store full 64-bit words, which can race with CAS-based set/clear/toggle
on any bit in the same word.

=head2 Stringification

    say "$bs";           # "01001..." (overloaded)
    my $s = $bs->to_string;

=head2 Common

    my $p  = $bs->path;       # backing file path (undef if anon/memfd)
    my $fd = $bs->memfd;      # memfd fd (-1 if file-backed/anon)
    $bs->sync;                # msync to disk
    $bs->unlink;              # remove backing file
    Class->unlink($path);     # class method form
    my $s  = $bs->stats;      # diagnostic hashref

=head1 BENCHMARKS

Single-process (1M ops, x86_64 Linux, Perl 5.40, 64K-bit set):

    set             10.5M/s
    test            10.3M/s
    toggle          10.5M/s
    first_set       13.8M/s
    count (64K pop)  0.5M/s

=head1 STATS

C<stats()> returns a hashref with keys: C<capacity>, C<count>,
C<sets>, C<clears>, C<toggles>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

=head1 SEE ALSO

L<Data::Buffer::Shared> - typed shared array

L<Data::Pool::Shared> - fixed-size object pool

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Queue::Shared> - FIFO queue

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log

L<Data::Sync::Shared> - synchronization primitives

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
