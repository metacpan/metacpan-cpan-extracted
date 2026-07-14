package DBIO::Diff::Op;
# ABSTRACT: Base class for DBIO driver diff operation objects

use strict;
use warnings;

use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors(simple => 'action');


sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}


sub mk_diff_accessors {
  my ($class, @names) = @_;
  $class->mk_group_accessors(simple => @names);
}

my %DEFAULT_PREFIX = (
  create => '+', add    => '+',
  drop   => '-',
  alter  => '~', modify => '~', change => '~',
);


sub summary_prefix {
  my ($self, %map) = @_;
  my $action = $self->action // '';
  return $map{$action} // $DEFAULT_PREFIX{$action} // '~';
}


sub diff_toplevel {
  my ($class, $source, $target, %cb) = @_;
  $source ||= {};
  $target ||= {};

  my @ops;
  for my $name (sort keys %$target) {
    next if exists $source->{$name};
    push @ops, $cb{create}->($name) if $cb{create};
  }
  for my $name (sort keys %$source) {
    next if exists $target->{$name};
    push @ops, $cb{drop}->($name) if $cb{drop};
  }
  return @ops;
}

# Internal: normalize a per-table member collection into { name => $member }.
# A collection that is already a hashref is returned as-is; an arrayref is
# keyed by the field named in $index_by.
sub _members_by_key {
  my ($members, $index_by) = @_;
  return {} unless defined $members;
  if (ref($members) eq 'HASH') {
    return $members;
  }
  my %by;
  $by{ $_->{$index_by} } = $_ for @{ $members };
  return \%by;
}


sub diff_nested {
  my ($class, $source, $target, %opt) = @_;
  $source ||= {};
  $target ||= {};

  my $index_by   = $opt{index_by};
  my $scope      = $opt{scope} || 'both';
  my $skip       = $opt{skip};
  my $changed    = $opt{changed_when};
  my $src_tables = $opt{source_tables} || $source;
  my $tgt_tables = $opt{target_tables} || $target;

  my @ops;

  for my $table (sort keys %$target) {
    if ($scope eq 'both') {
      next unless exists $src_tables->{$table} && exists $tgt_tables->{$table};
    }

    my $src = _members_by_key($source->{$table}, $index_by);
    my $tgt = _members_by_key($target->{$table}, $index_by);

    for my $name (sort keys %$tgt) {
      my $new = $tgt->{$name};
      next if $skip && $skip->($new);

      if (!exists $src->{$name}) {
        push @ops, $opt{on_new}->($table, $name, $new) if $opt{on_new};
        next;
      }

      my $old = $src->{$name};
      if (!$changed || $changed->($old, $new)) {
        push @ops, $opt{on_changed}->($table, $name, $old, $new) if $opt{on_changed};
      }
    }

    for my $name (sort keys %$src) {
      my $old = $src->{$name};
      next if $skip && $skip->($old);
      next if exists $tgt->{$name};
      push @ops, $opt{on_gone}->($table, $name, $old) if $opt{on_gone};
    }
  }

  if ($scope eq 'all') {
    for my $table (sort keys %$source) {
      next if exists $target->{$table};
      my $src = _members_by_key($source->{$table}, $index_by);
      for my $name (sort keys %$src) {
        my $old = $src->{$name};
        next if $skip && $skip->($old);
        push @ops, $opt{on_gone}->($table, $name, $old) if $opt{on_gone};
      }
    }
  }

  return @ops;
}


