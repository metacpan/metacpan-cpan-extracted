package Data::PerfectHash::Shared;
use strict; use warnings;
our $VERSION = '0.01';
use XSLoader;
XSLoader::load('Data::PerfectHash::Shared', $VERSION);

package Data::PerfectHash::Shared::Builder;   # blessed builder handle
our $VERSION = '0.01';

1;
__END__

=encoding utf-8

=head1 NAME

Data::PerfectHash::Shared - immutable shared-memory exact set via CHD minimal perfect hashing

=head1 SYNOPSIS

    use Data::PerfectHash::Shared;

    # --- integer keys, via the incremental builder ---
    my $b = Data::PerfectHash::Shared->new_builder(type => 'int');   # 'int' is the default
    $b->add($_) for 1, 2, 3, 5, 8, 13;
    $b->add_many([21, 34, 55]);
    $b->count;                            # 9 -- keys given to add/add_many so far
    $b->build('/tmp/fib.phs');            # computes the perfect hash, writes the image (mode 0600)

    my $set = Data::PerfectHash::Shared->load('/tmp/fib.phs');   # mmap, read-only
    $set->has(13);                        # true
    $set->has(14);                        # false
    $set->count;                          # 9 -- distinct keys actually stored
    $set->each_key(sub { my ($key) = @_; ... });   # visit every stored key
    $set->type;                           # 'int'
    $set->unlink;                         # remove the backing file

    # --- string keys, via the one-shot class methods ---
    Data::PerfectHash::Shared->build_str('/tmp/words.phs', ['apple', 'banana', 'cherry']);
    my $words = Data::PerfectHash::Shared->load('/tmp/words.phs');
    $words->has('banana');                # true
    $words->has('durian');                # false

    # same one-shot form for integers:
    Data::PerfectHash::Shared->build_int('/tmp/ids.phs', \@user_ids);

=head1 DESCRIPTION

Data::PerfectHash::Shared is an immutable exact static set: build it once from a
fixed collection of keys (integers or byte strings), then test membership from any
number of processes with lock-free, O(1)-worst-case reads over a shared read-only
mapping.

Membership is computed with a CHD (compress, hash, displace) minimal perfect hash
over XXH3: for the N distinct keys given to a builder, C<build> finds a
displacement value per bucket such that every key lands on its own slot, with no
collisions and no wasted slots. There are about a sixth as many buckets as keys,
and each bucket's displacement is stored byte-packed at the minimal width (1 to 4
bytes), so the whole index costs on the order of four bits per key. A minimal
perfect hash alone would map any
key -- even one never added -- to some occupied slot, so a bare "is this slot
occupied" test would false-positive on non-members. To rule that out, every key is
also stored in full (its int64 value, or its bytes in an append-only arena for
strings), so C<has> always finishes with an exact comparison against the stored
key: zero false positives, and (by construction, and covered by t/03_exact.t)
zero false negatives.

The image is B<immutable> once built: there is no incremental add, remove, or
update on a loaded set. That means C<load>'s reads need none of the locking,
atomics, or crash/dead-process recovery that the rest of the C<Data::*::Shared>
family carries for its mutable structures -- C<load> just C<mmap>s the file
C<PROT_READ|MAP_SHARED>, and any number of processes may C<load> and query the
same path concurrently. To change membership, build a new file (optionally at the
same path) and have readers C<load> it again.

The B<builder> is a private, in-process object (plain heap memory, not a shared
mapping) used only to collect keys before C<build> computes the hash and writes
the image; the built C<.phs> file -- opened with C<load> -- is the shared artifact.

The on-disk image is validated at C<load> time: a magic number, a format version,
an explicit endianness marker, and the recorded file size are all checked, along
with the bounds of every region (the displacement array, the slot array, and, for
string sets, the byte arena). A file that fails any check -- including one built
on a different byte order -- is refused with a descriptive error instead of being
misread. The image is written in the host's native byte order -- the header
struct and its 64-bit fields as-is, with only the packed displacement entries
explicitly little-endian -- and is tagged with an explicit endianness marker
that C<load> checks, so an image is portable only to hosts of the same byte
order (and C integer sizes) and is refused rather than misread on any other (see
L</SECURITY> for what is, and is not, re-validated on every lookup).

=head1 METHODS

=head2 Builder

    my $b = Data::PerfectHash::Shared->new_builder(%opts);
    my $b = Data::PerfectHash::Shared->new_builder;             # type => 'int', the default
    my $b = Data::PerfectHash::Shared->new_builder(type => 'str');

    $b->add($key);
    $b->add_many(\@keys);
    $b->count;
    $b->build($path, mode => 0600);

C<new_builder> is a class method that returns a blessed
C<Data::PerfectHash::Shared::Builder> handle. C<%opts> takes one key, C<type>,
which is C<'int'> or C<'str'> (default C<'int'>); every key later given to this
builder must match.

C<add> appends one key: an integer builder takes any Perl integer-ish scalar
(coerced with Perl's normal numeric conversion and stored as a signed 64-bit
integer); a string builder takes any byte string, including one with embedded NUL
bytes (encode wide-character strings to bytes yourself first). C<add_many> appends
every element of an arrayref the same way, in order; a nonexistent element (a hole
in a sparse array) is silently skipped.

C<count> returns the number of keys given to C<add>/C<add_many> so far --
B<before> deduplication, so adding the same key three times counts three towards
it. (This is a running tally on the builder; it does not change when C<build> is
called. The final, deduplicated key count is C<< $set->count >> after
C<build>/C<load> -- see below.)

