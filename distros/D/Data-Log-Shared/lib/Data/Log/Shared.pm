package Data::Log::Shared;
use strict;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Data::Log::Shared', $VERSION);

sub each_entry {
    my ($self, $cb, $from) = @_;
    $from //= 0;
    my $trunc = $self->truncation;
    $from = $trunc if $from < $trunc;
    while (1) {
        my ($data, $next) = $self->read_entry($from);
        last unless defined $data;
        $cb->($data, $from);
        $from = $next;
    }
    return $from;
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Log::Shared - Append-only shared-memory log (WAL) for Linux

=head1 SYNOPSIS

    use Data::Log::Shared;

    my $log = Data::Log::Shared->new(undef, 1_000_000);
    my $off = $log->append("first entry");
    $log->append("second entry");

    # replay from beginning
    my $pos = 0;
    while (my ($data, $next) = $log->read_entry($pos)) {
        say "offset=$pos: $data";
        $pos = $next;
    }

    # iterate
    $log->each_entry(sub { say $_[0] });

    # tail: block until new entries
    my $count = $log->entry_count;
    $log->wait_for($count, 5.0);

    # file-backed / memfd
    $log = Data::Log::Shared->new('/tmp/log.shm', 1_000_000);
    $log = Data::Log::Shared->new_memfd("my_log", 1_000_000);
    $log = Data::Log::Shared->new_from_fd($fd);

=head1 DESCRIPTION

Append-only log in shared memory. Multiple writers append variable-length
entries via CAS on a tail offset. Readers replay from any position.
Entries persist until explicit C<reset>.

Unlike L<Data::Queue::Shared> (consumed on read) and
L<Data::PubSub::Shared> (ring overwrites), the log retains all entries
until truncation. Useful for audit trails, event sourcing, debug logging.

B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Append

    my $off = $log->append($data);  # returns offset, or undef if full

C<$data> must be non-empty (empty strings are rejected since len=0
is the internal uncommitted marker).

=head2 Read

    my ($data, $next_off) = $log->read_entry($offset);
    # returns () if no entry at offset (end of log or uncommitted)

    my $final_pos = $log->each_entry(sub {
        my ($data, $offset) = @_;
    });
    my $final_pos = $log->each_entry(\&cb, $start_offset);

=head2 Status

    my $off  = $log->tail_offset;   # byte offset past last entry
    my $n    = $log->entry_count;   # number of committed entries
    my $sz   = $log->data_size;     # total data region size
    my $free = $log->available;     # remaining bytes

=head2 Waiting

    my $ok = $log->wait_for($expected_count);           # block until count changes
    my $ok = $log->wait_for($expected_count, $timeout);  # with timeout
    my $ok = $log->wait_for($expected_count, 0);         # non-blocking poll

Returns 1 if new entries arrived (count != expected), 0 on timeout.

=head2 Lifecycle

    $log->reset;                 # clear all (NOT concurrency-safe)
    $log->truncate($offset);     # mark entries before offset as invalid (concurrency-safe)
    my $off = $log->truncation;  # current truncation offset
    $log->sync;                  # msync to disk
    $log->unlink;                # remove backing file

=head2 Truncation vs Reset

The log has a fixed size (C<data_size>, set at creation). It is
append-only — space is never reclaimed automatically.

C<truncate($offset)> is concurrency-safe (lock-free CAS). It marks
all entries before C<$offset> as logically invalid — readers calling
C<read_entry> or C<each_entry> will skip them. However, truncation
does B<not> free physical space: the tail offset keeps advancing,
and the log will eventually fill regardless of truncation.

C<reset> reclaims all space by zeroing the tail, but is B<not>
concurrency-safe — it must only be called when no other process is
reading or writing.

Typical pattern for long-running logs: size the log generously,
truncate periodically to discard old entries from readers, and
reset during controlled maintenance windows when the log fills.

See C<eg/truncate.pl> in the distribution for a working example.

=head2 Common

    my $p  = $log->path;
    my $fd = $log->memfd;
    my $s  = $log->stats;

=head2 eventfd

    my $fd = $log->eventfd;
    $log->eventfd_set($fd);
    my $fd = $log->fileno;
    $log->notify;
    my $n  = $log->eventfd_consume;

=head1 STATS

C<stats()> returns: C<data_size>, C<tail>, C<count>, C<available>,
C<waiters>, C<appends>, C<waits>, C<timeouts>, C<mmap_size>.

=head1 SECURITY

The mmap region is writable by all processes that open it.
Do not share backing files with untrusted processes.

=head1 BENCHMARKS

Single-process (1M ops, x86_64 Linux, Perl 5.40):

    append (12B entries)     8.9M/s
    append (200B entries)    8.0M/s
    read_entry sequential   4.1M/s

Multi-process (8 workers, 200K appends each):

    concurrent append       6.2M/s aggregate

=head1 SEE ALSO

L<Data::Queue::Shared> - FIFO queue (consumed on read)

L<Data::ReqRep::Shared> - request-reply

L<Data::PubSub::Shared> - publish-subscribe ring (overwrites)

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Buffer::Shared> - typed shared array

L<Data::Sync::Shared> - synchronization primitives

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