sub should_emit_if_exists {
  my ($storage) = @_;
  return 0 unless $storage;
  return 0 unless ref($storage) && $storage->can('_use_if_exists');
  return $storage->_use_if_exists ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Diff::Op - Base class for DBIO driver diff operation objects

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

Base class for the per-engine diff operation objects (the C<Diff::Table>,
C<Diff::Column>, C<Diff::Index>, C<Diff::ForeignKey> classes each driver ships).
Those classes were byte-for-byte identical in their C<new>/accessor boilerplate
and 90-95% identical in their C<diff()> create/drop/alter walks across every
driver; only C<as_sql> (quoting, C<ENGINE=>, schema qualification, type
rendering) is genuinely engine-specific.

This base hosts the shared parts:

=over 4

=item * L</new> and the C<action> accessor, plus L</mk_diff_accessors> to
declare the rest without hand-rolling C<< sub foo { $_[0]->{foo} } >> lines.

=item * L</diff_toplevel> -- the create/drop walk for a flat keyed collection
(tables: a name exists only in the target -> create, only in the source ->
drop; no in-place change).

=item * L</diff_nested> -- the create/change/drop walk for members nested under
tables (columns, indexes, foreign keys), parameterized by a per-engine
"did this member change?" predicate (e.g. the C<is_same_*> functions from
L<DBIO::Diff::Compare>) and per-engine op-construction callbacks.

=item * L</summary_prefix> -- the C<+>/C<->/C<~> action glyph used in summaries.

=item * L</should_emit_if_exists> -- the F12 helper a per-driver C<as_sql>
calls to decide whether to emit C<IF [NOT] EXISTS> guards.

=back

Subclasses keep C<as_sql> (the real engine seam) and a thin C<summary>, and
call these helpers from their own C<diff> class method. Drivers whose diff is
orchestrated differently (e.g. PostgreSQL's registry-based dispatch, or its
global definition-string index comparison) are free to ignore the walk helpers
and use only L</new>/L</mk_diff_accessors>/L</summary_prefix>/L</should_emit_if_exists>.

=head1 METHODS

=head2 new

    my $op = $class->new(action => 'create', table_name => 'foo', ...);

Blesses the argument hash into the operation class.

=head2 mk_diff_accessors

    __PACKAGE__->mk_diff_accessors(qw/table_name column_name old_info new_info/);

Declares simple hash-slot accessors for the operation class. C<action> is
already provided by this base. This is a thin alias over
C<Class::Accessor::Grouped>'s C<simple> group.

=head2 summary_prefix

    my $glyph = $op->summary_prefix;            # by action, sensible defaults
    my $glyph = $op->summary_prefix(add => '*'); # override per action

Returns the one-character glyph for this op's C<action>: C<+> for
C<create>/C<add>, C<-> for C<drop>, C<~> for C<alter>/C<modify>/C<change>.
Pass an C<< action => glyph >> map to override. Unknown actions default to C<~>.

=head2 diff_toplevel

    my @ops = $class->diff_toplevel($source, $target,
      create => sub { my ($name) = @_; $class->new(action => 'create', ...) },
      drop   => sub { my ($name) = @_; $class->new(action => 'drop',   ...) },
    );

The create/drop walk for a flat collection keyed by name (the table-level
diff). C<$source> and C<$target> are hashrefs C<< { $name => $info } >>. For
each name present only in C<$target> the C<create> callback is invoked; for
each name present only in C<$source> the C<drop> callback is invoked. Names
present in both are left untouched (table identity has no in-place change here;
column/index/fk changes are handled by L</diff_nested>). Names are walked in
sorted order. Each callback may return zero or more ops; all are collected.

=head2 diff_nested

    my @ops = $class->diff_nested($source, $target,
      index_by      => 'column_name',     # omit if members are already a hash
      scope         => 'both',            # or 'all'
      source_tables => $src_model->{tables},
      target_tables => $tgt_model->{tables},
      skip          => sub { my ($m) = @_; ... },   # ignore a member (e.g. auto index)
      changed_when  => sub { my ($old, $new) = @_; scalar changed_column_fields($old, $new) },
      on_new     => sub { my ($table, $name, $new) = @_; ... },
      on_changed => sub { my ($table, $name, $old, $new) = @_; ... },
      on_gone    => sub { my ($table, $name, $old) = @_; ... },
    );

The create/change/drop walk for members nested one level under a table
(columns, indexes, foreign keys). C<$source> and C<$target> are hashrefs
C<< { $table => $members } >>, where C<$members> is either a hashref keyed by
member name or an arrayref of member hashes (in which case pass C<index_by> --
the field to key them by).

For each retained table, every member in the target is matched against the
source by name: present only in the target -> C<on_new>; present in both and
C<changed_when> returns true -> C<on_changed>; present only in the source ->
C<on_gone>. C<changed_when> is the per-engine seam -- pass one of the
C<is_same_*> predicates from L<DBIO::Diff::Compare> (they return the list of
changed fields, hence are true exactly when the member changed). C<skip>, if
given, drops a member from consideration on both sides (used to ignore
auto-generated primary-key / unique indexes).

C<scope> selects which tables are walked:

=over 4

=item * C<both> (default) -- only tables present in B<both> C<source_tables> and
C<target_tables>. Members of brand-new tables are emitted inline by the
table-create op, and members of dropped tables vanish with the table, so they
are skipped here. Pass the model C<tables> sections as C<source_tables> /
C<target_tables> (they default to C<$source> / C<$target> if omitted).

=item * C<all> -- every target table (regardless of source), plus a trailing
pass that emits C<on_gone> for members of source-only tables. Use this when the
member's drop must be emitted even as its table is dropped (e.g. indexes).

=back

Tables and members are both walked in sorted order. Each callback may return
zero or more ops; all are collected.

=head2 should_emit_if_exists

    return 1 if DBIO::Diff::Op::should_emit_if_exists($storage);

F12 helper: returns true iff the connected storage's C<_use_if_exists>
capability is truthy (L<DBIO::Storage::DBI::Capabilities>). Per-driver
C<as_sql> methods call this to decide whether to emit C<IF [NOT] EXISTS>
guards (C<CREATE TABLE IF NOT EXISTS>, C<DROP TABLE IF EXISTS>,
C<ALTER TABLE ... ADD COLUMN IF NOT EXISTS>) so that re-applying a diff
after a partial failure no-ops instead of erroring out.

Returns false (conservative) when C<$storage> is missing, the storage
lacks the capability probe, or the capability is 0. Per-driver adoption
of this helper is a follow-up; the 41 driver C<as_sql> files are not
modified in this commit.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
