package DBIO::DB2::Diff::Index;
# ABSTRACT: Diff operations for DB2 indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::DB2::DDL qw(_db2_quote_ident _db2_quote_table _split_table_name _index_is_duplicate);
use DBIO::Diff::Compare qw(changed_index_fields);


__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);


# The index behind a primary key is the primary key: made by the PRIMARY KEY
# clause of CREATE TABLE, gone with the constraint. Its name is the server's and
# differs in every schema (karr k45, ADR 0011).
sub _is_pk { return (($_[0] // {})->{origin} // '') eq 'pk' }

sub diff {
  my ($class, $source, $target, $source_tables, $target_tables,
      $target_columns, $target_ucs, $source_columns) = @_;
  my (@ops, @early);

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. Their indexes go with the table via DROP TABLE,
  # so a later standalone DROP INDEX for one of them must be suppressed (karr k19).
  $source_tables //= {};
  $target_tables //= {};
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  for my $table_name (sort keys %$target) {
    my $src_idxs = $source->{$table_name} // {};
    my $tgt_idxs = $target->{$table_name};

    # what covers a column sequence on this table, in the order the server
    # meets it: primary key, UNIQUE constraints, the indexes in name order
    my @existing;
    my @pk = map { $_->{column_name} }
      sort { ($a->{pk_position} // 0) <=> ($b->{pk_position} // 0) }
      grep { $_->{is_pk} } @{ ($target_columns // {})->{$table_name} // [] };
    push @existing, [ \@pk, 1 ] if @pk;
    push @existing, map { [ $_->[1], 1 ] }
      @{ ($target_ucs // {})->{$table_name} // [] };

    for my $name (sort keys %$tgt_idxs) {
      my $tgt = $tgt_idxs->{$name};
      next if _is_pk($tgt);
      my $cols = $tgt->{columns} // [];

      if (_index_is_duplicate($cols, $tgt->{is_unique}, \@existing)) {
        next;
      }
      push @existing, [ $cols, $tgt->{is_unique} ? 1 : 0 ];

      if (!exists $src_idxs->{$name}) {
        push @ops, $class->new(
          action     => 'create',
          table_name => $table_name,
          index_name => $name,
          index_info => $tgt,
        );
        next;
      }

      my $src = $src_idxs->{$name};

      if (scalar changed_index_fields($src, $tgt)) {
        push @ops, $class->new(
          action => 'drop', table_name => $table_name,
          index_name => $name, index_info => $src,
        );
        push @ops, $class->new(
          action => 'create', table_name => $table_name,
          index_name => $name, index_info => $tgt,
        );
      }
    }
  }

  for my $table_name (sort keys %$source) {
    # Db2 drops an index together with a column it covers (DROP COLUMN), so a
    # DROP INDEX behind it finds nothing (SQL0204N, karr k57): the columns this
    # pass drops, from the source and target column sections.
    my %gone;
    if ($source_columns && $source_columns->{$table_name}) {
      my %kept = map { $_->{column_name} => 1 } @{ ($target_columns // {})->{$table_name} // [] };
      %gone = map { $_->{column_name} => 1 }
        grep { !$kept{ $_->{column_name} } } @{ $source_columns->{$table_name} };
    }
    my $src_idxs = $source->{$table_name};
    my $tgt_idxs = $target->{$table_name} // {};
    # Skip the whole table when it is itself being dropped this pass; DROP TABLE
    # already removes its indexes, so a standalone DROP INDEX would fail (karr k19).
    next if $dropped_table{$table_name};
    my @creates = grep { $_->action eq 'create' && $_->table_name eq $table_name } @ops;
    for my $name (sort keys %$src_idxs) {
      next if exists $tgt_idxs->{$name};
      next if _is_pk($src_idxs->{$name});
      next if grep { $gone{$_} } @{ $src_idxs->{$name}{columns} // [] };
      my $drop = $class->new(
        action     => 'drop',
        table_name => $table_name,
        index_name => $name,
        index_info => $src_idxs->{$name},
      );
      # a create over the columns of this index is refused (SQL0605W) while the
      # index is still there: the drop goes first (karr k47)
      my $src = $src_idxs->{$name};
      if (grep { _index_is_duplicate($_->index_info->{columns}, $_->index_info->{is_unique},
                                     [ [ $src->{columns} // [], $src->{is_unique} ? 1 : 0 ] ]) } @creates) {
        push @early, $drop;
      }
      else {
        push @ops, $drop;
      }
    }
  }

  return (@early, @ops);
}

# An index lives in the schema of its table (karr k57): for a table named
# schema.table the index name is qualified with that schema.
sub _quoted_index_name {
  my ($self) = @_;
  my ($schema) = _split_table_name($self->table_name);
  return (defined $schema ? _db2_quote_ident($schema) . '.' : '') . _db2_quote_ident($self->index_name);
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $cols = join ', ',
      map { _db2_quote_ident($_) } @{ $self->index_info->{columns} // [] };
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique,
      $self->_quoted_index_name,
      _db2_quote_table($self->table_name),
      $cols;
  }
  return sprintf 'DROP INDEX %s;', $self->_quoted_index_name;
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

DBIO::DB2::Diff::Index - Diff operations for DB2 indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Index-level diff operations for DB2. DB2 supports C<CREATE INDEX> and
C<DROP INDEX>. Changed index definitions become a drop-then-create pair.
Index names must be unique within a schema.

C<new>, C<action> and C<summary_prefix> come from L<DBIO::Diff::Op>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DB2::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

Compares index sets across all tables. Index identity is by name; changed
definitions produce a drop-then-create pair. An index with C<< origin => 'pk' >>
(the one behind the primary key, which the model holds, see
L<DBIO::DB2::Introspect::Indexes>) is the primary key and never an operation,
on either side: not a C<CREATE INDEX> when only the target has one, not a
C<DROP INDEX> when only the source does. ADR 0011.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::DB2::Diff>). They are used to
detect tables being dropped in this same diff pass: DB2's C<DROP TABLE> already
removes that table's own indexes, so emitting a standalone C<DROP INDEX> for one
of them would fail (the index is already gone) and abort the deploy.
When these arguments are absent (e.g. direct unit-test calls) the dropped set is
empty and no drops are suppressed, preserving the original two-argument behaviour.

The optional last argument C<$source_columns> (the C<columns> section of the
source model) tells which columns this pass drops: Db2 drops an index with a
column it covers, so no C<DROP INDEX> is written for such an index.

The optional C<$target_columns> and C<$target_unique_constraints> (the
C<columns> and C<unique_constraints> sections of the target model) let the
diff know what already covers a column sequence. Db2 makes no index over
columns that the primary key, a C<UNIQUE> constraint or another index already
has in the same order -- SQL0605W, nothing created -- so no C<CREATE INDEX> is
emitted for one (a unique index is a duplicate only of a unique cover; see
L<DBIO::DB2::DDL/_index_is_duplicate>), and the follow-up diff stays empty. A
C<DROP INDEX> that frees a column sequence a created index takes over (a rename)
is moved in front of the creates, where the server would otherwise refuse the
create. ADR 0010.

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
