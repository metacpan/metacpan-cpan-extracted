package DBIO::Oracle::Diff::Index;
# ABSTRACT: Diff operations for Oracle indexes

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Diff::Op';

use DBIO::Oracle::Identifier ();
use DBIO::Diff::Compare qw(changed_index_fields);

__PACKAGE__->mk_diff_accessors(qw(index_name table_name index_info));



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  $source        ||= {};
  $target        ||= {};
  $source_tables ||= $source;
  $target_tables ||= $target;

  my $new_index = sub {
    my ($tbl, $idx_name, $idx) = @_;
    return $class->new(
      action     => 'create',
      index_name => $idx_name,
      table_name => $tbl,
      index_info => $idx,
    );
  };

  my @ops = $class->diff_nested(
    $source, $target,
    scope => 'both',
    source_tables => $source_tables,
    target_tables => $target_tables,
    changed_when => sub {
      my ($old, $new) = @_;
      return scalar changed_index_fields($old, $new);
    },
    on_new => $new_index,
    on_changed => sub {
      my ($tbl, $idx_name, $old, $new) = @_;
      return (
        $class->new(
          action     => 'drop',
          index_name => $idx_name,
          table_name => $tbl,
          index_info => $old,
        ),
        $class->new(
          action     => 'create',
          index_name => $idx_name,
          table_name => $tbl,
          index_info => $new,
        ),
      );
    },
    on_gone => sub {
      my ($tbl, $idx_name, $idx) = @_;
      $class->new(
        action     => 'drop',
        index_name => $idx_name,
        table_name => $tbl,
        index_info => $idx,
      );
    },
  );

  # The tables only the target has: all of their indexes are new.
  for my $tbl (sort keys %$target) {
    next if exists $source_tables->{$tbl} || !exists $target_tables->{$tbl};
    my $indexes = $target->{$tbl};
    push @ops, map { $new_index->($tbl, $_, $indexes->{$_}) } sort keys %$indexes;
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;

  my $idx = DBIO::Oracle::Identifier::quote_in($self->table_name, $self->index_name);
  my $tbl = DBIO::Oracle::Identifier::quote_table($self->table_name);
  my $info = $self->index_info;
  my $cols = join(', ', map { DBIO::Oracle::Identifier::quote($_) } @{ $info->{columns} // [] });

  if ($self->action eq 'create') {
    my $unique = $info->{is_unique} ? 'UNIQUE ' : '';
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique, $idx, $tbl, $cols;
  }

  if ($self->action eq 'drop') {
    return sprintf 'DROP INDEX %s;', $idx;
  }
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

DBIO::Oracle::Diff::Index - Diff operations for Oracle indexes

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Index-level diff operations for Oracle.

=head1 ATTRIBUTES

=head2 index_name

The bare index name.

=head2 table_name

The table key the index belongs to: a bare name, or C<schema.table>; the index
lives in the schema of its table.

=head2 index_info

Hashref of index metadata: C<is_unique>, C<columns>.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Oracle::Diff::Index->diff(
        $source, $target, $source_tables, $target_tables,
    );

Walks the indexes of tables present in B<both> models, and creates every
index of a table that only the target has, after the
C<CREATE TABLE> L<DBIO::Oracle::Diff::Table> wrote for it. Source-only tables
have their indexes dropped with the table, so they are not walked, and no
C<DROP INDEX> follows a C<DROP TABLE> (Oracle refuses it, ORA-01418). The
tables decide which tables there are; without them the tables are the keys of
the two index sections. The indexes Oracle keeps for a primary key or a unique
constraint are not in the model and are not created here; they come with the
C<CREATE TABLE>.

An existing index (same name, same table) whose C<is_unique> or C<columns>
changed is detected via L<DBIO::Diff::Compare/changed_index_fields> and
emitted as a drop+create pair -- Oracle has no in-place C<ALTER INDEX> for
column or uniqueness changes.

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
