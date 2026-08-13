package Data::BitSet::Shared;
use strict;
use warnings;
our $VERSION = '0.06';
require XSLoader;
XSLoader::load('Data::BitSet::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

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

    # freeze and ship: query it read-only (lock-free) on other machines
    my $shared = Data::BitSet::Shared->new("/tmp/seen.bitset", 256);
    $shared->set(10);
    $shared->freeze;
    my $ro = Data::BitSet::Shared->new_readonly("/tmp/seen.bitset");
    $ro->test(10);

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
    my $ro = Data::BitSet::Shared->new_readonly($path);      # frozen file, read-only

C<new_readonly> opens a B<frozen> file read-only for lock-free querying (see
L</"FROZEN (READ-ONLY) MODE">). The descriptor you pass is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the handle.

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

B<Not safe to call concurrently with per-bit operations> -- these
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
C<sets>, C<clears>, C<toggles>, C<mmap_size>, C<frozen> (1 if the bitset has
been sealed by C<freeze>, else 0), and C<readonly> (1 if this handle is a
read-only view -- from C<new_readonly>, or the handle that called C<freeze> --
else 0).

=head1 FROZEN (READ-ONLY) MODE

A file-backed bitset can be B<frozen> and then shipped to other machines,
where consumers open it B<read-only> and query it with B<no locking at all>
(bit operations are already lock-free CAS/atomics, frozen or not; freezing
only guarantees the mapping is never mutated again).

    # producer: build, freeze, ship the file
    my $bs = Data::BitSet::Shared->new("/tmp/seen.bitset", 1_000_000);
    $bs->set($_) for @known_ids;
    $bs->freeze;                 # seal: now immutable, and $bs itself is read-only
    # ... copy /tmp/seen.bitset to another host ...

    # consumer (any process, same architecture): read-only, lock-free
    my $ro = Data::BitSet::Shared->new_readonly("/tmp/seen.bitset");
    $ro->test($_) for @queries;

C<freeze> marks the bitset B<permanently immutable> (there is no unfreeze --
rebuild the file to change it) and flushes the seal to disk. A frozen bitset
rejects every mutator (C<set>, C<clear>, C<toggle>, C<fill>, C<zero>) with a
croak, and a read-write reopen (C<< new($path, ...) >> or C<new_from_fd>) of a
sealed file is B<refused> -- so a shipped artifact can never be silently
mutated out from under its readers.

C<new_readonly($path)> maps the file C<O_RDONLY> / C<PROT_READ> and B<requires
it to be frozen> (it croaks on a file that was never C<freeze>d). Every query
method (C<test>, C<count>, C<capacity>, C<any>, C<none>, C<first_set>,
C<first_clear>, C<to_string>, C<stats>, stringification) reads the mapping
directly with no lock, so a read-only view works from a read-only file
descriptor or a read-only filesystem, and any number of processes can share
one C<PROT_READ> mapping. C<frozen> and C<readonly> report the two states;
C<sync> is a silent no-op on a read-only handle.

B<Portability.> The on-disk format is native binary (native-endian 64-bit
words), so a frozen file may be copied only between machines of the B<same
architecture>; a wrong-endian file is rejected at open by the magic check.
B<Copy the file to each consumer> -- do not share one file over a network
filesystem: C<MAP_SHARED> coherency across NFS clients is not guaranteed, and
the "no live writer" contract assumes a static copy. Linux-only; 64-bit Perl.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only
the creating user can open and attach them. To share a backing file across
users, pass an explicit octal file mode such as C<0660> as the last argument
to C<new>; the mode is applied when the file is created; a pre-existing file
owned by the caller is adopted -- and also gets the requested mode -- when it
is empty, or when it is the full-size all-zero file an interrupted create
leaves behind (see L</CRASH SAFETY>). Any other existing file keeps its own
permissions. The file is opened with C<O_NOFOLLOW>, so a symlink planted at
the path is refused, and created with C<O_EXCL>; the on-disk header is
validated when the file is attached. Any process you grant write access to a
shared mapping is trusted not to corrupt its contents while other processes
are using it.

=head1 CRASH SAFETY

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete bitset file left
by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

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
