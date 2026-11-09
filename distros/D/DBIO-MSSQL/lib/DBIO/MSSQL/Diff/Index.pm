package DBIO::MSSQL::Diff::Index;
# ABSTRACT: Diff operations for MSSQL indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::MSSQL::DDL qw(_quote_ident _quote_table);
use DBIO::Diff::Compare qw(changed_fields);
use DBIO::MSSQL::Diff::Table ();


__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. MSSQL's DROP TABLE also removes the table's own
  # indexes, so a later standalone DROP INDEX ... ON <table> would fail (the
  # table no longer exists). Suppress those drops (karr k15). Absent table
  # sections yield an empty set, preserving the original two-argument
  # behaviour used by direct unit-test calls.
  $source_tables //= {};
  $target_tables //= {};

  # indexes of a view are not diffed: a view is Diff::View's (karr k82)
  my %is_view = map { $_ => 1 }
    DBIO::MSSQL::Diff::Table->view_names($source_tables, $target_tables);
  if (%is_view) {
    $source = { map { $_ => $source->{$_} } grep { !$is_view{$_} } keys %{ $source // {} } };
    $target = { map { $_ => $target->{$_} } grep { !$is_view{$_} } keys %{ $target // {} } };
  }
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  my $create = sub {
    my ($table, $name, $info) = @_;
    $class->new(action => 'create', table_name => $table,
      index_name => $name, index_info => $info);
  };
  my $drop = sub {
    my ($table, $name, $info) = @_;
    $class->new(action => 'drop', table_name => $table,
      index_name => $name, index_info => $info);
  };

  # scope 'all': indexes are diffed for every target table (including
  # brand-new ones, whose standalone indexes are not created inline by the
  # table op) plus a trailing drop pass for source-only tables.
  return $class->diff_nested($source, $target,
    scope        => 'all',
    changed_when => sub {
      scalar changed_fields($_[0], $_[1],
        bool   => ['is_unique', 'is_unique_constraint'],
        dim    => ['columns'],
        scalar => ['kind'])
      or $class->normalize_filter($_[0]{filter})
         ne $class->normalize_filter($_[1]{filter});
    },
    on_new     => sub { $create->(@_) },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      ($drop->($table, $name, $old), $create->($table, $name, $new));
    },
    on_gone    => sub {
      my ($table, $name, $info) = @_;
      # Skip when the owning table is itself being dropped this pass; the
      # DROP TABLE already removes this index (karr k15).
      return () if $dropped_table{$table};
      return $drop->($table, $name, $info);
    },
  );
}


sub normalize_filter {
  my ($class, $f) = @_;
  return '' unless defined $f && $f =~ /\S/;
  # literal and non-literal parts alternate; '' inside a literal is an escape
  my @parts = split /('(?:[^']|'')*')/, $f, -1;
  my $out = '';
  for my $i (0 .. $#parts) {
    if ($i % 2) { $out .= $parts[$i]; next }
    my $p = lc $parts[$i];
    $p =~ s/\[(\w+)\]/$1/g;
    $p =~ s/\s+/ /g;
    $p =~ s/ ?([=<>!(,]) ?/$1/g;
    $p =~ s/ \)/)/g;
    # parentheses around a number: the server writes (1) where a declaration has 1
    1 while $p =~ s/(?<=[=<>(,])\((-?[\d.]+)\)/$1/;
    $out .= $p;
  }
  $out =~ s/^ +| +$//g;
  # parentheses around the whole predicate
  while ($out =~ /^\((.*)\)$/s) {
    my ($inner, $depth, $wraps) = ($1, 0, 1);
    my @in = split /('(?:[^']|'')*')/, $inner, -1;
    OUTER: for my $i (0 .. $#in) {
      next if $i % 2;
      for my $c (split //, $in[$i]) {
        $depth++ if $c eq '(';
        if ($c eq ')' && --$depth < 0) { $wraps = 0; last OUTER }
      }
    }
    last unless $wraps && $depth == 0;
    $out = $inner;
  }
  return $out;
}


