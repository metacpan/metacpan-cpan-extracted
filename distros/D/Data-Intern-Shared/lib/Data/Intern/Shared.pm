package Data::Intern::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::Intern::Shared', $VERSION);
1;
__END__

=encoding utf-8

=head1 NAME

Data::Intern::Shared - shared-memory string interning table for Linux

=head1 SYNOPSIS

    use Data::Intern::Shared;

    # up to 1M distinct strings, 32 MB of string bytes, anonymous mapping
    my $in = Data::Intern::Shared->new(undef, 1_000_000, 32 << 20);

    my $id = $in->intern("alice");   # 0  (assigns and stores the string once)
    $in->intern("bob");              # 1
    $in->intern("alice");            # 0  (same bytes -> same id)

    my $same = $in->id_of("alice");  # 0, or undef if never interned
    my $str  = $in->string(0);       # "alice"
    $in->exists("carol");            # false

    # pair with Data::SortedSet::Shared (int64 members) for a string-keyed ZSET:
    $zset->add($in->intern($key), $score);
    my @names = map { $in->string($_) } $zset->rev_range_by_rank(0, 9);

=head1 DESCRIPTION

A string interning table in shared memory: it maps arbitrary byte strings to
dense C<uint32> ids (0, 1, 2, ... in interning order) and back. Each distinct
string is stored once in an append-only arena; interning the same bytes again
returns the same id.

It exists so that string-keyed shared structures can store a cheap fixed-size id
while the string itself is held once, and -- because the table lives in shared
memory -- so that B<< several processes agree on the same string<->id mapping >> (a
per-process Perl hash cannot do that). In particular it turns the int64-keyed
L<Data::SortedSet::Shared> into a string-keyed sorted set: intern the key, store
the id, map ids back to strings on the way out.

Lookups are O(1): an open-addressed forward hash (xxhash) finds the id; a dense
C<< id -> arena offset >> array gives the string back. A write-preferring futex
rwlock with dead-process recovery guards mutation, so many processes may intern
and look up concurrently.

Strings are interned by their B<byte> content (encode wide/utf8 strings first).
Interning is B<permanent>: ids are stable for the life of the table; there is no
per-string removal (see L</LIMITS>). B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $in = Data::Intern::Shared->new($path, $max_strings, $arena_bytes);
    my $in = Data::Intern::Shared->new(undef, $max_strings);          # anonymous
    my $in = Data::Intern::Shared->new_memfd($name, $max_strings, $arena_bytes);
    my $in = Data::Intern::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> for an anonymous mapping); C<$max_strings>
is the id/string capacity; C<$arena_bytes> is the total string-bytes capacity and
is optional (defaults to C<$max_strings * 32>, capped at 4 GB). When reopening an
existing file or memfd, the stored header wins and the caller's sizes are ignored.
C<new_memfd> creates a Linux memfd (transferable via its C<memfd> descriptor);
C<new_from_fd> reopens one in another process.

=head2 Interning

    my $id = $in->intern($str);   # id (>=0); undef if the id space or arena is full
    $in->id_of($str);             # id, or undef if $str was never interned
    $in->string($id);             # the string, or undef if $id is out of range
    $in->exists($str);
    $in->clear;                   # forget everything (all ids invalidated)

C<intern> returns the (existing or newly assigned) id, or C<undef> if either the
id space (C<$max_strings>) or the arena (C<$arena_bytes>) is exhausted -- an
already-interned string always succeeds since it needs no new id or storage.
C<$str> is taken by its bytes; a string containing wide characters croaks (encode
it first). The empty string and strings with embedded NULs are valid keys.

=head2 Introspection and lifecycle

    $in->count; $in->max_strings; $in->arena_used; $in->arena_bytes; $in->stats;
    $in->path; $in->memfd; $in->sync; $in->unlink;     # or Class->unlink($path)

C<count> is the number of distinct interned strings (also the next id to be
assigned). C<sync> flushes the mapping to its backing store (a no-op for
anonymous and memfd tables, which have none); C<unlink> removes the
backing file (also callable as C<< Class->unlink($path) >>); C<path> returns the
backing path (C<undef> for anonymous, memfd, or fd-reopened tables) and C<memfd>
the backing descriptor -- the memfd of a C<new_memfd> table or the dup'd fd of a
C<new_from_fd> table, and -1 for file-backed or anonymous tables.

=head1 SHARING ACROSS PROCESSES

The table lives in a shared mapping, shared the same three ways as the rest of the
family: a B<backing file> (every process calls C<< new($path, ...) >> on the same
path), an B<anonymous mapping inherited across C<fork>>, or a B<memfd> whose
descriptor is passed to an unrelated process (over a UNIX socket via C<SCM_RIGHTS>,
or via C</proc/$pid/fd/$n>) and reopened with C<< new_from_fd($fd) >>. Because the
mapping is shared, B<every process resolves a given string to the same id> and can
turn any id back into the string -- which is the whole point.

    # producer and consumer agree on ids with no coordination
    my $in = Data::Intern::Shared->new(undef, 100_000);   # before fork
    unless (fork) { my $id = $in->intern("session-42"); ...; exit }
    # parent: $in->id_of("session-42") yields the child's id; string($id) agrees

=head1 STATS

C<stats()> returns a hashref: C<count>, C<max_strings>, C<hash_slots>,
C<hash_load> (occupied fraction of the forward hash), C<arena_used>,
C<arena_bytes>, C<arena_load>, C<ops> (running count of C<intern> calls),
and C<mmap_size> (bytes).

=head1 LIMITS

=over 4

=item *

B<Permanent interning.> There is no per-string removal; ids never change. This is
ideal for a bounded key universe (usernames, symbols, paths): add/remove churn of
the same key in a consuming structure never grows the arena. For an unbounded
stream of unique strings the arena grows until full; C<clear> is the only reset.

=item *

B<Byte keys.> Strings are interned by byte content; encode wide strings first.

=item *

B<Fixed sizes.> C<$max_strings> (<= 2^30) and C<$arena_bytes> (<= 4 GB) are set at
construction and cannot grow.

=back

=head1 SECURITY

The mmap region is writable by all processes that open it. Do not share backing
files with untrusted processes.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. The arena and tables are append-only and never rewritten in place, so a
crash leaves the table consistent up to the last completed C<intern>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::SortedSet::Shared> (the int64-keyed sorted set this interns keys for),
L<Data::SpatialHash::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
