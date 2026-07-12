package DBIO::Firebird::Diff::Index;
# ABSTRACT: Diff operations for Firebird indexes

use strict;
use warnings;

use base 'DBIO::Diff::Op';

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Diff::Compare qw(changed_fields);


# new() and the action accessor come from DBIO::Diff::Op.
__PACKAGE__->mk_diff_accessors(qw/table_name index_name index_info/);


sub diff {
  my ($class, $source, $target, $source_tables, $target_tables) = @_;
  my @ops;

  # Tables present in the source model but absent from the target are being
  # dropped in this same pass. Their indexes go with the table via DROP TABLE,
  # so a later standalone DROP INDEX for one of them must be suppressed
  # (karr #14).
  $source_tables //= {};
  $target_tables //= {};
  my %dropped_table = map { $_ => 1 }
    grep { !exists $target_tables->{$_} } keys %$source_tables;

  for my $table_name (sort keys %$target) {
    my $src_idxs = $source->{$table_name} // {};
    my $tgt_idxs = $target->{$table_name};

    for my $name (sort keys %$tgt_idxs) {
      my $tgt = $tgt_idxs->{$name};

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
      # Firebird keeps ORDER-SENSITIVE column comparison: a reordered index is
      # a different index. So `columns` is a `dim` field (order-preserving),
      # NOT the order-independent `array`/is_same_index semantics core uses for
      # engines where index column order is irrelevant.
      my $changed = changed_fields($src, $tgt,
        bool => ['is_unique'],
        dim  => ['columns'],
      );

      if ($changed) {
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
    # Skip the whole table when it is itself being dropped this pass; Firebird's
    # DROP TABLE already removes its indexes, so a standalone DROP INDEX would
    # fail against the (now absent) table (karr #14).
    next if $dropped_table{$table_name};
    my $src_idxs = $source->{$table_name};
    my $tgt_idxs = $target->{$table_name} // {};
    for my $name (sort keys %$src_idxs) {
      next if exists $tgt_idxs->{$name};
      push @ops, $class->new(
        action     => 'drop',
        table_name => $table_name,
        index_name => $name,
        index_info => $src_idxs->{$name},
      );
    }
  }

  return @ops;
}


sub as_sql {
  my ($self) = @_;

  if ($self->action eq 'create') {
    my $unique = $self->index_info->{is_unique} ? 'UNIQUE ' : '';
    my $cols = join ', ',
      map { _quote_ident($_) } @{ $self->index_info->{columns} // [] };
    return sprintf 'CREATE %sINDEX %s ON %s (%s);',
      $unique,
      _quote_ident($self->index_name),
      _quote_ident($self->table_name),
      $cols;
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

DBIO::Firebird::Diff::Index - Diff operations for Firebird indexes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Index-level diff operations for Firebird. Firebird supports C<CREATE INDEX>
and C<DROP INDEX>. Changed index definitions become a drop-then-create pair.

=head1 METHODS

=head2 diff

    my @ops = DBIO::Firebird::Diff::Index->diff(
      $source, $target, $source_tables, $target_tables);

Compares index sets across all tables. Index identity is by name; a changed
definition produces a drop-then-create pair.

The optional C<$source_tables> / C<$target_tables> hashrefs are the C<tables>
sections of the two models (threaded in by L<DBIO::Firebird::Diff> via its
aux-section wiring). They are used to detect tables that are being dropped in
this same diff pass: Firebird's C<DROP TABLE> already removes that table's own
indexes, so a later standalone C<DROP INDEX> for one of them would fail once
the table is gone and abort the deploy (karr #14). When these arguments are
absent (e.g. direct unit-test calls) the dropped-table set is empty and no
drops are suppressed, preserving the original two-argument behaviour.

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
