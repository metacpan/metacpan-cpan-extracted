# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# The Index is the Perl-maximal lifecycle layer over a directory of compiled segments. It is where the
# headline property lives: adding or removing a pattern never rebuilds the whole cache. Adding patterns
# compiles ONE small new segment and appends it to the manifest; removing a pattern only records a
# tombstone. A full recompile ("merge") happens rarely and reads from the authoritative pattern set
# (PostgreSQL stays the source of truth; the compiled index is a derived, disposable cache).
#
# The native engine (Cavil::Matcher::Engine) only walks and resolves; every decision about which
# segments are active and which patterns are tombstoned is made here, in readable Perl.
#
# CONCURRENCY. add_segment/tombstone/merge read the manifest, bump its generation in memory, write
# generation-derived files, then save. Each mutation runs under an exclusive advisory lock (flock on a
# per-index lock file) held around the whole read-modify-save, so concurrent writers on the same host
# serialize instead of clobbering each other's update (which, unlocked, would be last-writer-wins on a
# shared generation-derived filename). The lock is advisory and host-local - which is the right scope,
# since the compiled index is a per-host cache (each host mmaps its own copy). Reads (building a matcher)
# never lock: the manifest swap is atomic (temp+rename), and merge defers deleting the segments it
# retires until the *next* merge (see merge), so a reader that read the old manifest can still mmap the
# files it named. Readers are therefore always safe without a lock.

package Cavil::Matcher::Index;

use strict;
use warnings;
use v5.20;
use feature 'signatures';
no warnings 'experimental::signatures';

use Cavil::Matcher;
use Cavil::Matcher::Manifest;
use Carp 'croak';
use Fcntl ':flock';
use File::Spec;

sub new ($class, %args) {
  croak 'dir required' unless defined $args{dir};
  my $dir = $args{dir};
  mkdir $dir                                unless -d $dir;
  croak "index dir $dir is not a directory" unless -d $dir;
  return bless {dir => $dir}, $class;
}

sub dir        ($self) { $self->{dir} }
sub _manifest  ($self) { Cavil::Matcher::Manifest->new(dir => $self->{dir}) }
sub generation ($self) { $self->_manifest->generation }

# Run a mutation under an exclusive advisory lock on a per-index lock file, held for the whole
# read-modify-save so concurrent writers on the same host serialize. The lock is released when the
# filehandle is closed as the sub returns - including if $code dies, since the handle is destroyed as the
# stack unwinds.
sub _locked ($self, $code) {
  my $path = File::Spec->catfile($self->{dir}, '.lock');
  open my $lock, '>', $path or croak "cannot open index lock $path: $!";    # uncoverable branch true (I/O error)
  flock $lock, LOCK_EX or croak "cannot lock index $path: $!";              # uncoverable branch true (flock failure)
  return $code->();
}

# Checksum a segment file with the engine's own hash (no extra dependency), for manifest-level
# integrity on top of the segment's internal CRC.
sub _checksum ($path) {
  open my $fh, '<:raw', $path or return '';    # uncoverable branch true (callers verify -r first)
  my $ctx = Cavil::Matcher::init_hash(0, 0);
  local $/ = \65536;
  while (my $chunk = <$fh>) { $ctx->add($chunk) }
  close $fh;
  return $ctx->hex;
}

# Parse each [id, pattern_text] row to [id, \@tokens], dropping any row that normalizes to an empty token
# list (text that is all punctuation or ignored words). Such a row can never match, so silently keeping
# it would make the manifest's pattern_count claim a pattern was indexed when nothing compilable exists.
# The count and the tombstone-clearing below therefore reflect what actually compiled, not what was asked.
sub _parse_patterns ($patterns) {
  my @parsed;
  for my $row (@$patterns) {
    my $tokens = Cavil::Matcher::parse_tokens($row->[1]);
    push @parsed, [$row->[0], $tokens] if @$tokens;
  }
  return \@parsed;
}

