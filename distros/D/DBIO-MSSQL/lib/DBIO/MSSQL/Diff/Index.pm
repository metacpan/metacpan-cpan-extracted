package DBIO::MSSQL::Diff::Index;
# ABSTRACT: Diff operations for MSSQL indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Diff::Compare qw(changed_fields);


__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. MSSQL's DROP TABLE also removes the table's own
  # indexes, so a later standalone DROP INDEX ... ON <table> would fail (the
  # table no longer exists). Suppress those drops (karr #15). Absent table
  # sections yield an empty set, preserving the original two-argument
  # behaviour used by direct unit-test calls.
  $source_tables //= {};
  $target_tables //= {};
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
      scalar changed_fields($_[0], $_[1], bool => ['is_unique'], dim => ['columns']);
    },
    on_new     => sub { $create->(@_) },
    on_changed => sub {
      my ($table, $name, $old, $new) = @_;
      ($drop->($table, $name, $old), $create->($table, $name, $new));
    },
    on_gone    => sub {
      my ($table, $name, $info) = @_;
      # Skip when the owning table is itself being dropped this pass; the
      # DROP TABLE already removes this index (karr #15).
      return () if $dropped_table{$table};
      return $drop->($table, $name, $info);
    },
  );
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $kind = $self->index_info->{kind} || '';
    my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED' : $kind eq 'nonclustered' ? 'NONCLUSTERED' : '';
    my $cols = join ', ',
      map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
    my $sql = sprintf 'CREATE %sINDEX %s ON %s %s(%s)',
      $unique,
      _quote_ident($self->index_name),
      _quote_ident($self->table_name),
      $kind_sql ? "$kind_sql " : '',
      $cols;
    return "$sql;";
  }
  return sprintf 'DROP INDEX %s ON %s;', _quote_ident($self->index_name), _quote_ident($self->table_name);
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

version 0.900001

=head1 DESCRIPTION

Index-level diff operations for MSSQL. MSSQL supports C<CREATE INDEX>,
C<DROP INDEX>, and C<CREATE INDEX ... DROP_EXISTING>. Built on
L<DBIO::Diff::Op> (the nested walk). A definition change is a drop-then-
create pair. Index column I<order> is significant, so the column list is
compared as an order-preserving C<dim> field (not the order-independent
default of L<DBIO::Diff::Compare/changed_index_fields>).

=head1 METHODS

=head2 diff

    my @ops = DBIO::MSSQL::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::MSSQL::Diff>). They detect
tables that are being dropped in this same diff pass: MSSQL's C<DROP TABLE>
already removes that table's own indexes, so emitting a standalone
C<DROP INDEX ... ON <table>> for one of them would fail once the table is gone
and abort the deploy (karr #15). When these arguments are absent (e.g. direct
unit-test calls) the set is empty and no drops are suppressed, preserving the
original two-argument behaviour.

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