C<build> deduplicates the keys added so far, computes the CHD perfect hash over
the survivors, and writes the immutable image to C<$path>, creating it securely
with mode C<0600> (owner-only) by default; pass C<< mode => $mode >> for a
different octal mode (e.g. C<0644>, to share the file with other users). C<build>
croaks on failure, including the (exceedingly unlikely for real key sets, and only
theoretically reachable for a pathological or adversarially crafted one) case
where CHD cannot find a placement within its attempt budget.

=head2 Class one-shots

    Data::PerfectHash::Shared->build_int($path, \@integers);
    Data::PerfectHash::Shared->build_str($path, \@strings);

Convenience wrappers that create a builder of the matching type, C<add_many> every
element, C<build> to C<$path> with the default mode C<0600>, and free the builder
-- equivalent to, but cheaper than, doing all of that by hand. Both croak on
failure and otherwise return a true value.

=head2 Set (querying a built image)

    my $set = Data::PerfectHash::Shared->load($path);

    $set->has($key);           # bool, O(1) worst case, exact (no false positives)
    $set->count;                # number of distinct keys stored
    $set->each_key(sub { my ($key) = @_; ... });
    $set->type;                 # 'int' or 'str'
    $set->path;                 # the path given to load()
    $set->unlink;                # remove the backing file

C<load> is a class method: it C<mmap>s C<$path> read-only
(C<PROT_READ|MAP_SHARED>) and validates its header, croaking with a description of
what failed (missing file, truncated file, bad magic, unsupported version, wrong
byte order, or a size/region mismatch) rather than returning a set that is not
safe to query.

C<has> reports whether C<$key> is a member, coercing C<$key> the same way C<add>
does (an integer set takes integers, a string set takes byte strings); it never
returns true for a key that was never added, and never false for one that was.

C<count> is the number of B<distinct> keys stored -- after the deduplication that
C<build> performed -- unlike the builder's C<count> described above.

C<each_key> calls C<< $cb->($key) >> once per stored key, in internal (CHD slot)
order -- not insertion order, and not sorted. For a string set, a key whose
on-disk slot fails a bounds check (only reachable via a corrupted or
adversarially crafted image) is silently skipped rather than read out of bounds;
see L</SECURITY>.

C<type> returns C<'int'> or C<'str'>. C<path> returns the path C<load> was given.
C<unlink> removes the backing file (a missing file is not an error); the
already-mapped set remains valid and queryable until it goes out of scope, since
unlinking only removes the directory entry.

=head1 SECURITY

C<build>, C<build_int>, and C<build_str> create the image file with mode C<0600>
(owner-only) by default; pass C<< mode => $mode >> to C<build> for a different
mode if the file needs to be shared with other users or processes.

C<load> treats its input as untrusted -- a C<.phs> path can come from anywhere --
so the header (magic, version, endianness, size, and every region's bounds) is
fully validated before any of it is used, and C<load> croaks instead of mmap-ing
something unsafe. Within a file that otherwise passes header validation, an
individual string slot's C<(offset, length)> pair is still attacker-controllable;
validating every slot at C<load> time would cost an O(n) pass on every load just
to guard a file that is already known to be untrusted, so instead C<has> and
C<each_key> each bounds-check a slot immediately before reading through it. A
slot that fails the check is reported as not present (or skipped, for
C<each_key>) rather than read out of bounds.

A built C<.phs> file must be treated as B<immutable> once written: replace it
only by building a fresh file -- which C<build> now does atomically, writing a
temporary file in the same directory and C<rename>-ing it over the target --
never by modifying a mapped file in place. A concurrent writer that truncates or
rewrites a file another process has C<load>-ed (mmap-ed) can crash those readers
with SIGBUS; the atomic temp-file-plus-rename build avoids this by leaving the
old inode intact for existing readers until they release it.

=head1 LIMITS

=over 4

=item *

B<Immutable.> A built image cannot be added to, removed from, or updated in
place; there is no such API. To change membership, build a new file (the builder
is cheap and disposable) and have readers C<load> it again.

=item *

B<Exact set, not a map.> Keys have no associated value -- C<has> is a membership
test, not a lookup. Store values elsewhere (keyed by the same integer or string)
if you need them.

=item *

B<Same byte order to load what you built.> C<load> checks an explicit endianness
marker in the header; an image built on a big-endian host refuses to load on a
little-endian one (or vice versa) with a clear error rather than misreading it.

=back

=head1 PERFORMANCE

Built once, queried many times -- so the read path is what matters. C<has> is
one hash of the key, a single indexed probe into the displacement table, and one
comparison against the stored key: lock-free, O(1) worst case, with no shared
mutable state, so lookups scale linearly across processes.

A snapshot for one million keys, in a single process on one core of an Intel
i5-1135G7 (perl 5.40) -- your numbers will vary:

  1,000,000 keys        int           str ("key-NNN")
  --------------------  ------------  ---------------
  build (one-shot)      ~10 s         ~11 s
  has() lookups         ~4.4 M/s      ~2.1 M/s
  each_key iteration    ~14 M/s       ~6.5 M/s
  index                 4.0 bits/key  4.0 bits/key
  image on disk         8.5 MB        26 MB

The perfect-hash index costs about four bits per key; the file itself is
dominated by the full keys it stores (eight bytes for each integer; the key
bytes plus a 16-byte slot for each string), which is what makes membership exact
-- zero false positives -- and lets C<each_key> hand the keys back. For contrast,
on the same machine C<has> on an integer set runs at about 4.4 M lookups/s
against 1.9 M/s for C<exists> on an ordinary Perl hash, while also being shared
between processes and persistent on disk.

Building is the one expensive step -- the CHD search does more work as the table
fills toward a perfect fit -- and it is a whole-image rebuild, after which
readers simply C<load> the new file. The scripts in F<bench/> reproduce these
figures.

=head1 SEE ALSO

The rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