# Compile one segment file from already-parsed [[id, \@tokens], ...] at the given generation. Returns the
# file's basename, or undef on failure.
sub _compile_segment ($self, $parsed, $gen, $basename) {
  my $engine = Cavil::Matcher::init_matcher();
  $engine->set_generation($gen);
  $engine->add_pattern($_->[0], $_->[1]) for @$parsed;
  my $path = File::Spec->catfile($self->{dir}, $basename);
  return undef unless $engine->dump($path);
  return $basename;
}

# Incrementally add patterns as a new delta segment. Existing segment files are never touched.
# $patterns is an arrayref of [id, pattern_text]. Returns the new generation.
sub add_segment ($self, $patterns) {
  return $self->generation unless $patterns && @$patterns;
  my $parsed = _parse_patterns($patterns);
  return $self->generation unless @$parsed;    # every row normalized to empty => nothing compilable to add
  return $self->_locked(sub {
    my $man  = $self->_manifest;
    my $gen  = $man->bump;
    my $file = sprintf('seg-%010d.seg', $gen);
    $self->_compile_segment($parsed, $gen, $file) or croak "failed to compile segment $file";
    my $path = File::Spec->catfile($self->{dir}, $file);

    # Fail closed: we just wrote this segment, so we must be able to checksum it. An empty result means
    # the file could not be read back (transient I/O or permissions) - store no entry rather than one
    # that silently opts out of the manifest-level integrity check. (An empty checksum in a *read*
    # manifest is still honoured for backward compatibility; only fresh writes are strict.)
    my $checksum = _checksum($path);
    croak "failed to checksum new segment $file" unless length $checksum;    # uncoverable branch true (I/O race)

    # Introducing an id must un-suppress it: clear any tombstone for the ids in this segment, so a
    # delete-then-re-add of the same id takes effect immediately rather than staying hidden until the
    # next merge clears all tombstones. (Cavil's pattern ids are DB-immutable so reuse should not happen;
    # this keeps the lifecycle correct if it ever does, instead of silently relying on that invariant.)
    $man->remove_tombstones(map { $_->[0] } @$parsed);
    $man->add_segment(file => $file, checksum => $checksum, pattern_count => scalar @$parsed);
    $man->save;
    return $gen;
  });
}

# Record pattern ids as removed. No segment is recompiled; the engine drops these before resolution.
sub tombstone ($self, @ids) {
  return $self->generation unless @ids;

  # Validate at the public boundary, as add_pattern does: a tombstone id must be an integer in the
  # engine's 32-bit id space. Otherwise we would bump the generation and record a tombstone the native
  # engine can never apply (it ignores out-of-range ids to avoid uint32 wraparound), and the manifest
  # reader would silently drop it on the next load - a dead write.
  for my $id (@ids) {
    croak sprintf('Cavil::Matcher::Index::tombstone: id %s out of range (must be 1..4294967295)',
      defined $id && !ref $id ? $id : '(invalid)')
      unless defined $id && !ref $id && $id =~ /^[0-9]+$/ && $id >= 1 && $id <= 4294967295;
  }

  return $self->_locked(sub {
    my $man = $self->_manifest;
    $man->bump;
    $man->add_tombstones(@ids);
    $man->save;
    return $man->generation;
  });
}

