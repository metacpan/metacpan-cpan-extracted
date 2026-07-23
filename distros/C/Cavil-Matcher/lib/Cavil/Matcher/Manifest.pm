# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# The manifest is the small, human-readable JSON file that names the active segments of an index, the
# set of tombstoned pattern ids, and a monotonic generation counter. It is pure Perl on purpose: this
# is policy, not the hot path, and it is where a new developer should be able to see the whole state of
# an index at a glance. Writes are atomic (temp + rename) so a reader never sees a half-written file.

package Cavil::Matcher::Manifest;

use strict;
use warnings;
use v5.20;
use feature 'signatures';
no warnings 'experimental::signatures';

use Cpanel::JSON::XS ();
use Carp 'croak';

use constant FORMAT_VERSION => 1;

# Cap the generation counter at the largest exactly-representable integer (2**53 - 1). A corrupt or
# hand-edited manifest could carry an enormous "generation"; coercing that with 0 + $gen would lose
# precision (it becomes a float), and the next bump would then derive nonsense segment filenames. Any
# real generation is astronomically below this, so an over-large value is treated as corrupt (reset to 0).
use constant MAX_GENERATION => 9_007_199_254_740_991;

sub new ($class, %args) {
  croak 'dir required' unless defined $args{dir};
  my $dir  = $args{dir};
  my $self = bless {dir => $dir, file => "$dir/manifest.json"}, $class;
  $self->{data} = $self->_read;
  return $self;
}

sub _default {
  return {format_version => FORMAT_VERSION, generation => 0, segments => [], tombstones => []};
}

# A manifest that cannot be read or parsed, or that carries an unknown format version, is treated as
# empty rather than fatal - the index simply rebuilds. Never dies on a bad file.
sub _read ($self) {
  return _default() unless -f $self->{file};    # a directory/socket at this path is "no manifest", not a read to decode
  my $json = do {
    open my $fh, '<:raw', $self->{file} or return _default();    # uncoverable branch true (unreadable after stat)
    local $/;
    <$fh>;
  };
  my $data = eval { Cpanel::JSON::XS->new->decode($json) };
  return _default() unless ref $data eq 'HASH' && ($data->{format_version} // 0) == FORMAT_VERSION;

  # Sanitize every field: a manifest is trusted local state, but a corrupt or hand-edited one must
  # never make a reader (matcher()) die. Anything malformed is dropped, so the index degrades to the
  # entries that are still well-formed rather than crashing.
  my $gen = $data->{generation};
  $data->{generation} = (defined $gen && !ref $gen && $gen =~ /^[0-9]+$/ && $gen <= MAX_GENERATION) ? 0 + $gen : 0;
  $data->{segments}   = _clean_segments($data->{segments});
  $data->{tombstones} = _clean_tombstones($data->{tombstones});
  return $data;
}

# A safe segment filename is a plain basename living inside the index directory: defined, a non-ref
# scalar, with no path separators or ".." traversal components.
sub _safe_name ($name) {
  return 0 unless defined $name && !ref $name && length $name;
  return 0 if $name =~ m{[/\\]} || $name =~ /\.\./;
  return 1;
}

sub _clean_segments ($segments) {
  return [] unless ref $segments eq 'ARRAY';
  my @clean;
  for my $seg (@$segments) {
    next unless ref $seg eq 'HASH' && _safe_name($seg->{file});
    my $checksum = $seg->{checksum};
    my $count    = $seg->{pattern_count};
    push @clean,
      {
      file          => $seg->{file},
      checksum      => (defined $checksum && !ref $checksum) ? "$checksum" : '',
      pattern_count => (defined $count    && !ref $count && $count =~ /^\d+$/) ? 0 + $count : 0
      };
  }
  return \@clean;
}

sub _clean_tombstones ($tombstones) {
  return [] unless ref $tombstones eq 'ARRAY';

  # Keep only non-negative integers within the engine's 32-bit pattern-id space. Dropping refs,
  # non-numeric, and out-of-range values stops a corrupt manifest from wrapping (e.g. 2^32+1 -> 1) and
  # suppressing the wrong pattern.
  return [grep { defined && !ref && /^[0-9]+$/ && $_ <= 4294967295 } @$tombstones];
}

sub data       ($self) { $self->{data} }
sub generation ($self) { $self->{data}{generation} }
sub segments   ($self) { $self->{data}{segments} }
sub tombstones ($self) { $self->{data}{tombstones} }

sub bump ($self) { return ++$self->{data}{generation} }

sub add_segment ($self, %entry) {
  push @{$self->{data}{segments}},
    {file => $entry{file}, checksum => $entry{checksum}, pattern_count => $entry{pattern_count} // 0};
  return $self;
}

sub set_segments ($self, @segs) {
  $self->{data}{segments} = [@segs];
  return $self;
}

sub add_tombstones ($self, @ids) {
  my %seen = map { $_ => 1 } @{$self->{data}{tombstones}};
  push @{$self->{data}{tombstones}}, grep { !$seen{$_}++ } @ids;
  return $self;
}

sub clear_tombstones ($self) {
  $self->{data}{tombstones} = [];
  return $self;
}

# Drop specific tombstones - used when a pattern id is (re)introduced by a new segment, so a stale
# tombstone can no longer suppress it.
sub remove_tombstones ($self, @ids) {
  return $self unless @ids;
  my %drop = map { $_ => 1 } @ids;
  $self->{data}{tombstones} = [grep { !$drop{$_} } @{$self->{data}{tombstones}}];
  return $self;
}

# Write the manifest by encoding to a temp file and renaming it over the real one. The rename is atomic
# for readers (no reader ever sees a half-written file), but this is deliberately not fsync-durable: the
# index is a disposable cache rebuilt from PostgreSQL, so crash recovery is "rebuild", not durability.
sub save ($self) {
  my $json = Cpanel::JSON::XS->new->canonical->pretty->encode($self->{data});
  my $tmp  = "$self->{file}.tmp.$$";
  my $ok   = eval {
    open my $fh, '>:raw', $tmp or die "cannot write manifest: $!\n";    # uncoverable branch true (I/O error)
    print {$fh} $json or die "cannot write manifest: $!\n";             # uncoverable branch true (I/O error)
    close $fh         or die "cannot write manifest: $!\n";             # uncoverable branch true (I/O error)
    rename $tmp, $self->{file} or die "cannot rename manifest: $!\n";
    1;
  };

  # On any failure, remove the temp file so a broken write (e.g. rename onto a bad target, full disk)
  # does not leave manifest.json.tmp.<pid> litter behind, then re-raise.
  unless ($ok) {
    my $err = $@;
    unlink $tmp;
    croak $err;
  }
  return $self;
}

1;