sub as_sql {
  my ($self) = @_;

  my $constraint = $self->index_info->{is_unique_constraint};

  if ($self->action eq 'create' && $constraint) {
    return sprintf 'ALTER TABLE %s ADD CONSTRAINT %s UNIQUE %s(%s);',
      _quote_table($self->table_name), _quote_ident($self->index_name),
      (($self->index_info->{kind} || '') eq 'clustered' ? 'CLUSTERED ' : ''),
      join ', ', map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
  }
  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $kind = $self->index_info->{kind} || '';
    my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED ' : $kind eq 'nonclustered' ? 'NONCLUSTERED ' : '';
    my $cols = join ', ',
      map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
    my $sql = sprintf 'CREATE %s%sINDEX %s ON %s (%s)',
      $unique,
      $kind_sql,
      _quote_ident($self->index_name),
      _quote_table($self->table_name),
      $cols;
    my $filter = $self->index_info->{filter};
    $sql .= " WHERE $filter" if defined $filter && length $filter;
    return "$sql;";
  }
  return sprintf 'ALTER TABLE %s DROP CONSTRAINT %s;',
      _quote_table($self->table_name), _quote_ident($self->index_name)
    if $constraint;
  return sprintf 'DROP INDEX %s ON %s;', _quote_ident($self->index_name), _quote_table($self->table_name);
}


sub summary {
  my ($self) = @_;
  return sprintf '  %sindex: %s on %s',
    $self->summary_prefix, $self->index_name, $self->table_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Diff::Index - Diff operations for MSSQL indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Index-level diff operations for MSSQL. MSSQL supports C<CREATE INDEX>,
C<DROP INDEX>, and C<CREATE INDEX ... DROP_EXISTING>. Built on
L<DBIO::Diff::Op> (the nested walk). A definition change is a drop-then-
create pair. Index column I<order> is significant, so the column list is
compared as an order-preserving C<dim> field (not the order-independent
default of L<DBIO::Diff::Compare/changed_index_fields>).

B<A unique constraint is not an index.> The model flags the entries that are
constraints (C<is_unique_constraint>, from C<sys.indexes>), the kind
L<DBIO::MSSQL::DDL/install_ddl> writes for a C<unique> declaration of the
result class. The diff creates one the same way, as
C<ALTER TABLE ... ADD CONSTRAINT E<lt>nameE<gt> UNIQUE (...)>, and removes it with
C<ALTER TABLE ... DROP CONSTRAINT>: the server refuses C<DROP INDEX> on a
constraint (Msg 3723). A unique B<index> (a declared C<mssql_indexes> or
C<idx> entry with C<unique>) stays C<CREATE UNIQUE INDEX> / C<DROP INDEX>.
Being a constraint is part of what an entry is: a change from one to the
other is a drop-then-create pair.

A B<filtered> index (C<CREATE INDEX ... WHERE E<lt>predicateE<gt>>, the C<filter> of
the model entry, read from C<sys.indexes.filter_definition>) is a different
index from the unfiltered one over the same columns: adding, removing or
changing the filter is a drop-then-create pair, like any other definition
change. The server hands the predicate back in a form of its own
(C<a = 1> as C<([a]=(1))>), so two filters are compared through
L</normalize_filter>, not as written. A target that declares no filter against a
live index that has one is a change (the filter is part of the definition, not
a field the desired state may leave open).

=head1 METHODS

=head2 diff

    my @ops = DBIO::MSSQL::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::MSSQL::Diff>). They detect
tables that are being dropped in this same diff pass: MSSQL's C<DROP TABLE>
already removes that table's own indexes, so emitting a standalone
C<DROP INDEX ... ON <table>> for one of them would fail once the table is gone
and abort the deploy. When these arguments are absent (e.g. direct
unit-test calls) the set is empty and no drops are suppressed, preserving the
original two-argument behaviour.

=head2 normalize_filter

    my $key = DBIO::MSSQL::Diff::Index->normalize_filter($predicate);

Returns a comparison key for the predicate of a filtered index; C<undef> and
blank give the empty string (no filter). Outside of string literals, which are
kept exactly: case is folded, whitespace collapsed and dropped around operators,
parentheses and commas, C<[name]> becomes C<name>, parentheses around a number
(C<(1)>, C<(-1)>) go, and so do the parentheses that wrap the whole predicate.
The server's C<([a]=(1))> and C<([a] IN ((1), (2), (3)))> and the C<a = 1>,
C<a IN (1,2,3)> a declaration says then come out the same (forms measured on
MSSQL 2022). The key is for comparing only, never written as SQL.

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
