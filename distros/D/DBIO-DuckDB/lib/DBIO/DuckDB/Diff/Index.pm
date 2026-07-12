package DBIO::DuckDB::Diff::Index;
# ABSTRACT: Diff operations for DuckDB indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::DuckDB::DDL::Emit qw(create_index);
use DBIO::Diff::Compare qw(changed_index_fields);

__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);



sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. DuckDB's DROP TABLE removes the table's own
  # indexes, so a later standalone DROP INDEX for one of them must be
  # suppressed (karr #8).
  $source_tables //= {};
  $target_tables //= {};
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  return $class->diff_nested($source, $target,
    scope        => 'all',
    changed_when => sub {
      my ($old, $new) = @_;
      scalar changed_index_fields($old, $new);
    },
    on_new => sub {
      my ($table_name, $name, $tgt) = @_;
      $class->new(
        action     => 'create',
        table_name => $table_name,
        index_name => $name,
        index_info => $tgt,
      );
    },
    on_changed => sub {
      my ($table_name, $name, $old, $new) = @_;
      return (
        $class->new(
          action => 'drop', table_name => $table_name,
          index_name => $name, index_info => $old,
        ),
        $class->new(
          action => 'create', table_name => $table_name,
          index_name => $name, index_info => $new,
        ),
      );
    },
    on_gone => sub {
      my ($table_name, $name, $old) = @_;
      # Skip when the owning table is itself being dropped this pass; DuckDB's
      # DROP TABLE already removes this index (karr #8).
      return () if $dropped_table{$table_name};
      $class->new(
        action     => 'drop',
        table_name => $table_name,
        index_name => $name,
        index_info => $old,
      );
    },
  );
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    if (my $sql = $self->index_info->{sql}) {
      $sql .= ';' unless $sql =~ /;\s*$/;
      return $sql;
    }
    return create_index(
      name    => $self->index_name,
      table   => $self->table_name,
      columns => $self->index_info->{columns} // [],
      unique  => $self->index_info->{is_unique},
    );
  }
  return sprintf 'DROP INDEX %s;', _quote_ident($self->index_name);
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

DBIO::DuckDB::Diff::Index - Diff operations for DuckDB indexes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Index-level diff operations for DuckDB. DuckDB has no C<ALTER INDEX>,
so changed definitions become a drop-then-create pair. Indexes backing
PRIMARY KEY / UNIQUE constraints are filtered out upstream by the
introspect layer -- they belong to the table, not to explicit CREATE
INDEX.

=head1 METHODS

=head2 diff

    my @ops = DBIO::DuckDB::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

Compares index sets across all tables. Index identity is by name; changed
definitions become a drop-then-create pair.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::DuckDB::Diff>). They detect
tables being dropped in this same pass: DuckDB's C<DROP TABLE> already removes
that table's own indexes, so emitting a later standalone C<DROP INDEX> for one
of them would fail once the table is gone (the diff order is
tables-then-columns-then-indexes). Such drops are suppressed. When these
arguments are absent (e.g. direct unit-test calls) the dropped-table set is
empty and no drops are suppressed, preserving the original two-argument
behaviour.

=head2 as_sql

=head2 summary

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