# Rare compaction: rebuild a single base segment from the authoritative pattern set and retire every
# existing segment and tombstone. This is the "merge" step - it is what keeps segment count and the
# tombstone list bounded over time. Reading the full set from the caller (the DB) keeps the engine
# simple and the source of truth in PostgreSQL. Returns the new generation.
sub merge ($self, $patterns) {
  my $parsed = _parse_patterns($patterns // []);
  return $self->_locked(sub {
    my $man  = $self->_manifest;
    my $gen  = $man->bump;
    my $file = sprintf('base-%010d.seg', $gen);
    $self->_compile_segment($parsed, $gen, $file) or croak "failed to compile base segment $file";
    my $path = File::Spec->catfile($self->{dir}, $file);

    # Fail closed on a fresh write, as in add_segment: a base we just wrote but cannot checksum must not
    # be recorded with an integrity-check-disabling empty checksum.
    my $checksum = _checksum($path);
    croak "failed to checksum new base segment $file" unless length $checksum;    # uncoverable branch true (I/O race)

    my @old = map { $_->{file} } @{$man->segments};
    $man->set_segments({file => $file, checksum => $checksum, pattern_count => scalar @$parsed});
    $man->clear_tombstones;
    $man->save;

    # Deferred deletion. Readers do not lock: one may have read the *old* manifest just before our swap
    # and be about to mmap the segments it named. If we deleted those now, that reader's open() would fail
    # and it would build a partial matcher. So we do NOT delete the segments this merge retires (@old);
    # we delete only files orphaned by a PREVIOUS merge - on disk but named by neither the manifest we
    # just replaced nor the new base. Since compaction is rare, "one merge ago" is an enormous grace
    # period next to a reader's read-manifest-then-mmap window, so no reader lock or timer is needed. The
    # retired @old become deletable at the next merge. (Not crash-durable - the index is a disposable
    # cache rebuilt from PostgreSQL - so recovery from a power loss mid-merge is simply to rebuild.)
    my %keep = map { $_ => 1 } (@old, $file);
    if (opendir my $dh, $self->{dir}) {    # uncoverable branch false (the index dir always exists here)
      for my $f (readdir $dh) {

        # Sweep two things: segment files no longer referenced (prior-merge orphans), and crash-leftover
        # temp files (*.tmp.<pid> from a hard kill between write and rename in dump/save). We hold the
        # writer lock and our own temps are already renamed by now, so any temp here is stale - otherwise
        # these would accumulate forever (they never match a real segment name, so the checksum/-r guards
        # ignore them, but they still litter the dir).
        my $orphan_seg = $f =~ /^(?:seg|base)-[0-9]+\.seg\z/ && !$keep{$f};
        my $stale_tmp  = $f =~ /\.tmp\.[0-9]+\z/;
        unlink File::Spec->catfile($self->{dir}, $f) if $orphan_seg || $stale_tmp;
      }
      closedir $dh;
    }
    return $gen;
  });
}

# Build a ready-to-query engine: attach every active segment (skipping any that are missing, fail their
# manifest checksum, or fail the segment's own validation - never dies), apply the tombstones, and pin
# the generation. A report can record the generation for reproducibility.
sub matcher ($self, %opts) {
  my $man    = $self->_manifest;
  my $engine = Cavil::Matcher::init_matcher();
  $engine->set_generation($man->generation);

  my $failed = 0;
  for my $seg (@{$man->segments}) {
    my $path = File::Spec->catfile($self->{dir}, $seg->{file});
    unless (-r $path) {
      warn "cavil-matcher: segment $seg->{file} missing; skipping\n" unless $opts{quiet};
      $failed++;
      next;
    }

    # An empty checksum means "skip the integrity check" (older manifests, or entries written without
    # one); the manifest reader guarantees this field is always a defined string, so no undef check.
    if (length $seg->{checksum} && _checksum($path) ne $seg->{checksum}) {
      warn "cavil-matcher: segment $seg->{file} checksum mismatch; skipping\n" unless $opts{quiet};
      $failed++;
      next;
    }
    unless ($engine->attach($path)) {
      warn "cavil-matcher: segment $seg->{file} failed validation; skipping\n" unless $opts{quiet};
      $failed++;
      next;
    }
  }

  # Availability vs. correctness: by default a damaged/missing segment is skipped so a scan can still run
  # (best effort), but that means an authoritative scan could quietly run against a partial index and
  # report false negatives. Callers that must not scan against an incomplete index pass strict => 1 to
  # fail closed instead.
  if ($opts{strict} && $failed) {
    my $total = scalar @{$man->segments};
    croak "cavil-matcher: $failed of $total segment(s) failed to load (strict)";
  }

  my @tombs = @{$man->tombstones};
  $engine->set_tombstones(\@tombs) if @tombs;
  return $engine;
}

1;
